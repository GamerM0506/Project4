import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/activity_model.dart';

abstract class UserRemoteDataSource {
  Future<UserModel> getProfile();
  Future<UserModel> updateProfile(UserModel user);
  Future<ActivityPageModel> getMyActivities({int page = 1, int limit = 20});
  Future<UserModel> getPublicProfile(String accountId);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final ApiClient apiClient;

  UserRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UserModel> getProfile() async {
    final response = await apiClient.dio.get(
      '${AppConstants.authApiBaseUrl}/profile/me',
    );
    return UserModel.fromJson(response.data);
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    final response = await apiClient.dio.put(
      '${AppConstants.authApiBaseUrl}/profile/me',
      data: user.toJson(),
    );
    return UserModel.fromJson(response.data);
  }

  @override
  Future<ActivityPageModel> getMyActivities({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await apiClient.dio.get(
      '${AppConstants.authApiBaseUrl}/profile/me/activities',
      queryParameters: {'page': page, 'limit': limit},
    );
    final envelope = Map<String, dynamic>.from(response.data as Map);
    return ActivityPageModel.fromJson(
      Map<String, dynamic>.from(envelope['data'] as Map),
    );
  }

  @override
  Future<UserModel> getPublicProfile(String accountId) async {
    final response = await apiClient.dio.get(
      '${AppConstants.authApiBaseUrl}/profile/$accountId',
    );
    return UserModel.fromJson(response.data);
  }
}
