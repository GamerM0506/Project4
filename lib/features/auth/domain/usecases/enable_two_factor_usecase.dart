import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';

class EnableTwoFactorUseCase {
  final AuthRepository repository;

  EnableTwoFactorUseCase(this.repository);

  Future<Either<String, void>> call(String code) {
    return repository.enableTwoFactor(code);
  }
}
