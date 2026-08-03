import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../injection_container.dart';
import '../../../donation/data/campaign_error.dart';
import '../../../donation/data/datasources/campaign_remote_data_source.dart';
import '../../../donation/data/donation_labels.dart';
import '../../../donation/data/models/campaign_item_input.dart';
import '../../../donation/data/models/campaign_model.dart';
import '../../../donation/data/models/contribution_model.dart';
import '../../../donation/presentation/pages/create_campaign_page.dart';
import '../../../donation/presentation/widgets/contribution_review_sheets.dart';
import '../../../donation/presentation/widgets/donation_photo_picker.dart';
import '../../../user/presentation/cubit/user_cubit.dart';
import '../../../user/presentation/cubit/user_state.dart';
import '../../data/models/group_model.dart';

class GroupCampaignsTab extends StatefulWidget {
  const GroupCampaignsTab({super.key, required this.group});

  final GroupModel group;

  @override
  State<GroupCampaignsTab> createState() => _GroupCampaignsTabState();
}

class _GroupCampaignsTabState extends State<GroupCampaignsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<List<CampaignModel>> _campaignsFuture;
  late Future<List<ContributionModel>> _contributionsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _reload();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reload() {
    final dataSource = sl<CampaignRemoteDataSource>();
    _campaignsFuture = dataSource.getCampaigns(
      groupId: widget.group.id,
      status: '',
    );
    // Phải gọi theo từng campaign_id: backend chỉ trả đóng góp của người khác
    // khi có campaign_id (kiểm tra quyền moderator theo đợt). Bỏ tham số này
    // sẽ khiến moderator chỉ thấy đơn của chính mình.
    _contributionsFuture = _campaignsFuture.then((campaigns) async {
      if (campaigns.isEmpty) return <ContributionModel>[];
      final results = await Future.wait(
        campaigns.map(
          (campaign) => dataSource.getContributions(campaignId: campaign.id),
        ),
      );
      return results.expand((items) => items).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> _refresh() async {
    setState(_reload);
    await Future.wait([_campaignsFuture, _contributionsFuture]);
  }

  @override
  Widget build(BuildContext context) {
    // Backend yêu cầu owner/moderator cho create/update/close/deliver.
    // Không hiện các nút này với thành viên thường để tránh 403 vô nghĩa.
    final group = widget.group;
    final userState = context.watch<UserCubit>().state;
    final currentUserId = userState is UserLoaded ? userState.user.id : null;
    final canModerate =
        (group.myStatus == 'approved' &&
            (group.myRole == 'owner' || group.myRole == 'moderator')) ||
        (currentUserId != null && currentUserId == group.ownerId);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Đợt quyên góp'),
                  Tab(text: 'Đóng góp nhận được'),
                ],
              ),
            ),
            if (canModerate)
              IconButton(
                tooltip: 'Tạo đợt quyên góp',
                onPressed: _createCampaign,
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _CampaignList(
                future: _campaignsFuture,
                onRefresh: _refresh,
                onChanged: _refresh,
                canModerate: canModerate,
              ),
              _ContributionList(
                future: _contributionsFuture,
                onRefresh: _refresh,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _createCampaign() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateCampaignPage(
          groupId: widget.group.id,
          groupName: widget.group.name,
        ),
      ),
    );
    if (created == true && mounted) await _refresh();
  }
}

class _CampaignList extends StatelessWidget {
  const _CampaignList({
    required this.future,
    required this.onRefresh,
    required this.onChanged,
    required this.canModerate,
  });

  final Future<List<CampaignModel>> future;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onChanged;
  final bool canModerate;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CampaignModel>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return AppEmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Chưa tải được danh sách',
            message: campaignErrorMessage(
              snapshot.error!,
              fallback: 'Vui lòng kéo xuống để thử lại.',
            ),
            isError: true,
            actionLabel: 'Thử lại',
            onAction: onRefresh,
          );
        }
        final campaigns = snapshot.data ?? const [];
        if (campaigns.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: Icons.volunteer_activism_outlined,
                    title: 'Chưa có đợt quyên góp',
                    message: canModerate
                        ? 'Tạo đợt đầu tiên để bắt đầu kêu gọi vật phẩm.'
                        : 'Hội nhóm chưa mở đợt quyên góp nào.',
                  ),
                ),
              ],
            ),
          );
        }

        // Đợt đang mở lên đầu, rồi mới đến đã đóng/đã trao.
        final sorted = [...campaigns]..sort((a, b) {
          final rank = _statusRank(a.status).compareTo(_statusRank(b.status));
          if (rank != 0) return rank;
          return b.createdAt.compareTo(a.createdAt);
        });

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final campaign = sorted[index];
              return _CampaignCard(
                campaign: campaign,
                canModerate: canModerate,
                onOpen: () => context.push(
                  '${AppRoutes.campaigns}/detail/${campaign.id}',
                ),
                onEdit: () => _edit(context, campaign),
                onClose: () => _close(context, campaign),
                onDeliver: () => _deliver(context, campaign),
              );
            },
          ),
        );
      },
    );
  }

  static int _statusRank(String status) => switch (status) {
    'active' => 0,
    'closed' => 1,
    'fulfilled' => 2,
    _ => 3,
  };

  Future<void> _edit(BuildContext context, CampaignModel campaign) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditCampaignForm(campaign: campaign),
    );
    if (updated == true) await onChanged();
  }

  Future<void> _close(BuildContext context, CampaignModel campaign) async {
    final closed = await showCloseCampaignSheet(
      context,
      campaignId: campaign.id,
      campaignTitle: campaign.title,
    );
    if (closed == true) await onChanged();
  }

  Future<void> _deliver(BuildContext context, CampaignModel campaign) async {
    final delivered = await showDeliverCampaignSheet(
      context,
      campaignId: campaign.id,
      campaignTitle: campaign.title,
    );
    if (delivered == true) await onChanged();
  }
}

/// Thẻ một đợt quyên góp trong trang quản lý của hội nhóm.
class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    required this.campaign,
    required this.canModerate,
    required this.onOpen,
    required this.onEdit,
    required this.onClose,
    required this.onDeliver,
  });

  final CampaignModel campaign;
  final bool canModerate;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onClose;
  final VoidCallback onDeliver;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isActive = campaign.status == 'active';
    // Chỉ đợt đang mở hoặc đã đóng mới còn thao tác; đã trao/đã huỷ là trạng
    // thái cuối.
    final showActions =
        canModerate && (isActive || campaign.status == 'closed');
    final overdue = campaign.isOverdue;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          campaign.title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AppStatusBadge(status: campaign.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        campaign.code,
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '·',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 13,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${campaign.items.length} loại vật phẩm',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: campaign.progress,
                            minHeight: 8,
                            backgroundColor: colors.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(campaign.progress * 100).round()}%',
                        style: textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Đã nhận ${campaign.totalReceived}/${campaign.totalTarget}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      if (campaign.deadline != null)
                        Row(
                          children: [
                            Icon(
                              overdue
                                  ? Icons.event_busy_outlined
                                  : Icons.event_outlined,
                              size: 13,
                              color: overdue
                                  ? colors.error
                                  : colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              overdue
                                  ? 'Quá hạn ${_formatDate(campaign.deadline!)}'
                                  : 'Đến ${_formatDate(campaign.deadline!)}',
                              style: textTheme.bodySmall?.copyWith(
                                color: overdue
                                    ? colors.error
                                    : colors.onSurfaceVariant,
                                fontWeight: overdue ? FontWeight.w600 : null,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (showActions) ...[
            Divider(
              height: 1,
              color: colors.outlineVariant.withValues(alpha: 0.5),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Sửa'),
                  ),
                  if (isActive)
                    TextButton.icon(
                      onPressed: onClose,
                      icon: const Icon(Icons.lock_outline_rounded, size: 16),
                      label: const Text('Đóng đợt'),
                    ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: onDeliver,
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Xác nhận trao'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContributionList extends StatefulWidget {
  const _ContributionList({required this.future, required this.onRefresh});

  final Future<List<ContributionModel>> future;
  final Future<void> Function() onRefresh;

  @override
  State<_ContributionList> createState() => _ContributionListState();
}

class _ContributionListState extends State<_ContributionList> {
  /// Lọc phía client: backend đã trả toàn bộ đơn của các đợt trong nhóm.
  ///
  /// Để `null` cho tới khi có dữ liệu, rồi [_resolveFilter] chọn mục đang thật
  /// sự có việc. Nếu cứng nhắc mặc định `pending`, đơn đã duyệt nhưng còn món
  /// chưa kiểm tra sẽ bị giấu và moderator tưởng không còn gì để làm.
  String? _filter;

  /// Xếp theo đúng thứ tự vòng đời của đơn.
  static const _filters = <({String value, String label})>[
    (value: 'pending', label: 'Chờ duyệt'),
    (value: 'checking', label: 'Đang kiểm tra'),
    (value: 'done', label: 'Đã xong'),
    (value: '', label: 'Tất cả'),
  ];

  static bool _matchesFilter(ContributionModel contribution, String filter) =>
      switch (filter) {
        'pending' => contribution.status == 'pending',
        'checking' =>
          contribution.status == 'accepted' ||
              contribution.status == 'received',
        'done' => const {
          'completed',
          'rejected',
          'cancelled',
        }.contains(contribution.status),
        _ => true,
      };

  /// Mục chọn sẵn lần đầu: ưu tiên đơn chờ duyệt, không có thì nhảy sang đơn
  /// đang kiểm tra để không mở ra một danh sách rỗng trong khi vẫn còn việc.
  String _resolveFilter(List<ContributionModel> all) {
    final current = _filter;
    if (current != null) return current;
    if (all.any((c) => _matchesFilter(c, 'pending'))) return 'pending';
    if (all.any((c) => _matchesFilter(c, 'checking'))) return 'checking';
    return 'pending';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ContributionModel>>(
      future: widget.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return AppEmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Chưa tải được đóng góp',
            message: campaignErrorMessage(
              snapshot.error!,
              fallback: 'Vui lòng kéo xuống để thử lại.',
            ),
            isError: true,
            actionLabel: 'Thử lại',
            onAction: widget.onRefresh,
          );
        }
        final all = snapshot.data ?? const <ContributionModel>[];
        final active = _resolveFilter(all);
        final visible = all
            .where((contribution) => _matchesFilter(contribution, active))
            .toList();

        return Column(
          children: [
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final count = all
                      .where(
                        (contribution) =>
                            _matchesFilter(contribution, filter.value),
                      )
                      .length;
                  return Center(
                    child: FilterChip(
                      label: Text('${filter.label} ($count)'),
                      selected: active == filter.value,
                      onSelected: (_) =>
                          setState(() => _filter = filter.value),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? RefreshIndicator(
                      onRefresh: widget.onRefresh,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: AppEmptyState(
                              icon: Icons.inbox_outlined,
                              title: all.isEmpty
                                  ? 'Chưa có đóng góp nào'
                                  : 'Không có đơn ở mục này',
                              message: all.isEmpty
                                  ? 'Khi có người quyên góp, đơn sẽ hiện ở đây.'
                                  : 'Thử chọn mục "Tất cả" để xem toàn bộ đơn.',
                            ),                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: widget.onRefresh,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _ModeratorContributionCard(
                              contribution: visible[index],
                              onChanged: widget.onRefresh,
                            ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ModeratorContributionCard extends StatefulWidget {
  const _ModeratorContributionCard({
    required this.contribution,
    required this.onChanged,
  });

  final ContributionModel contribution;
  final Future<void> Function() onChanged;

  @override
  State<_ModeratorContributionCard> createState() =>
      _ModeratorContributionCardState();
}

class _ModeratorContributionCardState
    extends State<_ModeratorContributionCard> {
  ContributionModel? _detail;
  bool _loading = false;

  ContributionModel get _contribution => _detail ?? widget.contribution;

  @override
  void initState() {
    super.initState();
    // Đơn đang chờ xử lý mà danh sách không kèm vật phẩm thì tự tải chi tiết:
    // nếu không, nút "Kiểm tra" không hiện và moderator không biết làm gì tiếp.
    if (widget.contribution.items.isEmpty &&
        canCheckItems(widget.contribution.status)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetail());
    }
  }

  @override
  Widget build(BuildContext context) {
    final contribution = _contribution;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final checkable = canCheckItems(contribution.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    contribution.code,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                AppStatusBadge(status: contribution.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${pickupMethodLabel(contribution.pickupMethod)} · '
              '${contribution.items.length} loại · '
              '${contribution.totalQuantity} món',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (contribution.pickupMethod == 'pickup' &&
                contribution.pickupAddress?.isNotEmpty == true) ...[
              const SizedBox(height: 2),
              Text(
                contribution.pickupAddress!,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (contribution.items.isEmpty)
              TextButton.icon(
                onPressed: _loading ? null : _loadDetail,
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more_rounded, size: 18),
                label: Text(_loading ? 'Đang tải...' : 'Xem vật phẩm'),
              )
            else
              ...contribution.items.map(
                (item) => _ItemRow(
                  item: item,
                  canCheck: checkable && item.isPending,
                  onCheck: () => _checkItem(item),
                ),
              ),
            if (checkable && contribution.hasPendingItems) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.checklist_rounded,
                      size: 16,
                      color: colors.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bước tiếp theo: kiểm tra '
                        '${contribution.items.where((item) => item.isPending).length} món còn lại. '
                        'Xong tất cả thì đơn tự chuyển sang hoàn tất.',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (contribution.rejectedReason?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                'Lý do từ chối: ${contribution.rejectedReason}',
                style: textTheme.bodySmall?.copyWith(color: colors.error),
              ),
            ],
            if (contribution.isPending) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: _review,
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  label: const Text('Duyệt đơn'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    try {
      final detail = await sl<CampaignRemoteDataSource>().getContribution(
        widget.contribution.id,
      );
      if (mounted) setState(() => _detail = detail);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            campaignErrorMessage(
              error,
              fallback: 'Không tải được chi tiết đơn.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _review() async {
    final reviewed = await showReviewContributionSheet(
      context,
      contribution: _contribution,
    );
    if (reviewed == true) await widget.onChanged();
  }

  Future<void> _checkItem(ContributionItemModel item) async {
    final checked = await showCheckItemSheet(
      context,
      contributionId: _contribution.id,
      item: item,
    );
    if (checked == true) await widget.onChanged();
  }
}

/// Một vật phẩm trong đơn, kèm kết quả kiểm tra nếu đã có.
class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.canCheck,
    required this.onCheck,
  });

  final ContributionItemModel item;
  final bool canCheck;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                item.isRejected
                    ? Icons.cancel_outlined
                    : item.isAccepted
                    ? Icons.check_circle_outline
                    : Icons.inventory_2_outlined,
                size: 18,
                color: item.isRejected
                    ? colors.error
                    : item.isAccepted
                    ? colors.primary
                    : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.name} × ${item.quantity}',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Khai báo: ${itemConditionLabel(item.conditionDeclared)}'
                      ' · ${contributionItemStatusLabel(item.status)}',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (item.conditionMismatch)
                      Text(
                        'Thực tế: ${itemConditionLabel(item.conditionActual)}',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (item.checkNote?.isNotEmpty == true)
                      Text(
                        'Ghi chú: ${item.checkNote}',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    if (item.rejectReason?.isNotEmpty == true)
                      Text(
                        'Không đạt: ${item.rejectReason}',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.error,
                        ),
                      ),
                  ],
                ),
              ),
              if (canCheck)
                FilledButton.tonal(
                  onPressed: onCheck,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: const Text('Kiểm tra'),
                ),
            ],
          ),
          if (item.images.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: RemotePhotoStrip(
                imageUrls: item.images.map((image) => image.imageUrl).toList(),
                height: 62,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Form sửa metadata đợt quyên góp (`PUT /donation/campaigns/{id}`).
/// Backend không cho sửa danh sách vật phẩm sau khi đã tạo.
class _EditCampaignForm extends StatefulWidget {
  const _EditCampaignForm({required this.campaign});

  final CampaignModel campaign;

  @override
  State<_EditCampaignForm> createState() => _EditCampaignFormState();
}

class _EditCampaignFormState extends State<_EditCampaignForm> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _beneficiary;
  late DateTime? _deadline;
  bool _submitting = false;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.campaign.title);
    _description = TextEditingController(
      text: widget.campaign.description ?? '',
    );
    _beneficiary = TextEditingController(
      text: widget.campaign.beneficiaryDescription ?? '',
    );
    _deadline = widget.campaign.deadline;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _beneficiary.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final initial = _deadline ?? now.add(const Duration(days: 14));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Vui lòng nhập tên đợt');
      return;
    }
    if (title.length > 200) {
      setState(() => _titleError = 'Tên đợt tối đa 200 ký tự');
      return;
    }
    setState(() {
      _titleError = null;
      _submitting = true;
    });
    try {
      await sl<CampaignRemoteDataSource>().updateCampaign(
        widget.campaign.id,
        title: title,
        description: _description.text,
        beneficiaryDescription: _beneficiary.text,
        deadline: _deadline,
        clearDeadline: _deadline == null && widget.campaign.deadline != null,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            campaignErrorMessage(
              error,
              fallback: 'Không cập nhật được đợt quyên góp.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sửa đợt quyên góp',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.campaign.code,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _title,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: 'Tên đợt *',
                errorText: _titleError,
                counterText: '',
              ),
            ),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Mô tả'),
            ),
            TextField(
              controller: _beneficiary,
              decoration: const InputDecoration(
                labelText: 'Đối tượng thụ hưởng',
              ),
            ),
            const SizedBox(height: 12),
            _DeadlineField(
              deadline: _deadline,
              onPick: _pickDeadline,
              onClear: () => setState(() => _deadline = null),
            ),
            const SizedBox(height: 8),
            Text(
              'Danh sách vật phẩm không thể thay đổi sau khi đã tạo đợt.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'Đang lưu...' : 'Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dropdown danh mục lấy từ `GET /donation/categories`.
class _DeadlineField extends StatelessWidget {
  const _DeadlineField({
    required this.deadline,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? deadline;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Hạn chót',
          helperText: 'Không bắt buộc',
          suffixIcon: deadline == null
              ? const Icon(Icons.calendar_today_outlined, size: 18)
              : IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                ),
        ),
        child: Text(
          deadline == null ? 'Chưa đặt' : _formatDate(deadline!),
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
