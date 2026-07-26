import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/router/app_routes.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/notification_entity.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationCubit>()..fetchNotifications(),
      child: const _NotificationView(),
    );
  }
}

class _NotificationView extends StatefulWidget {
  const _NotificationView();

  @override
  State<_NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<_NotificationView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreNearBottom);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMoreNearBottom() {
    if (_scrollController.position.extentAfter < 240) {
      context.read<NotificationCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationCubit, NotificationState>(
      listenWhen: (previous, current) =>
          previous.error != current.error && current.error != null,
      listener: (context, state) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.error!)));
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Thông báo'),
            actions: [
              TextButton(
                onPressed: state.unreadCount == 0 || state.isActionLoading
                    ? null
                    : () => context.read<NotificationCubit>().markAllAsRead(),
                child: const Text('Đọc tất cả'),
              ),
            ],
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, NotificationState state) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notifications_off_outlined, size: 52),
              const SizedBox(height: 12),
              Text(state.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    context.read<NotificationCubit>().fetchNotifications(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<NotificationCubit>().fetchNotifications(),
      child: state.notifications.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 180),
                Icon(Icons.notifications_none, size: 64),
                SizedBox(height: 12),
                Center(child: Text('Bạn chưa có thông báo nào.')),
              ],
            )
          : ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount:
                  state.notifications.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == state.notifications.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final item = state.notifications[index];
                return _NotificationTile(
                  notification: item,
                  onTap: () => _openNotification(context, item),
                );
              },
            ),
    );
  }

  Future<void> _openNotification(
    BuildContext context,
    NotificationEntity notification,
  ) async {
    await context.read<NotificationCubit>().markAsRead(notification.id);
    if (!context.mounted) return;

    final refId = notification.refId;
    switch (notification.refType) {
      case 'conversation' when refId != null && refId.isNotEmpty:
        await context.push(
          AppRoutes.chatRoom,
          extra: {'conversationId': refId, 'name': notification.title},
        );
      case 'group' when refId != null && refId.isNotEmpty:
        await context.push('${AppRoutes.groupDetail}/$refId');
      case 'listing' when refId != null && refId.isNotEmpty:
        await context.push('${AppRoutes.marketplace}/detail/$refId');
      case 'request':
      case 'donation':
        await context.push(AppRoutes.myRequests);
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thông báo này không có nội dung để mở.'),
          ),
        );
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final NotificationEntity notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: notification.isRead
          ? colors.surface
          : colors.primaryContainer.withValues(alpha: 0.35),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colors.secondaryContainer,
          child: Icon(_icon, color: colors.onSecondaryContainer),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.body),
            const SizedBox(height: 4),
            Text(
              timeago.format(notification.createdAt.toLocal(), locale: 'vi'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: onTap,
      ),
    );
  }

  IconData get _icon => switch (notification.refType) {
    'conversation' => Icons.chat_bubble_outline,
    'group' => Icons.groups_outlined,
    'listing' => Icons.inventory_2_outlined,
    'donation' => Icons.volunteer_activism_outlined,
    'request' => Icons.assignment_outlined,
    _ => Icons.notifications_outlined,
  };
}
