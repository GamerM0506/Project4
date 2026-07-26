import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/listing_entity.dart';
import '../cubit/marketplace_cubit.dart';
import '../cubit/marketplace_state.dart';
import '../../../../core/network/location_service.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final MarketplaceCubit _marketplaceCubit = sl<MarketplaceCubit>();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _selectedCategory = '';
  String _selectedProvince = '';
  List<dynamic> _provinces = const [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _marketplaceCubit.loadCatalog();
    _scrollController.addListener(_onScroll);
    _loadProvinces();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _marketplaceCubit.close();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    final provinces = await LocationService().getProvinces();
    if (mounted) setState(() => _provinces = provinces);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 400) {
      _marketplaceCubit.loadMore();
    }
  }

  void _reload() {
    _marketplaceCubit.loadCatalog(
      categoryId: _selectedCategory,
      provinceCode: _selectedProvince,
      search: _searchController.text,
    );
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _reload);
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
              onPressed: () {
                _searchController.clear();
                _debounce?.cancel();
                _reload();
              },
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
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearch,
                  onSubmitted: (_) {
                    _debounce?.cancel();
                    _reload();
                  },
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm vật phẩm 0 đồng...',
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<MarketplaceCubit, MarketplaceState>(
                builder: (context, state) {
                  final categories = state.categories;
                  final filters = <Widget>[
                    _buildFilterChip('Tất cả', '', colorScheme),
                    const SizedBox(width: 8),
                    ...categories.expand(
                      (category) => [
                        _buildFilterChip(
                          category.name,
                          category.id,
                          colorScheme,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ];
                  Widget content;
                  if (state.isLoading && state.listings.isEmpty) {
                    content = const Center(child: CircularProgressIndicator());
                  } else if (state.error != null && state.listings.isEmpty) {
                    content = Center(
                      child: FilledButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh),
                        label: Text(state.error!),
                      ),
                    );
                  } else {
                    final listings = state.listings;
                    if (listings.isEmpty) {
                      content = const Center(
                        child: Text('Không có sản phẩm nào.'),
                      );
                    } else {
                      content = RefreshIndicator(
                        onRefresh: () async => _reload(),
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.65,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount:
                              listings.length + (state.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) =>
                              index == listings.length
                              ? const Center(child: CircularProgressIndicator())
                              : _buildProductCard(
                                  listings[index],
                                  colorScheme,
                                  theme,
                                  context,
                                ),
                        ),
                      );
                    }
                  }
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedProvince,
                          decoration: const InputDecoration(
                            labelText: 'Tỉnh/Thành phố',
                            prefixIcon: Icon(Icons.location_on_outlined),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('Tất cả địa phương'),
                            ),
                            ..._provinces.whereType<Map>().map(
                              (province) => DropdownMenuItem(
                                value: province['code'].toString(),
                                child: Text(province['name']?.toString() ?? ''),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedProvince = value ?? '');
                            _reload();
                          },
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: filters,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(child: content),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String categoryId,
    ColorScheme colorScheme,
  ) {
    final isSelected = _selectedCategory == categoryId;
    return GestureDetector(
      onTap: () {
        if (isSelected) return;
        setState(() => _selectedCategory = categoryId);
        _reload();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.secondary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? colorScheme.onSecondary
                : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(
    ListingEntity item,
    ColorScheme colorScheme,
    ThemeData theme,
    BuildContext context,
  ) {
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
              color: Colors.black.withValues(alpha: 0.05),
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
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: item.imageUrl != null
                          ? Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.broken_image,
                                    size: 50,
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                                  ),
                            )
                          : Icon(
                              Icons.image,
                              size: 50,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: item.condition.toLowerCase() == 'new'
                            ? colorScheme.primaryContainer
                            : colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _conditionText(item.condition).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: item.condition.toLowerCase() == 'new'
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
                          child: Icon(
                            Icons.person,
                            size: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.createdBy,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            'Địa điểm',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
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
                        child: const Text(
                          'Nhận món này',
                          style: TextStyle(fontSize: 12),
                        ),
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
