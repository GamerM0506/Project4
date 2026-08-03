import 'package:dartz/dartz.dart';
import '../entities/post_entity.dart';
import '../repositories/post_repository.dart';

class SetPostPinnedUseCase {
  final PostRepository repository;

  SetPostPinnedUseCase(this.repository);

  Future<Either<String, PostEntity>> call(String postId, bool isPinned) {
    return repository.setPostPinned(postId, isPinned);
  }
}
