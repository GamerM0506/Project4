import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import 'models/group_model.dart';
import 'models/listing_model.dart';

class HomeRepository {
  final ApiClient apiClient;

  HomeRepository({required this.apiClient});

  Future<List<GroupModel>> getFeaturedGroups({int limit = 5}) async {
    final response = await apiClient.dio.get(
      '${AppConstants.communityApiBaseUrl}/groups',
      queryParameters: {'limit': limit},
    );
    final body = response.data;
    final List data = body is Map && body['data'] is Map
        ? (body['data']['items'] as List? ?? const [])
        : const [];
    return data.map((json) => GroupModel.fromJson(json)).toList();
  }

  Future<List<ListingModel>> getRecentItems({int limit = 5}) async {
    final response = await apiClient.dio.get(
      '${AppConstants.marketplaceApiBaseUrl}/catalog',
      queryParameters: {'limit': limit},
    );
    final body = response.data;
    final List data = body is Map && body['data'] is List
        ? body['data'] as List
        : const [];
    return data.map((json) => ListingModel.fromJson(json)).toList();
  }
}
