import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../injection_container.dart';
import '../../../user/presentation/cubit/user_cubit.dart';
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

  void _requestItem(String groupId) {
    final prefs = sl<SharedPreferences>();
    var receiverId = prefs.getString(AppConstants.keyUserId) ?? '';
    // fallback: profile đã load
    if (receiverId.isEmpty) {
      try {
        final user = context.read<UserCubit>().state.userOrNull;
        if (user != null && user.id.isNotEmpty) {
          receiverId = user.id;
          prefs.setString(AppConstants.keyUserId, user.id);
        }
      } catch (_) {}
    }
    if (receiverId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng đăng nhập lại để gửi yêu cầu.')),
      );
      return;
    }
    if (groupId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thiếu thông tin nhóm của món đồ.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final reasonController = TextEditingController();
        int quantity = 1;
        var submitting = false;
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
                        onPressed: submitting
                            ? null
                            : () {
                                if (quantity > 1) {
                                  setStateSB(() => quantity--);
                                }
                              },
                      ),
                      Text(
                        '$quantity',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: submitting
                            ? null
                            : () => setStateSB(() => quantity++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    enabled: !submitting,
                    decoration: const InputDecoration(
                      labelText: 'Lý do nhận đồ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              setStateSB(() => submitting = true);
                              final error = await _cubit.requestItem(
                                listingId: widget.listingId,
                                groupId: groupId,
                                receiverId: receiverId,
                                quantity: quantity,
                                reason: reasonController.text.trim(),
                              );
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              if (!mounted) return;
                              final messenger =
                                  ScaffoldMessenger.of(this.context);
                              if (error == null) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã gửi yêu cầu nhận đồ!'),
                                  ),
                                );
                              } else {
                                final needJoin = error.toLowerCase().contains(
                                        'tham gia nhóm') ||
                                    error.toLowerCase().contains('duyệt') ||
                                    error.contains('403');
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(error),
                                    backgroundColor:
                                        Theme.of(this.context).colorScheme.error,
                                    action: needJoin && groupId.isNotEmpty
                                        ? SnackBarAction(
                                            label: 'Tới nhóm',
                                            textColor: Colors.white,
                                            onPressed: () {
                                              this.context.push(
                                                  '${AppRoutes.groups}/detail/$groupId');
                                            },
                                          )
                                        : null,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: submitting
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
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider.value(
      value: _cubit,
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
            } else if (state is ListingDetailLoaded) {
              final item = state.listing;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 320,
                    child: AppNetworkImage(
                      url: item.imageUrl,
                      fit: BoxFit.cover,
                      placeholderIcon: Icons.inventory_2_outlined,
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
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: item.condition == 'New' ? colorScheme.primaryContainer : colorScheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  item.condition.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: item.condition == 'New'
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onTertiaryContainer,
                                  ),
                                ),
                              ),
                              Text(
                                'Còn lại: ${item.quantityTotal}',
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
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: colorScheme.surfaceVariant,
                                child: Icon(Icons.person, color: colorScheme.onSurfaceVariant),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.createdBy,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Người tặng',
                                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: const Text('Nhắn tin'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Mô tả',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.description.isNotEmpty ? item.description : 'Không có mô tả chi tiết.',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 100), // padding for bottom bar
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return const SizedBox();
          },
        ),
        bottomSheet: BlocBuilder<ListingDetailCubit, ListingDetailState>(
          builder: (context, state) {
            if (state is ListingDetailLoaded) {
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
                  onPressed: () => _requestItem(state.listing.groupId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Nhận món này', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
