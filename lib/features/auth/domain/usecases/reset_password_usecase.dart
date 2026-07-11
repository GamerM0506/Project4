import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<Either<String, void>> call(String email, String code, String resetToken, String newPassword) async {
    return await repository.resetPassword(email, code, resetToken, newPassword);
  }
}
