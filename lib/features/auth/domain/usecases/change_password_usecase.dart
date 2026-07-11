import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';

class ChangePasswordUseCase {
  final AuthRepository repository;

  ChangePasswordUseCase(this.repository);

  Future<Either<String, void>> call(String currentPassword, String newPassword) async {
    return await repository.changePassword(currentPassword, newPassword);
  }
}
