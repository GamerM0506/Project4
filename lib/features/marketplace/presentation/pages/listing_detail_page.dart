import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/listing_entity.dart';
import '../cubit/listing_detail_cubit.dart';
import '../cubit/listing_detail_state.dart';

class ListingDetailPage extends StatefulWidget {
  final String listingId;

  const ListingDetailPage({super.key, required this.listingId});

  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage> {
  final _cubit = sl<ListingDetailCubit>();

  @override
  void initState() {
    super.initState();
    _cubit.loadDetail(widget.listingId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  ListingEntity? _listingFromState(ListingDetailState state) {
    return switch (state) {
      ListingDetailLoaded(:final listing) => listing,
      ListingRequestSubmitting(:final listing) => listing,
      ListingRequestSuccess(:final listing) => listing,
      ListingRequestFailure(:final listing) => listing,
      _ => null,
    };
  }

  Future<void> _requestItem() async {
    final listing = _listingFromState(_cubit.state);
    if (listing == null || listing.quantityAvailable <= 0) return;

    final reasonController = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        int quantity = 1;
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gửi yêu cầu nhận món đồ này',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Số lượng:'),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          if (!isSubmitting && quantity > 1) {
                            setStateSB(() => quantity--);
                          }
                        },
                      ),
                      Text(
                        '$quantity',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (!isSubmitting &&
                              quantity < listing.quantityAvailable) {
                            setStateSB(() => quantity++);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Lý do nhận đồ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setStateSB(() => isSubmitting = true);
                              final success = await _cubit.requestItem(
                                quantity,
                                reasonController.text,
                              );
                              if (!ctx.mounted) return;
                              if (success) {
                                Navigator.pop(ctx);
                              } else {
                                setStateSB(() => isSubmitting = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Gửi yêu cầu'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
    reasonController.dispose();
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
              const SnackBar(content: Text('Đã gửi yêu cầu nhận đồ.')),
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
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.share, color: colorScheme.onSurface),
                onPressed: () {},
              ),
            ],
          ),
          extendBodyBehindAppBar: true,
          body: BlocBuilder<ListingDetailCubit, ListingDetailState>(
            builder: (context, state) {
              if (state is ListingDetailLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ListingDetailError) {
                return Center(child: Text(state.message));
              } else {
                final item = _listingFromState(state);
                if (item == null) return const SizedBox();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                      ),
                      child: item.imageUrl != null
                          ? Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.broken_image,
                                    size: 80,
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                                  ),
                            )
                          : Icon(
                              Icons.image,
                              size: 80,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: item.condition.toLowerCase() == 'new'
                                        ? colorScheme.primaryContainer
                                        : colorScheme.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    _conditionText(
                                      item.condition,
                                    ).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          item.condition.toLowerCase() == 'new'
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onTertiaryContainer,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Còn lại: ${item.quantityAvailable}',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              item.title,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: colorScheme.surfaceVariant,
                                  child: Icon(
                                    Icons.person,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.createdBy,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Người tặng',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text('Nhắn tin'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Mô tả',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.description.isNotEmpty
                                  ? item.description
                                  : 'Không có mô tả chi tiết.',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(
                              height: 100,
                            ), // padding for bottom bar
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          bottomSheet: BlocBuilder<ListingDetailCubit, ListingDetailState>(
            builder: (context, state) {
              final listing = _listingFromState(state);
              if (listing != null) {
                final isSubmitting = state is ListingRequestSubmitting;
                final isAvailable =
                    listing.status == 'active' && listing.quantityAvailable > 0;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, -4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: isSubmitting || !isAvailable
                        ? null
                        : _requestItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.secondary,
                      foregroundColor: colorScheme.onSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isAvailable ? 'Nhận món này' : 'Đã hết vật phẩm',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
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
