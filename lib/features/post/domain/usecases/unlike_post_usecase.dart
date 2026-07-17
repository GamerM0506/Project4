import 'package:dartz/dartz.dart';
import '../repositories/post_repository.dart';

class UnlikePostUseCase {
  final PostRepository repository;

  UnlikePostUseCase(this.repository);

  Future<Either<String, void>> call(String postId) async {
    return await repository.unlikePost(postId);
  }
}
