import 'package:dartz/dartz.dart';
import '../../domain/entities/listing_entity.dart';
import '../../domain/entities/request_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/delivery_confirmation_entity.dart';
import '../../domain/entities/paginated_result.dart';

abstract class MarketplaceRepository {
  Future<Either<String, PaginatedResult<ListingEntity>>> getCatalog({
    String? categoryId,
    String? provinceCode,
    String? groupId,
    String? status,
    int page,
    int limit,
    String? search,
  });
  Future<Either<String, List<CategoryEntity>>> getCategories();
  Future<Either<String, List<ListingEntity>>> getListings();
  Future<Either<String, ListingEntity>> getListingDetail(String id);
  Future<Either<String, void>> closeListing(String id);
  Future<Either<String, void>> createListing(
    String inventoryItemId,
    String groupId,
    String title,
    String description,
    String categoryId,
    String condition,
    int quantityTotal,
    String createdBy,
    List<String> imageUrls,
  );

  Future<Either<String, PaginatedResult<RequestEntity>>> getRequests({
    String? groupId,
    String? listingId,
    String? receiverId,
    String? status,
    int page,
    int limit,
  });
  Future<Either<String, void>> createRequest(
    String listingId,
    int quantity,
    String reason,
  );
  Future<Either<String, void>> approveRequest(String id);
  Future<Either<String, void>> rejectRequest(String id, String reason);
  Future<Either<String, void>> scheduleRequest(String id, DateTime scheduledAt);
  Future<Either<String, void>> completeRequest(
    String id,
    String qrToken,
    String? photoUrl,
    String? note,
  );
  Future<Either<String, void>> cancelRequest(String id);
  Future<Either<String, void>> noShowRequest(String id);
  Future<Either<String, DeliveryConfirmationEntity>> getDeliveryConfirmation(
    String id,
  );
  Future<Either<String, Map<String, dynamic>>> getStats();
}
