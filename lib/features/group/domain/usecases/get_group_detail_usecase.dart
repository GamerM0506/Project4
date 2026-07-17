import 'package:dartz/dartz.dart';
import '../repositories/group_repository.dart';
import '../../data/models/group_model.dart';

class GetGroupDetailUseCase {
  final GroupRepository repository;

  GetGroupDetailUseCase(this.repository);

  Future<Either<String, GroupModel>> call(String groupId) {
    return repository.getGroupDetail(groupId);
  }
}
