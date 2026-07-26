import 'package:dartz/dartz.dart';
import '../../domain/entities/listing_entity.dart';
import '../../domain/entities/request_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../datasources/marketplace_remote_data_source.dart';
import '../../domain/entities/delivery_confirmation_entity.dart';
import '../../domain/entities/paginated_result.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  final MarketplaceRemoteDataSource remoteDataSource;

  MarketplaceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<String, PaginatedResult<ListingEntity>>> getCatalog({
    String? categoryId,
    String? provinceCode,
    String? groupId,
    String? status,
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final items = await remoteDataSource.getCatalog(
        categoryId: categoryId,
        provinceCode: provinceCode,
        groupId: groupId,
        status: status,
        page: page,
        limit: limit,
        search: search,
      );
      return Right(items);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> closeListing(String id) async {
    try {
      await remoteDataSource.closeListing(id);
      return const Right(null);
    } catch (e) {
      return Left(_message(e));
    }
  }

  @override
  Future<Either<String, List<CategoryEntity>>> getCategories() async {
    try {
      return Right(await remoteDataSource.getCategories());
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<ListingEntity>>> getListings() async {
    try {
      final items = await remoteDataSource.getListings();
      return Right(items);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, ListingEntity>> getListingDetail(String id) async {
    try {
      final item = await remoteDataSource.getListingDetail(id);
      return Right(item);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
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
  ) async {
    try {
      final payload = <String, dynamic>{
        'inventory_item_id': inventoryItemId,
        'group_id': groupId,
        'quantity_total': quantityTotal,
      };
      if (title.isNotEmpty) payload['title'] = title;
      if (description.isNotEmpty) payload['description'] = description;
      if (categoryId.isNotEmpty) payload['category_id'] = categoryId;
      if (condition.isNotEmpty) payload['condition'] = condition;
      // created_by optional: marketplace lấy từ JWT nếu thiếu
      if (createdBy.isNotEmpty && createdBy != 'user_current') {
        payload['created_by'] = createdBy;
      }
      if (imageUrls.isNotEmpty) {
        payload['images'] = imageUrls
            .where((url) => url.isNotEmpty)
            .map((url) => {'image_url': url})
            .toList();
      }

      await remoteDataSource.createListing(payload);
      return const Right(null);
    } catch (e) {
      final s = e.toString();
      if (s.startsWith('Exception: ')) return Left(s.substring(11));
      return Left(s);
    }
  }

  @override
  Future<Either<String, PaginatedResult<RequestEntity>>> getRequests({
    String? groupId,
    String? listingId,
    String? receiverId,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final models = await remoteDataSource.getRequests(
        groupId: groupId,
        listingId: listingId,
        receiverId: receiverId,
        status: status,
        page: page,
        limit: limit,
      );
      return Right(models);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> createRequest(
    String listingId,
    int quantity,
    String reason,
  ) async {
    try {
      await remoteDataSource.createRequest({
        'listing_id': listingId,
        'quantity': quantity,
        if (reason.trim().isNotEmpty) 'reason': reason.trim(),
      });
      return const Right(null);
    } catch (e) {
      final message = e.toString();
      return Left(
        message.startsWith('Exception: ') ? message.substring(11) : message,
      );
    }
  }

  @override
  Future<Either<String, void>> approveRequest(String id) async {
    try {
      await remoteDataSource.approveRequest(id);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> rejectRequest(String id, String reason) async {
    try {
      await remoteDataSource.rejectRequest(id, reason);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, Map<String, dynamic>>> getStats() async {
    try {
      final stats = await remoteDataSource.getStats();
      return Right(stats);
    } catch (e) {
      return Left('Failed to get stats: $e');
    }
  }

  @override
  Future<Either<String, void>> scheduleRequest(
    String id,
    DateTime scheduledAt,
  ) async {
    try {
      await remoteDataSource.scheduleRequest(id, scheduledAt);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> completeRequest(
    String id,
    String qrToken,
    String? photoUrl,
    String? note,
  ) async {
    try {
      await remoteDataSource.completeRequest(
        id,
        qrToken: qrToken,
        photoUrl: photoUrl,
        note: note,
      );
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> cancelRequest(String id) async {
    try {
      await remoteDataSource.cancelRequest(id);
      return const Right(null);
    } catch (e) {
      return Left(_message(e));
    }
  }

  @override
  Future<Either<String, void>> noShowRequest(String id) async {
    try {
      await remoteDataSource.noShowRequest(id);
      return const Right(null);
    } catch (e) {
      return Left(_message(e));
    }
  }

  @override
  Future<Either<String, DeliveryConfirmationEntity>> getDeliveryConfirmation(
    String id,
  ) async {
    try {
      return Right(await remoteDataSource.getDeliveryConfirmation(id));
    } catch (e) {
      return Left(_message(e));
    }
  }

  String _message(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
