import 'package:dartz/dartz.dart';
import '../repositories/group_repository.dart';

class UpdateMemberStatusUseCase {
  final GroupRepository repository;

  UpdateMemberStatusUseCase(this.repository);

  Future<Either<String, void>> call(String groupId, String userId, String status) async {
    return await repository.updateMemberStatus(groupId, userId, status);
  }
}
