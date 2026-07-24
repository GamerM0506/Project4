import 'package:dartz/dartz.dart';
import '../../data/models/group_model.dart';
import '../repositories/group_repository.dart';

class UpdateGroupUseCase {
  final GroupRepository repository;

  UpdateGroupUseCase(this.repository);

  Future<Either<String, GroupModel>> call(
    String groupId, {
    String? name,
    String? description,
    String? avatarUrl,
    String? coverUrl,
    String? address,
    String? provinceCode,
    String? districtCode,
    bool? allowMemberPost,
    bool? requirePostReview,
  }) {
    return repository.updateGroup(
      groupId,
      name: name,
      description: description,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
      address: address,
      provinceCode: provinceCode,
      districtCode: districtCode,
      allowMemberPost: allowMemberPost,
      requirePostReview: requirePostReview,
    );
  }
}
