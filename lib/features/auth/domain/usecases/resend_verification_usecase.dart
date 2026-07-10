import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';

class ResendVerificationUseCase {
  final AuthRepository repository;

  ResendVerificationUseCase(this.repository);

  Future<Either<String, void>> call(String emailOrPhone) {
    return repository.resendVerification(emailOrPhone);
  }
}
