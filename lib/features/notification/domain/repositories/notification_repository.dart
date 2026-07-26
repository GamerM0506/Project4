import 'package:dartz/dartz.dart';
import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<Either<String, List<NotificationEntity>>> getNotifications({
    int limit = 30,
    int offset = 0,
  });
  Future<Either<String, void>> markAsRead(String notificationId);
  Future<Either<String, void>> markAllAsRead();
  Future<Either<String, void>> registerDeviceToken(
    String token,
    String deviceType,
  );
  Future<Either<String, void>> unregisterDeviceToken(String token);
}
