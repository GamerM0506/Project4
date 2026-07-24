import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/login_two_factor_usecase.dart';
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
  final LoginTwoFactorUseCase loginTwoFactorUseCase;
  final LogoutUseCase logoutUseCase;
  final RegisterUseCase registerUseCase;
  final VerifyUseCase verifyUseCase;
  final ResendVerificationUseCase resendVerificationUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final VerifyResetCodeUseCase verifyResetCodeUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final SharedPreferences sharedPreferences;
  String? _challengeToken;

  AuthCubit({
    required this.loginUseCase,
    required this.loginTwoFactorUseCase,
    required this.logoutUseCase,
    required this.registerUseCase,
    required this.verifyUseCase,
    required this.resendVerificationUseCase,
    required this.forgotPasswordUseCase,
    required this.verifyResetCodeUseCase,
    required this.resetPasswordUseCase,
    required this.sharedPreferences,
  }) : super(AuthInitial());

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

    result.fold(
      (failureMessage) => emit(AuthFailure(message: failureMessage)),
      (authEntity) async {
        if (authEntity.twoFactorRequired) {
          final challengeToken = authEntity.challengeToken;
          if (challengeToken == null || challengeToken.isEmpty) {
            emit(AuthFailure(message: 'Máy chủ không trả về mã xác thực 2FA.'));
            return;
          }
          _challengeToken = challengeToken;
          emit(AuthTwoFactorRequired());
          return;
        }
        await _persistTokens(authEntity.accessToken, authEntity.refreshToken);
        await _persistUserId(authEntity.userId, authEntity.accessToken);
        if (authEntity.accessToken != null &&
            authEntity.accessToken!.isNotEmpty) {
          emit(AuthSuccess());
        } else {
          emit(
            AuthFailure(
              message:
                  'Đăng nhập chưa nhận được token. Kiểm tra 2FA hoặc thử lại.',
            ),
          );
        }
      },
    );
  }

  Future<void> verifyLoginTwoFactor(String code) async {
    final challengeToken = _challengeToken;
    if (challengeToken == null || challengeToken.isEmpty) {
      emit(AuthFailure(message: 'Phiên xác thực 2FA không còn hợp lệ.'));
      return;
    }
    if (code.length < 6) {
      emit(AuthFailure(message: 'Vui lòng nhập mã xác thực hợp lệ.'));
      return;
    }

    emit(AuthLoading());
    final result = await loginTwoFactorUseCase(challengeToken, code);
    await result.fold(
      (failureMessage) async => emit(AuthFailure(message: failureMessage)),
      (authEntity) async {
        await _persistTokens(authEntity.accessToken, authEntity.refreshToken);
        await _persistUserId(authEntity.userId, authEntity.accessToken);
        await sharedPreferences.setBool(AppConstants.keyTwoFactorEnabled, true);
        _challengeToken = null;
        emit(AuthSuccess());
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

  Future<void> _persistUserId(String? userId, String? accessToken) async {
    final resolvedUserId = userId ?? _readJwtSubject(accessToken);
    if (resolvedUserId != null && resolvedUserId.isNotEmpty) {
      await sharedPreferences.setString(AppConstants.keyUserId, resolvedUserId);
    }
  }

  String? _readJwtSubject(String? token) {
    if (token == null || token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final json = jsonDecode(payload);
      return json is Map ? json['sub']?.toString() : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> handleSessionExpired() async {
    await _clearSession();
    emit(AuthUnauthenticated());
  }

  Future<void> _clearSession() async {
    _challengeToken = null;
    await sharedPreferences.remove(AppConstants.keyAccessToken);
    await sharedPreferences.remove(AppConstants.keyRefreshToken);
    await sharedPreferences.remove(AppConstants.keyUserId);
    await sharedPreferences.remove(AppConstants.keyTwoFactorEnabled);
  }

  Future<void> registerUser(
    String fullName,
    String emailOrPhone,
    String password,
  ) async {
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

    final result = await registerUseCase(
      username,
      fullName,
      email,
      phone,
      password,
    );

    result.fold(
      (failureMessage) => emit(AuthFailure(message: failureMessage)),
      (data) {
        emit(RegisterSuccess(emailOrPhone: emailOrPhone));
      },
    );
  }

  Future<void> verify(String emailOrPhone, String code) async {
    if (emailOrPhone.isEmpty) {
      emit(
        VerifyFailure(
          message: 'Không tìm thấy thông tin email. Vui lòng thử lại từ đầu.',
        ),
      );
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
    String email,
    String code,
    String resetToken,
    String newPassword,
  ) async {
    if (newPassword.isEmpty || newPassword.length < 8) {
      emit(AuthFailure(message: 'Mật khẩu phải có ít nhất 8 ký tự.'));
      return;
    }

    emit(ResetPasswordLoading());
    final result = await resetPasswordUseCase(
      email,
      code,
      resetToken,
      newPassword,
    );

    result.fold(
      (failureMessage) => emit(AuthFailure(message: failureMessage)),
      (_) => emit(ResetPasswordSuccess()),
    );
  }

  Future<void> resendVerification(String emailOrPhone) async {
    if (emailOrPhone.isEmpty) {
      emit(
        VerifyFailure(
          message: 'Không tìm thấy thông tin email. Vui lòng đăng ký lại.',
        ),
      );
      return;
    }
    final result = await resendVerificationUseCase(emailOrPhone);

    result.fold(
      (failureMessage) => emit(VerifyFailure(message: failureMessage)),
      (_) {},
    );
  }

  Future<void> logout() async {
    final refreshToken = sharedPreferences.getString(
      AppConstants.keyRefreshToken,
    );
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await logoutUseCase(refreshToken);
    }
    await handleSessionExpired();
  }
}
