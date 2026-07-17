import 'package:dartz/dartz.dart';
import '../entities/member_entity.dart';
import '../repositories/group_repository.dart';

class GetMembersUseCase {
  final GroupRepository repository;

  GetMembersUseCase(this.repository);

  Future<Either<String, List<MemberEntity>>> call(String groupId, {String? status, int limit = 20, int offset = 0}) {
    return repository.getGroupMembers(groupId, status: status, limit: limit, offset: offset);
  }
}
