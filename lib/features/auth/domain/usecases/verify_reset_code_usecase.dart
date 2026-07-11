import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';

class VerifyResetCodeUseCase {
  final AuthRepository repository;

  VerifyResetCodeUseCase(this.repository);

  Future<Either<String, String>> call(String email, String code) async {
    return await repository.verifyResetCode(email, code);
  }
}
