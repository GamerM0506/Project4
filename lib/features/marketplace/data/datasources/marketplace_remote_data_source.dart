import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/listing_model.dart';
import '../models/request_model.dart';

abstract class MarketplaceRemoteDataSource {
  Future<List<ListingModel>> getCatalog({String? category, String? province, String? groupId});
  Future<List<ListingModel>> getListings();
  Future<ListingModel> getListingDetail(String id);
  Future<void> createListing(Map<String, dynamic> data);
  
  Future<List<RequestModel>> getRequests();
  Future<void> createRequest(Map<String, dynamic> data);
  Future<void> approveRequest(String id, String reviewedBy);
  Future<void> rejectRequest(String id, String reviewedBy, String reason);
  Future<void> scheduleRequest(String id, String reviewedBy, DateTime scheduledAt);
  Future<void> completeRequest(String id, String confirmedBy, String qrToken, String photoUrl);
  Future<Map<String, dynamic>> getStats();
}

class MarketplaceRemoteDataSourceImpl implements MarketplaceRemoteDataSource {
  final ApiClient apiClient;

  MarketplaceRemoteDataSourceImpl(this.apiClient);

  String get _baseUrl => AppConstants.marketplaceApiBaseUrl;

  @override
  Future<List<ListingModel>> getCatalog({String? category, String? province, String? groupId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (province != null) queryParams['province'] = province;
      if (groupId != null) queryParams['group_id'] = groupId;

      final response = await apiClient.dio.get('$_baseUrl/catalog', queryParameters: queryParams);
      
      // Assume response.data is a list or response.data['data'] is a list
      final List<dynamic> data = response.data is List ? response.data : (response.data['data'] ?? []);
      return data.map((json) => ListingModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get catalog: $e');
    }
  }

  @override
  Future<List<ListingModel>> getListings() async {
    try {
      final response = await apiClient.dio.get('$_baseUrl/listings');
      final List<dynamic> data = response.data is List ? response.data : (response.data['data'] ?? []);
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
      final groupId = payload['group_id']?.toString() ?? '';

      // Query donation-service inventory for a valid UUID item ID
      try {
        final query = groupId.isNotEmpty ? {'group_id': groupId} : <String, dynamic>{};
        final response = await apiClient.dio.get(
          '${AppConstants.apiBaseUrl}/donation/inventory',
          queryParameters: query,
        );
        if (response.data != null) {
          final rawData = response.data is Map ? response.data['data'] : response.data;
          List items = [];
          if (rawData is Map && rawData['items'] is List) {
            items = rawData['items'];
          } else if (rawData is List) {
            items = rawData;
          }
          if (items.isNotEmpty) {
            final validId = items.first['id']?.toString();
            if (validId != null && validId.isNotEmpty) {
              payload['inventory_item_id'] = validId;
            }
          }
        }
      } catch (_) {}

      await apiClient.dio.post('$_baseUrl/listings', data: payload);
    } catch (e) {
      throw Exception('Failed to create listing: $e');
    }
  }

  @override
  Future<List<RequestModel>> getRequests() async {
    try {
      final response = await apiClient.dio.get('$_baseUrl/requests');
      final List<dynamic> data = response.data is List ? response.data : (response.data['data'] ?? []);
      return data.map((json) => RequestModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get requests: $e');
    }
  }

  @override
  Future<void> createRequest(Map<String, dynamic> data) async {
    try {
      await apiClient.dio.post('$_baseUrl/requests', data: data);
    } catch (e) {
      throw Exception('Failed to create request: $e');
    }
  }

  @override
  Future<void> approveRequest(String id, String reviewedBy) async {
    try {
      await apiClient.dio.put('$_baseUrl/requests/$id/approve', data: {'reviewed_by': reviewedBy});
    } catch (e) {
      throw Exception('Failed to approve request: $e');
    }
  }

  @override
  Future<void> rejectRequest(String id, String reviewedBy, String reason) async {
    try {
      await apiClient.dio.put('$_baseUrl/requests/$id/reject', data: {'reviewed_by': reviewedBy, 'reason': reason});
    } catch (e) {
      throw Exception('Failed to reject request: $e');
    }
  }

  @override
  Future<void> scheduleRequest(String id, String reviewedBy, DateTime scheduledAt) async {
    try {
      await apiClient.dio.put('$_baseUrl/requests/$id/schedule', data: {
        'reviewed_by': reviewedBy,
        'scheduled_at': scheduledAt.toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to schedule request: $e');
    }
  }

  @override
  Future<void> completeRequest(String id, String confirmedBy, String qrToken, String photoUrl) async {
    try {
      await apiClient.dio.put('$_baseUrl/requests/$id/complete', data: {
        'confirmed_by': confirmedBy,
        'qr_token': qrToken,
        'photo_url': photoUrl,
      });
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
