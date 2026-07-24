import 'package:dartz/dartz.dart';
import '../entities/listing_entity.dart';
import '../entities/category_entity.dart';
import '../repositories/marketplace_repository.dart';

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

  Future<Either<String, List<ListingEntity>>> call({String? category, String? province, String? groupId}) {
    return repository.getCatalog(category: category, province: province, groupId: groupId);
  }
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

  Future<Either<String, void>> call(String inventoryItemId, String groupId, String title, String description, String categoryId, String condition, int quantityTotal, String createdBy) {
    return repository.createListing(inventoryItemId, groupId, title, description, categoryId, condition, quantityTotal, createdBy);
  }
}
