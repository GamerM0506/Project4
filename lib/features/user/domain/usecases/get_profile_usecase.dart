import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class GetProfileUseCase {
  final UserRepository repository;

  GetProfileUseCase(this.repository);

  Future<Either<String, UserEntity>> call() {
    return repository.getProfile();
  }
}
