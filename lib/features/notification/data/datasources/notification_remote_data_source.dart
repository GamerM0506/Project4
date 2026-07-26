import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications({
    int limit = 30,
    int offset = 0,
  });
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<void> registerDeviceToken(String token, String deviceType);
  Future<void> unregisterDeviceToken(String token);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient apiClient;

  NotificationRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<NotificationModel>> getNotifications({
    int limit = 30,
    int offset = 0,
  }) async {
    final response = await apiClient.dio.get(
      '${AppConstants.chatApiBaseUrl}/notifications',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final body = response.data;
    final data = body is List
        ? body
        : body is Map && body['data'] is List
        ? body['data'] as List
        : const [];
    return data
        .whereType<Map>()
        .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await apiClient.dio.patch(
      '${AppConstants.chatApiBaseUrl}/notifications/$notificationId/read',
    );
  }

  @override
  Future<void> markAllAsRead() async {
    await apiClient.dio.post(
      '${AppConstants.chatApiBaseUrl}/notifications/read-all',
    );
  }

  @override
  Future<void> registerDeviceToken(String token, String deviceType) async {
    await apiClient.dio.post(
      '${AppConstants.chatApiBaseUrl}/devices/tokens',
      data: {'fcmToken': token, 'platform': deviceType},
    );
  }

  @override
  Future<void> unregisterDeviceToken(String token) async {
    await apiClient.dio.delete(
      '${AppConstants.chatApiBaseUrl}/devices/tokens',
      data: {'fcmToken': token},
    );
  }
}
