import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import 'models/group_model.dart';
import 'models/listing_model.dart';

class HomeRepository {
  final ApiClient apiClient;

  HomeRepository({required this.apiClient});

  Future<List<GroupModel>> getFeaturedGroups({int limit = 5}) async {
    try {
      final response = await apiClient.dio.get(
        '${AppConstants.communityApiBaseUrl}/groups',
        queryParameters: {'limit': limit},
      );
      if (response.statusCode == 200) {
        final List data = response.data['data']['items'] ?? [];
        return data.map((json) => GroupModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching featured groups: $e');
      return [];
    }
  }

  Future<List<ListingModel>> getRecentItems({int limit = 5}) async {
    try {
      final response = await apiClient.dio.get(
        '${AppConstants.marketplaceApiBaseUrl}/catalog',
        queryParameters: {'limit': limit},
      );
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((json) => ListingModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching recent items: $e');
      return [];
    }
  }
}
