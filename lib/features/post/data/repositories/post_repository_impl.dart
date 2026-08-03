import 'package:dartz/dartz.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/post_remote_data_source.dart';

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource remoteDataSource;

  PostRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<String, List<PostEntity>>> getGroupPosts(String groupId, {int offset = 0, int limit = 20}) async {
    try {
      final posts = await remoteDataSource.getGroupPosts(groupId, offset: offset, limit: limit);
      return Right<String, List<PostEntity>>(posts);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, PostEntity>> createPost(String groupId, String content, String type, List<String> imageUrls) async {
    try {
      final post = await remoteDataSource.createPost(groupId, content, type, imageUrls);
      return Right<String, PostEntity>(post);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, void>> deletePost(String postId) async {
    try {
      await remoteDataSource.deletePost(postId);
      return const Right(null);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, PostEntity>> updatePostStatus(String postId, String status) async {
    try {
      final post = await remoteDataSource.updatePostStatus(postId, status);
      return Right(post);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, PostEntity>> setPostPinned(
    String postId,
    bool isPinned,
  ) async {
    try {
      final post = await remoteDataSource.setPostPinned(postId, isPinned);
      return Right(post);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, PostEntity>> getPostDetail(String postId) async {
    try {
      final post = await remoteDataSource.getPostDetail(postId);
      return Right(post);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, void>> likePost(String postId) async {
    try {
      await remoteDataSource.likePost(postId);
      return const Right(null);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, void>> unlikePost(String postId) async {
    try {
      await remoteDataSource.unlikePost(postId);
      return const Right(null);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, List<CommentEntity>>> getComments(String postId, {int limit = 20, int offset = 0}) async {
    try {
      final comments = await remoteDataSource.getComments(postId, limit: limit, offset: offset);
      return Right(comments);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, CommentEntity>> addComment(
    String postId,
    String content, {
    String? parentId,
  }) async {
    try {
      final comment = await remoteDataSource.addComment(
        postId,
        content,
        parentId: parentId,
      );
      return Right(comment);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
