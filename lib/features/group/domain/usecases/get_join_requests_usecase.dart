import 'package:dartz/dartz.dart';
import '../entities/join_request_entity.dart';
import '../repositories/group_repository.dart';

class GetJoinRequestsUseCase {
  final GroupRepository repository;

  GetJoinRequestsUseCase(this.repository);

  Future<Either<String, List<JoinRequestEntity>>> call(String groupId, {String? status, int limit = 20, int offset = 0}) {
    return repository.getJoinRequests(groupId, status: status, limit: limit, offset: offset);
  }
}
