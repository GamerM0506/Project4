import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/user_cubit.dart';
import '../cubit/user_state.dart';

class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        final user = state.userOrNull;
        final donated = user?.donationCount ?? 0;
        final received = user?.receivedCount ?? 0;
        final reputation = user?.reputationScore ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              _buildStatItem(
                context,
                '$donated',
                'Đã tặng',
                colorScheme.primary,
                textTheme,
              ),
              Container(
                width: 1,
                height: 40,
                color: colorScheme.surfaceContainerHighest,
              ),
              _buildStatItem(
                context,
                '$received',
                'Đã nhận',
                colorScheme.onSurface,
                textTheme,
              ),
              Container(
                width: 1,
                height: 40,
                color: colorScheme.surfaceContainerHighest,
              ),
              _buildStatItem(
                context,
                '$reputation',
                'Uy tín',
                colorScheme.secondary,
                textTheme,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    Color valueColor,
    TextTheme textTheme,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              value,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
                height: 32 / 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 16 / 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
