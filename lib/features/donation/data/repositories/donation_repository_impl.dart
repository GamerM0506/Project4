import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../domain/repositories/donation_repository.dart';
import '../datasources/donation_remote_data_source.dart';
import '../models/donation_model.dart';

class DonationRepositoryImpl implements DonationRepository {
  final DonationRemoteDataSource remoteDataSource;

  DonationRepositoryImpl({required this.remoteDataSource});

  String _mapError(Object e, String fallback) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final detail = data['detail'] ?? data['message'];
        if (detail is String && detail.isNotEmpty) return detail;
      }
      if (e.message != null && e.message!.isNotEmpty) return e.message!;
    }
    final s = e.toString();
    if (s.startsWith('Exception: ')) return s.substring(11);
    return fallback;
  }

  @override
  Future<Either<String, List<DonationCategoryModel>>> getCategories() async {
    try {
      return Right(await remoteDataSource.getCategories());
    } catch (e) {
      return Left(_mapError(e, 'Không tải được danh mục vật phẩm'));
    }
  }

  @override
  Future<Either<String, List<DonationModel>>> getDonations({
    String? groupId,
    String? status,
    bool mine = false,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      return Right(
        await remoteDataSource.getDonations(
          groupId: groupId,
          status: status,
          mine: mine,
          limit: limit,
          offset: offset,
        ),
      );
    } catch (e) {
      return Left(_mapError(e, 'Không tải được danh sách quyên góp'));
    }
  }

  @override
  Future<Either<String, DonationModel>> createDonation({
    required String groupId,
    required String title,
    String? description,
    String pickupMethod = 'drop_off',
    String? pickupAddress,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final result = await remoteDataSource.createDonation(
        groupId: groupId,
        title: title,
        description: description,
        pickupMethod: pickupMethod,
        pickupAddress: pickupAddress,
        items: items,
      );
      return Right(result);
    } catch (e) {
      return Left(_mapError(e, 'Không tạo được đơn quyên góp'));
    }
  }

  @override
  Future<Either<String, DonationModel>> reviewDonation(
    String donationId,
    String action, {
    String? reason,
  }) async {
    try {
      final result = await remoteDataSource.reviewDonation(
        donationId,
        action,
        reason: reason,
      );
      return Right(result);
    } catch (e) {
      return Left(_mapError(e, 'Không duyệt được đơn quyên góp'));
    }
  }

  @override
  Future<Either<String, DonationModel>> checkItem({
    required String donationId,
    required String itemId,
    required String action,
    String? conditionActual,
    String? checkNote,
    String? rejectReason,
  }) async {
    try {
      final result = await remoteDataSource.checkItem(
        donationId: donationId,
        itemId: itemId,
        action: action,
        conditionActual: conditionActual,
        checkNote: checkNote,
        rejectReason: rejectReason,
      );
      return Right(result);
    } catch (e) {
      return Left(_mapError(e, 'Không kiểm tra được vật phẩm'));
    }
  }

  @override
  Future<Either<String, DonationModel>> getDonation(String donationId) async {
    try {
      final result = await remoteDataSource.getDonation(donationId);
      return Right(result);
    } catch (e) {
      return Left(_mapError(e, 'Không tải được đơn quyên góp'));
    }
  }

  @override
  Future<Either<String, DonationModel>> scheduleDonation(
    String donationId,
    DateTime scheduledAt,
  ) async {
    try {
      return Right(
        await remoteDataSource.scheduleDonation(donationId, scheduledAt),
      );
    } catch (e) {
      return Left(_mapError(e, 'Không lưu được lịch tiếp nhận'));
    }
  }

  @override
  Future<Either<String, DonationModel>> cancelDonation(
    String donationId,
  ) async {
    try {
      return Right(await remoteDataSource.cancelDonation(donationId));
    } catch (e) {
      return Left(_mapError(e, 'Không hủy được đơn quyên góp'));
    }
  }

  @override
  Future<Either<String, List<DonationTimelineModel>>> getDonationTimeline(
    String donationId,
  ) async {
    try {
      return Right(await remoteDataSource.getDonationTimeline(donationId));
    } catch (e) {
      return Left(_mapError(e, 'Không tải được tiến trình quyên góp'));
    }
  }

  @override
  Future<Either<String, List<InventoryItemModel>>> getInventory({
    String? groupId,
    String? status,
    bool mine = false,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final result = await remoteDataSource.getInventory(
        groupId: groupId,
        status: status,
        mine: mine,
        limit: limit,
        offset: offset,
      );
      return Right(result);
    } catch (e) {
      return Left(_mapError(e, 'Không tải được kho đồ'));
    }
  }

  @override
  Future<Either<String, InventoryItemModel>> getInventoryItem(
    String itemId,
  ) async {
    try {
      return Right(await remoteDataSource.getInventoryItem(itemId));
    } catch (e) {
      return Left(_mapError(e, 'Không tải được vật phẩm'));
    }
  }

  @override
  Future<Either<String, List<InventoryHistoryModel>>> getInventoryHistory(
    String itemId,
  ) async {
    try {
      return Right(await remoteDataSource.getInventoryHistory(itemId));
    } catch (e) {
      return Left(_mapError(e, 'Không tải được lịch sử vật phẩm'));
    }
  }

  @override
  Future<Either<String, DonationModel>> acceptDonationToInventory({
    required String donationId,
    String defaultCondition = 'used',
  }) async {
    try {
      var donation = await remoteDataSource.reviewDonation(
        donationId,
        'accepted',
      );

      for (final item in donation.items) {
        if (item.status == 'pending') {
          donation = await remoteDataSource.checkItem(
            donationId: donationId,
            itemId: item.id,
            action: 'accepted',
            conditionActual: item.conditionDeclared.isNotEmpty
                ? item.conditionDeclared
                : defaultCondition,
          );
        }
      }

      return Right(donation);
    } catch (e) {
      return Left(_mapError(e, 'Không nhập kho được đơn quyên góp'));
    }
  }
}
