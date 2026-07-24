import 'package:dartz/dartz.dart';
import '../../data/models/group_model.dart';
import '../repositories/group_repository.dart';

class UpdateGroupUseCase {
  final GroupRepository repository;

  UpdateGroupUseCase(this.repository);

  Future<Either<String, GroupModel>> call(
    String groupId, {
    String? name,
    String? description,
    String? avatarUrl,
    String? coverUrl,
  }) {
    return repository.updateGroup(
      groupId,
      name: name,
      description: description,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
    );
  }
}
