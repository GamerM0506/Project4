import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/user_model.dart';

abstract class UserRemoteDataSource {
  Future<UserModel> getProfile();
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final ApiClient apiClient;

  UserRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UserModel> getProfile() async {
    final response = await apiClient.dio.get('${AppConstants.authApiBaseUrl}/auth/me');
    return UserModel.fromJson(response.data);
  }
}
