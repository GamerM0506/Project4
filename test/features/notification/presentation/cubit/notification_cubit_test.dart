import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:project4_chosv/features/notification/domain/entities/notification_entity.dart';
import 'package:project4_chosv/features/notification/domain/repositories/notification_repository.dart';
import 'package:project4_chosv/features/notification/presentation/cubit/notification_cubit.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  test('markAsRead failure keeps local notification unread', () async {
    final repository = MockNotificationRepository();
    final notification = NotificationEntity(
      id: 'notification-1',
      title: 'Title',
      body: 'Body',
      type: 'system',
      isRead: false,
      createdAt: DateTime.utc(2026, 7, 24),
    );
    when(
      () => repository.getNotifications(limit: 30, offset: 0),
    ).thenAnswer((_) async => Right([notification]));
    when(
      () => repository.markAsRead('notification-1'),
    ).thenAnswer((_) async => const Left('Khong the danh dau'));
    final cubit = NotificationCubit(repository: repository);

    await cubit.fetchNotifications();
    await cubit.markAsRead('notification-1');

    expect(cubit.state.notifications.single.isRead, isFalse);
    expect(cubit.state.unreadCount, 1);
    expect(cubit.state.error, 'Khong the danh dau');
    expect(cubit.state.isActionLoading, isFalse);
    await cubit.close();
  });
}
