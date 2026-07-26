import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<String, List<NotificationEntity>>> getNotifications({
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final notifications = await remoteDataSource.getNotifications(
        limit: limit,
        offset: offset,
      );
      return Right(notifications);
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'Lỗi khi tải thông báo'));
    } catch (e) {
      return Left('Đã xảy ra lỗi: $e');
    }
  }

  @override
  Future<Either<String, void>> markAsRead(String notificationId) async {
    try {
      await remoteDataSource.markAsRead(notificationId);
      return const Right(null);
    } catch (e) {
      return Left('Đã xảy ra lỗi: $e');
    }
  }

  @override
  Future<Either<String, void>> markAllAsRead() async {
    try {
      await remoteDataSource.markAllAsRead();
      return const Right(null);
    } catch (e) {
      return Left('Đã xảy ra lỗi: $e');
    }
  }

  @override
  Future<Either<String, void>> registerDeviceToken(
    String token,
    String deviceType,
  ) async {
    try {
      await remoteDataSource.registerDeviceToken(token, deviceType);
      return const Right(null);
    } catch (e) {
      return Left('Đã xảy ra lỗi: $e');
    }
  }

  @override
  Future<Either<String, void>> unregisterDeviceToken(String token) async {
    try {
      await remoteDataSource.unregisterDeviceToken(token);
      return const Right(null);
    } catch (e) {
      return Left('Đã xảy ra lỗi: $e');
    }
  }

  String _mapDioError(DioException e, String fallback) {
    if (e.response?.statusCode == 401) {
      return 'Phiên đăng nhập hết hạn.';
    }
    return fallback;
  }
}
