import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../entities/activity_entity.dart';

abstract class UserRepository {
  Future<Either<String, UserEntity>> getProfile();
  Future<Either<String, UserEntity>> updateProfile(UserEntity user);
  Future<Either<String, ActivityPageEntity>> getMyActivities({
    int page = 1,
    int limit = 20,
  });
  Future<Either<String, UserEntity>> getPublicProfile(String accountId);
}
