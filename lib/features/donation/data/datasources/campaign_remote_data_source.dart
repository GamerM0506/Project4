import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/campaign_item_input.dart';
import '../models/campaign_model.dart';
import '../models/category_model.dart';
import '../models/contribution_model.dart';

class CampaignRemoteDataSource {
  const CampaignRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// Danh mục vật phẩm do backend seed sẵn (Quần áo, Giày dép, ...).
  Future<List<CategoryModel>> getCategories() async {
    final response = await apiClient.dio.get(
      '${AppConstants.donationApiBaseUrl}/categories',
    );
    final body = response.data;
    final data = body is Map ? body['data'] : null;
    if (data is! List) {
      throw const FormatException('Category response is invalid');
    }
    final categories = data
        .whereType<Map>()
        .map((item) => CategoryModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return categories;
  }

  /// Backend trả kèm `items` ngay trong danh sách, không cần gọi thêm chi tiết
  /// cho từng đợt.
  Future<List<CampaignModel>> getCampaigns({
    String? groupId,
    String status = 'active',
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await apiClient.dio.get(
      '${AppConstants.donationApiBaseUrl}/campaigns',
      queryParameters: {
        if (groupId != null && groupId.isNotEmpty) 'group_id': groupId,
        if (status.isNotEmpty) 'status': status,
        'limit': limit,
        'offset': offset,
      },
    );
    final body = response.data;
    final data = body is Map ? body['data'] : null;
    final items = data is Map ? data['items'] : null;
    if (items is! List) {
      throw const FormatException('Campaign response is invalid');
    }
    return items
        .whereType<Map>()
        .map((item) => CampaignModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<CampaignModel> getCampaign(String id) async {
    final response = await apiClient.dio.get(
      '${AppConstants.donationApiBaseUrl}/campaigns/$id',
    );
    final body = response.data;
    final data = body is Map ? body['data'] : null;
    if (data is! Map) {
      throw const FormatException('Campaign response is invalid');
    }
    return CampaignModel.fromJson(Map<String, dynamic>.from(data));
  }

  /// Tiến độ từng mục tiêu của đợt (`remaining`, `fulfilled` do backend tính).
  Future<CampaignProgress> getCampaignProgress(String id) async {
    final response = await apiClient.dio.get(
      '${AppConstants.donationApiBaseUrl}/campaigns/$id/progress',
    );
    final body = response.data;
    final data = body is Map ? body['data'] : null;
    if (data is! Map) {
      throw const FormatException('Campaign progress response is invalid');
    }
    return CampaignProgress.fromJson(Map<String, dynamic>.from(data));
  }

  /// Gửi đơn đóng góp gồm một hoặc nhiều vật phẩm.
  ///
  /// Mỗi phần tử [items] trỏ tới một `campaign_item_id` của đợt và mang theo
  /// ảnh khai báo riêng.
  Future<ContributionModel> createContribution({
    required String campaignId,
    required List<ContributionItemInput> items,
    required String pickupMethod,
    String? pickupAddress,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('Đơn đóng góp cần ít nhất một vật phẩm.');
    }
    final response = await apiClient.dio.post(
      '${AppConstants.donationApiBaseUrl}/contributions',
      data: {
        'campaign_id': campaignId,
        'pickup_method': pickupMethod,
        if (pickupAddress != null && pickupAddress.trim().isNotEmpty)
          'pickup_address': pickupAddress.trim(),
        'items': items.map((item) => item.toJson()).toList(),
      },
    );
    return _contributionFromResponse(response.data);
  }

  Future<List<ContributionModel>> getContributions({
    String? campaignId,
    String? donorId,
    bool mine = false,
    String? status,
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await apiClient.dio.get(
      '${AppConstants.donationApiBaseUrl}/contributions',
      queryParameters: {
        if (campaignId != null && campaignId.isNotEmpty)
          'campaign_id': campaignId,
        if (donorId != null && donorId.isNotEmpty) 'donor_id': donorId,
        if (mine) 'mine': true,
        if (status != null && status.isNotEmpty) 'status': status,
        'limit': limit,
        'offset': offset,
      },
    );
    final body = response.data;
    final data = body is Map ? body['data'] : null;
    final items = data is Map ? data['items'] : null;
    if (items is! List) {
      throw const FormatException('Contribution response is invalid');
    }
    return items
        .whereType<Map>()
        .map(
          (item) => ContributionModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<ContributionModel> getContribution(String id) async {
    final response = await apiClient.dio.get(
      '${AppConstants.donationApiBaseUrl}/contributions/$id',
    );
    return _contributionFromResponse(response.data);
  }

  Future<void> reviewContribution({
    required String id,
    required String action,
    String? reason,
  }) async {
    await apiClient.dio.put(
      '${AppConstants.donationApiBaseUrl}/contributions/$id/review',
      data: {
        'action': action,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
  }

  Future<void> cancelContribution(String id) async {
    await apiClient.dio.put(
      '${AppConstants.donationApiBaseUrl}/contributions/$id/cancel',
    );
  }

  /// Kiểm tra một vật phẩm trong đơn.
  ///
  /// Backend chạy trong một transaction: món `accepted` sẽ cộng vào
  /// `campaign_items.received_quantity`, và khi mọi món đã kiểm tra xong thì
  /// đơn tự chuyển sang `completed` (hoặc `rejected` nếu hỏng hết).
  Future<void> checkContributionItem({
    required String contributionId,
    required String itemId,
    required String action,
    String? conditionActual,
    String? note,
    String? rejectReason,
    List<String> imageUrls = const [],
  }) async {
    await apiClient.dio.put(
      '${AppConstants.donationApiBaseUrl}/contributions/$contributionId/items/$itemId/check',
      data: {
        'action': action,
        if (conditionActual != null && conditionActual.isNotEmpty)
          'condition_actual': conditionActual,
        if (note != null && note.trim().isNotEmpty) 'check_note': note.trim(),
        if (rejectReason != null && rejectReason.trim().isNotEmpty)
          'reject_reason': rejectReason.trim(),
        'images': imageUrls
            .map((url) => {'image_url': url, 'type': 'actual_check'})
            .toList(),
      },
    );
  }

  Future<void> createCampaign({
    required String groupId,
    required String title,
    required List<CampaignItemInput> items,
    String? description,
    String? beneficiaryDescription,
    String? provinceCode,
    String? districtCode,
    DateTime? deadline,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('Đợt quyên góp cần ít nhất một vật phẩm.');
    }
    await apiClient.dio.post(
      '${AppConstants.donationApiBaseUrl}/campaigns',
      data: {
        'group_id': groupId,
        'title': title.trim(),
        if (description?.trim().isNotEmpty == true)
          'description': description!.trim(),
        if (beneficiaryDescription?.trim().isNotEmpty == true)
          'beneficiary_description': beneficiaryDescription!.trim(),
        if (provinceCode?.trim().isNotEmpty == true)
          'province_code': provinceCode!.trim(),
        if (districtCode?.trim().isNotEmpty == true)
          'district_code': districtCode!.trim(),
        if (deadline != null) 'deadline': _formatDate(deadline),
        'items': items.map((item) => item.toJson()).toList(),
      },
    );
  }

  /// Chỉ sửa được metadata của đợt; backend không cho đổi danh sách vật phẩm.
  Future<CampaignModel> updateCampaign(
    String id, {
    String? title,
    String? description,
    String? beneficiaryDescription,
    DateTime? deadline,
    bool clearDeadline = false,
  }) async {
    final response = await apiClient.dio.put(
      '${AppConstants.donationApiBaseUrl}/campaigns/$id',
      data: {
        if (title?.trim().isNotEmpty == true) 'title': title!.trim(),
        if (description != null) 'description': description.trim(),
        if (beneficiaryDescription != null)
          'beneficiary_description': beneficiaryDescription.trim(),
        if (clearDeadline)
          'deadline': null
        else if (deadline != null)
          'deadline': _formatDate(deadline),
      },
    );
    final body = response.data;
    final data = body is Map ? body['data'] : null;
    if (data is! Map) {
      throw const FormatException('Campaign response is invalid');
    }
    return CampaignModel.fromJson(Map<String, dynamic>.from(data));
  }

  static String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> closeCampaign(String id, {String? reason}) async {
    await apiClient.dio.put(
      '${AppConstants.donationApiBaseUrl}/campaigns/$id/close',
      data: {if (reason?.trim().isNotEmpty == true) 'reason': reason!.trim()},
    );
  }

  /// Trao tặng toàn bộ đợt: `active → fulfilled`.
  ///
  /// Ảnh trao tặng là bằng chứng cuối của hành trình món đồ, backend gửi kèm
  /// trong thông báo `campaign.delivered` tới mọi người đã quyên góp.
  Future<void> deliverCampaign(
    String id, {
    String? note,
    String? deliveryPhotoUrl,
  }) async {
    await apiClient.dio.post(
      '${AppConstants.donationApiBaseUrl}/campaigns/$id/deliver',
      data: {
        if (deliveryPhotoUrl != null && deliveryPhotoUrl.trim().isNotEmpty)
          'delivery_photo_url': deliveryPhotoUrl.trim(),
        if (note?.trim().isNotEmpty == true) 'delivery_note': note!.trim(),
      },
    );
  }

  ContributionModel _contributionFromResponse(dynamic body) {
    final data = body is Map ? body['data'] : null;
    if (data is! Map) {
      throw const FormatException('Contribution response is invalid');
    }
    return ContributionModel.fromJson(Map<String, dynamic>.from(data));
  }
}
