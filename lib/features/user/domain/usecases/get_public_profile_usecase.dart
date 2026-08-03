import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class GetPublicProfileUseCase {
  final UserRepository repository;

  GetPublicProfileUseCase(this.repository);

  Future<Either<String, UserEntity>> call(String accountId) {
    return repository.getPublicProfile(accountId);
  }
}
