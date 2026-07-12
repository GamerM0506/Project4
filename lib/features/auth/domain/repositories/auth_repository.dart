import 'package:dartz/dartz.dart';
import '../entities/auth_entity.dart';
import '../entities/two_factor_setup_entity.dart';

abstract class AuthRepository {
  Future<Either<String, AuthEntity>> login(String? email, String? phone, String password);
  Future<Either<String, AuthEntity>> register(String fullName, String? email, String? phone, String password);
  Future<Either<String, void>> verify(String emailOrPhone, String code);
  Future<Either<String, void>> resendVerification(String emailOrPhone);
  Future<Either<String, void>> forgotPassword(String email);
  Future<Either<String, String>> verifyResetCode(String email, String code);
  Future<Either<String, void>> resetPassword(String email, String code, String resetToken, String newPassword);
  Future<Either<String, void>> changePassword(String currentPassword, String newPassword);
  Future<Either<String, TwoFactorSetupEntity>> setupTwoFactor();
  Future<Either<String, void>> enableTwoFactor(String code);
  Future<Either<String, void>> disableTwoFactor(String code);
}
