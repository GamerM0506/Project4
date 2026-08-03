import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/user_cubit.dart';
import '../cubit/user_state.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats.dart';
import '../widgets/profile_menu.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<UserCubit>().state;
      if (state is! UserLoaded) {
        context.read<UserCubit>().fetchProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.read<UserCubit>().clear();
          context.go(AppRoutes.login);
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Giữ chỗ cân đối với nút cài đặt bên phải để tiêu đề
                    // nằm chính giữa.
                    const SizedBox(width: 48),
                    Text(
                      'Cá nhân',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push(AppRoutes.settings),
                      icon: const Icon(Icons.settings_outlined),
                      color: colorScheme.primary,
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<UserCubit, UserState>(
                  builder: (context, state) {
                    return RefreshIndicator(
                      color: colorScheme.primary,
                      onRefresh: () => context.read<UserCubit>().fetchProfile(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                        child: Column(
                          children: [
                            if (state is UserError &&
                                state.userOrNull == null) ...[
                              _ErrorBanner(
                                message: state.message,
                                onRetry: () =>
                                    context.read<UserCubit>().fetchProfile(),
                              ),
                              const SizedBox(height: 24),
                            ],
                            const ProfileHeader(),
                            const SizedBox(height: 40),
                            const ProfileStats(),
                            const SizedBox(height: 40),
                            const ProfileMenu(),
                            const SizedBox(height: 24),
                            TextButton.icon(
                              onPressed: () => _showLogoutDialog(context),
                              icon: Icon(
                                Icons.logout,
                                color: colorScheme.error,
                                size: 20,
                              ),
                              label: Text(
                                'Đăng xuất',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.error,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ]
                              .animate(interval: 50.ms)
                              .fade(duration: 400.ms)
                              .slideY(
                                begin: 0.1,
                                curve: Curves.easeOutCubic,
                              ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<UserCubit>().clear();
              context.read<AuthCubit>().logout();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onErrorContainer),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Thử lại',
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
