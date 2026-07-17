import 'package:dartz/dartz.dart';
import '../repositories/group_repository.dart';
import '../../data/models/group_model.dart';

class CreateGroupParams {
  final String name;
  final String? description;
  final String? avatarUrl;
  final String? coverUrl;
  final String? address;
  final String? provinceCode;
  final String? districtCode;

  CreateGroupParams({
    required this.name,
    this.description,
    this.avatarUrl,
    this.coverUrl,
    this.address,
    this.provinceCode,
    this.districtCode,
  });
}

class CreateGroupUseCase {
  final GroupRepository repository;

  CreateGroupUseCase(this.repository);

  Future<Either<String, GroupModel>> call(CreateGroupParams params) {
    return repository.createGroup(
      name: params.name,
      description: params.description,
      avatarUrl: params.avatarUrl,
      coverUrl: params.coverUrl,
      address: params.address,
      provinceCode: params.provinceCode,
      districtCode: params.districtCode,
    );
  }
}
