import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/session_token.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/user_entity.dart';
import '../cubit/public_profile_cubit.dart';
import '../cubit/public_profile_state.dart';

/// Trang xem hồ sơ công khai của người dùng khác.
class PublicProfilePage extends StatelessWidget {
  const PublicProfilePage({super.key, required this.accountId, this.initialName});

  final String accountId;

  /// Tên hiển thị tạm khi chưa tải xong, tránh AppBar trống.
  final String? initialName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PublicProfileCubit>()..load(accountId),
      child: _PublicProfileView(accountId: accountId, initialName: initialName),
    );
  }
}

class _PublicProfileView extends StatelessWidget {
  const _PublicProfileView({required this.accountId, this.initialName});

  final String accountId;
  final String? initialName;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PublicProfileCubit, PublicProfileState>(
      builder: (context, state) {
        final user = state.user;
        final title = user?.fullName ?? initialName ?? 'Trang cá nhân';

        return Scaffold(
          appBar: AppBar(title: Text(title), centerTitle: true),
          body: switch (state.status) {
            PublicProfileStatus.initial ||
            PublicProfileStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            PublicProfileStatus.error => AppEmptyState(
              icon: Icons.person_off_outlined,
              title: 'Không tải được hồ sơ',
              message: state.errorMessage,
              isError: true,
              actionLabel: 'Thử lại',
              onAction: () =>
                  context.read<PublicProfileCubit>().load(accountId),
            ),
            PublicProfileStatus.loaded => RefreshIndicator(
              onRefresh: () =>
                  context.read<PublicProfileCubit>().load(accountId),
              child: _ProfileBody(user: user!),
            ),
          },
        );
      },
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelf = sameUserId(user.id, resolveCurrentUserId(sl()));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        Center(
          child: AppAvatar(
            imageUrl: user.resolvedAvatarUrl,
            name: user.fullName,
            radius: 48,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.fullName,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (isSelf) ...[
          const SizedBox(height: 8),
          Center(
            child: Chip(
              label: const Text('Đây là bạn'),
              visualDensity: VisualDensity.compact,
              backgroundColor: colors.primaryContainer,
              side: BorderSide.none,
            ),
          ),
        ],
        if (user.bio != null && user.bio!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            user.bio!.trim(),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 24),
        _StatsRow(user: user),
        const SizedBox(height: 24),
        if (_hasLocation(user)) ...[
          _InfoTile(
            icon: Icons.place_outlined,
            label: 'Khu vực',
            value: _locationLabel(user),
          ),
        ],
        _InfoTile(
          icon: Icons.verified_user_outlined,
          label: 'Điểm uy tín',
          value: '${user.reputationScore}',
        ),
      ],
    );
  }

  bool _hasLocation(UserEntity user) {
    final province = user.provinceCode?.trim() ?? '';
    final district = user.districtCode?.trim() ?? '';
    return province.isNotEmpty || district.isNotEmpty;
  }

  String _locationLabel(UserEntity user) {
    final parts = <String>[
      if ((user.districtCode?.trim() ?? '').isNotEmpty) user.districtCode!.trim(),
      if ((user.provinceCode?.trim() ?? '').isNotEmpty) user.provinceCode!.trim(),
    ];
    return parts.join(' · ');
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _StatItem(
            value: '${user.donationCount}',
            label: 'Đã tặng',
            color: colors.primary,
          ),
          _Divider(color: colors.surfaceContainerHighest),
          _StatItem(
            value: '${user.receivedCount}',
            label: 'Đã nhận',
            color: colors.onSurface,
          ),
          _Divider(color: colors.surfaceContainerHighest),
          _StatItem(
            value: '${user.reputationScore}',
            label: 'Uy tín',
            color: colors.secondary,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: color);
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        child: Icon(icon, size: 20),
      ),
      title: Text(label, style: Theme.of(context).textTheme.labelMedium),
      subtitle: Text(value, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}
