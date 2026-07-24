import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications();
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<void> registerDeviceToken(String token, String deviceType);
  Future<void> unregisterDeviceToken(String token);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient apiClient;

  NotificationRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<NotificationModel>> getNotifications() async {
    final response = await apiClient.dio.get('${AppConstants.chatApiBaseUrl}/notifications');
    final data = response.data['data'] as List? ?? [];
    return data.map((e) => NotificationModel.fromJson(e)).toList();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await apiClient.dio.patch('${AppConstants.chatApiBaseUrl}/notifications/$notificationId/read');
  }

  @override
  Future<void> markAllAsRead() async {
    await apiClient.dio.post('${AppConstants.chatApiBaseUrl}/notifications/read-all');
  }

  @override
  Future<void> registerDeviceToken(String token, String deviceType) async {
    await apiClient.dio.post(
      '${AppConstants.chatApiBaseUrl}/devices/tokens',
      data: {'token': token, 'device_type': deviceType},
    );
  }

  @override
  Future<void> unregisterDeviceToken(String token) async {
    await apiClient.dio.delete(
      '${AppConstants.chatApiBaseUrl}/devices/tokens',
      data: {'token': token},
    );
  }
}
