import 'package:dartz/dartz.dart';
import '../entities/post_entity.dart';
import '../repositories/post_repository.dart';

class GetPostsUseCase {
  final PostRepository repository;

  GetPostsUseCase(this.repository);

  Future<Either<String, List<PostEntity>>> call(String groupId, {int offset = 0, int limit = 20}) {
    return repository.getGroupPosts(groupId, offset: offset, limit: limit);
  }
}
