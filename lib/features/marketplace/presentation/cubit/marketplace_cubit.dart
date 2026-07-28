import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/listing_usecases.dart';
import 'marketplace_state.dart';

class MarketplaceCubit extends Cubit<MarketplaceState> {
  final GetCatalogUseCase getCatalogUseCase;
  final GetCategoriesUseCase getCategoriesUseCase;

  static const _limit = 20;
  int _generation = 0;
  int _page = 1;
  String? _categoryId;
  String? _provinceCode;
  String? _groupId;
  String? _search;

  MarketplaceCubit({
    required this.getCatalogUseCase,
    required this.getCategoriesUseCase,
  }) : super(const MarketplaceState());

  Future<void> loadCatalog({
    String? categoryId,
    String? provinceCode,
    String? groupId,
    String? search,
  }) async {
    _categoryId = _clean(categoryId);
    _provinceCode = _clean(provinceCode);
    _groupId = _clean(groupId);
    _search = _clean(search);
    _page = 1;
    final generation = ++_generation;
    emit(state.copyWith(isLoading: true, clearError: true));

    var categories = state.categories;
    if (categories.isEmpty) {
      final categoryResult = await getCategoriesUseCase();
      categoryResult.fold((_) {}, (value) => categories = value);
    }

    final result = await getCatalogUseCase(
      categoryId: _categoryId,
      provinceCode: _provinceCode,
      groupId: _groupId,
      page: _page,
      limit: _limit,
      search: _search,
    );
    if (generation != _generation || isClosed) return;
    result.fold(
      (error) => emit(
        state.copyWith(categories: categories, isLoading: false, error: error),
      ),
      (page) => emit(
        MarketplaceState(
          listings: page.items
              .where(
                (listing) =>
                    listing.status == 'active' && listing.quantityAvailable > 0,
              )
              .toList(),
          categories: categories,
          hasMore: page.hasMore,
        ),
      ),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final generation = _generation;
    final nextPage = _page + 1;
    emit(state.copyWith(isLoadingMore: true, clearError: true));
    final result = await getCatalogUseCase(
      categoryId: _categoryId,
      provinceCode: _provinceCode,
      groupId: _groupId,
      page: nextPage,
      limit: _limit,
      search: _search,
    );
    if (generation != _generation || isClosed) return;
    result.fold(
      (error) => emit(state.copyWith(isLoadingMore: false, error: error)),
      (page) {
        _page = nextPage;
        final availableItems = page.items
            .where(
              (listing) =>
                  listing.status == 'active' && listing.quantityAvailable > 0,
            )
            .toList();
        emit(
          state.copyWith(
            listings: [...state.listings, ...availableItems],
            isLoadingMore: false,
            hasMore: page.hasMore,
            clearError: true,
          ),
        );
      },
    );
  }

  String? _clean(String? value) {
    final result = value?.trim();
    return result == null || result.isEmpty ? null : result;
  }
}
