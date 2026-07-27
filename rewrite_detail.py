import os

code = """import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routes/app_routes.dart';
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
      '\\\n'
      'V?t ph?m mi?n phí trên ChoSV\\n'
      'Mã: \',
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
                content: const Text('Ðã g?i yêu c?u. Nhóm s? ph?n h?i trong m?c Yêu c?u c?a tôi.'),
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
              if (state is ListingDetailLoading || state is ListingDetailInitial) {
                return const _DetailLoading();
              }
              if (state is ListingDetailError) {
                return _DetailError(
                  message: state.message,
                  onBack: context.pop,
                  onRetry: () => _cubit.loadDetail(widget.listingId),
                );
              }

              final listing = _listingFromState(state);
              if (listing == null) return const SizedBox.shrink();

              // Resolve additional content (images from donations)
              return FutureBuilder<ListingContent>(
                future: ListingContentResolver.resolve(listing),
                builder: (context, contentSnapshot) {
                  final imageUrl = contentSnapshot.data?.imageUrl ?? listing.imageUrl;
                  final description = contentSnapshot.data?.description ?? listing.description;
                  
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 820;
                      
                      final requestBar = _RequestBar(
                        isSubmitting: state is ListingRequestSubmitting,
                        hasRequested: _hasRequested(state),
                        isOwnListing: sl<SharedPreferences>().getString(AppConstants.keyUserId) == listing.createdBy,
                        isAvailable: listing.status == 'active' && listing.quantityAvailable > 0,
                        onRequest: _requestItem,
                        onViewRequests: () => context.push(AppRoutes.myRequests),
                      );

                      if (isWide) {
                        return _WebLayout(
                          listing: listing,
                          imageUrl: imageUrl,
                          description: description,
                          requestBar: requestBar,
                          onBack: context.pop,
                          onShare: () => _share(listing),
                        );
                      } else {
                        return _MobileLayout(
                          listing: listing,
                          imageUrl: imageUrl,
                          description: description,
                          requestBar: requestBar,
                          onBack: context.pop,
                          onShare: () => _share(listing),
                        );
                      }
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
    return Column(
      children: [
        // App Bar
        AppBar(
          title: const Text('Chi ti?t v?t ph?m'),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
          actions: [
            IconButton(icon: const Icon(Icons.ios_share_outlined), onPressed: onShare, tooltip: 'Chia s?'),
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
                    // Left Column: Image & Details
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ListingImage(imageUrl: imageUrl),
                          const SizedBox(height: 32),
                          _ListingInfoColumn(listing: listing, description: description),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                    // Right Column: Sticky Action Panel
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              listing.title,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            requestBar,
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
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 360,
                pinned: true,
                leading: _OverlayButton(icon: Icons.arrow_back, onPressed: onBack, tooltip: 'Quay l?i'),
                actions: [
                  _OverlayButton(icon: Icons.ios_share_outlined, onPressed: onShare, tooltip: 'Chia s?'),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _ListingImage(imageUrl: imageUrl),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _ListingInfoColumn(listing: listing, description: description),
                      const SizedBox(height: 64),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Bottom Action Bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: requestBar,
          ),
        ),
      ],
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const _OverlayButton({required this.icon, required this.onPressed, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: colorScheme.surface.withValues(alpha: 0.7),
          foregroundColor: colorScheme.onSurface,
        ),
        icon: Icon(icon),
      ),
    );
  }
}

class _ListingImage extends StatelessWidget {
  final String? imageUrl;

  const _ListingImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedUrl = imageUrl?.trim();

    return AspectRatio(
      aspectRatio: 1.2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: colorScheme.surfaceContainerHighest),
            if (resolvedUrl != null && resolvedUrl.isNotEmpty)
              Image.network(
                resolvedUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.broken_image_outlined, size: 64, color: colorScheme.onSurfaceVariant),
              )
            else
              Icon(Icons.image_not_supported_outlined, size: 64, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _ListingInfoColumn extends StatelessWidget {
  final ListingEntity listing;
  final String description;

  const _ListingInfoColumn({required this.listing, required this.description});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(
              icon: Icons.auto_awesome_outlined,
              label: _conditionText(listing.condition),
              background: colorScheme.secondaryContainer,
              foreground: colorScheme.onSecondaryContainer,
            ),
            _Pill(
              icon: listing.quantityAvailable > 0 ? Icons.check_circle_outline : Icons.cancel_outlined,
              label: listing.quantityAvailable > 0 ? '\ kh? d?ng' : 'H?t hàng',
              background: colorScheme.tertiaryContainer,
              foreground: colorScheme.onTertiaryContainer,
            ),
          ],
        ),
        const SizedBox(height: 24),
        FutureBuilder<ListingAttribution>(
          future: ListingAttributionResolver.resolve(
            inventoryItemId: listing.inventoryItemId,
            createdBy: listing.createdBy,
            groupId: listing.groupId,
          ),
          builder: (context, snapshot) => _AttributionCard(attribution: snapshot.data),
        ),
        const SizedBox(height: 24),
        Text('Mô t?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(
          description.isNotEmpty ? description : 'Không có mô t? chi ti?t.',
          style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.6, fontSize: 16),
        ),
      ],
    );
  }
}

class _AttributionCard extends StatelessWidget {
  final ListingAttribution? attribution;

  const _AttributionCard({this.attribution});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage: attribution?.donorAvatar != null ? NetworkImage(attribution!.donorAvatar!) : null,
            child: attribution?.donorAvatar == null ? Icon(Icons.person, color: colorScheme.onPrimaryContainer) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attribution?.donorName ?? 'Ðang t?i thông tin...',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (attribution?.groupName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 14, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          attribution!.groupName!,
                          style: TextStyle(color: colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
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
    final colorScheme = Theme.of(context).colorScheme;
    
    if (hasRequested) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onViewRequests,
          icon: const Icon(Icons.history),
          label: const Text('Xem yêu c?u c?a tôi'),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
      );
    }
    
    if (isOwnListing) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colorScheme.errorContainer, borderRadius: BorderRadius.circular(16)),
        child: Text(
          'Ðây là món d? c?a b?n. B?n không th? t? yêu c?u.',
          textAlign: TextAlign.center,
          style: TextStyle(color: colorScheme.onErrorContainer, fontWeight: FontWeight.bold),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isAvailable && !isSubmitting ? onRequest : null,
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        child: isSubmitting
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(isAvailable ? 'Nh?n d?' : 'Ðã h?t v?t ph?m', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

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
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Yêu c?u nh?n d?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('S? lu?ng:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              Row(
                children: [
                  IconButton(
                    onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('\', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: _quantity < widget.listing.quantityAvailable ? () => setState(() => _quantity++) : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'L?i nh?n (không b?t bu?c)',
              hintText: 'VD: Mình là sinh viên nam nh?t dang c?n...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onSubmit(_quantity, widget.reasonController.text);
            },
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('G?i yêu c?u', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  const _Pill({required this.icon, required this.label, required this.background, required this.foreground});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: foreground, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

String _conditionText(String value) {
  return switch (value.toLowerCase()) {
    'new' => 'M?i',
    'like_new' => 'G?n nhu m?i',
    'good' => 'T?t',
    'used' => 'Ðã qua s? d?ng',
    'worn' => 'Hao mòn',
    'fair' => 'Khá',
    'poor' => 'Kém',
    _ => 'Không xác d?nh',
  };
}

class _DetailLoading extends StatelessWidget {
  const _DetailLoading();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _DetailError extends StatelessWidget {
  final String message;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  const _DetailError({required this.message, required this.onBack, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(onPressed: onRetry, child: const Text('Th? l?i')),
            ],
          ),
        ),
      ),
    );
  }
}
"""

with open('lib/features/marketplace/presentation/pages/listing_detail_page.dart', 'w', encoding='utf-8') as f:
    f.write(code)
print("File written successfully!")
