import 'package:dartz/dartz.dart';
import '../entities/post_entity.dart';
import '../entities/comment_entity.dart';

abstract class PostRepository {
  Future<Either<String, List<PostEntity>>> getGroupPosts(String groupId, {int offset = 0, int limit = 20});
  Future<Either<String, PostEntity>> createPost(
    String groupId,
    String content,
    String type,
    List<String> imageUrls,
  );
  Future<Either<String, void>> deletePost(String postId);
  Future<Either<String, PostEntity>> updatePostStatus(String postId, String status);
  Future<Either<String, PostEntity>> getPostDetail(String postId);
  Future<Either<String, void>> likePost(String postId);
  Future<Either<String, void>> unlikePost(String postId);
  Future<Either<String, List<CommentEntity>>> getComments(String postId, {int limit = 20, int offset = 0});
  Future<Either<String, CommentEntity>> addComment(String postId, String content);
}
