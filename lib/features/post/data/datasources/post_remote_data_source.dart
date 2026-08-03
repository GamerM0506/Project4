import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import 'package:dio/dio.dart';

abstract class PostRemoteDataSource {
  Future<List<PostModel>> getGroupPosts(
    String groupId, {
    int offset = 0,
    int limit = 20,
  });
  Future<PostModel> createPost(
    String groupId,
    String content,
    String type,
    List<String> imageUrls,
  );
  Future<void> deletePost(String postId);
  Future<PostModel> updatePostStatus(String postId, String status);
  Future<PostModel> setPostPinned(String postId, bool isPinned);
  Future<PostModel> getPostDetail(String postId);
  Future<void> likePost(String postId);
  Future<void> unlikePost(String postId);
  Future<List<CommentModel>> getComments(
    String postId, {
    int limit = 20,
    int offset = 0,
  });
  Future<CommentModel> addComment(String postId, String content, {String? parentId});
}

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  final ApiClient apiClient;

  static const String _likedPostsKeyPrefix = 'LIKED_POST_IDS_';

  PostRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<PostModel>> getGroupPosts(
    String groupId, {
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final response = await apiClient.dio.get(
        '${AppConstants.communityApiBaseUrl}/groups/$groupId/posts',
        queryParameters: {'offset': offset, 'limit': limit},
      );

      final dataEnvelope = response.data as Map<String, dynamic>;
      final data = dataEnvelope['data'] as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>;

      final likedPostIds = _likedPostIds();
      return items
          .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
          .map(
            (post) => likedPostIds.contains(post.id)
                ? PostModel(
                    id: post.id,
                    groupId: post.groupId,
                    authorId: post.authorId,
                    content: post.content,
                    type: post.type,
                    refId: post.refId,
                    status: post.status,
                    isPinned: post.isPinned,
                    likeCount: post.likeCount,
                    commentCount: post.commentCount,
                    isLiked: true,
                    imageUrls: post.imageUrls,
                    createdAt: post.createdAt,
                    updatedAt: post.updatedAt,
                  )
                : post,
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(_communityError(e, 'Lỗi khi tải bài đăng'));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<PostModel> createPost(
    String groupId,
    String content,
    String type,
    List<String> imageUrls,
  ) async {
    try {
      final response = await apiClient.dio.post(
        '${AppConstants.communityApiBaseUrl}/groups/$groupId/posts',
        data: {'content': content, 'type': type, 'image_urls': imageUrls},
      );

      final dataEnvelope = response.data as Map<String, dynamic>;
      final data = dataEnvelope['data'] as Map<String, dynamic>;

      return PostModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(_communityError(e, 'Lỗi khi tạo bài đăng'));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    try {
      await apiClient.dio.patch(
        '${AppConstants.communityApiBaseUrl}/posts/$postId',
        data: {'status': 'hidden'},
      );
    } on DioException catch (e) {
      throw Exception(_communityError(e, 'Lỗi khi ẩn bài đăng'));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<PostModel> updatePostStatus(String postId, String status) async {
    try {
      final response = await apiClient.dio.patch(
        '${AppConstants.communityApiBaseUrl}/posts/$postId',
        data: {'status': status},
      );
      final dataEnvelope = response.data as Map<String, dynamic>;
      return PostModel.fromJson(dataEnvelope['data']);
    } on DioException catch (e) {
      throw Exception(_communityError(e, 'Lỗi khi cập nhật bài đăng'));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<PostModel> setPostPinned(String postId, bool isPinned) async {
    try {
      final response = await apiClient.dio.patch(
        '${AppConstants.communityApiBaseUrl}/posts/$postId',
        data: {'is_pinned': isPinned},
      );
      final dataEnvelope = response.data as Map<String, dynamic>;
      return PostModel.fromJson(dataEnvelope['data']);
    } on DioException catch (e) {
      throw Exception(
        _communityError(
          e,
          isPinned ? 'Lỗi khi ghim bài đăng' : 'Lỗi khi bỏ ghim bài đăng',
        ),
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<PostModel> getPostDetail(String postId) async {
    try {
      final response = await apiClient.dio.get(
        '${AppConstants.communityApiBaseUrl}/posts/$postId',
      );
      return PostModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(_communityError(e, 'Lỗi tải chi tiết bài đăng'));
    }
  }

  @override
  Future<void> likePost(String postId) async {
    try {
      await apiClient.dio.post(
        '${AppConstants.communityApiBaseUrl}/posts/$postId/reactions',
      );
      await _setLiked(postId, true);
    } on DioException catch (e) {
      throw Exception(_communityError(e, 'Lỗi khi thích bài đăng'));
    }
  }

  @override
  Future<void> unlikePost(String postId) async {
    try {
      await apiClient.dio.delete(
        '${AppConstants.communityApiBaseUrl}/posts/$postId/reactions',
      );
      await _setLiked(postId, false);
    } on DioException catch (e) {
      throw Exception(_communityError(e, 'Lỗi khi bỏ thích bài đăng'));
    }
  }

  Set<String> _likedPostIds() {
    final userId = apiClient.sharedPreferences.getString(
      AppConstants.keyUserId,
    );
    if (userId == null || userId.isEmpty) return <String>{};
    return apiClient.sharedPreferences
            .getStringList('$_likedPostsKeyPrefix$userId')
            ?.toSet() ??
        <String>{};
  }

  Future<void> _setLiked(String postId, bool liked) async {
    final userId = apiClient.sharedPreferences.getString(
      AppConstants.keyUserId,
    );
    if (userId == null || userId.isEmpty) return;
    final ids = _likedPostIds();
    liked ? ids.add(postId) : ids.remove(postId);
    await apiClient.sharedPreferences.setStringList(
      '$_likedPostsKeyPrefix$userId',
      ids.toList(),
    );
  }

  @override
  Future<List<CommentModel>> getComments(
    String postId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await apiClient.dio.get(
        '${AppConstants.communityApiBaseUrl}/posts/$postId/comments',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final data = response.data['data']['items'] as List;
      return data.map((e) => CommentModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(_communityError(e, 'Lỗi tải bình luận'));
    }
  }

  @override
  Future<CommentModel> addComment(
    String postId,
    String content, {
    String? parentId,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '${AppConstants.communityApiBaseUrl}/posts/$postId/comments',
        data: {
          'content': content,
          if (parentId != null && parentId.trim().isNotEmpty)
            'parent_id': parentId.trim(),
        },
      );
      return CommentModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(_communityError(e, 'Lỗi khi thêm bình luận'));
    }
  }
}

String _communityError(DioException exception, String fallback) {
  final data = exception.response?.data;
  if (data is! Map) return fallback;
  final error = data['error'];
  if (error is String && error.isNotEmpty) return error;
  if (error is Map) {
    final message = error['message'];
    if (message is String && message.isNotEmpty) return message;
    final details = error['details'];
    if (details is List && details.isNotEmpty) {
      final first = details.first;
      if (first is Map && first['msg'] is String) return first['msg'] as String;
      return details.join(', ');
    }
  }
  return fallback;
}
