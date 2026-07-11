import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class UpdateProfileUseCase {
  final UserRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<Either<String, UserEntity>> call(UserEntity user) async {
    return await repository.updateProfile(user);
  }
}
