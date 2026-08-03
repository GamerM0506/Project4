import 'package:dartz/dartz.dart';
import '../repositories/post_repository.dart';
import '../entities/comment_entity.dart';

class AddCommentUseCase {
  final PostRepository repository;

  AddCommentUseCase(this.repository);

  /// [parentId] khác null nghĩa là trả lời một bình luận đã có.
  Future<Either<String, CommentEntity>> call(
    String postId,
    String content, {
    String? parentId,
  }) async {
    return await repository.addComment(postId, content, parentId: parentId);
  }
}
