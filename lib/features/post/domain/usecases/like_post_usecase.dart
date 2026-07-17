import 'package:dartz/dartz.dart';
import '../repositories/post_repository.dart';

class LikePostUseCase {
  final PostRepository repository;

  LikePostUseCase(this.repository);

  Future<Either<String, void>> call(String postId) async {
    return await repository.likePost(postId);
  }
}
