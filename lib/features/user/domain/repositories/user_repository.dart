import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';

abstract class UserRepository {
  Future<Either<String, UserEntity>> getProfile();
  Future<Either<String, UserEntity>> updateProfile(UserEntity user);
}
