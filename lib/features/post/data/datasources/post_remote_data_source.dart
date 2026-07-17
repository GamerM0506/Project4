import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import 'package:dio/dio.dart';

abstract class PostRemoteDataSource {
  Future<List<PostModel>> getGroupPosts(String groupId, {int offset = 0, int limit = 20});
  Future<PostModel> createPost(String groupId, String content, String type, List<String> imageUrls);
  Future<void> deletePost(String postId);
  Future<PostModel> getPostDetail(String postId);
  Future<void> likePost(String postId);
  Future<void> unlikePost(String postId);
  Future<List<CommentModel>> getComments(String postId, {int limit = 20, int offset = 0});
  Future<CommentModel> addComment(String postId, String content);
}

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  final ApiClient apiClient;

  PostRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<PostModel>> getGroupPosts(String groupId, {int offset = 0, int limit = 20}) async {
    try {
      final response = await apiClient.dio.get(
        '${AppConstants.communityApiBaseUrl}/groups/$groupId/posts',
        queryParameters: {
          'offset': offset,
          'limit': limit,
        },
      );

      final dataEnvelope = response.data as Map<String, dynamic>;
      final data = dataEnvelope['data'] as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>;

      return items.map((json) => PostModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Lỗi khi tải bài đăng');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<PostModel> createPost(String groupId, String content, String type, List<String> imageUrls) async {
    try {
      final response = await apiClient.dio.post(
        '${AppConstants.communityApiBaseUrl}/groups/$groupId/posts',
        data: {
          'content': content,
          'type': type,
          'image_urls': imageUrls,
        },
      );

      final dataEnvelope = response.data as Map<String, dynamic>;
      final data = dataEnvelope['data'] as Map<String, dynamic>;
      
      return PostModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Lỗi khi tạo bài đăng');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    try {
      // Backend không có hàm DELETE bài viết. Thay vào đó dùng PATCH để ẩn bài viết
      await apiClient.dio.patch(
        '${AppConstants.communityApiBaseUrl}/posts/$postId',
        data: {'status': 'hidden'}, // Hoặc trạng thái tương ứng để ẩn bài
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Lỗi khi xóa bài đăng');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<PostModel> getPostDetail(String postId) async {
    try {
      final response = await apiClient.dio.get('${AppConstants.communityApiBaseUrl}/posts/$postId');
      return PostModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Lỗi tải chi tiết bài đăng');
    }
  }

  @override
  Future<void> likePost(String postId) async {
    try {
      await apiClient.dio.post('${AppConstants.communityApiBaseUrl}/posts/$postId/reactions');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Lỗi khi thích bài đăng');
    }
  }

  @override
  Future<void> unlikePost(String postId) async {
    try {
      await apiClient.dio.delete('${AppConstants.communityApiBaseUrl}/posts/$postId/reactions');
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Lỗi khi bỏ thích bài đăng');
    }
  }

  @override
  Future<List<CommentModel>> getComments(String postId, {int limit = 20, int offset = 0}) async {
    try {
      final response = await apiClient.dio.get(
        '${AppConstants.communityApiBaseUrl}/posts/$postId/comments',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final data = response.data['data']['items'] as List;
      return data.map((e) => CommentModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Lỗi tải bình luận');
    }
  }

  @override
  Future<CommentModel> addComment(String postId, String content) async {
    try {
      final response = await apiClient.dio.post(
        '${AppConstants.communityApiBaseUrl}/posts/$postId/comments',
        data: {'content': content},
      );
      return CommentModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['detail'] ?? 'Lỗi khi thêm bình luận');
    }
  }
}
