import 'package:dartz/dartz.dart';
import '../entities/two_factor_setup_entity.dart';
import '../repositories/auth_repository.dart';

class SetupTwoFactorUseCase {
  final AuthRepository repository;

  SetupTwoFactorUseCase(this.repository);

  Future<Either<String, TwoFactorSetupEntity>> call() {
    return repository.setupTwoFactor();
  }
}
