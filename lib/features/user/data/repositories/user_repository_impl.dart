import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/user_model.dart';
import '../datasources/user_remote_data_source.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  UserRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<String, UserEntity>> getProfile() async {
    try {
      final userModel = await remoteDataSource.getProfile();
      return Right(userModel);
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'Lỗi khi lấy thông tin người dùng'));
    } catch (e) {
      return Left('Đã xảy ra lỗi: $e');
    }
  }

  @override
  Future<Either<String, UserEntity>> updateProfile(UserEntity user) async {
    try {
      final userModel = UserModel(
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        phone: user.phone,
        avatar: user.avatar,
        dob: user.dob,
        gender: user.gender,
        provinceCode: user.provinceCode,
        districtCode: user.districtCode,
        addressDetail: user.addressDetail,
        bio: user.bio,
        reputationScore: user.reputationScore,
        donationCount: user.donationCount,
        receivedCount: user.receivedCount,
      );
      final updatedModel = await remoteDataSource.updateProfile(userModel);
      return Right(updatedModel);
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'Lỗi khi cập nhật thông tin'));
    } catch (e) {
      return Left('Đã xảy ra lỗi: $e');
    }
  }

  @override
  Future<Either<String, List<dynamic>>> getMyActivities() async {
    try {
      final activities = await remoteDataSource.getMyActivities();
      return Right(activities);
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'Lỗi khi lấy lịch sử hoạt động'));
    } catch (e) {
      return Left('Đã xảy ra lỗi: $e');
    }
  }

  @override
  Future<Either<String, UserEntity>> getPublicProfile(String accountId) async {
    try {
      final userModel = await remoteDataSource.getPublicProfile(accountId);
      return Right(userModel);
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'Lỗi khi lấy thông tin người dùng'));
    } catch (e) {
      return Left('Đã xảy ra lỗi: $e');
    }
  }

  String _mapDioError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      final error = data['error'] ?? data['detail'] ?? data['message'];
      if (error is String && error.isNotEmpty) return error;
      if (error is Map && error['message'] != null) {
        return error['message'].toString();
      }
    }

    if (e.response?.statusCode == 401) {
      return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Không kết nối được máy chủ. Kiểm tra mạng và thử lại.';
    }
    return fallback;
  }
}
