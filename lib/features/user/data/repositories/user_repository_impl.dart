import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
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
      return Left(e.response?.data?['detail']?.toString() ?? 'Lỗi khi lấy thông tin người dùng');
    } catch (e) {
      return Left('Đã xảy ra lỗi: $e');
    }
  }
}
