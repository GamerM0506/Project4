import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../injection_container.dart';
import '../../../group/data/datasources/group_remote_data_source.dart';
import '../../../group/data/models/group_model.dart';
import '../../data/campaign_error.dart';
import '../../data/datasources/campaign_remote_data_source.dart';
import '../../data/donation_eligibility.dart';
import '../../data/models/campaign_item_input.dart';
import '../../data/models/campaign_model.dart';
import '../widgets/donation_gate.dart';

class CampaignDetailPage extends StatefulWidget {
  const CampaignDetailPage({super.key, required this.campaignId});

  final String campaignId;

  @override
  State<CampaignDetailPage> createState() => _CampaignDetailPageState();
}

class _CampaignDetailPageState extends State<CampaignDetailPage> {
  late Future<CampaignModel> _future;

  /// Quyền quyên góp, kiểm tra ngay khi tải xong đợt để không bắt người dùng
  /// điền hết form rồi mới nhận 403 từ backend.
  DonationEligibility? _eligibility;
  bool _checkingAccess = false;
  String? _checkedGroupId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _eligibility = null;
    _checkedGroupId = null;
    _future = sl<CampaignRemoteDataSource>().getCampaign(widget.campaignId);
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  Future<void> _checkAccess(String groupId, {bool force = false}) async {
    if (_checkingAccess) return;
    if (!force && _checkedGroupId == groupId) return;
    _checkedGroupId = groupId;
    setState(() => _checkingAccess = true);
    final result = await checkDonationEligibility(
      sl<GroupRemoteDataSource>(),
      groupId,
    );
    if (!mounted) return;
    setState(() {
      _eligibility = result;
      _checkingAccess = false;
    });
  }

  void _donate(CampaignModel campaign, {String? itemId}) {
    context.push(
      AppRoutes.donate,
      extra: {
        'campaignId': campaign.id,
        if (itemId != null) 'campaignItemId': itemId,
        'groupId': campaign.groupId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<CampaignModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(),
              body: AppEmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Không tải được đợt quyên góp',
                message: snapshot.hasError
                    ? campaignErrorMessage(snapshot.error!)
                    : 'Đợt này có thể đã bị gỡ.',
                isError: true,
                actionLabel: 'Thử lại',
                onAction: () => setState(_reload),
              ),
            );
          }

          final campaign = snapshot.data!;

          // Kiểm tra quyền sau khi frame hiện tại vẽ xong.
          if (campaign.groupId.isNotEmpty &&
              _checkedGroupId != campaign.groupId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkAccess(campaign.groupId);
            });
          }

          final eligibility = _eligibility;
          final canDonate = eligibility?.canDonate ?? false;
          final isActive = campaign.status == 'active';

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _DetailAppBar(campaign: campaign),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, isActive ? 110 : 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _ProgressCard(campaign: campaign),
                      const SizedBox(height: 14),
                      if (eligibility?.group != null)
                        _GroupTile(
                          group: eligibility!.group!,
                          onTap: () => context.push(
                            '${AppRoutes.groupDetail}/${campaign.groupId}',
                          ),
                        ),
                      if (_checkingAccess && eligibility == null) ...[
                        const SizedBox(height: 14),
                        const _AccessCheckPlaceholder(),
                      ] else if (eligibility != null && !canDonate) ...[
                        const SizedBox(height: 14),
                        DonationGateBanner(
                          eligibility: eligibility,
                          onJoined: () =>
                              _checkAccess(campaign.groupId, force: true),
                          onRetry: () =>
                              _checkAccess(campaign.groupId, force: true),
                        ),
                      ],
                      if (campaign.description?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 22),
                        _Section(
                          icon: Icons.info_outline_rounded,
                          title: 'Về đợt quyên góp',
                          child: Text(
                            campaign.description!.trim(),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(height: 1.55),
                          ),
                        ),
                      ],
                      if (campaign.beneficiaryDescription?.trim().isNotEmpty ==
                          true) ...[
                        const SizedBox(height: 18),
                        _Section(
                          icon: Icons.favorite_outline_rounded,
                          title: 'Đối tượng thụ hưởng',
                          child: Text(
                            campaign.beneficiaryDescription!.trim(),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(height: 1.55),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      _ItemsHeader(count: campaign.items.length),
                      const SizedBox(height: 12),
                      if (campaign.items.isEmpty)
                        _EmptyItems()
                      else
                        for (final item in campaign.items) ...[
                          _ItemCard(
                            item: item,
                            canDonate: canDonate && isActive,
                            showAction: isActive,
                            onDonate: () => _donate(campaign, itemId: item.id),
                          ),
                          const SizedBox(height: 10),
                        ],
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<CampaignModel>(
        future: _future,
        builder: (context, snapshot) {
          final campaign = snapshot.data;
          if (campaign == null || campaign.status != 'active') {
            return const SizedBox.shrink();
          }
          return _DonateBar(
            eligibility: _eligibility,
            checking: _checkingAccess,
            onDonate: () => _donate(campaign),
            onJoin: () => showJoinGroupSheet(
              context,
              groupId: campaign.groupId,
              groupName: _eligibility?.groupName ?? 'hội nhóm này',
              onJoined: () => _checkAccess(campaign.groupId, force: true),
            ),
          );
        },
      ),
    );
  }
}

/// AppBar co giãn với dải bìa gradient theo trạng thái đợt.
class _DetailAppBar extends StatelessWidget {
  const _DetailAppBar({required this.campaign});

  final CampaignModel campaign;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final done = campaign.status == 'fulfilled';
    final closed = campaign.status == 'closed';
    final daysLeft = campaign.deadline?.difference(DateTime.now()).inDays;
    final urgent =
        campaign.status == 'active' && daysLeft != null && daysLeft <= 7;

    final (Color from, Color to) = done
        ? (colors.tertiaryContainer, colors.tertiary.withValues(alpha: 0.35))
        : closed
        ? (colors.surfaceContainerHigh, colors.surfaceContainerHighest)
        : (colors.primaryContainer, colors.primary.withValues(alpha: 0.3));

    return SliverAppBar(
      expandedHeight: 188,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [from, to],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -30,
                child: Icon(
                  done
                      ? Icons.card_giftcard_rounded
                      : Icons.volunteer_activism_rounded,
                  size: 150,
                  color: colors.onPrimaryContainer.withValues(alpha: 0.12),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Pill(
                          text: campaign.code,
                          icon: Icons.tag_rounded,
                          tone: _PillTone.neutral,
                        ),
                        if (done)
                          const _Pill(
                            text: 'Đã trao',
                            icon: Icons.check_circle_rounded,
                            tone: _PillTone.success,
                          )
                        else if (closed)
                          const _Pill(
                            text: 'Đã đóng',
                            icon: Icons.lock_outline_rounded,
                            tone: _PillTone.neutral,
                          )
                        else if (urgent)
                          _Pill(
                            text: daysLeft <= 0
                                ? 'Hết hạn hôm nay'
                                : 'Còn $daysLeft ngày',
                            icon: Icons.local_fire_department_rounded,
                            tone: _PillTone.danger,
                          )
                        else if (daysLeft != null)
                          _Pill(
                            text: 'Còn $daysLeft ngày',
                            icon: Icons.schedule_rounded,
                            tone: _PillTone.neutral,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      campaign.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thẻ tiến độ tổng: phần trăm lớn + số liệu phụ.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.campaign});

  final CampaignModel campaign;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final percent = (campaign.progress * 100).round();
    final remaining = (campaign.totalTarget - campaign.totalReceived).clamp(
      0,
      campaign.totalTarget,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$percent',
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 2),
                child: Text(
                  '%',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${campaign.totalReceived}/${campaign.totalTarget}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'vật phẩm đã nhận',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: campaign.progress,
              minHeight: 10,
              backgroundColor: colors.surfaceContainerHighest,
            ),
          ),
          if (remaining > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.flag_outlined,
                  size: 14,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Text(
                  'Còn thiếu $remaining vật phẩm',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group, required this.onTap});

  final GroupModel group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              child: const Icon(Icons.groups_rounded, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổ chức bởi',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    group.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: colors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _ItemsHeader extends StatelessWidget {
  const _ItemsHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.inventory_2_outlined, size: 17, color: colors.primary),
        const SizedBox(width: 8),
        Text(
          'Vật phẩm đang cần',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Thẻ một vật phẩm: tiến độ riêng, tình trạng yêu cầu, ghi chú.
class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.canDonate,
    required this.showAction,
    required this.onDonate,
  });

  final CampaignItemModel item;
  final bool canDonate;
  final bool showAction;
  final VoidCallback onDonate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final done = item.remaining == 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (done)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'Đã đủ',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.onTertiaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Text(
                  'còn ${item.remaining} ${item.unit ?? ''}'.trim(),
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          if (item.conditionRequired != null || item.note != null) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (item.conditionRequired != null)
                  _MetaChip(
                    icon: Icons.verified_outlined,
                    text: itemConditionLabel(item.conditionRequired),
                  ),
                if (item.note?.trim().isNotEmpty == true)
                  _MetaChip(
                    icon: Icons.sticky_note_2_outlined,
                    text: item.note!.trim(),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: item.progress,
                    minHeight: 6,
                    backgroundColor: colors.surfaceContainerHighest,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${item.receivedQuantity}/${item.targetQuantity}',
                style: textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (showAction && canDonate) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onDonate,
                icon: const Icon(Icons.add_rounded, size: 17),
                label: Text(done ? 'Vẫn đóng góp' : 'Đóng góp món này'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyItems extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 20,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Đợt này chưa khai báo vật phẩm cần nhận.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thanh hành động cố định dưới màn hình.
class _DonateBar extends StatelessWidget {
  const _DonateBar({
    required this.eligibility,
    required this.checking,
    required this.onDonate,
    required this.onJoin,
  });

  final DonationEligibility? eligibility;
  final bool checking;
  final VoidCallback onDonate;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget button;
    if (checking && eligibility == null) {
      button = const FilledButton(
        onPressed: null,
        child: Text('Đang kiểm tra quyền...'),
      );
    } else if (eligibility?.canDonate ?? false) {
      button = FilledButton.icon(
        onPressed: onDonate,
        icon: const Icon(Icons.volunteer_activism_rounded, size: 19),
        label: const Text('Quyên góp ngay'),
      );
    } else if (eligibility?.canRequestJoin ?? false) {
      button = FilledButton.tonalIcon(
        onPressed: onJoin,
        icon: const Icon(Icons.group_add_rounded, size: 19),
        label: const Text('Tham gia để quyên góp'),
      );
    } else {
      button = FilledButton(
        onPressed: null,
        child: Text(
          switch (eligibility?.access) {
            DonationAccess.pending => 'Đang chờ hội nhóm duyệt',
            DonationAccess.banned => 'Không thể quyên góp',
            DonationAccess.groupInactive => 'Hội nhóm tạm dừng',
            _ => 'Chưa thể quyên góp',
          },
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            top: BorderSide(
              color: colors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: button,
        ),
      ),
    );
  }
}

enum _PillTone { neutral, success, danger }

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.icon, required this.tone});

  final String text;
  final IconData icon;
  final _PillTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (Color fg, Color bg) = switch (tone) {
      _PillTone.success => (colors.onTertiaryContainer, colors.surface),
      _PillTone.danger => (colors.onErrorContainer, colors.errorContainer),
      _PillTone.neutral => (
        colors.onSurfaceVariant,
        colors.surface.withValues(alpha: 0.85),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessCheckPlaceholder extends StatelessWidget {
  const _AccessCheckPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Đang kiểm tra quyền quyên góp...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
