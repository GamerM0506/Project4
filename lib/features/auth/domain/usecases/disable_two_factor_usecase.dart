import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';

class DisableTwoFactorUseCase {
  final AuthRepository repository;

  DisableTwoFactorUseCase(this.repository);

  Future<Either<String, void>> call(String code) {
    return repository.disableTwoFactor(code);
  }
}
