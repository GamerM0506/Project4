import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_hero_banner.dart';
import '../../../../injection_container.dart';
import '../../data/campaign_error.dart';
import '../../data/datasources/campaign_remote_data_source.dart';
import '../../data/models/campaign_model.dart';

/// Bộ lọc nhanh theo trạng thái đợt.
enum _CampaignFilter {
  active('Đang mở', 'active'),
  urgent('Sắp hết hạn', null),
  fulfilled('Đã trao', 'fulfilled'),
  all('Tất cả', '');

  const _CampaignFilter(this.label, this.status);

  final String label;

  /// null = lọc phía client, '' = mọi trạng thái.
  final String? status;
}

/// Chieu cao banner khi mo rong.
const double _kBannerHeight = 196;

class CampaignsPage extends StatefulWidget {
  const CampaignsPage({super.key});

  @override
  State<CampaignsPage> createState() => _CampaignsPageState();
}

class _CampaignsPageState extends State<CampaignsPage> {
  late Future<List<CampaignModel>> _future;
  _CampaignFilter _filter = _CampaignFilter.active;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    // Tải mọi trạng thái một lần rồi lọc phía client: danh sách đợt nhỏ,
    // đổi tab tức thì dễ chịu hơn là gọi lại mạng mỗi lần.
    _future = sl<CampaignRemoteDataSource>().getCampaigns(status: '');
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  List<CampaignModel> _apply(List<CampaignModel> source) {
    final now = DateTime.now();
    final filtered = switch (_filter) {
      // Sao chép: `sort` bên dưới thay đổi tại chỗ, không được đụng vào
      // danh sách gốc mà FutureBuilder đang giữ.
      _CampaignFilter.all => [...source],
      _CampaignFilter.active =>
        source.where((c) => c.status == 'active').toList(),
      _CampaignFilter.fulfilled =>
        source.where((c) => c.status == 'fulfilled').toList(),
      _CampaignFilter.urgent => source
          .where(
            (c) =>
                c.status == 'active' &&
                c.deadline != null &&
                c.deadline!.difference(now).inDays <= 7,
          )
          .toList(),
    };

    // Đợt đang mở lên trước, trong đó đợt sắp hết hạn ưu tiên hơn.
    filtered.sort((a, b) {
      final rank = _rank(a).compareTo(_rank(b));
      if (rank != 0) return rank;
      final ad = a.deadline;
      final bd = b.deadline;
      if (ad != null && bd != null) return ad.compareTo(bd);
      if (ad != null) return -1;
      if (bd != null) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return filtered;
  }

  static int _rank(CampaignModel c) => switch (c.status) {
    'active' => 0,
    'closed' => 1,
    'fulfilled' => 2,
    _ => 3,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<CampaignModel>>(
        future: _future,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState == ConnectionState.waiting;
          final all = snapshot.data ?? const <CampaignModel>[];
          final items = _apply(all);
          // Tính một lần rồi dùng lại cho cả 4 chip.
          final counts = _countsOf(all);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: _kBannerHeight,
                  pinned: true,
                  stretch: true,
                  // Chữ trắng trên nền brand đậm, kể cả khi đã thu gọn.
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  flexibleSpace: AppHeroBanner(
                    title: 'Cho đúng thứ người khác đang cần',
                    subtitle: 'Nhu cầu có thật từ các hội nhóm thiện nguyện.',
                    collapsedTitle: 'Đợt quyên góp',
                    icon: Icons.volunteer_activism_rounded,
                    expandedHeight: _kBannerHeight,
                    bottomBarHeight: AppFilterBar.height,
                    stats: _statsOf(all),
                  ),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(AppFilterBar.height),
                      child: AppFilterBar(
                        children: [
                          for (final f in _CampaignFilter.values)
                            FilterChip(
                              selected: _filter == f,
                              onSelected: (_) => setState(() => _filter = f),
                              showCheckmark: false,
                              label: Text(
                                (counts[f] ?? 0) > 0
                                    ? '${f.label} (${counts[f]})'
                                    : f.label,
                                style: _filter == f
                                    ? TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        fontWeight: FontWeight.w700,
                                      )
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                ),
                if (loading)
                  const SliverToBoxAdapter(child: _CampaignSkeleton())
                else if (snapshot.hasError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'Chưa tải được đợt quyên góp',
                      message: campaignErrorMessage(
                        snapshot.error!,
                        fallback: 'Kéo xuống để thử lại.',
                      ),
                      isError: true,
                      actionLabel: 'Thử lại',
                      onAction: () => setState(_reload),
                    ),
                  )
                else if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: Icons.volunteer_activism_outlined,
                      title: _emptyTitle,
                      message: _emptyMessage,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) => _CampaignCard(
                        campaign: items[index],
                        onTap: () => context.push(
                          '${AppRoutes.campaigns}/detail/${items[index].id}',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String get _emptyTitle => switch (_filter) {
    _CampaignFilter.urgent => 'Không có đợt nào sắp hết hạn',
    _CampaignFilter.fulfilled => 'Chưa có đợt nào được trao',
    _ => 'Chưa có đợt quyên góp',
  };

  String get _emptyMessage => switch (_filter) {
    _CampaignFilter.urgent => 'Các đợt còn nhiều thời gian tiếp nhận.',
    _CampaignFilter.fulfilled => 'Khi hội nhóm trao quà, đợt sẽ hiện ở đây.',
    _ => 'Các hội nhóm sẽ đăng nhu cầu cụ thể tại đây.',
  };

  Map<_CampaignFilter, int> _countsOf(List<CampaignModel> source) {
    final now = DateTime.now();
    return {
      _CampaignFilter.active:
          source.where((c) => c.status == 'active').length,
      _CampaignFilter.urgent: source
          .where(
            (c) =>
                c.status == 'active' &&
                c.deadline != null &&
                c.deadline!.difference(now).inDays <= 7,
          )
          .length,
      _CampaignFilter.fulfilled:
          source.where((c) => c.status == 'fulfilled').length,
      _CampaignFilter.all: source.length,
    };
  }

  /// Số liệu tổng quan trên banner. Rỗng khi chưa tải xong để không hiện
  /// "0 đợt đang mở" gây hiểu nhầm là không có gì.
  List<AppHeroStat> _statsOf(List<CampaignModel> source) {
    if (source.isEmpty) return const [];
    final active = source.where((c) => c.status == 'active').toList();
    final stillNeeded = active.fold<int>(
      0,
      (sum, c) => sum + (c.totalTarget - c.totalReceived).clamp(0, 1 << 30),
    );
    final delivered = source.where((c) => c.status == 'fulfilled').length;
    return [
      AppHeroStat(value: '${active.length}', label: 'đợt đang mở'),
      if (stillNeeded > 0)
        AppHeroStat(value: '$stillNeeded', label: 'vật phẩm còn thiếu'),
      if (delivered > 0)
        AppHeroStat(value: '$delivered', label: 'đợt đã trao'),
    ];
  }
}

/// Banner đầu trang: nền brand đậm kèm số liệu tổng quan.
///
/// Thay cho `SliverAppBar.large` chỉ có mỗi tiêu đề — người dùng mở trang lên
/// thấy ngay đang có bao nhiêu đợt mở và cần thêm bao nhiêu vật phẩm.
class _CampaignCard extends StatelessWidget {
  const _CampaignCard({required this.campaign, required this.onTap});

  final CampaignModel campaign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final daysLeft = campaign.deadline?.difference(DateTime.now()).inDays;
    final urgent =
        campaign.status == 'active' && daysLeft != null && daysLeft <= 7;
    final percent = (campaign.progress * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: AppRadius.brXl,
        // Thẻ sắp hết hạn chỉ nhấn bằng viền mảnh; màu mạnh để dành cho nhãn
        // trạng thái, tránh cả danh sách đỏ rực.
        border: Border.all(
          color: urgent
              ? colors.error.withValues(alpha: 0.35)
              : colors.outlineVariant.withValues(alpha: 0.6),
        ),
        // Đổ bóng nhẹ để thẻ tách khỏi nền, thay vì chỉ dựa vào viền mảnh.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CoverBanner(
              campaign: campaign,
              urgent: urgent,
              daysLeft: daysLeft,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm + 2,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (campaign.description?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(
                      campaign.description!.trim(),
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (campaign.items.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _ItemChips(items: campaign.items),
                  ],
                  const SizedBox(height: AppSpacing.md + 2),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: AppRadius.brPill,
                          child: LinearProgressIndicator(
                            value: campaign.progress,
                            minHeight: AppSizes.progressBar,
                            // Nền đậm hơn surfaceContainerHighest để thấy rõ
                            // phần chưa đạt, thanh không bị chìm vào thẻ.
                            backgroundColor: colors.primary.withValues(
                              alpha: 0.14,
                            ),
                            valueColor: AlwaysStoppedAnimation(
                              campaign.status == 'fulfilled'
                                  ? colors.tertiary
                                  : colors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        '$percent%',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 14,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Đã nhận ${campaign.totalReceived}/${campaign.totalTarget}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      if (campaign.status == 'active')
                        Text(
                          'Xem chi tiết',
                          style: textTheme.labelMedium?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (campaign.status == 'active')
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 17,
                          color: colors.primary,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dải đầu thẻ: nền trắng, chỉ dùng màu ở nhãn trạng thái.
///
/// Trước đây là gradient brand đậm cho từng thẻ, nhưng khi xếp thành danh sách
/// dài thì cả trang đỏ rực và chọi với banner phía trên. Màu để dành cho
/// banner; danh sách giữ tone trắng như trang Hội nhóm.
class _CoverBanner extends StatelessWidget {
  const _CoverBanner({
    required this.campaign,
    required this.urgent,
    required this.daysLeft,
  });

  final CampaignModel campaign;
  final bool urgent;
  final int? daysLeft;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final done = campaign.status == 'fulfilled';
    final closed = campaign.status == 'closed';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md + 2,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          Icon(
            done
                ? Icons.card_giftcard_rounded
                : Icons.volunteer_activism_rounded,
            size: AppSizes.iconSm,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(
            campaign.code,
            style: textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
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
              text: daysLeft! <= 0 ? 'Hết hạn hôm nay' : 'Còn $daysLeft ngày',
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
    );
  }
}

enum _PillTone { neutral, success, danger }

/// Nhãn trạng thái nhỏ, nền màu nhạt trên thẻ trắng.
class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.icon, required this.tone});

  final String text;
  final IconData icon;
  final _PillTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (Color fg, Color bg) = switch (tone) {
      _PillTone.success => (colors.success, colors.successContainer),
      _PillTone.danger => (colors.error, colors.errorContainer),
      _PillTone.neutral => (
        colors.onSurfaceVariant,
        colors.surfaceContainerHighest,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.brPill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: AppSpacing.xs),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip từng vật phẩm cần nhận, kèm số còn thiếu.
class _ItemChips extends StatelessWidget {
  const _ItemChips({required this.items});

  final List<CampaignItemModel> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const maxShown = 3;
    final shown = items.take(maxShown).toList();
    final extra = items.length - shown.length;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final item in shown)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  item.remaining > 0
                      ? 'còn ${item.remaining}'
                      : 'đủ',
                  style: textTheme.labelSmall?.copyWith(
                    color: item.remaining > 0
                        ? colors.primary
                        : colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        if (extra > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+$extra loại',
              style: textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _CampaignSkeleton extends StatelessWidget {
  const _CampaignSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              height: 208,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
        ],
      ),
    );
  }
}
