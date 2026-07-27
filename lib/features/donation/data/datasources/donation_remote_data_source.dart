import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/donation_model.dart';

abstract class DonationRemoteDataSource {
  Future<List<DonationCategoryModel>> getCategories();

  Future<List<DonationModel>> getDonations({
    String? groupId,
    String? status,
    bool mine,
    int limit,
    int offset,
  });

  Future<DonationModel> createDonation({
    required String groupId,
    required String title,
    String? description,
    String pickupMethod,
    String? pickupAddress,
    required List<Map<String, dynamic>> items,
  });

  Future<DonationModel> reviewDonation(
    String donationId,
    String action, {
    String? reason,
  });

  Future<DonationModel> checkItem({
    required String donationId,
    required String itemId,
    required String action,
    String? conditionActual,
    String? checkNote,
    String? rejectReason,
  });

  Future<DonationModel> getDonation(String donationId);

  Future<DonationModel> getDonationByCode(String code, String groupId);

  Future<DonationModel> scheduleDonation(
    String donationId,
    DateTime scheduledAt,
  );

  Future<DonationModel> cancelDonation(String donationId);

  Future<List<DonationTimelineModel>> getDonationTimeline(String donationId);

  Future<List<InventoryItemModel>> getInventory({
    String? groupId,
    String? status,
    bool mine = false,
    int limit = 20,
    int offset = 0,
  });

  Future<InventoryItemModel> getInventoryItem(String itemId);

  Future<List<InventoryHistoryModel>> getInventoryHistory(String itemId);
}

class DonationRemoteDataSourceImpl implements DonationRemoteDataSource {
  final ApiClient apiClient;

  DonationRemoteDataSourceImpl({required this.apiClient});

  String get _base => AppConstants.donationApiBaseUrl;

  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      return data;
    }
    return <String, dynamic>{};
  }

  List<dynamic> _unwrapList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final inner = data['data'];
      if (inner is List) return inner;
      if (inner is Map && inner['items'] is List) return inner['items'] as List;
      if (data['items'] is List) return data['items'] as List;
    }
    return const [];
  }

  String _errorMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      final detail = data['detail'] ?? data['message'] ?? data['error'];
      if (detail is String && detail.isNotEmpty) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] != null) {
          return first['msg'].toString();
        }
        return first.toString();
      }
    }
    return fallback;
  }

  @override
  Future<List<DonationCategoryModel>> getCategories() async {
    try {
      final response = await apiClient.dio.get('$_base/categories');
      return _unwrapList(response.data)
          .whereType<Map>()
          .map(
            (item) =>
                DonationCategoryModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((category) => category.id.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không tải được danh mục vật phẩm'));
    }
  }

  @override
  Future<List<DonationModel>> getDonations({
    String? groupId,
    String? status,
    bool mine = false,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await apiClient.dio.get(
        '$_base/donations',
        queryParameters: {
          'limit': limit,
          'offset': offset,
          if (groupId != null && groupId.isNotEmpty) 'group_id': groupId,
          if (status != null && status.isNotEmpty) 'status': status,
          if (mine) 'mine': true,
        },
      );
      return _unwrapList(response.data)
          .whereType<Map>()
          .map(
            (item) => DonationModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không tải được danh sách quyên góp'));
    }
  }

  @override
  Future<DonationModel> createDonation({
    required String groupId,
    required String title,
    String? description,
    String pickupMethod = 'drop_off',
    String? pickupAddress,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '$_base/donations',
        data: {
          'group_id': groupId,
          'title': title,
          if (description != null && description.isNotEmpty)
            'description': description,
          'pickup_method': pickupMethod,
          if (pickupAddress != null && pickupAddress.isNotEmpty)
            'pickup_address': pickupAddress,
          'items': items,
        },
      );
      return DonationModel.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không tạo được đơn quyên góp'));
    }
  }

  @override
  Future<DonationModel> reviewDonation(
    String donationId,
    String action, {
    String? reason,
  }) async {
    try {
      final response = await apiClient.dio.put(
        '$_base/donations/$donationId/review',
        data: {
          'action': action,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      return DonationModel.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không duyệt được đơn quyên góp'));
    }
  }

  @override
  Future<DonationModel> checkItem({
    required String donationId,
    required String itemId,
    required String action,
    String? conditionActual,
    String? checkNote,
    String? rejectReason,
  }) async {
    try {
      final response = await apiClient.dio.put(
        '$_base/donations/$donationId/items/$itemId/check',
        data: {
          'action': action,
          if (conditionActual != null) 'condition_actual': conditionActual,
          if (checkNote != null) 'check_note': checkNote,
          if (rejectReason != null) 'reject_reason': rejectReason,
        },
      );
      return DonationModel.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không kiểm tra được vật phẩm'));
    }
  }

  @override
  Future<DonationModel> getDonation(String donationId) async {
    try {
      final response = await apiClient.dio.get('$_base/donations/$donationId');
      return DonationModel.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không tải được đơn quyên góp'));
    }
  }

  @override
  Future<DonationModel> getDonationByCode(String code, String groupId) async {
    try {
      final response = await apiClient.dio.get(
        '$_base/donations/by-code/${Uri.encodeComponent(code.trim())}',
        queryParameters: {'group_id': groupId},
      );
      return DonationModel.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không tìm thấy đơn quyên góp'));
    }
  }

  @override
  Future<DonationModel> scheduleDonation(
    String donationId,
    DateTime scheduledAt,
  ) async {
    try {
      final response = await apiClient.dio.put(
        '$_base/donations/$donationId/schedule',
        data: {'scheduled_at': scheduledAt.toUtc().toIso8601String()},
      );
      return DonationModel.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không lưu được lịch tiếp nhận'));
    }
  }

  @override
  Future<DonationModel> cancelDonation(String donationId) async {
    try {
      final response = await apiClient.dio.put(
        '$_base/donations/$donationId/cancel',
      );
      return DonationModel.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không hủy được đơn quyên góp'));
    }
  }

  @override
  Future<List<DonationTimelineModel>> getDonationTimeline(
    String donationId,
  ) async {
    try {
      final response = await apiClient.dio.get(
        '$_base/donations/$donationId/timeline',
      );
      return _unwrapList(response.data)
          .whereType<Map>()
          .map(
            (item) =>
                DonationTimelineModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không tải được tiến trình quyên góp'));
    }
  }

  @override
  Future<List<InventoryItemModel>> getInventory({
    String? groupId,
    String? status,
    bool mine = false,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final query = <String, dynamic>{
        'limit': limit,
        'offset': offset,
        if (groupId != null && groupId.isNotEmpty) 'group_id': groupId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (mine) 'mine': true,
      };
      final response = await apiClient.dio.get(
        '$_base/inventory',
        queryParameters: query,
      );
      final list = _unwrapList(response.data);
      return list
          .whereType<Map>()
          .map((e) => InventoryItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không tải được kho đồ'));
    }
  }

  @override
  Future<InventoryItemModel> getInventoryItem(String itemId) async {
    try {
      final response = await apiClient.dio.get('$_base/inventory/$itemId');
      return InventoryItemModel.fromJson(_unwrap(response.data));
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không tải được vật phẩm'));
    }
  }

  @override
  Future<List<InventoryHistoryModel>> getInventoryHistory(String itemId) async {
    try {
      final response = await apiClient.dio.get(
        '$_base/inventory/$itemId/history',
      );
      return _unwrapList(response.data)
          .whereType<Map>()
          .map(
            (item) =>
                InventoryHistoryModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Không tải được lịch sử vật phẩm'));
    }
  }
}
