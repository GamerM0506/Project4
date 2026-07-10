abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {}

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
