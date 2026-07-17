import 'package:dartz/dartz.dart';
import '../repositories/group_repository.dart';
import '../../data/models/group_model.dart';

class GetMyGroupsUseCase {
  final GroupRepository repository;

  GetMyGroupsUseCase(this.repository);

  Future<Either<String, List<GroupModel>>> call({int limit = 20, int offset = 0, String? memberStatus}) {
    return repository.getMyGroups(limit: limit, offset: offset, memberStatus: memberStatus);
  }
}
