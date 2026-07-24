import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../data/models/group_model.dart';
import '../../../marketplace/domain/entities/listing_entity.dart';
import '../cubit/group_inventory_cubit.dart';
import '../cubit/group_inventory_state.dart';

class GroupDashboardInventory extends StatelessWidget {
  final GroupModel group;

  const GroupDashboardInventory({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<GroupInventoryCubit>()..fetchInventory(group.id),
      child: _GroupDashboardInventoryView(group: group),
    );
  }
}

class _GroupDashboardInventoryView extends StatelessWidget {
  final GroupModel group;

  const _GroupDashboardInventoryView({required this.group});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Kho vật phẩm', style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Thêm vật phẩm'),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocConsumer<GroupInventoryCubit, GroupInventoryState>(
            listener: (context, state) {
              if (state is GroupInventoryError) {
                // Show a friendly error instead of raw Exception string
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lỗi máy chủ: Không thể tải danh sách kho đồ.')),
                );
              }
            },
            builder: (context, state) {
              if (state is GroupInventoryLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is GroupInventoryLoaded) {
                if (state.items.isEmpty) {
                  return const Center(child: Text('Kho đồ trống'));
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 500 ? 3 : 2);
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: state.items.length,
                      itemBuilder: (context, index) {
                        return _buildInventoryItem(context, state.items[index]);
                      },
                    );
                  }
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryItem(BuildContext context, ListingEntity item) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final imageUrl = (item.imageUrl != null && item.imageUrl!.isNotEmpty) 
      ? item.imageUrl!
      : 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(item.status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(item.status),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('SL: ${item.quantityTotal}', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                      IconButton(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'given':
      case 'completed':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'available':
      case 'active':
        return 'Sẵn sàng';
      case 'pending':
        return 'Đang chờ';
      case 'given':
      case 'completed':
        return 'Đã kết thúc';
      default:
        return status;
    }
  }
}
