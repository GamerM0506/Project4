import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import '../datasources/auth_remote_data_source.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/auth_entity.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<String, AuthEntity>> login(String? email, String? phone, String password) async {
    try {
      final response = await remoteDataSource.login(email, phone, password);
      return Right(response);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic> && errorData['detail'] != null) {
          final detail = errorData['detail'];
          if (detail is String) return Left(detail);
          if (detail is List && detail.isNotEmpty) {
            return Left(detail[0]['msg'] ?? 'Validation Error');
          }
        }
      }
      return const Left('Tài khoản hoặc mật khẩu không chính xác.');
    } catch (e) {
      return Left('Đã xảy ra lỗi: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, AuthEntity>> register(String fullName, String? email, String? phone, String password) async {
    try {
      final response = await remoteDataSource.register(fullName, email, phone, password);
      return Right(response);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic> && errorData['detail'] != null) {
          final detail = errorData['detail'];
          if (detail is String) return Left(detail);
          if (detail is List && detail.isNotEmpty) {
            return Left(detail[0]['msg'] ?? 'Validation Error');
          }
        }
      }
      return const Left('Đăng ký không thành công. Vui lòng kiểm tra lại thông tin.');
    } catch (e) {
      return Left('Đã xảy ra lỗi: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, void>> verify(String emailOrPhone, String code) async {
    try {
      await remoteDataSource.verify(emailOrPhone, code);
      return const Right(null);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic> && errorData['detail'] != null) {
          final detail = errorData['detail'];
          if (detail is String) return Left(detail);
        }
      }
      return const Left('Mã xác thực không hợp lệ hoặc đã hết hạn.');
    } catch (e) {
      return Left('Đã xảy ra lỗi: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, void>> resendVerification(String emailOrPhone) async {
    try {
      await remoteDataSource.resendVerification(emailOrPhone);
      return const Right(null);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic> && errorData['detail'] != null) {
          final detail = errorData['detail'];
          if (detail is String) return Left(detail);
        }
      }
      return const Left('Không thể gửi lại mã xác thực. Vui lòng thử lại sau.');
    } catch (e) {
      return Left('Đã xảy ra lỗi: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, void>> forgotPassword(String email) async {
    try {
      await remoteDataSource.forgotPassword(email);
      return const Right(null);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic> && errorData['detail'] != null) {
          final detail = errorData['detail'];
          if (detail is String) return Left(detail);
        }
      }
      return const Left('Không thể gửi mã khôi phục. Email có thể không tồn tại.');
    } catch (e) {
      return Left('Đã xảy ra lỗi: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, String>> verifyResetCode(String email, String code) async {
    try {
      final resetToken = await remoteDataSource.verifyResetCode(email, code);
      return Right(resetToken);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic> && errorData['detail'] != null) {
          final detail = errorData['detail'];
          if (detail is String) return Left(detail);
        }
      }
      return const Left('Mã xác nhận không hợp lệ hoặc đã hết hạn.');
    } catch (e) {
      return Left('Đã xảy ra lỗi: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, void>> resetPassword(String email, String code, String resetToken, String newPassword) async {
    try {
      await remoteDataSource.resetPassword(email, code, resetToken, newPassword);
      return const Right(null);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic> && errorData['detail'] != null) {
          final detail = errorData['detail'];
          if (detail is String) return Left(detail);
        }
      }
      return const Left('Không thể đổi mật khẩu. Vui lòng thử lại.');
    } catch (e) {
      return Left('Đã xảy ra lỗi: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, void>> changePassword(String currentPassword, String newPassword) async {
    try {
      await remoteDataSource.changePassword(currentPassword, newPassword);
      return const Right(null);
    } catch (e) {
      return Left('Đã xảy ra lỗi: ${e.toString()}');
    }
  }
}
