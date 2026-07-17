import 'package:dartz/dartz.dart';
import '../entities/join_request_entity.dart';
import '../repositories/group_repository.dart';

class JoinGroupUseCase {
  final GroupRepository repository;

  JoinGroupUseCase(this.repository);

  Future<Either<String, JoinRequestEntity>> call(String groupId, {String? message}) {
    return repository.joinGroup(groupId, message: message);
  }
}
