import '../../../../core/constants/app_constants.dart';
import '../models/auth_model.dart';
import '../../../../../core/network/api_client.dart';

abstract class AuthRemoteDataSource {
  Future<AuthModel> login(String? email, String? phone, String password);
  Future<AuthModel> register(String fullName, String? email, String? phone, String password);
  Future<void> verify(String emailOrPhone, String code);
  Future<void> resendVerification(String emailOrPhone);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AuthModel> login(String? email, String? phone, String password) async {
    final response = await apiClient.dio.post(
      '${AppConstants.authApiBaseUrl}/auth/login',
      data: {
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        'password': password,
      },
    );
    return AuthModel.fromJson(response.data);
  }

  @override
  Future<AuthModel> register(String fullName, String? email, String? phone, String password) async {
    final response = await apiClient.dio.post(
      '${AppConstants.authApiBaseUrl}/auth/register',
      data: {
        'full_name': fullName,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        'password': password,
      },
    );
    return AuthModel.fromJson(response.data);
  }

  @override
  Future<void> verify(String emailOrPhone, String code) async {
    final body = <String, dynamic>{'code': code};
    if (emailOrPhone.contains('@')) {
      body['email'] = emailOrPhone;
    } else {
      body['phone'] = emailOrPhone;
    }

    await apiClient.dio.post(
      '${AppConstants.authApiBaseUrl}/auth/verify',
      data: body,
    );
  }

  @override
  Future<void> resendVerification(String emailOrPhone) async {
    final body = <String, dynamic>{};
    if (emailOrPhone.contains('@')) {
      body['email'] = emailOrPhone;
    } else {
      body['phone'] = emailOrPhone;
    }

    await apiClient.dio.post(
      '${AppConstants.authApiBaseUrl}/auth/resend-verification',
      data: body,
    );
  }
}
