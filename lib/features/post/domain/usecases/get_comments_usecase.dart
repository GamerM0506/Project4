import 'package:dartz/dartz.dart';
import '../repositories/post_repository.dart';
import '../entities/comment_entity.dart';

class GetCommentsUseCase {
  final PostRepository repository;

  GetCommentsUseCase(this.repository);

  Future<Either<String, List<CommentEntity>>> call(String postId, {int limit = 20, int offset = 0}) async {
    return await repository.getComments(postId, limit: limit, offset: offset);
  }
}
