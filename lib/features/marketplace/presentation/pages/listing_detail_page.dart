import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/listing_entity.dart';
import '../cubit/listing_detail_cubit.dart';
import '../cubit/listing_detail_state.dart';
import '../utils/listing_attribution_resolver.dart';
import '../utils/listing_content_resolver.dart';

class ListingDetailPage extends StatefulWidget {
  final String listingId;

  const ListingDetailPage({super.key, required this.listingId});

  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage> {
  late final ListingDetailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<ListingDetailCubit>()..loadDetail(widget.listingId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  ListingEntity? _listingFromState(ListingDetailState state) => switch (state) {
    ListingDetailLoaded(:final listing) => listing,
    ListingRequestSubmitting(:final listing) => listing,
    ListingRequestSuccess(:final listing) => listing,
    ListingRequestFailure(:final listing) => listing,
    _ => null,
  };

  bool _hasRequested(ListingDetailState state) => switch (state) {
    ListingDetailLoaded(:final hasRequested) => hasRequested,
    ListingRequestSubmitting(:final hasRequested) => hasRequested,
    ListingRequestSuccess(:final hasRequested) => hasRequested,
    ListingRequestFailure(:final hasRequested) => hasRequested,
    _ => false,
  };

  Future<void> _requestItem() async {
    final listing = _listingFromState(_cubit.state);
    if (listing == null || listing.quantityAvailable <= 0) return;

    final reasonController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _RequestSheet(
        listing: listing,
        reasonController: reasonController,
        onSubmit: (quantity, reason) => _cubit.requestItem(quantity, reason),
      ),
    );
    reasonController.dispose();
  }

  void _share(ListingEntity listing) {
    Share.share(
      '${listing.title}\n'
      'Vật phẩm miễn phí trên ChoSV\n'
      'Mã: ${listing.id}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<ListingDetailCubit, ListingDetailState>(
        listener: (context, state) {
          if (state is ListingRequestSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Đã gửi yêu cầu. Nhóm sẽ phản hồi trong mục Yêu cầu của tôi.',
                ),
                action: SnackBarAction(
                  label: 'Xem',
                  onPressed: () => context.push(AppRoutes.myRequests),
                ),
              ),
            );
          } else if (state is ListingRequestFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.error,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          body: BlocBuilder<ListingDetailCubit, ListingDetailState>(
            builder: (context, state) {
              if (state is ListingDetailLoading ||
                  state is ListingDetailInitial) {
                return const _DetailSkeleton();
              }
              if (state is ListingDetailError) {
                return Scaffold(
                  appBar: AppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: context.pop,
                    ),
                  ),
                  body: AppEmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'Không tải được vật phẩm',
                    message: state.message,
                    actionLabel: 'Thử lại',
                    onAction: () => _cubit.loadDetail(widget.listingId),
                    isError: true,
                  ),
                );
              }

              final listing = _listingFromState(state);
              if (listing == null) return const SizedBox.shrink();

              return FutureBuilder<ListingContent>(
                future: ListingContentResolver.resolve(listing),
                builder: (context, contentSnapshot) {
                  final imageUrl =
                      contentSnapshot.data?.imageUrl ?? listing.imageUrl;
                  final description =
                      contentSnapshot.data?.description ?? listing.description;

                  final requestBar = _RequestBar(
                    isSubmitting: state is ListingRequestSubmitting,
                    hasRequested: _hasRequested(state),
                    isOwnListing:
                        sl<SharedPreferences>().getString(
                          AppConstants.keyUserId,
                        ) ==
                        listing.createdBy,
                    isAvailable:
                        listing.status == 'active' &&
                        listing.quantityAvailable > 0,
                    onRequest: _requestItem,
                    onViewRequests: () => context.push(AppRoutes.myRequests),
                  );

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 820) {
                        return _WebLayout(
                          listing: listing,
                          imageUrl: imageUrl,
                          description: description,
                          requestBar: requestBar,
                          onBack: context.pop,
                          onShare: () => _share(listing),
                        );
                      }
                      return _MobileLayout(
                        listing: listing,
                        imageUrl: imageUrl,
                        description: description,
                        requestBar: requestBar,
                        onBack: context.pop,
                        onShare: () => _share(listing),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile
// ---------------------------------------------------------------------------

class _MobileLayout extends StatelessWidget {
  final ListingEntity listing;
  final String? imageUrl;
  final String description;
  final Widget requestBar;
  final VoidCallback onBack;
  final VoidCallback onShare;

  const _MobileLayout({
    required this.listing,
    required this.imageUrl,
    required this.description,
    required this.requestBar,
    required this.onBack,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 340,
                pinned: true,
                stretch: true,
                backgroundColor: colorScheme.surface,
                leading: _OverlayButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: onBack,
                  tooltip: 'Quay lại',
                ),
                actions: [
                  _OverlayButton(
                    icon: Icons.share_rounded,
                    onPressed: onShare,
                    tooltip: 'Chia sẻ',
                  ),
                  const SizedBox(width: 12),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: _ListingImage(imageUrl: imageUrl, rounded: false),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PriceAndTitle(listing: listing),
                      const SizedBox(height: 20),
                      _StatRow(listing: listing),
                      const SizedBox(height: 20),
                      FutureBuilder<ListingAttribution>(
                        future: ListingAttributionResolver.resolve(
                          inventoryItemId: listing.inventoryItemId,
                          createdBy: listing.createdBy,
                          groupId: listing.groupId,
                        ),
                        builder: (context, snapshot) =>
                            _AttributionCard(attribution: snapshot.data),
                      ),
                      const SizedBox(height: 24),
                      _DescriptionSection(description: description),
                      const SizedBox(height: 24),
                      _DetailGrid(listing: listing),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _BottomBar(child: requestBar),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Web
// ---------------------------------------------------------------------------

class _WebLayout extends StatelessWidget {
  final ListingEntity listing;
  final String? imageUrl;
  final String description;
  final Widget requestBar;
  final VoidCallback onBack;
  final VoidCallback onShare;

  const _WebLayout({
    required this.listing,
    required this.imageUrl,
    required this.description,
    required this.requestBar,
    required this.onBack,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        AppBar(
          title: const Text('Chi tiết vật phẩm'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: onBack,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: onShare,
              tooltip: 'Chia sẻ',
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ListingImage(imageUrl: imageUrl, rounded: true),
                          const SizedBox(height: 32),
                          _DescriptionSection(description: description),
                          const SizedBox(height: 24),
                          _DetailGrid(listing: listing),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PriceAndTitle(listing: listing),
                            const SizedBox(height: 20),
                            _StatRow(listing: listing),
                            const SizedBox(height: 20),
                            requestBar,
                            const SizedBox(height: 20),
                            FutureBuilder<ListingAttribution>(
                              future: ListingAttributionResolver.resolve(
                                inventoryItemId: listing.inventoryItemId,
                                createdBy: listing.createdBy,
                                groupId: listing.groupId,
                              ),
                              builder: (context, snapshot) =>
                                  _AttributionCard(attribution: snapshot.data),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sections
// ---------------------------------------------------------------------------

/// Giá "Miễn phí" nổi bật + tiêu đề + meta (thởi gian đăng, trạng thái).
class _PriceAndTitle extends StatelessWidget {
  final ListingEntity listing;

  const _PriceAndTitle({required this.listing});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Miễn phí',
          style: textTheme.headlineMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          listing.title,
          style: textTheme.titleLarge?.copyWith(height: 1.35),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 15,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              timeago.format(listing.createdAt, locale: 'vi'),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 10),
            AppStatusBadge(status: listing.status),
          ],
        ),
      ],
    );
  }
}

/// 3 ô thống kê: tình trạng / còn lại / đăng.
class _StatRow extends StatelessWidget {
  final ListingEntity listing;

  const _StatRow({required this.listing});

  @override
  Widget build(BuildContext context) {
    final available = listing.quantityAvailable;

    return Row(
      children: [
        Expanded(
          child: _StatBox(
            icon: Icons.auto_awesome_rounded,
            label: 'Tình trạng',
            value: _conditionText(listing.condition),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            icon: Icons.inventory_2_rounded,
            label: 'Còn lại',
            value: '$available/${listing.quantityTotal}',
            valueColor: available > 0 ? AppColors.success : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            icon: Icons.volunteer_activism_rounded,
            label: 'Hình thức',
            value: 'Tặng miễn phí',
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.labelLarge?.copyWith(
              color: valueColor ?? colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  final String description;

  const _DescriptionSection({required this.description});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mô tả chi tiết', style: textTheme.titleMedium),
        const SizedBox(height: 10),
        Text(
          description.isNotEmpty ? description : 'Không có mô tả chi tiết.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

/// Bảng chi tiết dạng label/value, kiểu "Chi tiết sản phẩm" của sàn TMĐT.
class _DetailGrid extends StatelessWidget {
  final ListingEntity listing;

  const _DetailGrid({required this.listing});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final d = listing.createdAt;
    final date =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    final rows = <(String, String)>[
      ('Mã tin', '#${listing.id.substring(0, 8).toUpperCase()}'),
      ('Tình trạng', _conditionText(listing.condition)),
      ('Số lượng', '${listing.quantityAvailable}/${listing.quantityTotal}'),
      ('Ngày đăng', date),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('Thông tin chi tiết', style: textTheme.titleMedium),
          ),
          ...List.generate(rows.length, (i) {
            final (label, value) = rows[i];
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        value,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < rows.length - 1)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: colorScheme.outlineVariant,
                  ),
              ],
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _AttributionCard extends StatelessWidget {
  final ListingAttribution? attribution;

  const _AttributionCard({this.attribution});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          AppAvatar(
            imageUrl: attribution?.donorAvatar,
            name: attribution?.donorName ?? '',
            radius: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attribution?.donorName ?? 'Đang tải thông tin...',
                  style: textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (attribution?.groupName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          attribution?.groupName ?? '',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom bar + request bar
// ---------------------------------------------------------------------------

class _BottomBar extends StatelessWidget {
  final Widget child;

  const _BottomBar({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SafeArea(top: false, child: child),
    );
  }
}

class _RequestBar extends StatelessWidget {
  final bool isSubmitting;
  final bool hasRequested;
  final bool isOwnListing;
  final bool isAvailable;
  final VoidCallback onRequest;
  final VoidCallback onViewRequests;

  const _RequestBar({
    required this.isSubmitting,
    required this.hasRequested,
    required this.isOwnListing,
    required this.isAvailable,
    required this.onRequest,
    required this.onViewRequests,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    if (hasRequested) {
      return AppButton(
        label: 'Xem yêu cầu của tôi',
        icon: Icons.history_rounded,
        variant: AppButtonVariant.tonal,
        onPressed: onViewRequests,
      );
    }

    if (isOwnListing) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.infoContainerDark
              : AppColors.infoContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: isDark ? AppColors.infoDark : AppColors.info,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Đây là món đồ của bạn.',
                style: textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.onInfoContainerDark
                      : AppColors.onInfoContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AppButton(
      label: isAvailable ? 'Nhận đồ miễn phí' : 'Đã hết vật phẩm',
      icon: Icons.handshake_rounded,
      loading: isSubmitting,
      onPressed: isAvailable ? onRequest : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Request sheet
// ---------------------------------------------------------------------------

class _RequestSheet extends StatefulWidget {
  final ListingEntity listing;
  final TextEditingController reasonController;
  final void Function(int quantity, String reason) onSubmit;

  const _RequestSheet({
    required this.listing,
    required this.reasonController,
    required this.onSubmit,
  });

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Yêu cầu nhận đồ', style: textTheme.titleLarge),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Số lượng', style: textTheme.titleSmall),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _StepperButton(
                      icon: Icons.remove_rounded,
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        '$_quantity',
                        style: textTheme.titleMedium,
                      ),
                    ),
                    _StepperButton(
                      icon: Icons.add_rounded,
                      onPressed:
                          _quantity < widget.listing.quantityAvailable
                              ? () => setState(() => _quantity++)
                              : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Lời nhắn (không bắt buộc)',
              hintText: 'VD: Mình là sinh viên năm nhất đang cần...',
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Gửi yêu cầu',
            icon: Icons.send_rounded,
            onPressed: () {
              Navigator.pop(context);
              widget.onSubmit(_quantity, widget.reasonController.text);
            },
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepperButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(
          icon,
          size: 20,
          color: onPressed == null
              ? colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
              : colorScheme.primary,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Misc
// ---------------------------------------------------------------------------

class _OverlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const _OverlayButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.9),
        shape: const CircleBorder(),
        elevation: 1,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Tooltip(
            message: tooltip,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, size: 20, color: colorScheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}

class _ListingImage extends StatelessWidget {
  final String? imageUrl;
  final bool rounded;

  const _ListingImage({required this.imageUrl, required this.rounded});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedUrl = imageUrl?.trim();

    final content = Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: colorScheme.surfaceContainerHigh),
        if (resolvedUrl != null && resolvedUrl.isNotEmpty)
          Image.network(
            resolvedUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Icon(
              Icons.broken_image_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          )
        else
          Icon(
            Icons.image_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
      ],
    );

    if (!rounded) return content;

    return AspectRatio(
      aspectRatio: 1.2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: content,
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            AppSkeleton(height: 340, radius: 0),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeleton(height: 28, width: 120),
                  SizedBox(height: 12),
                  AppSkeleton(height: 22, width: 260),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: AppSkeleton(height: 84, radius: 16)),
                      SizedBox(width: 10),
                      Expanded(child: AppSkeleton(height: 84, radius: 16)),
                      SizedBox(width: 10),
                      Expanded(child: AppSkeleton(height: 84, radius: 16)),
                    ],
                  ),
                  SizedBox(height: 24),
                  AppSkeleton(height: 72, radius: 16),
                  SizedBox(height: 24),
                  AppSkeleton(height: 16, width: 140),
                  SizedBox(height: 12),
                  AppSkeleton(height: 14),
                  SizedBox(height: 8),
                  AppSkeleton(height: 14),
                  SizedBox(height: 8),
                  AppSkeleton(height: 14, width: 200),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _conditionText(String value) {
  return switch (value.toLowerCase()) {
    'new' => 'Mới',
    'like_new' => 'Gần như mới',
    'good' => 'Tốt',
    'used' => 'Đã qua sử dụng',
    'worn' => 'Hao mòn',
    'fair' => 'Khá',
    'poor' => 'Kém',
    _ => 'Không xác định',
  };
}
