import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  final AuthRepository repository;

  ForgotPasswordUseCase(this.repository);

  Future<Either<String, void>> call(String email) async {
    return await repository.forgotPassword(email);
  }
}
