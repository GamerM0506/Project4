import 'package:dartz/dartz.dart';
import '../repositories/group_repository.dart';
import '../../data/models/group_model.dart';

class GetGroupsUseCase {
  final GroupRepository repository;

  GetGroupsUseCase(this.repository);

  Future<Either<String, List<GroupModel>>> call({int limit = 20, int offset = 0, String? query, String? provinceCode}) {
    return repository.getGroups(limit: limit, offset: offset, query: query, provinceCode: provinceCode);
  }
}
