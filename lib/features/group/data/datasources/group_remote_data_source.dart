import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../models/group_model.dart';
import '../models/join_request_model.dart';
import '../models/member_model.dart';

abstract class GroupRemoteDataSource {
  Future<List<GroupModel>> getGroups({int limit = 20, int offset = 0, String? query, String? provinceCode});
  Future<List<GroupModel>> getMyGroups({int limit = 20, int offset = 0, String? memberStatus});
  Future<GroupModel> getGroupDetail(String groupId);
  Future<GroupModel> updateGroup(
    String groupId, {
    String? name,
    String? description,
    String? avatarUrl,
    String? coverUrl,
  });
  Future<GroupModel> createGroup({
    required String name,
    String? description,
    String? avatarUrl,
    String? coverUrl,
    String? address,
    String? provinceCode,
    String? districtCode,
  });
  Future<JoinRequestModel> joinGroup(String groupId, {String? message});
  Future<List<JoinRequestModel>> getJoinRequests(String groupId, {String? status, int limit = 20, int offset = 0});
  Future<JoinRequestModel> approveJoinRequest(String groupId, String requestId);
  Future<JoinRequestModel> rejectJoinRequest(String groupId, String requestId);
  Future<List<MemberModel>> getGroupMembers(String groupId, {String? status, int limit = 20, int offset = 0});
  Future<void> updateMemberRole(String groupId, String userId, String role);
  Future<void> updateMemberStatus(String groupId, String userId, String status);
  Future<void> suspendGroup(String groupId);
}

class GroupRemoteDataSourceImpl implements GroupRemoteDataSource {
  final ApiClient apiClient;

  GroupRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<GroupModel>> getGroups({int limit = 20, int offset = 0, String? query, String? provinceCode}) async {
    final Map<String, dynamic> queryParameters = {
      'limit': limit,
      'offset': offset,
    };
    if (query != null && query.isNotEmpty) queryParameters['q'] = query;
    if (provinceCode != null && provinceCode.isNotEmpty) queryParameters['province_code'] = provinceCode;

    final response = await apiClient.dio.get(
      '${AppConstants.communityApiBaseUrl}/groups',
      queryParameters: queryParameters,
    );

    if (response.statusCode == 200) {
      final data = response.data['data']['items'] as List;
      return data.map((json) => GroupModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load groups');
    }
  }

  @override
  Future<GroupModel> getGroupDetail(String groupId) async {
    final response = await apiClient.dio.get(
      '${AppConstants.communityApiBaseUrl}/groups/$groupId',
    );

    if (response.statusCode == 200) {
      return GroupModel.fromJson(response.data['data']);
    } else {
      throw Exception('Failed to load group detail');
    }
  }

  @override
  Future<List<GroupModel>> getMyGroups({int limit = 20, int offset = 0, String? memberStatus}) async {
    final Map<String, dynamic> queryParameters = {
      'limit': limit,
      'offset': offset,
    };
    if (memberStatus != null && memberStatus.isNotEmpty) queryParameters['member_status'] = memberStatus;

    final response = await apiClient.dio.get(
      '${AppConstants.communityApiBaseUrl}/groups/me',
      queryParameters: queryParameters,
    );

    if (response.statusCode == 200) {
      final data = response.data['data']['items'] as List;
      return data.map((json) => GroupModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load my groups');
    }
  }

  @override
  Future<GroupModel> updateGroup(
    String groupId, {
    String? name,
    String? description,
    String? avatarUrl,
    String? coverUrl,
  }) async {
    try {
      final response = await apiClient.dio.patch(
        '${AppConstants.communityApiBaseUrl}/groups/$groupId',
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
          if (coverUrl != null) 'cover_url': coverUrl,
        },
      );
      if (response.statusCode == 200) {
        return GroupModel.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to update group');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Lỗi khi cập nhật nhóm');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<GroupModel> createGroup({
    required String name,
    String? description,
    String? avatarUrl,
    String? coverUrl,
    String? address,
    String? provinceCode,
    String? districtCode,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '${AppConstants.communityApiBaseUrl}/groups',
        data: {
          'name': name,
          if (description != null) 'description': description,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
          if (coverUrl != null) 'cover_url': coverUrl,
          if (address != null) 'address': address,
          if (provinceCode != null) 'province_code': provinceCode,
          if (districtCode != null) 'district_code': districtCode,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return GroupModel.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to create group');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Lỗi khi tạo nhóm');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<JoinRequestModel> joinGroup(String groupId, {String? message}) async {
    try {
      final response = await apiClient.dio.post(
        '${AppConstants.communityApiBaseUrl}/groups/$groupId/join',
        data: {
          if (message != null && message.isNotEmpty) 'message': message,
        },
      );
      final body = response.data;
      final data = body is Map && body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : (body is Map
              ? Map<String, dynamic>.from(body)
              : <String, dynamic>{});
      return JoinRequestModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        ApiErrorMapper.fromDio(e, fallback: 'Không gửi được yêu cầu tham gia nhóm.'),
      );
    }
  }

  @override
  Future<List<JoinRequestModel>> getJoinRequests(String groupId, {String? status, int limit = 20, int offset = 0}) async {
    try {
      final response = await apiClient.dio.get(
        '${AppConstants.communityApiBaseUrl}/groups/$groupId/join-requests',
        queryParameters: {
          if (status != null) 'status': status,
          'limit': limit,
          'offset': offset,
        },
      );
      final data = response.data['data']['items'] as List<dynamic>;
      return data.map((e) => JoinRequestModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Lỗi tải danh sách yêu cầu');
    }
  }

  @override
  Future<JoinRequestModel> approveJoinRequest(String groupId, String requestId) async {
    try {
      final response = await apiClient.dio.post(
        '${AppConstants.communityApiBaseUrl}/groups/$groupId/join-requests/$requestId/approve',
      );
      return JoinRequestModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Lỗi khi duyệt yêu cầu');
    }
  }

  @override
  Future<JoinRequestModel> rejectJoinRequest(String groupId, String requestId) async {
    try {
      final response = await apiClient.dio.post(
        '${AppConstants.communityApiBaseUrl}/groups/$groupId/join-requests/$requestId/reject',
      );
      return JoinRequestModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Lỗi khi từ chối yêu cầu');
    }
  }

  @override
  Future<List<MemberModel>> getGroupMembers(String groupId, {String? status, int limit = 20, int offset = 0}) async {
    try {
      final response = await apiClient.dio.get(
        '${AppConstants.communityApiBaseUrl}/groups/$groupId/members',
        queryParameters: {
          if (status != null) 'status': status,
          'limit': limit,
          'offset': offset,
        },
      );
      final data = response.data['data']['items'] as List<dynamic>;
      return data.map((e) => MemberModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Lỗi tải danh sách thành viên');
    }
  }

  @override
  Future<void> updateMemberRole(String groupId, String userId, String role) async {
    try {
      await apiClient.dio.put(
        '${AppConstants.communityApiBaseUrl}/groups/$groupId/members/$userId/role',
        data: {'role': role},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Lỗi cập nhật quyền thành viên');
    }
  }

  @override
  Future<void> updateMemberStatus(String groupId, String userId, String status) async {
    try {
      await apiClient.dio.put(
        '${AppConstants.communityApiBaseUrl}/groups/$groupId/members/$userId/status',
        data: {'status': status},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Lỗi cập nhật trạng thái thành viên');
    }
  }

  @override
  Future<void> suspendGroup(String groupId) async {
    try {
      await apiClient.dio.post('${AppConstants.communityApiBaseUrl}/admin/groups/$groupId/suspend');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Lỗi khi khóa nhóm');
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
