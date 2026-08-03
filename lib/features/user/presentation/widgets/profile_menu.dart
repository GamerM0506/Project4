import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../cubit/user_cubit.dart';

class ProfileMenu extends StatelessWidget {
  const ProfileMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            context,
            Icons.volunteer_activism_outlined,
            'Đóng góp của tôi',
            onTap: () async {
              await context.push(AppRoutes.myItems);
              if (context.mounted) {
                context.read<UserCubit>().fetchProfile();
              }
            },
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.surfaceContainerHighest,
          ),
          _buildMenuItem(
            context,
            Icons.manage_accounts_outlined,
            'Cài đặt tài khoản',
            onTap: () {
              context.push(AppRoutes.settings);
            },
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.surfaceContainerHighest,
          ),
          _buildMenuItem(
            context,
            Icons.support_agent_outlined,
            'Trợ giúp & Hỗ trợ',
            onTap: () {
              context.push(AppRoutes.support);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  // Use surfaceContainer for background icon
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
