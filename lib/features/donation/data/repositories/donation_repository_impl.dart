import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/donation_entity.dart';
import '../../domain/repositories/donation_repository.dart';
import '../datasources/donation_remote_data_source.dart';

class DonationRepositoryImpl implements DonationRepository {
  final DonationRemoteDataSource remote;

  DonationRepositoryImpl(this.remote);

  String _mapError(Object e, String fallback) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final detail = data['detail'] ?? data['error'] ?? data['message'];
        if (detail is String && detail.isNotEmpty) return detail;
        if (detail is Map && detail['message'] != null) {
          return detail['message'].toString();
        }
      }
      if (e.response?.statusCode == 403) {
        return 'Không có quyền thực hiện thao tác này.';
      }
    }
    return fallback;
  }

  @override
  Future<Either<String, List<DonationEntity>>> getDonations({
    String? groupId,
    bool mine = false,
    String? status,
  }) async {
    try {
      final items = await remote.getDonations(
        groupId: groupId,
        mine: mine,
        status: status,
      );
      return Right(items);
    } catch (e) {
      return Left(_mapError(e, 'Không tải được danh sách quyên góp.'));
    }
  }

  @override
  Future<Either<String, DonationEntity>> getDonationDetail(String id) async {
    try {
      final item = await remote.getDonationDetail(id);
      return Right(item);
    } catch (e) {
      return Left(_mapError(e, 'Không tải được chi tiết quyên góp.'));
    }
  }

  @override
  Future<Either<String, DonationEntity>> createDonation({
    required String groupId,
    required String title,
    String? description,
    String pickupMethod = 'drop_off',
    String? pickupAddress,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final created = await remote.createDonation({
        'group_id': groupId,
        'title': title,
        if (description != null && description.isNotEmpty)
          'description': description,
        'pickup_method': pickupMethod,
        if (pickupAddress != null && pickupAddress.isNotEmpty)
          'pickup_address': pickupAddress,
        'items': items,
      });
      return Right(created);
    } catch (e) {
      return Left(_mapError(e, 'Không tạo được đơn quyên góp.'));
    }
  }

  @override
  Future<Either<String, void>> reviewDonation({
    required String id,
    required String action,
    String? reason,
  }) async {
    try {
      await remote.reviewDonation(id, {
        'action': action,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
      return const Right(null);
    } catch (e) {
      return Left(_mapError(e, 'Không duyệt được đơn quyên góp.'));
    }
  }

  @override
  Future<Either<String, void>> checkItem({
    required String donationId,
    required String itemId,
    required String action,
    String? conditionActual,
    String? checkNote,
    String? rejectReason,
  }) async {
    try {
      await remote.checkItem(donationId, itemId, {
        'action': action,
        if (conditionActual != null) 'condition_actual': conditionActual,
        if (checkNote != null) 'check_note': checkNote,
        if (rejectReason != null) 'reject_reason': rejectReason,
      });
      return const Right(null);
    } catch (e) {
      return Left(_mapError(e, 'Không kiểm tra được món đồ.'));
    }
  }

  @override
  Future<Either<String, List<DonationTimelineEntry>>> getTimeline(
      String id) async {
    try {
      final items = await remote.getTimeline(id);
      return Right(items);
    } catch (e) {
      return Left(_mapError(e, 'Không tải được hành trình món đồ.'));
    }
  }
}
