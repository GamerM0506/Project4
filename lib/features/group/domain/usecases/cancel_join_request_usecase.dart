import 'package:dartz/dartz.dart';
import '../repositories/group_repository.dart';

class CancelJoinRequestUseCase {
  final GroupRepository repository;

  CancelJoinRequestUseCase(this.repository);

  Future<Either<String, void>> call(String groupId) {
    return repository.cancelJoinRequest(groupId);
  }
}
