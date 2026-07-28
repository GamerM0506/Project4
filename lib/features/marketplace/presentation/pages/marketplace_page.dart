import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/location_service.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/listing_entity.dart';
import '../cubit/marketplace_cubit.dart';
import '../cubit/marketplace_state.dart';
import '../utils/listing_attribution_resolver.dart';

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
    if (_scrollController.position.extentAfter < 500) {
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
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _reload);
  }

  void _clearFilters() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _selectedCategory = '';
      _selectedProvince = '';
    });
    _reload();
  }

  bool get _hasFilters =>
      _searchController.text.trim().isNotEmpty ||
      _selectedCategory.isNotEmpty ||
      _selectedProvince.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider.value(
      value: _marketplaceCubit,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: BlocBuilder<MarketplaceCubit, MarketplaceState>(
          builder: (context, state) => RefreshIndicator(
            onRefresh: () async => _reload(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _MarketplaceHeader(itemCount: state.listings.length),
                SliverToBoxAdapter(
                  child: _FilterPanel(
                    searchController: _searchController,
                    selectedProvince: _selectedProvince,
                    provinces: _provinces,
                    hasFilters: _hasFilters,
                    onSearch: _onSearch,
                    onSearchSubmitted: _reload,
                    onProvinceChanged: (value) {
                      setState(() => _selectedProvince = value ?? '');
                      _reload();
                    },
                    onClear: _clearFilters,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _CategoryBar(
                    categories: state.categories
                        .map((item) => (id: item.id, name: item.name))
                        .toList(),
                    selectedId: _selectedCategory,
                    onSelected: (id) {
                      if (_selectedCategory == id) return;
                      setState(() => _selectedCategory = id);
                      _reload();
                    },
                  ),
                ),
                if (state.isLoading && state.listings.isEmpty)
                  const SliverToBoxAdapter(child: _LoadingState())
                else if (state.error != null && state.listings.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorState(message: state.error!, onRetry: _reload),
                  )
                else if (state.listings.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(
                      hasFilters: _hasFilters,
                      onClear: _clearFilters,
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                      child: Row(
                        children: [
                          Text(
                            'Đồ đang chờ một mái nhà mới',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          Text(
                            '${state.listings.length} món',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 300,
                            mainAxisExtent: 354,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 16,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _ListingCard(
                          listing: state.listings[index],
                          onTap: () async {
                            await context.push(
                              '/marketplace/detail/${state.listings[index].id}',
                            );
                            if (mounted) _reload();
                          },
                        ),
                        childCount: state.listings.length,
                      ),
                    ),
                  ),
                  if (state.isLoadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 28),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 76)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MarketplaceHeader extends StatelessWidget {
  final int itemCount;

  const _MarketplaceHeader({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final startColor = isDark
        ? const Color(0xFF5B1720)
        : const Color(0xFF8E2730);
    final endColor = isDark ? const Color(0xFF281817) : const Color(0xFFB64246);

    return SliverAppBar(
      pinned: true,
      expandedHeight: 196,
      backgroundColor: startColor,
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Gian hàng 0 đồng',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [startColor, endColor],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: 22,
                child: Icon(
                  Icons.volunteer_activism,
                  size: 178,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 62, 140, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          itemCount == 0
                              ? 'Chia sẻ tử tế'
                              : '$itemCount món miễn phí',
                          style: TextStyle(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Món đồ cũ,\nkhởi đầu mới.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedProvince;
  final List<dynamic> provinces;
  final bool hasFilters;
  final ValueChanged<String> onSearch;
  final VoidCallback onSearchSubmitted;
  final ValueChanged<String?> onProvinceChanged;
  final VoidCallback onClear;

  const _FilterPanel({
    required this.searchController,
    required this.selectedProvince,
    required this.provinces,
    required this.hasFilters,
    required this.onSearch,
    required this.onSearchSubmitted,
    required this.onProvinceChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final search = TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onChanged: onSearch,
              onSubmitted: (_) => onSearchSubmitted(),
              decoration: InputDecoration(
                hintText: 'Bạn đang cần món đồ gì?',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Xóa tìm kiếm',
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            );
            final province = DropdownButtonFormField<String>(
              initialValue: selectedProvince,
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.location_on_outlined),
                hintText: 'Khu vực',
              ),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Tất cả khu vực'),
                ),
                ...provinces.whereType<Map>().map(
                  (item) => DropdownMenuItem(
                    value: item['code'].toString(),
                    child: Text(
                      item['name']?.toString() ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: onProvinceChanged,
            );

            if (constraints.maxWidth >= 650) {
              return Row(
                children: [
                  Expanded(flex: 3, child: search),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: province),
                  if (hasFilters) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Xóa bộ lọc',
                      onPressed: onClear,
                      icon: const Icon(Icons.filter_alt_off_outlined),
                    ),
                  ],
                ],
              );
            }
            return Column(
              children: [
                search,
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: province),
                    if (hasFilters) ...[
                      const SizedBox(width: 6),
                      IconButton.filledTonal(
                        tooltip: 'Xóa bộ lọc',
                        onPressed: onClear,
                        icon: const Icon(Icons.filter_alt_off_outlined),
                      ),
                    ],
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final List<({String id, String name})> categories;
  final String selectedId;
  final ValueChanged<String> onSelected;

  const _CategoryBar({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = [(id: '', name: 'Tất cả'), ...categories];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final selected = selectedId == item.id;
          return FilterChip(
            selected: selected,
            showCheckmark: false,
            avatar: Icon(
              index == 0 ? Icons.grid_view_rounded : _categoryIcon(item.name),
              size: 17,
            ),
            label: Text(item.name),
            onSelected: (_) => onSelected(item.id),
          );
        },
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final ListingEntity listing;
  final VoidCallback onTap;

  const _ListingCard({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = listing.imageUrl?.trim();
    final available = listing.quantityAvailable > 0;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: available ? onTap : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 164,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _ImagePlaceholder(colorScheme: colorScheme),
                      )
                    else
                      _ImagePlaceholder(colorScheme: colorScheme),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.16),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: _ConditionBadge(condition: listing.condition),
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          available
                              ? 'Còn ${listing.quantityAvailable}'
                              : 'Đã hết',
                          style: TextStyle(
                            color: available
                                ? const Color(0xFF006A65)
                                : colorScheme.error,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 9),
                      FutureBuilder<ListingAttribution>(
                        future: ListingAttributionResolver.resolve(
                          inventoryItemId: listing.inventoryItemId,
                          createdBy: listing.createdBy,
                          groupId: listing.groupId,
                        ),
                        builder: (context, snapshot) => _AttributionSummary(
                          attribution: snapshot.data,
                          colorScheme: colorScheme,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: FilledButton.icon(
                          onPressed: available ? onTap : null,
                          icon: Icon(
                            available
                                ? Icons.redeem_outlined
                                : Icons.block_outlined,
                            size: 17,
                          ),
                          label: Text(available ? 'Xem món đồ' : 'Đã hết hàng'),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.secondary,
                            foregroundColor: colorScheme.onSecondary,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
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
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final ColorScheme colorScheme;

  const _ImagePlaceholder({required this.colorScheme});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: colorScheme.surfaceContainerHighest,
    child: Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 46,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
      ),
    ),
  );
}

class _ConditionBadge extends StatelessWidget {
  final String condition;

  const _ConditionBadge({required this.condition});

  @override
  Widget build(BuildContext context) {
    final isNew = condition.toLowerCase() == 'new';
    final background = isNew
        ? const Color(0xFF8E2730)
        : const Color(0xFF006A65);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _conditionText(condition).toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _AttributionSummary extends StatelessWidget {
  final ListingAttribution? attribution;
  final ColorScheme colorScheme;

  const _AttributionSummary({
    required this.attribution,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = attribution?.donorAvatar;
    final secondaryStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
      height: 1.15,
    );

    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: colorScheme.secondaryContainer,
              backgroundImage: avatar == null ? null : NetworkImage(avatar),
              child: avatar == null
                  ? Icon(
                      Icons.person_outline,
                      size: 12,
                      color: colorScheme.onSecondaryContainer,
                    )
                  : null,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                attribution?.donorName ?? 'Đang tải người tặng...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: secondaryStyle?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Icon(
              Icons.groups_outlined,
              size: 15,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                attribution?.groupName ?? 'Đang tải hội nhóm...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: secondaryStyle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 72),
    child: Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          'Đang tìm những món đồ phù hợp...',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClear;

  const _EmptyState({required this.hasFilters, required this.onClear});

  @override
  Widget build(BuildContext context) => _MessageState(
    icon: Icons.search_off_rounded,
    title: hasFilters
        ? 'Chưa tìm thấy món phù hợp'
        : 'Gian hàng đang chờ đồ mới',
    message: hasFilters
        ? 'Thử đổi từ khóa, khu vực hoặc danh mục để xem thêm kết quả.'
        : 'Các món đồ miễn phí mới sẽ xuất hiện tại đây.',
    actionLabel: hasFilters ? 'Xóa bộ lọc' : null,
    onAction: hasFilters ? onClear : null,
  );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => _MessageState(
    icon: Icons.cloud_off_outlined,
    title: 'Chưa tải được gian hàng',
    message: message,
    actionLabel: 'Thử lại',
    onAction: onRetry,
  );
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 42,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

IconData _categoryIcon(String name) {
  final value = name.toLowerCase();
  if (value.contains('quần') || value.contains('áo')) {
    return Icons.checkroom_outlined;
  }
  if (value.contains('sách')) return Icons.menu_book_outlined;
  if (value.contains('điện')) return Icons.devices_other_outlined;
  if (value.contains('gia dụng')) return Icons.chair_outlined;
  if (value.contains('trẻ') || value.contains('em bé')) {
    return Icons.child_friendly_outlined;
  }
  if (value.contains('thực phẩm')) return Icons.restaurant_outlined;
  return Icons.inventory_2_outlined;
}

String _conditionText(String value) {
  return switch (value.toLowerCase()) {
    'new' => 'Mới',
    'like_new' => 'Gần như mới',
    'good' => 'Tốt',
    'used' => 'Đã sử dụng',
    'worn' => 'Hao mòn',
    'fair' => 'Khá',
    'poor' => 'Kém',
    _ => 'Chưa rõ',
  };
}
