import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/listing_entity.dart';
import '../cubit/marketplace_cubit.dart';
import '../cubit/marketplace_state.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final MarketplaceCubit _marketplaceCubit = sl<MarketplaceCubit>();

  @override
  void initState() {
    super.initState();
    _marketplaceCubit.loadCatalog();
  }

  @override
  void dispose() {
    _marketplaceCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocProvider.value(
      value: _marketplaceCubit,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Text(
            'Gian hàng 0 đồng',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: colorScheme.surface,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: colorScheme.primary),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm vật phẩm 0 đồng...',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ),
            ),
            // Filters
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip('Tất cả', true, colorScheme),
                  const SizedBox(width: 8),
                  _buildFilterChip('Quần áo', false, colorScheme),
                  const SizedBox(width: 8),
                  _buildFilterChip('Điện tử', false, colorScheme),
                  const SizedBox(width: 8),
                  _buildFilterChip('Sách vở', false, colorScheme),
                  const SizedBox(width: 8),
                  _buildFilterChip('Đồ gia dụng', false, colorScheme),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Grid
            Expanded(
              child: BlocBuilder<MarketplaceCubit, MarketplaceState>(
                builder: (context, state) {
                  if (state is MarketplaceLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is MarketplaceError) {
                    return Center(child: Text(state.message));
                  } else if (state is MarketplaceLoaded) {
                    final listings = state.listings;
                    if (listings.isEmpty) {
                      return const Center(child: Text('Không có sản phẩm nào.'));
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: listings.length,
                      itemBuilder: (context, index) {
                        final item = listings[index];
                        return _buildProductCard(item, colorScheme, theme, context);
                      },
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.secondary : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? colorScheme.onSecondary : colorScheme.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildProductCard(ListingEntity item, ColorScheme colorScheme, ThemeData theme, BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/marketplace/detail/${item.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  AppNetworkImage(
                    url: item.imageUrl,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                    fit: BoxFit.cover,
                    placeholderIcon: Icons.inventory_2_outlined,
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.condition == 'New' ? colorScheme.primaryContainer : colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.condition.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: item.condition == 'New'
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info area
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 8,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.person, size: 10, color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.createdBy,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            'Địa điểm',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context.push('/marketplace/detail/${item.id}');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.secondary,
                          foregroundColor: colorScheme.onSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 0),
                          minimumSize: const Size(double.infinity, 30),
                        ),
                        child: const Text('Nhận món này', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
