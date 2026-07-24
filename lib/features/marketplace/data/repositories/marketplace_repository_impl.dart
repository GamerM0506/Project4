import 'package:dartz/dartz.dart';
import '../../domain/entities/listing_entity.dart';
import '../../domain/entities/request_entity.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../datasources/marketplace_remote_data_source.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  final MarketplaceRemoteDataSource remoteDataSource;

  MarketplaceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<String, List<ListingEntity>>> getCatalog({String? category, String? province, String? groupId}) async {
    try {
      final items = await remoteDataSource.getCatalog(category: category, province: province, groupId: groupId);
      return Right(items);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<ListingEntity>>> getListings({
    String? groupId,
    String? status,
  }) async {
    try {
      final items =
          await remoteDataSource.getListings(groupId: groupId, status: status);
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
  Future<Either<String, void>> createListing(String inventoryItemId, String groupId, String title, String description, String categoryId, String condition, int quantityTotal, String createdBy) async {
    try {
      await remoteDataSource.createListing({
        'inventory_item_id': inventoryItemId,
        'group_id': groupId,
        'title': title,
        'description': description,
        'category_id': categoryId,
        'condition': condition,
        'quantity_total': quantityTotal,
        'created_by': createdBy,
      });
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<RequestEntity>>> getRequests({
    String? receiverId,
    String? groupId,
    String? status,
  }) async {
    try {
      final items = await remoteDataSource.getRequests(
        receiverId: receiverId,
        groupId: groupId,
        status: status,
      );
      return Right(items);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> createRequest(String listingId, String groupId, String receiverId, int quantity, String reason) async {
    try {
      final body = <String, dynamic>{
        'listing_id': listingId,
        'quantity': quantity < 1 ? 1 : quantity,
        if (groupId.isNotEmpty) 'group_id': groupId,
        if (receiverId.isNotEmpty) 'receiver_id': receiverId,
        if (reason.trim().isNotEmpty) 'reason': reason.trim(),
      };
      await remoteDataSource.createRequest(body);
      return const Right(null);
    } catch (e) {
      return Left(e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''));
    }
  }

  @override
  Future<Either<String, void>> approveRequest(String id, String reviewedBy) async {
    try {
      await remoteDataSource.approveRequest(id, reviewedBy);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> rejectRequest(String id, String reviewedBy, String reason) async {
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
  Future<Either<String, void>> scheduleRequest(String id, String reviewedBy, DateTime scheduledAt) async {
    try {
      await remoteDataSource.scheduleRequest(id, reviewedBy, scheduledAt);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> completeRequest(String id, String confirmedBy, String qrToken, String photoUrl) async {
    try {
      await remoteDataSource.completeRequest(id, confirmedBy, qrToken, photoUrl);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
