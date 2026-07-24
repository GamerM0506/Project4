import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';
import '../entities/auth_entity.dart';

class Login2FAUseCase {
  final AuthRepository repository;

  Login2FAUseCase(this.repository);

  Future<Either<String, AuthEntity>> call(String challengeToken, String code) {
    return repository.login2FA(challengeToken, code);
  }
}
