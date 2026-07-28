import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../domain/entities/paginated_result.dart';
import '../models/category_model.dart';
import '../models/delivery_confirmation_model.dart';
import '../models/listing_model.dart';
import '../models/request_model.dart';

abstract class MarketplaceRemoteDataSource {
  Future<PaginatedResult<ListingModel>> getCatalog({
    String? categoryId,
    String? provinceCode,
    String? groupId,
    String? status,
    int page = 1,
    int limit = 20,
    String? search,
  });
  Future<List<CategoryModel>> getCategories();
  Future<List<ListingModel>> getListings();
  Future<ListingModel> getListingDetail(String id);
  Future<void> createListing(Map<String, dynamic> data);
  Future<void> closeListing(String id);

  Future<PaginatedResult<RequestModel>> getRequests({
    String? groupId,
    String? listingId,
    String? receiverId,
    String? status,
    int page = 1,
    int limit = 20,
  });
  Future<RequestModel> getRequestByCode(String code);
  Future<void> createRequest(Map<String, dynamic> data);
  Future<void> approveRequest(String id);
  Future<void> rejectRequest(String id, String reason);
  Future<void> scheduleRequest(String id, DateTime scheduledAt);
  Future<void> completeRequest(
    String id, {
    required String qrToken,
    String? photoUrl,
    String? note,
  });
  Future<void> cancelRequest(String id);
  Future<void> noShowRequest(String id);
  Future<DeliveryConfirmationModel> getDeliveryConfirmation(String id);
  Future<Map<String, dynamic>> getStats();
}

class MarketplaceRemoteDataSourceImpl implements MarketplaceRemoteDataSource {
  final ApiClient apiClient;

  MarketplaceRemoteDataSourceImpl(this.apiClient);

  String get _baseUrl => AppConstants.marketplaceApiBaseUrl;

  @override
  Future<PaginatedResult<ListingModel>> getCatalog({
    String? categoryId,
    String? provinceCode,
    String? groupId,
    String? status,
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final response = await apiClient.dio.get(
        '$_baseUrl/catalog',
        queryParameters: {
          if (categoryId?.isNotEmpty ?? false) 'category_id': categoryId,
          if (provinceCode?.isNotEmpty ?? false) 'province_code': provinceCode,
          if (groupId?.isNotEmpty ?? false) 'group_id': groupId,
          if (status?.isNotEmpty ?? false) 'status': status,
          'page': page,
          'limit': limit,
          if (search?.trim().isNotEmpty ?? false) 'search': search!.trim(),
        },
      );
      return _page(
        response.data,
        (json) => ListingModel.fromJson(json),
        page,
        limit,
      );
    } catch (error) {
      throw Exception(
        apiErrorMessage(error, fallback: 'Không thể tải gian hàng.'),
      );
    }
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await apiClient.dio.get(
        '${AppConstants.donationApiBaseUrl}/categories',
      );
      final data = response.data is Map ? response.data['data'] : response.data;
      final items = data is List ? data : const [];
      return items
          .whereType<Map>()
          .map(
            (item) => CategoryModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (error) {
      throw Exception(
        apiErrorMessage(error, fallback: 'Không thể tải danh mục.'),
      );
    }
  }

  @override
  Future<List<ListingModel>> getListings() async {
    try {
      final response = await apiClient.dio.get('$_baseUrl/listings');
      final data = response.data is Map ? response.data['data'] : response.data;
      return (data is List ? data : const [])
          .whereType<Map>()
          .map((json) => ListingModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (error) {
      throw Exception(
        apiErrorMessage(error, fallback: 'Không thể tải danh sách vật phẩm.'),
      );
    }
  }

  @override
  Future<ListingModel> getListingDetail(String id) async {
    try {
      final response = await apiClient.dio.get('$_baseUrl/listings/$id');
      final data = response.data is Map
          ? (response.data['data'] ?? response.data)
          : response.data;
      return ListingModel.fromJson(Map<String, dynamic>.from(data as Map));
    } catch (error) {
      throw Exception(
        apiErrorMessage(error, fallback: 'Không thể tải chi tiết vật phẩm.'),
      );
    }
  }

  @override
  Future<void> createListing(Map<String, dynamic> data) async {
    try {
      final payload = Map<String, dynamic>.from(data);
      if ((payload['inventory_item_id']?.toString() ?? '').isEmpty) {
        throw Exception('inventory_item_id is required (UUID từ kho donation)');
      }
      if ((payload['group_id']?.toString() ?? '').isEmpty) {
        throw Exception('group_id is required');
      }
      payload.removeWhere((key, value) => value == null || value == '');
      await apiClient.dio.post('$_baseUrl/listings', data: payload);
    } catch (error) {
      throw Exception(
        apiErrorMessage(error, fallback: 'Không thể đăng vật phẩm.'),
      );
    }
  }

  @override
  Future<void> closeListing(String id) => _put(
    '$_baseUrl/listings/$id/close',
    fallback: 'Không thể đóng vật phẩm.',
  );

  @override
  Future<PaginatedResult<RequestModel>> getRequests({
    String? groupId,
    String? listingId,
    String? receiverId,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await apiClient.dio.get(
        '$_baseUrl/requests',
        queryParameters: {
          if (groupId?.isNotEmpty ?? false) 'group_id': groupId,
          if (listingId?.isNotEmpty ?? false) 'listing_id': listingId,
          if (receiverId?.isNotEmpty ?? false) 'receiver_id': receiverId,
          if (status?.isNotEmpty ?? false) 'status': status,
          'page': page,
          'limit': limit,
        },
      );
      return _page(
        response.data,
        (json) => RequestModel.fromJson(json),
        page,
        limit,
      );
    } catch (error) {
      throw Exception(
        apiErrorMessage(error, fallback: 'Không thể tải yêu cầu nhận đồ.'),
      );
    }
  }

  @override
  Future<void> createRequest(Map<String, dynamic> data) async {
    final listingId = data['listing_id']?.toString() ?? '';
    final quantity = data['quantity'];
    if (listingId.isEmpty) throw Exception('listing_id is required');
    if (quantity is! int || quantity <= 0) {
      throw Exception('quantity must be greater than 0');
    }
    try {
      await apiClient.dio.post(
        '$_baseUrl/requests',
        data: {
          'listing_id': listingId,
          'quantity': quantity,
          if (data['reason']?.toString().trim().isNotEmpty ?? false)
            'reason': data['reason'].toString().trim(),
        },
      );
    } catch (error) {
      throw Exception(
        apiErrorMessage(error, fallback: 'Không thể gửi yêu cầu nhận đồ.'),
      );
    }
  }

  @override
  Future<RequestModel> getRequestByCode(String code) async {
    try {
      final response = await apiClient.dio.get(
        '$_baseUrl/requests/by-code/${Uri.encodeComponent(code.trim())}',
      );
      final data = response.data is Map
          ? (response.data['data'] ?? response.data)
          : response.data;
      return RequestModel.fromJson(Map<String, dynamic>.from(data as Map));
    } catch (error) {
      throw Exception(
        apiErrorMessage(error, fallback: 'Không thể tra cứu yêu cầu nhận đồ.'),
      );
    }
  }

  @override
  Future<void> approveRequest(String id) => _put(
    '$_baseUrl/requests/$id/approve',
    data: const <String, dynamic>{},
    fallback: 'Không thể duyệt yêu cầu.',
  );

  @override
  Future<void> rejectRequest(String id, String reason) => _put(
    '$_baseUrl/requests/$id/reject',
    data: {'reason': reason},
    fallback: 'Không thể từ chối yêu cầu.',
  );

  @override
  Future<void> scheduleRequest(String id, DateTime scheduledAt) => _put(
    '$_baseUrl/requests/$id/schedule',
    data: {'scheduled_at': scheduledAt.toIso8601String()},
    fallback: 'Không thể đặt lịch nhận đồ.',
  );

  @override
  Future<void> completeRequest(
    String id, {
    required String qrToken,
    String? photoUrl,
    String? note,
  }) => _put(
    '$_baseUrl/requests/$id/complete',
    data: {
      'qr_token': qrToken,
      if (photoUrl?.trim().isNotEmpty ?? false) 'photo_url': photoUrl!.trim(),
      if (note?.trim().isNotEmpty ?? false) 'note': note!.trim(),
    },
    fallback: 'Không thể hoàn tất giao nhận.',
  );

  @override
  Future<void> cancelRequest(String id) =>
      _put('$_baseUrl/requests/$id/cancel', fallback: 'Không thể hủy yêu cầu.');

  @override
  Future<void> noShowRequest(String id) => _put(
    '$_baseUrl/requests/$id/no-show',
    data: const <String, dynamic>{},
    fallback: 'Không thể đánh dấu không đến nhận.',
  );

  @override
  Future<DeliveryConfirmationModel> getDeliveryConfirmation(String id) async {
    try {
      final response = await apiClient.dio.get(
        '$_baseUrl/requests/$id/confirmation',
      );
      final data = response.data is Map
          ? (response.data['data'] ?? response.data)
          : response.data;
      return DeliveryConfirmationModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
    } catch (error) {
      throw Exception(
        apiErrorMessage(error, fallback: 'Không thể tải biên nhận giao đồ.'),
      );
    }
  }

  @override
  Future<DeliveryConfirmationModel> addReceiverConfirmation(
    String id,
    String photoUrl,
    String? note,
  ) async {
    try {
      final response = await apiClient.dio.put(
        '$_baseUrl/requests/$id/receiver-confirmation',
        data: {
          'photo_url': photoUrl,
          if (note?.trim().isNotEmpty ?? false) 'note': note!.trim(),
        },
      );
      final data = response.data is Map
          ? (response.data['data'] ?? response.data)
          : response.data;
      return DeliveryConfirmationModel.fromJson(Map<String, dynamic>.from(data as Map));
    } catch (error) {
      throw Exception(
        apiErrorMessage(error, fallback: 'Không thể xác nhận đã nhận đồ.'),
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await apiClient.dio.get('$_baseUrl/stats');
      final data = response.data is Map
          ? (response.data['data'] ?? response.data)
          : response.data;
      return Map<String, dynamic>.from(data as Map);
    } catch (error) {
      throw Exception(
        apiErrorMessage(error, fallback: 'Không thể tải thống kê.'),
      );
    }
  }

  Future<void> _put(
    String path, {
    Map<String, dynamic>? data,
    required String fallback,
  }) async {
    try {
      await apiClient.dio.put(path, data: data);
    } catch (error) {
      throw Exception(apiErrorMessage(error, fallback: fallback));
    }
  }

  PaginatedResult<T> _page<T>(
    dynamic body,
    T Function(Map<String, dynamic>) convert,
    int fallbackPage,
    int fallbackLimit,
  ) {
    final map = body is Map ? body : const <String, dynamic>{};
    final rawItems = body is List ? body : (map['data'] as List? ?? const []);
    final meta = map['meta'] is Map ? map['meta'] as Map : const {};
    final items = rawItems
        .whereType<Map>()
        .map((json) => convert(Map<String, dynamic>.from(json)))
        .toList();
    return PaginatedResult(
      items: items,
      page: int.tryParse(meta['page']?.toString() ?? '') ?? fallbackPage,
      limit: int.tryParse(meta['limit']?.toString() ?? '') ?? fallbackLimit,
      total: int.tryParse(meta['total']?.toString() ?? '') ?? items.length,
      totalPages:
          int.tryParse(meta['total_pages']?.toString() ?? '') ??
          (items.isEmpty ? 0 : 1),
    );
  }
}
