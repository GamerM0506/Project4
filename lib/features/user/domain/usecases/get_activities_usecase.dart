import 'package:dartz/dartz.dart';

import '../entities/activity_entity.dart';
import '../repositories/user_repository.dart';

class GetActivitiesUseCase {
  final UserRepository repository;

  GetActivitiesUseCase(this.repository);

  Future<Either<String, ActivityPageEntity>> call({
    int page = 1,
    int limit = 20,
  }) {
    return repository.getMyActivities(page: page, limit: limit);
  }
}
