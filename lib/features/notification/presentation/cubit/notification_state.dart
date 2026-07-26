import 'package:equatable/equatable.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationState extends Equatable {
  final bool isLoading;
  final List<NotificationEntity> notifications;
  final String? error;
  final int unreadCount;
  final bool isLoadingMore;
  final bool isActionLoading;
  final bool hasMore;

  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.error,
    this.unreadCount = 0,
    this.isLoadingMore = false,
    this.isActionLoading = false,
    this.hasMore = true,
  });

  NotificationState copyWith({
    bool? isLoading,
    List<NotificationEntity>? notifications,
    String? error,
    int? unreadCount,
    bool? isLoadingMore,
    bool? isActionLoading,
    bool? hasMore,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    notifications,
    error,
    unreadCount,
    isLoadingMore,
    isActionLoading,
    hasMore,
  ];
}
