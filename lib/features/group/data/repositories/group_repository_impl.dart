import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/entities/join_request_entity.dart';
import '../../domain/entities/member_entity.dart';
import '../datasources/group_remote_data_source.dart';
import '../models/group_model.dart';

class GroupRepositoryImpl implements GroupRepository {
  final GroupRemoteDataSource remoteDataSource;

  GroupRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<String, List<GroupModel>>> getGroups({int limit = 20, int offset = 0, String? query, String? provinceCode}) async {
    try {
      final result = await remoteDataSource.getGroups(
        limit: limit,
        offset: offset,
        query: query,
        provinceCode: provinceCode,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(e.response?.data?['detail']?[0]?['msg'] ?? 'Không thể tải danh sách nhóm');
    } catch (e) {
      return Left('Đã xảy ra lỗi: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, GroupModel>> getGroupDetail(String groupId) async {
    try {
      final result = await remoteDataSource.getGroupDetail(groupId);
      return Right(result);
    } on DioException catch (e) {
      return Left(e.response?.data?['detail'] ?? 'Không thể tải thông tin nhóm');
    } catch (e) {
      return Left('Đã xảy ra lỗi: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, GroupModel>> updateGroup(
    String groupId, {
    String? name,
    String? description,
    String? avatarUrl,
    String? coverUrl,
  }) async {
    try {
      final group = await remoteDataSource.updateGroup(
        groupId,
        name: name,
        description: description,
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
      );
      return Right(group);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, List<GroupModel>>> getMyGroups({int limit = 20, int offset = 0, String? memberStatus}) async {
    try {
      final result = await remoteDataSource.getMyGroups(
        limit: limit,
        offset: offset,
        memberStatus: memberStatus,
      );
      return Right(result);
    } on DioException catch (e) {
      return Left(e.response?.data?['detail']?[0]?['msg'] ?? 'Không thể tải danh sách nhóm của bạn');
    } catch (e) {
      return Left('Đã xảy ra lỗi: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, GroupModel>> createGroup({
    required String name,
    String? description,
    String? avatarUrl,
    String? coverUrl,
    String? address,
    String? provinceCode,
    String? districtCode,
  }) async {
    try {
      final group = await remoteDataSource.createGroup(
        name: name,
        description: description,
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
        address: address,
        provinceCode: provinceCode,
        districtCode: districtCode,
      );
      return Right(group);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, JoinRequestEntity>> joinGroup(String groupId, {String? message}) async {
    try {
      final request = await remoteDataSource.joinGroup(groupId, message: message);
      return Right(request);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, List<JoinRequestEntity>>> getJoinRequests(String groupId, {String? status, int limit = 20, int offset = 0}) async {
    try {
      final requests = await remoteDataSource.getJoinRequests(groupId, status: status, limit: limit, offset: offset);
      return Right(requests.cast<JoinRequestEntity>());
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, JoinRequestEntity>> approveJoinRequest(String groupId, String requestId) async {
    try {
      final request = await remoteDataSource.approveJoinRequest(groupId, requestId);
      return Right(request);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, JoinRequestEntity>> rejectJoinRequest(String groupId, String requestId) async {
    try {
      final request = await remoteDataSource.rejectJoinRequest(groupId, requestId);
      return Right(request);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, List<MemberEntity>>> getGroupMembers(String groupId, {String? status, int limit = 20, int offset = 0}) async {
    try {
      final members = await remoteDataSource.getGroupMembers(groupId, status: status, limit: limit, offset: offset);
      return Right(members.cast<MemberEntity>());
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, void>> updateMemberRole(String groupId, String userId, String role) async {
    try {
      await remoteDataSource.updateMemberRole(groupId, userId, role);
      return const Right(null);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, void>> updateMemberStatus(String groupId, String userId, String status) async {
    try {
      await remoteDataSource.updateMemberStatus(groupId, userId, status);
      return const Right(null);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, void>> approveGroup(String groupId) async {
    try {
      // Giả sử API endpoint là /admin/groups/:id/approve
      // Hiện tại remoteDataSource chưa có hàm này nên bỏ qua hoặc throw unimplemented
      // await remoteDataSource.approveGroup(groupId);
      return const Right(null);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<Either<String, void>> suspendGroup(String groupId) async {
    try {
      await remoteDataSource.suspendGroup(groupId);
      return const Right(null);
    } catch (e) {
      return Left(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
