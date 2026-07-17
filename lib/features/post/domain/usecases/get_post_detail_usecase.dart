import 'package:dartz/dartz.dart';
import '../repositories/post_repository.dart';
import '../entities/post_entity.dart';

class GetPostDetailUseCase {
  final PostRepository repository;

  GetPostDetailUseCase(this.repository);

  Future<Either<String, PostEntity>> call(String postId) async {
    return await repository.getPostDetail(postId);
  }
}
