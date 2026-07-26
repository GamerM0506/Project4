import 'package:dartz/dartz.dart';
import '../entities/listing_entity.dart';
import '../entities/category_entity.dart';
import '../repositories/marketplace_repository.dart';
import '../entities/paginated_result.dart';

class GetCategoriesUseCase {
  final MarketplaceRepository repository;
  GetCategoriesUseCase(this.repository);

  Future<Either<String, List<CategoryEntity>>> call() {
    return repository.getCategories();
  }
}

class GetCatalogUseCase {
  final MarketplaceRepository repository;
  GetCatalogUseCase(this.repository);

  Future<Either<String, PaginatedResult<ListingEntity>>> call({
    String? categoryId,
    String? provinceCode,
    String? groupId,
    String? status,
    int page = 1,
    int limit = 20,
    String? search,
  }) {
    return repository.getCatalog(
      categoryId: categoryId,
      provinceCode: provinceCode,
      groupId: groupId,
      status: status,
      page: page,
      limit: limit,
      search: search,
    );
  }
}

class CloseListingUseCase {
  final MarketplaceRepository repository;
  CloseListingUseCase(this.repository);

  Future<Either<String, void>> call(String id) => repository.closeListing(id);
}

class GetListingDetailUseCase {
  final MarketplaceRepository repository;
  GetListingDetailUseCase(this.repository);

  Future<Either<String, ListingEntity>> call(String id) {
    return repository.getListingDetail(id);
  }
}

class CreateListingUseCase {
  final MarketplaceRepository repository;
  CreateListingUseCase(this.repository);

  Future<Either<String, void>> call(
    String inventoryItemId,
    String groupId,
    String title,
    String description,
    String categoryId,
    String condition,
    int quantityTotal,
    String createdBy, {
    List<String> imageUrls = const [],
  }) {
    return repository.createListing(
      inventoryItemId,
      groupId,
      title,
      description,
      categoryId,
      condition,
      quantityTotal,
      createdBy,
      imageUrls,
    );
  }
}
