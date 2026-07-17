import 'package:dartz/dartz.dart';
import '../repositories/post_repository.dart';

class DeletePostUseCase {
  final PostRepository repository;

  DeletePostUseCase(this.repository);

  Future<Either<String, void>> call(String postId) async {
    return await repository.deletePost(postId);
  }
}
