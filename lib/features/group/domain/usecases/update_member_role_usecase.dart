import 'package:dartz/dartz.dart';
import '../repositories/group_repository.dart';

class UpdateMemberRoleUseCase {
  final GroupRepository repository;

  UpdateMemberRoleUseCase(this.repository);

  Future<Either<String, void>> call(String groupId, String userId, String role) async {
    return await repository.updateMemberRole(groupId, userId, role);
  }
}
