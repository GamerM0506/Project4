import 'package:dartz/dartz.dart';
import '../repositories/post_repository.dart';
import '../entities/comment_entity.dart';

class AddCommentUseCase {
  final PostRepository repository;

  AddCommentUseCase(this.repository);

  Future<Either<String, CommentEntity>> call(String postId, String content) async {
    return await repository.addComment(postId, content);
  }
}
