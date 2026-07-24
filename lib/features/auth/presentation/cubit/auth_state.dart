abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthTwoFactorRequired extends AuthState {}

class RegisterSuccess extends AuthState {
  final String emailOrPhone;
  RegisterSuccess({required this.emailOrPhone});
}

class VerifyLoading extends AuthState {}

class VerifySuccess extends AuthState {}

class VerifyFailure extends AuthState {
  final String message;
  VerifyFailure({required this.message});
}

class AuthFailure extends AuthState {
  final String message;

  AuthFailure({required this.message});
}

// Forgot Password States
class ForgotPasswordLoading extends AuthState {}

class ForgotPasswordSuccess extends AuthState {
  final String email;
  ForgotPasswordSuccess({required this.email});
}

class VerifyResetCodeLoading extends AuthState {}

class VerifyResetCodeSuccess extends AuthState {
  final String resetToken;
  VerifyResetCodeSuccess({required this.resetToken});
}

class ResetPasswordLoading extends AuthState {}

class ResetPasswordSuccess extends AuthState {}
