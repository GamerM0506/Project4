import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/entities/notification_entity.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository repository;

  NotificationCubit({required this.repository}) : super(const NotificationState());

  Future<void> fetchNotifications() async {
    emit(state.copyWith(isLoading: true, error: null));
    final result = await repository.getNotifications();
    
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, error: failure)),
      (notifications) {
        final unreadCount = notifications.where((n) => !n.isRead).length;
        emit(state.copyWith(
          isLoading: false,
          notifications: notifications,
          unreadCount: unreadCount,
        ));
      },
    );
  }

  Future<void> markAsRead(String id) async {
    await repository.markAsRead(id);
    
    final updatedList = state.notifications.map((n) {
      if (n.id == id && !n.isRead) {
        return NotificationEntity(
          id: n.id,
          title: n.title,
          body: n.body,
          type: n.type,
          isRead: true, // Marked as read
          createdAt: n.createdAt,
        );
      }
      return n;
    }).toList();
    
    final unreadCount = updatedList.where((n) => !n.isRead).length;
    emit(state.copyWith(notifications: updatedList, unreadCount: unreadCount));
  }

  Future<void> markAllAsRead() async {
    await repository.markAllAsRead();
    
    final updatedList = state.notifications.map((n) {
      return NotificationEntity(
        id: n.id,
        title: n.title,
        body: n.body,
        type: n.type,
        isRead: true,
        createdAt: n.createdAt,
      );
    }).toList();
    
    emit(state.copyWith(notifications: updatedList, unreadCount: 0));
  }

  Future<void> registerDeviceToken(String token, String deviceType) async {
    await repository.registerDeviceToken(token, deviceType);
  }

  Future<void> unregisterDeviceToken(String token) async {
    await repository.unregisterDeviceToken(token);
  }
}
