import 'package:dartz/dartz.dart';
import '../../domain/entities/listing_entity.dart';
import '../../domain/entities/request_entity.dart';
import '../../domain/entities/category_entity.dart';

abstract class MarketplaceRepository {
  Future<Either<String, List<CategoryEntity>>> getCategories();
  Future<Either<String, List<ListingEntity>>> getCatalog({String? category, String? province, String? groupId});
  Future<Either<String, List<ListingEntity>>> getListings();
  Future<Either<String, ListingEntity>> getListingDetail(String id);
  Future<Either<String, void>> createListing(String inventoryItemId, String groupId, String title, String description, String categoryId, String condition, int quantityTotal, String createdBy);
  
  Future<Either<String, List<RequestEntity>>> getRequests();
  Future<Either<String, void>> createRequest(String listingId, String groupId, String receiverId, int quantity, String reason);
  Future<Either<String, void>> approveRequest(String id, String reviewedBy);
  Future<Either<String, void>> rejectRequest(String id, String reviewedBy, String reason);
  Future<Either<String, void>> scheduleRequest(String id, String reviewedBy, DateTime scheduledAt);
  Future<Either<String, void>> completeRequest(String id, String confirmedBy, String qrToken, String photoUrl);
  Future<Either<String, Map<String, dynamic>>> getStats();
}
