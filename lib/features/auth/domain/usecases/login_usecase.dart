import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';
import '../entities/auth_entity.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<String, AuthEntity>> call(String? email, String? phone, String password) {
    return repository.login(email, phone, password);
  }
}
