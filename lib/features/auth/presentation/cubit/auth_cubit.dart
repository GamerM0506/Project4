import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/verify_usecase.dart';
import '../../domain/usecases/resend_verification_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final VerifyUseCase verifyUseCase;
  final ResendVerificationUseCase resendVerificationUseCase;
  final SharedPreferences sharedPreferences;

  AuthCubit({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.verifyUseCase,
    required this.resendVerificationUseCase,
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
        final token = authEntity.accessToken;

        if (token != null) {
          await sharedPreferences.setString(AppConstants.keyAccessToken, token);
          emit(AuthSuccess());
        } else {
          // Trường hợp trả về 200 OK nhưng body rỗng hoặc yêu cầu 2FA
          emit(AuthSuccess()); // Tạm thời coi như thành công nếu không lấy được token rõ ràng
        }
      },
    );
  }

  Future<void> registerUser(String fullName, String emailOrPhone, String password) async {
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

    final result = await registerUseCase(fullName, email, phone, password);

    result.fold(
      (failureMessage) => emit(AuthFailure(message: failureMessage)),
      (data) {
        emit(RegisterSuccess(emailOrPhone: emailOrPhone));
      },
    );
  }

  Future<void> verify(String emailOrPhone, String code) async {
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

  Future<void> resendVerification(String emailOrPhone) async {
    // Không chuyển qua Loading state để khỏi làm mất UI nhập mã
    final result = await resendVerificationUseCase(emailOrPhone);

    result.fold(
      (failureMessage) => emit(VerifyFailure(message: failureMessage)),
      (_) {
        // Gửi thành công, có thể không cần emit state mới nếu chỉ thông báo qua listener ở UI
        // Hoặc emit VerifySuccess (nhưng UI đang ở Verify rồi)
      },
    );
  }
}
