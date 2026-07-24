import 'package:dartz/dartz.dart';

import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

class LoginTwoFactorUseCase {
  final AuthRepository repository;

  LoginTwoFactorUseCase(this.repository);

  Future<Either<String, AuthEntity>> call(String challengeToken, String code) {
    return repository.login2FA(challengeToken, code);
  }
}
