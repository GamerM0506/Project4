import 'package:dartz/dartz.dart';
import '../entities/post_entity.dart';
import '../repositories/post_repository.dart';

class CreatePostUseCase {
  final PostRepository repository;

  CreatePostUseCase(this.repository);

  Future<Either<String, PostEntity>> call(String groupId, String content, String type, List<String> imageUrls) {
    return repository.createPost(groupId, content, type, imageUrls);
  }
}
