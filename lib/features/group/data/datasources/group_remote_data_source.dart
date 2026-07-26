import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/group_model.dart';
import '../models/join_request_model.dart';
import '../models/member_model.dart';
import '../../../../core/constants/app_constants.dart';

abstract class GroupRemoteDataSource {
  Future<List<GroupModel>> getGroups({
    int limit = 20,
    int offset = 0,
    String? query,
    String? provinceCode,
  });
  Future<List<GroupModel>> getMyGroups({
    int limit = 20,
    int offset = 0,
    String? memberStatus,
  });
  Future<GroupModel> getGroupDetail(String groupId);
  Future<GroupModel> updateGroup(
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
  Future<List<JoinRequestModel>> getJoinRequests(
    String groupId, {
    String? status,
    int limit = 20,
    int offset = 0,
  });
  Future<JoinRequestModel> approveJoinRequest(String groupId, String requestId);
  Future<JoinRequestModel> rejectJoinRequest(String groupId, String requestId);
  Future<List<MemberModel>> getGroupMembers(
    String groupId, {
    String? status,
    int limit = 20,
    int offset = 0,
  });
  Future<void> updateMemberRole(String groupId, String userId, String role);
  Future<void> updateMemberStatus(String groupId, String userId, String status);
  Future<void> approveGroup(String groupId);
  Future<void> suspendGroup(String groupId);
  bool hasPendingJoin(String groupId);
  Future<void> clearPendingJoin(String groupId);
}

class GroupRemoteDataSourceImpl implements GroupRemoteDataSource {
  final ApiClient apiClient;
  static const _pendingGroupsKeyPrefix = 'PENDING_GROUP_IDS_';

  GroupRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<GroupModel>> getGroups({
    int limit = 20,
    int offset = 0,
    String? query,
    String? provinceCode,
  }) async {
    final Map<String, dynamic> queryParameters = {
      'limit': limit,
      'offset': offset,
    };
    if (query != null && query.isNotEmpty) queryParameters['q'] = query;
    if (provinceCode != null && provinceCode.isNotEmpty) {
      queryParameters['province_code'] = provinceCode;
    }

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
  Future<List<GroupModel>> getMyGroups({
    int limit = 20,
    int offset = 0,
    String? memberStatus,
  }) async {
    final Map<String, dynamic> queryParameters = {
      'limit': limit,
      'offset': offset,
    };
    if (memberStatus != null && memberStatus.isNotEmpty) {
      queryParameters['member_status'] = memberStatus;
    }

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
    String? address,
    String? provinceCode,
    String? districtCode,
    bool? allowMemberPost,
    bool? requirePostReview,
  }) async {
    try {
      final response = await apiClient.dio.patch(
        '${AppConstants.communityApiBaseUrl}/groups/$groupId',
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (avatarUrl != null) 'avatar_url': avatarUrl,
          if (coverUrl != null) 'cover_url': coverUrl,
          if (address != null) 'address': address,
          if (provinceCode != null) 'province_code': provinceCode,
          if (districtCode != null) 'district_code': districtCode,
          if (allowMemberPost != null) 'allow_member_post': allowMemberPost,
          if (requirePostReview != null)
            'require_post_review': requirePostReview,
        },
      );
      if (response.statusCode == 200) {
        return GroupModel.fromJson(response.data['data']);
      } else {
        throw Exception('Failed to update group');
      }
    } on DioException catch (e) {
      throw Exception(_communityError(e, 'Lỗi khi cập nhật nhóm'));
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
      throw Exception(_communityError(e, 'Lỗi khi tạo nhóm'));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<JoinRequestModel> joinGroup(String groupId, {String? message}) async {
    try {
      final response = await apiClient.dio.post(
        '${AppConstants.communityApiBaseUrl}/groups/$groupId/join',
        data: message != null ? {'message': message} : {},
      );
      final dataEnvelope = response.data as Map<String, dynamic>;
      final request = JoinRequestModel.fromJson(dataEnvelope['data']);
      await _setPendingJoin(groupId, true);
      return request;
    } on DioException catch (e) {
      throw Exception(_communityError(e, 'Lỗi khi xin tham gia nhóm'));
    }
  }

  String? get _pendingGroupsKey {
    final userId = apiClient.sharedPreferences.getString(
      AppConstants.keyUserId,
    );
    return userId == null || userId.isEmpty
        ? null
        : '$_pendingGroupsKeyPrefix$userId';
  }

  @override
  bool hasPendingJoin(String groupId) {
    final key = _pendingGroupsKey;
    return key != null &&
        (apiClient.sharedPreferences.getStringList(key) ?? const []).contains(
          groupId,
        );
  }

  @override
  Future<void> clearPendingJoin(String groupId) =>
      _setPendingJoin(groupId, false);

  Future<void> _setPendingJoin(String groupId, bool pending) async {
    final key = _pendingGroupsKey;
    if (key == null) return;
    final ids = (apiClient.sharedPreferences.getStringList(key) ?? const [])
        .toSet();
    pending ? ids.add(groupId) : ids.remove(groupId);
    await apiClient.sharedPreferences.setStringList(key, ids.toList());
  }

  @override
  Future<List<JoinRequestModel>> getJoinRequests(
    String groupId, {
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
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
      throw Exception(_communityError(e, 'Lỗi tải danh sách yêu cầu'));
    }
  }

  @override
  Future<JoinRequestModel> approveJoinRequest(
    String groupId,
    String requestId,
  ) async {
    try {
      final response = await apiClient.dio.post(
        '${AppConstants.communityApiBaseUrl}/groups/$groupId/join-requests/$requestId/approve',
      );
      return JoinRequestModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(_communityError(e, 'Lỗi khi duyệt yêu cầu'));
    }
  }

  @override
  Future<JoinRequestModel> rejectJoinRequest(
    String groupId,
    String requestId,
  ) async {
    try {
      final response = await apiClient.dio.post(
        '${AppConstants.communityApiBaseUrl}/groups/$groupId/join-requests/$requestId/reject',
      );
      return JoinRequestModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(_communityError(e, 'Lỗi khi từ chối yêu cầu'));
    }
  }

  @override
  Future<List<MemberModel>> getGroupMembers(
    String groupId, {
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
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
      throw Exception(_communityError(e, 'Lỗi tải danh sách thành viên'));
    }
  }

  @override
  Future<void> updateMemberRole(
    String groupId,
    String userId,
    String role,
  ) async {
    try {
      await apiClient.dio.put(
        '${AppConstants.communityApiBaseUrl}/groups/$groupId/members/$userId/role',
        data: {'role': role},
      );
    } on DioException catch (e) {
      throw Exception(_communityError(e, 'Lỗi cập nhật quyền thành viên'));
    }
  }

  @override
  Future<void> updateMemberStatus(
    String groupId,
    String userId,
    String status,
  ) async {
    try {
      await apiClient.dio.put(
        '${AppConstants.communityApiBaseUrl}/groups/$groupId/members/$userId/status',
        data: {'status': status},
      );
    } on DioException catch (e) {
      throw Exception(_communityError(e, 'Lỗi cập nhật trạng thái thành viên'));
    }
  }

  @override
  Future<void> approveGroup(String groupId) async {
    try {
      await apiClient.dio.post(
        '${AppConstants.communityApiBaseUrl}/admin/groups/$groupId/approve',
      );
    } on DioException catch (e) {
      throw Exception(_communityError(e, 'Lỗi khi duyệt nhóm'));
    }
  }

  @override
  Future<void> suspendGroup(String groupId) async {
    try {
      await apiClient.dio.post(
        '${AppConstants.communityApiBaseUrl}/admin/groups/$groupId/suspend',
      );
    } on DioException catch (e) {
      throw Exception(_communityError(e, 'Lỗi khi khóa nhóm'));
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}

String _communityError(DioException exception, String fallback) {
  final data = exception.response?.data;
  if (data is! Map) return fallback;
  final error = data['error'];
  if (error is String && error.isNotEmpty) return error;
  if (error is Map) {
    final message = error['message'];
    if (message is String && message.isNotEmpty) return message;
    final details = error['details'];
    if (details is List && details.isNotEmpty) {
      final first = details.first;
      if (first is Map && first['msg'] is String) return first['msg'] as String;
      return details.join(', ');
    }
  }
  return fallback;
}
