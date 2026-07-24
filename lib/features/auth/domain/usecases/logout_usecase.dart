import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<Either<String, void>> call({String? refreshToken}) {
    return repository.logout(refreshToken: refreshToken);
  }
}
