import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';
import '../entities/auth_entity.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<String, AuthEntity>> call(String fullName, String? email, String? phone, String password) {
    return repository.register(fullName, email, phone, password);
  }
}
