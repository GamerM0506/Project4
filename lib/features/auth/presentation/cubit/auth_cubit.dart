import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/login_2fa_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/verify_usecase.dart';
import '../../domain/usecases/resend_verification_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/verify_reset_code_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final Login2FAUseCase login2FAUseCase;
  final LogoutUseCase logoutUseCase;
  final RegisterUseCase registerUseCase;
  final VerifyUseCase verifyUseCase;
  final ResendVerificationUseCase resendVerificationUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final VerifyResetCodeUseCase verifyResetCodeUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final SharedPreferences sharedPreferences;

  AuthCubit({
    required this.loginUseCase,
    required this.login2FAUseCase,
    required this.logoutUseCase,
    required this.registerUseCase,
    required this.verifyUseCase,
    required this.resendVerificationUseCase,
    required this.forgotPasswordUseCase,
    required this.verifyResetCodeUseCase,
    required this.resetPasswordUseCase,
    required this.sharedPreferences,
  }) : super(AuthInitial());

  bool get hasAccessToken {
    final token = sharedPreferences.getString(AppConstants.keyAccessToken);
    return token != null && token.isNotEmpty;
  }

  bool get hasRefreshToken {
    final token = sharedPreferences.getString(AppConstants.keyRefreshToken);
    return token != null && token.isNotEmpty;
  }

  /// Restore session on app start: try access token, else refresh.
  Future<bool> restoreSession() async {
    if (hasAccessToken) {
      emit(AuthAuthenticated());
      return true;
    }

    if (!hasRefreshToken) {
      emit(AuthUnauthenticated());
      return false;
    }

    final ok = await _tryRefresh();
    if (ok) {
      emit(AuthAuthenticated());
      return true;
    }

    await _clearTokens();
    emit(AuthUnauthenticated());
    return false;
  }

  Future<bool> _tryRefresh() async {
    final refreshToken =
        sharedPreferences.getString(AppConstants.keyRefreshToken);
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        ),
      );
      final res = await dio.post<Map<String, dynamic>>(
        '${AppConstants.authApiBaseUrl}/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final body = res.data;
      final data = (body?['data'] is Map)
          ? Map<String, dynamic>.from(body!['data'] as Map)
          : body;
      final access = data?['access_token']?.toString();
      final refresh = data?['refresh_token']?.toString();
      if (access != null && access.isNotEmpty) {
        await sharedPreferences.setString(AppConstants.keyAccessToken, access);
        if (refresh != null && refresh.isNotEmpty) {
          await sharedPreferences.setString(
              AppConstants.keyRefreshToken, refresh);
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> login(String emailOrPhone, String password) async {
    if (emailOrPhone.isEmpty || password.isEmpty) {
      emit(AuthFailure(message: 'Vui lòng nhập đầy đủ thông tin.'));
      return;
    }

    emit(AuthLoading());

    String? email;
    String? phone;

    if (emailOrPhone.contains('@')) {
      email = emailOrPhone;
    } else {
      phone = emailOrPhone;
    }

    final result = await loginUseCase(email, phone, password);

    await result.fold(
      (failureMessage) async {
        emit(AuthFailure(message: failureMessage));
      },
      (authEntity) async {
        if (authEntity.twoFactorRequired &&
            authEntity.challengeToken != null &&
            authEntity.challengeToken!.isNotEmpty) {
          emit(AuthTwoFactorRequired(
              challengeToken: authEntity.challengeToken!));
          return;
        }

        await _persistTokens(authEntity.accessToken, authEntity.refreshToken);
        if (authEntity.hasTokens) {
          if (authEntity.userId != null && authEntity.userId!.isNotEmpty) {
            await sharedPreferences.setString(
                AppConstants.keyUserId, authEntity.userId!);
          }
          emit(AuthSuccess());
        } else {
          emit(AuthFailure(
            message:
                'Đăng nhập chưa nhận được token. Kiểm tra 2FA hoặc thử lại.',
          ));
        }
      },
    );
  }

  Future<void> submitTwoFactorCode(String challengeToken, String code) async {
    if (code.isEmpty || code.length < 6) {
      emit(AuthFailure(message: 'Vui lòng nhập mã 2FA hợp lệ (6 số).'));
      return;
    }

    emit(AuthLoading());
    final result = await login2FAUseCase(challengeToken, code);

    await result.fold(
      (failureMessage) async {
        emit(AuthFailure(message: failureMessage));
      },
      (authEntity) async {
        await _persistTokens(authEntity.accessToken, authEntity.refreshToken);
        if (authEntity.hasTokens) {
          if (authEntity.userId != null && authEntity.userId!.isNotEmpty) {
            await sharedPreferences.setString(
                AppConstants.keyUserId, authEntity.userId!);
          }
          emit(AuthSuccess());
        } else {
          emit(AuthFailure(message: 'Xác thực 2FA thất bại. Thử lại.'));
        }
      },
    );
  }

  Future<void> _persistTokens(String? access, String? refresh) async {
    if (access != null && access.isNotEmpty) {
      await sharedPreferences.setString(AppConstants.keyAccessToken, access);
    }
    if (refresh != null && refresh.isNotEmpty) {
      await sharedPreferences.setString(AppConstants.keyRefreshToken, refresh);
    }
  }

  Future<void> _clearTokens() async {
    await sharedPreferences.remove(AppConstants.keyAccessToken);
    await sharedPreferences.remove(AppConstants.keyRefreshToken);
  }

  Future<void> handleSessionExpired() async {
    await _clearTokens();
    emit(AuthUnauthenticated());
  }

  Future<void> registerUser(
      String fullName, String emailOrPhone, String password) async {
    if (fullName.isEmpty || emailOrPhone.isEmpty || password.isEmpty) {
      emit(AuthFailure(message: 'Vui lòng nhập đầy đủ thông tin.'));
      return;
    }

    if (password.length < 8) {
      emit(AuthFailure(message: 'Mật khẩu phải có ít nhất 8 ký tự.'));
      return;
    }

    emit(AuthLoading());

    String? email;
    String? phone;

    if (emailOrPhone.contains('@')) {
      email = emailOrPhone;
    } else {
      phone = emailOrPhone;
    }

    String username = '';
    if (email != null && email.contains('@')) {
      username = email.split('@')[0].replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    } else if (phone != null) {
      username = 'user_$phone';
    } else {
      username = 'user_${DateTime.now().millisecondsSinceEpoch}';
    }
    if (username.length < 3) username = 'usr$username';
    if (username.length > 30) username = username.substring(0, 30);

    final result =
        await registerUseCase(username, fullName, email, phone, password);

    result.fold(
      (failureMessage) => emit(AuthFailure(message: failureMessage)),
      (data) {
        emit(RegisterSuccess(emailOrPhone: emailOrPhone));
      },
    );
  }

  Future<void> verify(String emailOrPhone, String code) async {
    if (emailOrPhone.isEmpty) {
      emit(VerifyFailure(
          message:
              'Không tìm thấy thông tin email. Vui lòng thử lại từ đầu.'));
      return;
    }
    if (code.isEmpty) {
      emit(VerifyFailure(message: 'Vui lòng nhập mã xác thực.'));
      return;
    }

    emit(VerifyLoading());

    final result = await verifyUseCase(emailOrPhone, code);

    result.fold(
      (failureMessage) => emit(VerifyFailure(message: failureMessage)),
      (_) => emit(VerifySuccess()),
    );
  }

  Future<void> forgotPassword(String email) async {
    if (email.isEmpty) {
      emit(AuthFailure(message: 'Vui lòng nhập email.'));
      return;
    }

    emit(ForgotPasswordLoading());
    final result = await forgotPasswordUseCase(email);

    result.fold(
      (failureMessage) => emit(AuthFailure(message: failureMessage)),
      (_) => emit(ForgotPasswordSuccess(email: email)),
    );
  }

  Future<void> verifyResetCode(String email, String code) async {
    if (code.isEmpty || code.length < 6) {
      emit(AuthFailure(message: 'Vui lòng nhập mã OTP hợp lệ.'));
      return;
    }

    emit(VerifyResetCodeLoading());
    final result = await verifyResetCodeUseCase(email, code);

    result.fold(
      (failureMessage) => emit(AuthFailure(message: failureMessage)),
      (resetToken) => emit(VerifyResetCodeSuccess(resetToken: resetToken)),
    );
  }

  Future<void> resetPassword(
      String email, String code, String resetToken, String newPassword) async {
    if (newPassword.isEmpty || newPassword.length < 8) {
      emit(AuthFailure(message: 'Mật khẩu phải có ít nhất 8 ký tự.'));
      return;
    }

    emit(ResetPasswordLoading());
    final result =
        await resetPasswordUseCase(email, code, resetToken, newPassword);

    result.fold(
      (failureMessage) => emit(AuthFailure(message: failureMessage)),
      (_) => emit(ResetPasswordSuccess()),
    );
  }

  Future<void> resendVerification(String emailOrPhone) async {
    if (emailOrPhone.isEmpty) {
      emit(VerifyFailure(
          message:
              'Không tìm thấy thông tin email. Vui lòng đăng ký lại.'));
      return;
    }
    final result = await resendVerificationUseCase(emailOrPhone);

    result.fold(
      (failureMessage) => emit(VerifyFailure(message: failureMessage)),
      (_) {},
    );
  }

  Future<void> logout() async {
    final refresh =
        sharedPreferences.getString(AppConstants.keyRefreshToken);
    await logoutUseCase(refreshToken: refresh);
    await _clearTokens();
    emit(AuthUnauthenticated());
  }
}
