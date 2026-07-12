import '../../../../core/constants/app_constants.dart';
import '../models/auth_model.dart';
import '../models/two_factor_setup_model.dart';
import '../../../../core/network/api_client.dart';

abstract class AuthRemoteDataSource {
  Future<AuthModel> login(String? email, String? phone, String password);
  Future<AuthModel> register(String fullName, String? email, String? phone, String password);
  Future<void> verify(String emailOrPhone, String code);
  Future<void> resendVerification(String emailOrPhone);
  Future<void> forgotPassword(String email);
  Future<String> verifyResetCode(String email, String code);
  Future<void> resetPassword(String email, String code, String resetToken, String newPassword);
  Future<void> changePassword(String currentPassword, String newPassword);
  Future<TwoFactorSetupModel> setupTwoFactor();
  Future<void> enableTwoFactor(String code);
  Future<void> disableTwoFactor(String code);
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
      '${AppConstants.authApiBaseUrl}/auth/verify-email',
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

  @override
  Future<void> forgotPassword(String email) async {
    await apiClient.dio.post(
      '${AppConstants.authApiBaseUrl}/auth/forgot-password',
      data: {'email': email},
    );
  }

  @override
  Future<String> verifyResetCode(String email, String code) async {
    final response = await apiClient.dio.post(
      '${AppConstants.authApiBaseUrl}/auth/verify-reset-code',
      data: {'email': email, 'code': code},
    );
    return response.data['data']['reset_token'];
  }

  @override
  Future<void> resetPassword(String email, String code, String resetToken, String newPassword) async {
    await apiClient.dio.post(
      '${AppConstants.authApiBaseUrl}/auth/reset-password',
      data: {
        'email': email,
        'code': code,
        'reset_token': resetToken,
        'new_password': newPassword,
      },
    );
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await apiClient.dio.post(
      '${AppConstants.authApiBaseUrl}/auth/change-password',
      data: {
        'old_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }

  @override
  Future<TwoFactorSetupModel> setupTwoFactor() async {
    final response = await apiClient.dio.post(
      '${AppConstants.authApiBaseUrl}/auth/2fa/setup',
    );
    return TwoFactorSetupModel.fromJson(
      response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{},
    );
  }

  @override
  Future<void> enableTwoFactor(String code) async {
    await apiClient.dio.post(
      '${AppConstants.authApiBaseUrl}/auth/2fa/enable',
      data: {'code': code},
    );
  }

  @override
  Future<void> disableTwoFactor(String code) async {
    await apiClient.dio.post(
      '${AppConstants.authApiBaseUrl}/auth/2fa/disable',
      data: {'code': code},
    );
  }
}
