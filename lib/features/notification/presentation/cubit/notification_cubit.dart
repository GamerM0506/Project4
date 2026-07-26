import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/notification_repository.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  static const pageSize = 30;
  final NotificationRepository repository;

  NotificationCubit({required this.repository})
    : super(const NotificationState());

  Future<void> fetchNotifications() async {
    emit(state.copyWith(isLoading: true, error: null));
    final result = await repository.getNotifications(limit: pageSize);

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, error: failure)),
      (notifications) {
        final unreadCount = notifications.where((n) => !n.isRead).length;
        emit(
          state.copyWith(
            isLoading: false,
            notifications: notifications,
            unreadCount: unreadCount,
            hasMore: notifications.length == pageSize,
          ),
        );
      },
    );
  }

  Future<void> markAsRead(String id) async {
    final notification = state.notifications
        .where((item) => item.id == id)
        .firstOrNull;
    if (notification == null || notification.isRead) return;
    emit(state.copyWith(isActionLoading: true, error: null));
    final result = await repository.markAsRead(id);
    result.fold(
      (failure) => emit(state.copyWith(isActionLoading: false, error: failure)),
      (_) {
        final updatedList = state.notifications.map((n) {
          if (n.id == id && !n.isRead) {
            return n.copyWith(isRead: true, readAt: DateTime.now());
          }
          return n;
        }).toList();
        final unreadCount = updatedList.where((n) => !n.isRead).length;
        emit(
          state.copyWith(
            notifications: updatedList,
            unreadCount: unreadCount,
            isActionLoading: false,
          ),
        );
      },
    );
  }

  Future<void> markAllAsRead() async {
    if (state.unreadCount == 0) return;
    emit(state.copyWith(isActionLoading: true, error: null));
    final result = await repository.markAllAsRead();
    result.fold(
      (failure) => emit(state.copyWith(isActionLoading: false, error: failure)),
      (_) {
        final now = DateTime.now();
        final updatedList = state.notifications
            .map((n) => n.copyWith(isRead: true, readAt: now))
            .toList();
        emit(
          state.copyWith(
            notifications: updatedList,
            unreadCount: 0,
            isActionLoading: false,
          ),
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    emit(state.copyWith(isLoadingMore: true, error: null));
    final result = await repository.getNotifications(
      limit: pageSize,
      offset: state.notifications.length,
    );
    result.fold(
      (failure) => emit(state.copyWith(isLoadingMore: false, error: failure)),
      (items) {
        final byId = {for (final item in state.notifications) item.id: item};
        for (final item in items) {
          byId[item.id] = item;
        }
        final merged = byId.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        emit(
          state.copyWith(
            notifications: merged,
            unreadCount: merged.where((item) => !item.isRead).length,
            isLoadingMore: false,
            hasMore: items.length == pageSize,
          ),
        );
      },
    );
  }

  Future<void> registerDeviceToken(String token, String deviceType) async {
    await repository.registerDeviceToken(token, deviceType);
  }

  Future<void> unregisterDeviceToken(String token) async {
    await repository.unregisterDeviceToken(token);
  }
}
