import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import '../datasources/auth_remote_data_source.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/auth_entity.dart';
import '../../domain/entities/two_factor_setup_entity.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<String, AuthEntity>> login(
    String? email,
    String? phone,
    String password,
  ) async {
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
  Future<Either<String, AuthEntity>> register(
    String username,
    String fullName,
    String? email,
    String? phone,
    String password,
  ) async {
    try {
      final response = await remoteDataSource.register(
        username,
        fullName,
        email,
        phone,
        password,
      );
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
      return const Left(
        'Đăng ký không thành công. Vui lòng kiểm tra lại thông tin.',
      );
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
      return const Left(
        'Không thể gửi mã khôi phục. Email có thể không tồn tại.',
      );
    } catch (e) {
      return Left('Đã xảy ra lỗi: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, String>> verifyResetCode(
    String email,
    String code,
  ) async {
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
  Future<Either<String, void>> resetPassword(
    String email,
    String code,
    String resetToken,
    String newPassword,
  ) async {
    try {
      await remoteDataSource.resetPassword(
        email,
        code,
        resetToken,
        newPassword,
      );
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
  Future<Either<String, void>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await remoteDataSource.changePassword(currentPassword, newPassword);
      return const Right(null);
    } catch (e) {
      return Left('Đã xảy ra lỗi: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, TwoFactorSetupEntity>> setupTwoFactor() async {
    try {
      final result = await remoteDataSource.setupTwoFactor();
      if (result.secret.isEmpty) {
        return const Left('Không nhận được secret 2FA từ máy chủ.');
      }
      return Right(result);
    } on DioException catch (e) {
      return Left(
        _mapDioError(e, 'Không thể thiết lập 2FA. Vui lòng thử lại.'),
      );
    } catch (e) {
      return Left('Đã xảy ra lỗi: $e');
    }
  }

  @override
  Future<Either<String, bool>> getTwoFactorStatus() async {
    try {
      return Right(await remoteDataSource.getTwoFactorStatus());
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'Không thể tải trạng thái 2FA.'));
    } catch (e) {
      return Left('Đã xảy ra lỗi: $e');
    }
  }

  @override
  Future<Either<String, void>> enableTwoFactor(String code) async {
    try {
      await remoteDataSource.enableTwoFactor(code);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'Mã 2FA không hợp lệ. Vui lòng thử lại.'));
    } catch (e) {
      return Left('Đã xảy ra lỗi: $e');
    }
  }

  @override
  Future<Either<String, void>> disableTwoFactor(String code) async {
    try {
      await remoteDataSource.disableTwoFactor(code);
      return const Right(null);
    } on DioException catch (e) {
      return Left(
        _mapDioError(e, 'Không thể tắt 2FA. Kiểm tra mã và thử lại.'),
      );
    } catch (e) {
      return Left('Đã xảy ra lỗi: $e');
    }
  }

  @override
  Future<Either<String, AuthEntity>> login2FA(
    String challengeToken,
    String code,
  ) async {
    try {
      final response = await remoteDataSource.login2FA(challengeToken, code);
      return Right(response);
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'Mã xác thực 2FA không chính xác.'));
    } catch (e) {
      return Left('Đã xảy ra lỗi: $e');
    }
  }

  @override
  Future<Either<String, void>> logout(String refreshToken) async {
    try {
      await remoteDataSource.logout(refreshToken);
      return const Right(null);
    } catch (e) {
      return Left('Đã xảy ra lỗi: $e');
    }
  }

  String _mapDioError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      final error = data['error'] ?? data['detail'] ?? data['message'];
      if (error is String && error.isNotEmpty) {
        return _localizeTwoFactorError(error);
      }
      if (error is Map && error['message'] != null) {
        return error['message'].toString();
      }
    }
    if (e.response?.statusCode == 401) {
      return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
    }
    return fallback;
  }

  String _localizeTwoFactorError(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('invalid 2fa')) {
      return 'Mã xác thực không đúng. Hãy kiểm tra app Authenticator.';
    }
    if (lower.contains('run 2fa setup')) {
      return 'Cần thiết lập 2FA trước khi bật.';
    }
    if (lower.contains('not enabled')) {
      return '2FA chưa được bật trên tài khoản này.';
    }
    return error;
  }
}
