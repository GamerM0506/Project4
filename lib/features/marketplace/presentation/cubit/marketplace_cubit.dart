import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/listing_usecases.dart';
import '../../domain/entities/category_entity.dart';
import 'marketplace_state.dart';

class MarketplaceCubit extends Cubit<MarketplaceState> {
  final GetCatalogUseCase getCatalogUseCase;
  final GetCategoriesUseCase getCategoriesUseCase;

  List<CategoryEntity> _categories = [];

  MarketplaceCubit({
    required this.getCatalogUseCase,
    required this.getCategoriesUseCase,
  }) : super(MarketplaceInitial());

  Future<void> loadCatalog({String? category, String? province, String? groupId}) async {
    emit(MarketplaceLoading());

    if (_categories.isEmpty) {
      final catResult = await getCategoriesUseCase();
      catResult.fold(
        (error) => null,
        (cats) => _categories = cats,
      );
    }

    final result = await getCatalogUseCase(category: category, province: province, groupId: groupId);

    result.fold(
      (error) => emit(MarketplaceError(message: error)),
      (listings) => emit(MarketplaceLoaded(listings: listings, categories: _categories)),
    );
  }
}
