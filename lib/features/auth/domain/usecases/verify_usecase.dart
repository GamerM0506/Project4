import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';

class VerifyUseCase {
  final AuthRepository repository;

  VerifyUseCase(this.repository);

  Future<Either<String, void>> call(String emailOrPhone, String code) {
    return repository.verify(emailOrPhone, code);
  }
}
