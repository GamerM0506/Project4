import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/session_token.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/login_two_factor_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/verify_usecase.dart';
import '../../domain/usecases/resend_verification_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/verify_reset_code_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../../notification/application/push_notification_service.dart';
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
  final PushNotificationService pushNotificationService;
  String? _challengeToken;
  bool? _pendingRememberMe;
  String? _pendingIdentifier;

  bool get hasActiveLoginChallenge =>
      _challengeToken != null && _challengeToken!.isNotEmpty;

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
    required this.pushNotificationService,
  }) : super(AuthInitial());

  Future<void> login(
    String emailOrPhone,
    String password, {
    required bool rememberMe,
  }) async {
    _clearPendingLogin();
    if (emailOrPhone.isEmpty || password.isEmpty) {
      emit(AuthFailure(message: 'Vui lòng nhập đầy đủ thông tin.'));
      return;
    }
    if (password.length > 128) {
      emit(AuthFailure(message: 'Mật khẩu không được quá 128 ký tự.'));
      return;
    }

    await sharedPreferences.setBool(AppConstants.keyRememberMe, rememberMe);
    if (!rememberMe) {
      await sharedPreferences.remove(AppConstants.keyRememberedIdentifier);
    }
    _pendingRememberMe = rememberMe;
    _pendingIdentifier = emailOrPhone;

    emit(AuthLoading());

    String? email;
    String? phone;

    if (emailOrPhone.contains('@')) {
      email = emailOrPhone;
    } else {
      phone = emailOrPhone;
    }

    final result = await loginUseCase(email, phone, password);

    await result.fold<Future<void>>(
      (failureMessage) async {
        _clearPendingLogin();
        emit(AuthFailure(message: failureMessage));
      },
      (authEntity) async {
        if (authEntity.twoFactorRequired) {
          final challengeToken = authEntity.challengeToken;
          if (challengeToken == null || challengeToken.isEmpty) {
            _clearPendingLogin();
            emit(AuthFailure(message: 'Máy chủ không trả về mã xác thực 2FA.'));
            return;
          }
          _challengeToken = challengeToken;
          emit(AuthTwoFactorRequired());
          return;
        }
        if (await _persistSession(authEntity)) {
          await _applyRememberPreference();
          emit(AuthSuccess());
        } else {
          _clearPendingLogin();
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
        if (!await _persistSession(authEntity)) {
          _clearPendingLogin();
          emit(AuthFailure(message: 'Phản hồi đăng nhập 2FA không hợp lệ.'));
          return;
        }
        await sharedPreferences.setBool(AppConstants.keyTwoFactorEnabled, true);
        await _applyRememberPreference();
        emit(AuthSuccess());
      },
    );
  }

  Future<bool> _persistSession(AuthEntity authEntity) async {
    final access = authEntity.accessToken;
    final refresh = authEntity.refreshToken;
    // JWT sub khớp sender_id backend; ưu tiên hơn user_id trong body (thường không có).
    final resolvedUserId =
        jwtSubject(access) ?? normalizeUserId(authEntity.userId);
    if (access == null ||
        access.isEmpty ||
        refresh == null ||
        refresh.isEmpty ||
        resolvedUserId == null ||
        resolvedUserId.isEmpty) {
      return false;
    }

    await _clearSession(clearPendingLogin: false);
    await sharedPreferences.setString(AppConstants.keyAccessToken, access);
    await sharedPreferences.setString(AppConstants.keyRefreshToken, refresh);
    await sharedPreferences.setString(AppConstants.keyUserId, resolvedUserId);
    return true;
  }

  Future<void> handleSessionExpired() async {
    await _clearSession();
    emit(AuthUnauthenticated());
  }

  Future<void> _clearSession({bool clearPendingLogin = true}) async {
    if (clearPendingLogin) _clearPendingLogin();
    await sharedPreferences.remove(AppConstants.keyAccessToken);
    await sharedPreferences.remove(AppConstants.keyRefreshToken);
    await sharedPreferences.remove(AppConstants.keyUserId);
    await sharedPreferences.remove(AppConstants.keyTwoFactorEnabled);
    await sharedPreferences.setInt(
      AppConstants.keySessionGeneration,
      (sharedPreferences.getInt(AppConstants.keySessionGeneration) ?? 0) + 1,
    );
  }

  Future<void> _applyRememberPreference() async {
    final rememberMe = _pendingRememberMe ?? true;
    final identifier = _pendingIdentifier;
    await sharedPreferences.setBool(AppConstants.keyRememberMe, rememberMe);
    if (rememberMe && identifier != null && identifier.isNotEmpty) {
      await sharedPreferences.setString(
        AppConstants.keyRememberedIdentifier,
        identifier,
      );
    } else {
      await sharedPreferences.remove(AppConstants.keyRememberedIdentifier);
    }
    _clearPendingLogin();
  }

  void cancelLoginChallenge() {
    _clearPendingLogin();
  }

  void _clearPendingLogin() {
    _challengeToken = null;
    _pendingRememberMe = null;
    _pendingIdentifier = null;
  }

  Future<void> registerUser(
    String username,
    String fullName,
    String email,
    String password,
  ) async {
    if (username.isEmpty ||
        fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      emit(AuthFailure(message: 'Vui lòng nhập đầy đủ thông tin.'));
      return;
    }

    if (password.length < 8) {
      emit(AuthFailure(message: 'Mật khẩu phải có ít nhất 8 ký tự.'));
      return;
    }
    if (password.length > 128) {
      emit(AuthFailure(message: 'Mật khẩu không được quá 128 ký tự.'));
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(username)) {
      emit(
        AuthFailure(
          message: 'Tên đăng nhập gồm 3-30 ký tự chữ, số hoặc dấu gạch dưới.',
        ),
      );
      return;
    }
    if (!email.contains('@')) {
      emit(AuthFailure(message: 'Vui lòng nhập email hợp lệ để xác thực.'));
      return;
    }

    emit(AuthLoading());

    final result = await registerUseCase(
      username,
      fullName,
      email,
      null,
      password,
    );

    result.fold(
      (failureMessage) => emit(AuthFailure(message: failureMessage)),
      (data) {
        emit(RegisterSuccess(emailOrPhone: email));
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
    if (newPassword.length > 128) {
      emit(AuthFailure(message: 'Mật khẩu không được quá 128 ký tự.'));
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
    emit(ResendVerificationLoading());
    final result = await resendVerificationUseCase(emailOrPhone);

    result.fold(
      (failureMessage) => emit(VerifyFailure(message: failureMessage)),
      (_) => emit(ResendVerificationSuccess()),
    );
  }

  Future<void> logout() async {
    final refreshToken = sharedPreferences.getString(
      AppConstants.keyRefreshToken,
    );
    await pushNotificationService.unregisterBeforeLogout();
    await handleSessionExpired();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await logoutUseCase(refreshToken);
    }
  }
}
