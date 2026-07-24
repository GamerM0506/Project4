import 'package:dartz/dartz.dart';
import '../../data/models/group_model.dart';
import '../entities/join_request_entity.dart';
import '../entities/member_entity.dart';

abstract class GroupRepository {
  Future<Either<String, List<GroupModel>>> getGroups({
    int limit = 20,
    int offset = 0,
    String? query,
    String? provinceCode,
  });
  Future<Either<String, List<GroupModel>>> getMyGroups({
    int limit = 20,
    int offset = 0,
    String? memberStatus,
  });
  Future<Either<String, GroupModel>> getGroupDetail(String groupId);
  Future<Either<String, GroupModel>> updateGroup(
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
  });
  Future<Either<String, GroupModel>> createGroup({
    required String name,
    String? description,
    String? avatarUrl,
    String? coverUrl,
    String? address,
    String? provinceCode,
    String? districtCode,
  });
  Future<Either<String, void>> suspendGroup(String groupId);
  Future<Either<String, JoinRequestEntity>> joinGroup(
    String groupId, {
    String? message,
  });
  Future<Either<String, List<JoinRequestEntity>>> getJoinRequests(
    String groupId, {
    String? status,
    int limit = 20,
    int offset = 0,
  });
  Future<Either<String, JoinRequestEntity>> approveJoinRequest(
    String groupId,
    String requestId,
  );
  Future<Either<String, JoinRequestEntity>> rejectJoinRequest(
    String groupId,
    String requestId,
  );
  Future<Either<String, List<MemberEntity>>> getGroupMembers(
    String groupId, {
    String? status,
    int limit = 20,
    int offset = 0,
  });
  Future<Either<String, void>> updateMemberRole(
    String groupId,
    String userId,
    String role,
  );
  Future<Either<String, void>> updateMemberStatus(
    String groupId,
    String userId,
    String status,
  );

  // Admin Actions
  Future<Either<String, void>> approveGroup(String groupId);
}
