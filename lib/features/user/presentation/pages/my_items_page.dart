import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../injection_container.dart';
import '../../../donation/data/campaign_error.dart';
import '../../../donation/data/datasources/campaign_remote_data_source.dart';
import '../../../donation/data/donation_labels.dart';
import '../../../donation/data/models/campaign_item_input.dart';
import '../../../donation/data/models/contribution_model.dart';
import '../../../donation/presentation/widgets/donation_photo_picker.dart';

class MyItemsPage extends StatefulWidget {
  const MyItemsPage({super.key});

  @override
  State<MyItemsPage> createState() => _MyItemsPageState();
}

class _MyItemsPageState extends State<MyItemsPage> {
  late Future<List<ContributionModel>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    // Backend trả kèm items ngay trong danh sách nên không cần gọi chi tiết
    // cho từng đóng góp nữa.
    _future = sl<CampaignRemoteDataSource>().getContributions(mine: true);
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đóng góp của tôi'),
        leading: IconButton(
          onPressed: context.pop,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: FutureBuilder<List<ContributionModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AppEmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Không tải được đóng góp',
              message: campaignErrorMessage(
                snapshot.error!,
                fallback: 'Vui lòng thử lại.',
              ),
              isError: true,
              actionLabel: 'Tải lại',
              onAction: () => setState(_reload),
            );
          }
          final contributions = snapshot.data ?? const [];
          if (contributions.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: Icons.volunteer_activism_outlined,
                      title: 'Chưa có đóng góp nào',
                      message:
                          'Chọn một đợt quyên góp đang mở để gửi vật phẩm đầu tiên.',
                      actionLabel: 'Xem các đợt quyên góp',
                      onAction: () => context.go(AppRoutes.campaigns),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: contributions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final contribution = contributions[index];
                return _ContributionCard(
                  contribution: contribution,
                  onCancel: canCancelContribution(contribution.status)
                      ? () => _cancel(contribution)
                      : null,
                  onOpenCampaign: contribution.campaignId.isEmpty
                      ? null
                      : () => context.push(
                          '${AppRoutes.campaigns}/detail/${contribution.campaignId}',
                        ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _cancel(ContributionModel contribution) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đóng góp?'),
        content: Text(
          'Đơn ${contribution.code} sẽ được gỡ khỏi danh sách chờ của hội nhóm. '
          'Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy đóng góp'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await sl<CampaignRemoteDataSource>().cancelContribution(contribution.id);
      if (mounted) await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            campaignErrorMessage(
              error,
              fallback: 'Không hủy được đóng góp.',
            ),
          ),
        ),
      );
    }
  }
}

class _ContributionCard extends StatelessWidget {
  const _ContributionCard({
    required this.contribution,
    this.onCancel,
    this.onOpenCampaign,
  });

  final ContributionModel contribution;
  final VoidCallback? onCancel;
  final VoidCallback? onOpenCampaign;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final done = contribution.status == 'completed';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onOpenCampaign,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
                    '${contribution.totalQuantity} món',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  // Sau khi kiểm tra xong, người quyên góp cần thấy ngay kết
                  // quả: bao nhiêu món đạt, bao nhiêu món không.
                  if (done) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 16,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${contribution.acceptedItemCount}/${contribution.items.length} món đã được tiếp nhận'
                            '${contribution.rejectedItemCount > 0 ? ', ${contribution.rejectedItemCount} món không đạt' : ''}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (contribution.rejectedReason?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Lý do: ${contribution.rejectedReason}',
                      style: textTheme.bodySmall?.copyWith(color: colors.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Divider(
            height: 1,
            color: colors.outlineVariant.withValues(alpha: 0.5),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              children: contribution.items
                  .map((item) => _ItemTile(item: item))
                  .toList(),
            ),
          ),
          if (onCancel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Hủy đóng góp'),
                  style: TextButton.styleFrom(foregroundColor: colors.error),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Một vật phẩm kèm kết quả kiểm tra của hội nhóm (nếu đã có).
class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item});

  final ContributionItemModel item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final actualImages = item.actualCheckImages;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
                      '${itemConditionLabel(item.conditionDeclared)}'
                      ' · ${contributionItemStatusLabel(item.status)}',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (item.conditionMismatch)
                      Text(
                        'Hội nhóm ghi nhận: ${itemConditionLabel(item.conditionActual)}',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.tertiary,
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
            ],
          ),
          if (actualImages.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ảnh hội nhóm chụp khi kiểm tra',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RemotePhotoStrip(
                    imageUrls: actualImages
                        .map((image) => image.imageUrl)
                        .toList(),
                    height: 62,
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
