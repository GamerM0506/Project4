import 'package:dartz/dartz.dart';
import '../entities/post_entity.dart';
import '../repositories/post_repository.dart';

class UpdatePostStatusUseCase {
  final PostRepository repository;

  UpdatePostStatusUseCase(this.repository);

  Future<Either<String, PostEntity>> call(String postId, String status) {
    return repository.updatePostStatus(postId, status);
  }
}
