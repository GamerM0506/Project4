import 'package:dartz/dartz.dart';
import '../entities/join_request_entity.dart';
import '../repositories/group_repository.dart';

class ApproveJoinUseCase {
  final GroupRepository repository;

  ApproveJoinUseCase(this.repository);

  Future<Either<String, JoinRequestEntity>> call(String groupId, String requestId) {
    return repository.approveJoinRequest(groupId, requestId);
  }
}
