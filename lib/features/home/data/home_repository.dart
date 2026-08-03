import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import 'models/feed_post_model.dart';
import 'models/group_model.dart';

/// Kết quả một trang feed.
class FeedPage {
  const FeedPage({required this.items, required this.total});

  final List<FeedPostModel> items;
  final int total;
}

class HomeRepository {
  final ApiClient apiClient;

  HomeRepository({required this.apiClient});

  Future<List<GroupModel>> getFeaturedGroups({int limit = 5}) async {
    // Lấy dư một chút để còn chỗ ưu tiên nhóm có ảnh, nhưng không kéo cả 100
    // bản ghi rồi vứt đi như trước.
    final response = await apiClient.dio.get(
      '${AppConstants.communityApiBaseUrl}/groups',
      queryParameters: {'limit': limit * 4, 'status': 'active'},
    );
    final body = response.data;
    final List data = body is Map && body['data'] is Map
        ? (body['data']['items'] as List? ?? const [])
        : const [];
    final groups = data.map((json) => GroupModel.fromJson(json)).toList();
    groups.sort((a, b) {
      final aHasImage = a.imageUrl != null ? 1 : 0;
      final bHasImage = b.imageUrl != null ? 1 : 0;
      return bHasImage.compareTo(aHasImage);
    });
    return groups.take(limit).toList();
  }

  /// Feed tổng hợp bài viết công khai từ các hội nhóm đang hoạt động.
  Future<FeedPage> getFeed({int limit = 10, int offset = 0}) async {
    final response = await apiClient.dio.get(
      '${AppConstants.communityApiBaseUrl}/feed',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final body = response.data;
    final data = body is Map ? body['data'] : null;
    if (data is! Map) {
      throw const FormatException('Feed response is invalid');
    }
    final items = data['items'];
    final meta = data['meta'];
    return FeedPage(
      items: items is List
          ? items
                .whereType<Map>()
                .map(
                  (json) =>
                      FeedPostModel.fromJson(Map<String, dynamic>.from(json)),
                )
                .toList()
          : const [],
      total: meta is Map ? (meta['total'] as num?)?.toInt() ?? 0 : 0,
    );
  }
}
