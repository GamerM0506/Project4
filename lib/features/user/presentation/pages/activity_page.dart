import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart';
import '../../domain/entities/activity_entity.dart';
import '../cubit/activity_cubit.dart';
import '../cubit/activity_state.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ActivityCubit>()..load(),
      child: const _ActivityView(),
    );
  }
}

class _ActivityView extends StatelessWidget {
  const _ActivityView();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử hoạt động'), centerTitle: true),
      body: BlocConsumer<ActivityCubit, ActivityState>(
        listener: (context, state) {
          if (state is ActivityError && state.activities.isNotEmpty) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is ActivityInitial || state is ActivityLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ActivityError && state.activities.isEmpty) {
            return _ActivityMessage(
              icon: Icons.error_outline,
              message: state.message,
              buttonLabel: 'Thử lại',
              onPressed: context.read<ActivityCubit>().load,
            );
          }

          final activities = switch (state) {
            ActivityLoaded() => state.activities,
            ActivityError() => state.activities,
            _ => const <ActivityEntity>[],
          };
          final hasMore = switch (state) {
            ActivityLoaded() => state.hasMore,
            ActivityError() => state.hasMore,
            _ => false,
          };
          final loadingMore = state is ActivityLoadingMore;

          if (activities.isEmpty) {
            return RefreshIndicator(
              onRefresh: context.read<ActivityCubit>().refresh,
              child: const CustomScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ActivityMessage(
                      icon: Icons.history,
                      message: 'Chưa có hoạt động nào.',
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: context.read<ActivityCubit>().refresh,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.extentAfter < 240) {
                  context.read<ActivityCubit>().loadMore();
                }
                return false;
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: activities.length + (hasMore ? 1 : 0),
                separatorBuilder: (_, index) => index < activities.length - 1
                    ? const SizedBox(height: 8)
                    : const SizedBox.shrink(),
                itemBuilder: (context, index) {
                  if (index == activities.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: loadingMore
                            ? const CircularProgressIndicator()
                            : OutlinedButton(
                                onPressed: context
                                    .read<ActivityCubit>()
                                    .loadMore,
                                child: const Text('Tải thêm'),
                              ),
                      ),
                    );
                  }
                  final activity = activities[index];
                  final display = _displayFor(activity.action);
                  return Card(
                    elevation: 0,
                    color: colors.surfaceContainerLow,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: colors.primaryContainer,
                        foregroundColor: colors.onPrimaryContainer,
                        child: Icon(display.icon),
                      ),
                      title: Text(display.label),
                      subtitle: Text(_formatTimestamp(activity.createdAt)),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActivityMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  const _ActivityMessage({
    required this.icon,
    required this.message,
    this.buttonLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            if (buttonLabel != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onPressed, child: Text(buttonLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

({String label, IconData icon}) _displayFor(String action) {
  return switch (action) {
    'login' => (label: 'Đăng nhập', icon: Icons.login),
    'change_password' => (label: 'Đổi mật khẩu', icon: Icons.password_outlined),
    'reset_password' => (label: 'Đặt lại mật khẩu', icon: Icons.lock_reset),
    'enable_2fa' || 'two_factor_enabled' => (
      label: 'Bật xác thực 2 bước',
      icon: Icons.security,
    ),
    'disable_2fa' || 'two_factor_disabled' => (
      label: 'Tắt xác thực 2 bước',
      icon: Icons.security_outlined,
    ),
    'update_profile' || 'profile_updated' => (
      label: 'Cập nhật hồ sơ',
      icon: Icons.manage_accounts_outlined,
    ),
    _ => (label: action, icon: Icons.history),
  };
}

String _formatTimestamp(DateTime value) {
  final local = value.toLocal();
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(local.hour)}:${twoDigits(local.minute)} '
      '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year}';
}
