import 'package:dartz/dartz.dart';

import '../repositories/auth_repository.dart';

class GetTwoFactorStatusUseCase {
  final AuthRepository repository;

  GetTwoFactorStatusUseCase(this.repository);

  Future<Either<String, bool>> call() {
    return repository.getTwoFactorStatus();
  }
}
