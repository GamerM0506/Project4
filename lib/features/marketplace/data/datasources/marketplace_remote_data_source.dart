import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/listing_model.dart';
import '../models/request_model.dart';

abstract class MarketplaceRemoteDataSource {
  Future<List<ListingModel>> getCatalog({
    String? category,
    String? province,
    String? groupId,
  });
  Future<List<ListingModel>> getListings();
  Future<ListingModel> getListingDetail(String id);
  Future<void> createListing(Map<String, dynamic> data);

  Future<List<RequestModel>> getRequests();
  Future<void> createRequest(Map<String, dynamic> data);
  Future<void> approveRequest(String id, String reviewedBy);
  Future<void> rejectRequest(String id, String reviewedBy, String reason);
  Future<void> scheduleRequest(
    String id,
    String reviewedBy,
    DateTime scheduledAt,
  );
  Future<void> completeRequest(
    String id,
    String confirmedBy,
    String qrToken,
    String photoUrl,
  );
  Future<Map<String, dynamic>> getStats();
}

class MarketplaceRemoteDataSourceImpl implements MarketplaceRemoteDataSource {
  final ApiClient apiClient;

  MarketplaceRemoteDataSourceImpl(this.apiClient);

  String get _baseUrl => AppConstants.marketplaceApiBaseUrl;

  @override
  Future<List<ListingModel>> getCatalog({
    String? category,
    String? province,
    String? groupId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (province != null) queryParams['province'] = province;
      if (groupId != null) queryParams['group_id'] = groupId;

      final response = await apiClient.dio.get(
        '$_baseUrl/catalog',
        queryParameters: queryParams,
      );

      // Assume response.data is a list or response.data['data'] is a list
      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['data'] ?? []);
      return data.map((json) => ListingModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get catalog: $e');
    }
  }

  @override
  Future<List<ListingModel>> getListings() async {
    try {
      final response = await apiClient.dio.get('$_baseUrl/listings');
      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['data'] ?? []);
      return data.map((json) => ListingModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get listings: $e');
    }
  }

  @override
  Future<ListingModel> getListingDetail(String id) async {
    try {
      final response = await apiClient.dio.get('$_baseUrl/listings/$id');
      final data = response.data['data'] ?? response.data;
      return ListingModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get listing detail: $e');
    }
  }

  @override
  Future<void> createListing(Map<String, dynamic> data) async {
    try {
      final payload = Map<String, dynamic>.from(data);
      final inventoryItemId = payload['inventory_item_id']?.toString() ?? '';
      final groupId = payload['group_id']?.toString() ?? '';

      if (inventoryItemId.isEmpty) {
        throw Exception('inventory_item_id is required (UUID từ kho donation)');
      }
      if (groupId.isEmpty) {
        throw Exception('group_id is required');
      }

      // Backend fills title/category/condition from inventory when missing
      payload.removeWhere((key, value) => value == null || value == '');

      await apiClient.dio.post('$_baseUrl/listings', data: payload);
    } on DioException catch (e) {
      final detail = e.response?.data;
      if (detail is Map) {
        final msg = detail['message'] ?? detail['detail'] ?? detail['error'];
        if (msg != null) throw Exception(msg.toString());
      }
      throw Exception('Failed to create listing: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create listing: $e');
    }
  }

  @override
  Future<List<RequestModel>> getRequests() async {
    try {
      final response = await apiClient.dio.get('$_baseUrl/requests');
      final List<dynamic> data = response.data is List
          ? response.data
          : (response.data['data'] ?? []);
      return data.map((json) => RequestModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get requests: $e');
    }
  }

  @override
  Future<void> createRequest(Map<String, dynamic> data) async {
    try {
      final listingId = data['listing_id']?.toString() ?? '';
      final quantity = data['quantity'];
      if (listingId.isEmpty) throw Exception('listing_id is required');
      if (quantity is! int || quantity <= 0) {
        throw Exception('quantity must be greater than 0');
      }

      await apiClient.dio.post(
        '$_baseUrl/requests',
        data: {
          'listing_id': listingId,
          'quantity': quantity,
          if (data['reason']?.toString().trim().isNotEmpty ?? false)
            'reason': data['reason'].toString().trim(),
        },
      );
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map) {
        final detail = body['message'] ?? body['detail'] ?? body['error'];
        if (detail is String && detail.isNotEmpty) throw Exception(detail);
        if (detail is Map && detail['message'] != null) {
          throw Exception(detail['message'].toString());
        }
      }
      throw Exception('Không thể gửi yêu cầu nhận đồ. Vui lòng thử lại.');
    }
  }

  @override
  Future<void> approveRequest(String id, String reviewedBy) async {
    try {
      await apiClient.dio.put(
        '$_baseUrl/requests/$id/approve',
        data: {'reviewed_by': reviewedBy},
      );
    } catch (e) {
      throw Exception('Failed to approve request: $e');
    }
  }

  @override
  Future<void> rejectRequest(
    String id,
    String reviewedBy,
    String reason,
  ) async {
    try {
      await apiClient.dio.put(
        '$_baseUrl/requests/$id/reject',
        data: {'reviewed_by': reviewedBy, 'reason': reason},
      );
    } catch (e) {
      throw Exception('Failed to reject request: $e');
    }
  }

  @override
  Future<void> scheduleRequest(
    String id,
    String reviewedBy,
    DateTime scheduledAt,
  ) async {
    try {
      await apiClient.dio.put(
        '$_baseUrl/requests/$id/schedule',
        data: {
          'reviewed_by': reviewedBy,
          'scheduled_at': scheduledAt.toIso8601String(),
        },
      );
    } catch (e) {
      throw Exception('Failed to schedule request: $e');
    }
  }

  @override
  Future<void> completeRequest(
    String id,
    String confirmedBy,
    String qrToken,
    String photoUrl,
  ) async {
    try {
      await apiClient.dio.put(
        '$_baseUrl/requests/$id/complete',
        data: {
          'confirmed_by': confirmedBy,
          'qr_token': qrToken,
          'photo_url': photoUrl,
        },
      );
    } catch (e) {
      throw Exception('Failed to complete request: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await apiClient.dio.get('$_baseUrl/stats');
      return response.data['data'] as Map<String, dynamic>? ?? response.data;
    } catch (e) {
      throw Exception('Failed to get stats: $e');
    }
  }
}
