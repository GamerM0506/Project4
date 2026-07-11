import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/user_model.dart';

abstract class UserRemoteDataSource {
  Future<UserModel> getProfile();
  Future<UserModel> updateProfile(UserModel user);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final ApiClient apiClient;

  UserRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UserModel> getProfile() async {
    final response = await apiClient.dio.get('${AppConstants.authApiBaseUrl}/profile/me');
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
}
