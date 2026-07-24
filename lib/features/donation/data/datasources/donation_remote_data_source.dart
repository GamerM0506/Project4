import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/donation_model.dart';

abstract class DonationRemoteDataSource {
  Future<List<DonationModel>> getDonations({
    String? groupId,
    bool mine = false,
    String? status,
  });

  Future<DonationModel> getDonationDetail(String id);

  Future<DonationModel> createDonation(Map<String, dynamic> body);

  Future<void> reviewDonation(String id, Map<String, dynamic> body);

  Future<void> checkItem(
    String donationId,
    String itemId,
    Map<String, dynamic> body,
  );

  Future<List<DonationTimelineModel>> getTimeline(String id);
}

class DonationRemoteDataSourceImpl implements DonationRemoteDataSource {
  final ApiClient apiClient;

  DonationRemoteDataSourceImpl(this.apiClient);

  String get _base => '${AppConstants.apiBaseUrl}/donation';

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final inner = data['data'];
      if (inner is List) return inner;
      if (inner is Map) {
        if (inner['items'] is List) return inner['items'] as List;
        if (inner['data'] is List) return inner['data'] as List;
      }
      if (data['items'] is List) return data['items'] as List;
    }
    return const [];
  }

  Map<String, dynamic> _extractMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      return data;
    }
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  @override
  Future<List<DonationModel>> getDonations({
    String? groupId,
    bool mine = false,
    String? status,
  }) async {
    final query = <String, dynamic>{};
    if (groupId != null && groupId.isNotEmpty) query['group_id'] = groupId;
    if (mine) query['mine'] = true;
    if (status != null && status.isNotEmpty) query['status'] = status;

    final response = await apiClient.dio.get(
      '$_base/donations',
      queryParameters: query.isEmpty ? null : query,
    );
    final list = _extractList(response.data);
    return list
        .map((e) => DonationModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<DonationModel> getDonationDetail(String id) async {
    final response = await apiClient.dio.get('$_base/donations/$id');
    return DonationModel.fromJson(_extractMap(response.data));
  }

  @override
  Future<DonationModel> createDonation(Map<String, dynamic> body) async {
    final response = await apiClient.dio.post('$_base/donations', data: body);
    return DonationModel.fromJson(_extractMap(response.data));
  }

  @override
  Future<void> reviewDonation(String id, Map<String, dynamic> body) async {
    await apiClient.dio.put('$_base/donations/$id/review', data: body);
  }

  @override
  Future<void> checkItem(
    String donationId,
    String itemId,
    Map<String, dynamic> body,
  ) async {
    await apiClient.dio.put(
      '$_base/donations/$donationId/items/$itemId/check',
      data: body,
    );
  }

  @override
  Future<List<DonationTimelineModel>> getTimeline(String id) async {
    final response = await apiClient.dio.get('$_base/donations/$id/timeline');
    final list = _extractList(response.data);
    return list
        .map((e) =>
            DonationTimelineModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
