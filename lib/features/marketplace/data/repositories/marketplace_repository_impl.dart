import 'package:dartz/dartz.dart';
import '../../domain/entities/listing_entity.dart';
import '../../domain/entities/request_entity.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../datasources/marketplace_remote_data_source.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  final MarketplaceRemoteDataSource remoteDataSource;

  MarketplaceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<String, List<ListingEntity>>> getCatalog({
    String? category,
    String? province,
    String? groupId,
  }) async {
    try {
      final items = await remoteDataSource.getCatalog(
        category: category,
        province: province,
        groupId: groupId,
      );
      return Right(items);
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
  Future<Either<String, List<RequestEntity>>> getRequests() async {
    try {
      final items = await remoteDataSource.getRequests();
      return Right(items);
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
  Future<Either<String, void>> approveRequest(
    String id,
    String reviewedBy,
  ) async {
    try {
      await remoteDataSource.approveRequest(id, reviewedBy);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> rejectRequest(
    String id,
    String reviewedBy,
    String reason,
  ) async {
    try {
      await remoteDataSource.rejectRequest(id, reviewedBy, reason);
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
    String reviewedBy,
    DateTime scheduledAt,
  ) async {
    try {
      await remoteDataSource.scheduleRequest(id, reviewedBy, scheduledAt);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> completeRequest(
    String id,
    String confirmedBy,
    String qrToken,
    String photoUrl,
  ) async {
    try {
      await remoteDataSource.completeRequest(
        id,
        confirmedBy,
        qrToken,
        photoUrl,
      );
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
