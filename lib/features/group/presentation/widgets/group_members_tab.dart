import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/member_entity.dart';
import '../cubit/group_members_cubit.dart';
import '../cubit/group_members_state.dart';

class GroupMembersTab extends StatelessWidget {
  final String groupId;
  final String? currentUserRole;
  final String status;

  const GroupMembersTab({
    super.key,
    required this.groupId,
    required this.currentUserRole,
    this.status = 'approved',
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<GroupMembersCubit>()..fetchMembers(groupId, status: status),
      child: BlocBuilder<GroupMembersCubit, GroupMembersState>(
        builder: (context, state) {
          if (state is GroupMembersLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GroupMembersError) {
            return AppEmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Không tải được thành viên',
              message: state.message,
              actionLabel: 'Thử lại',
              onAction: () => context
                  .read<GroupMembersCubit>()
                  .fetchMembers(groupId, status: status),
              isError: true,
            );
          }

          if (state is GroupMembersLoaded) {
            final members = state.members;

            if (members.isEmpty) {
              return AppEmptyState(
                icon: status == 'banned'
                    ? Icons.block_rounded
                    : Icons.people_outline_rounded,
                title: status == 'banned'
                    ? 'Không có ai bị cấm'
                    : 'Chưa có thành viên nào',
                message: status == 'banned'
                    ? null
                    : 'Chia sẻ nhóm để mời thêm thành viên.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: members.length + (state.hasReachedMax ? 0 : 1),
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == members.length) {
                  return Center(
                    child: TextButton(
                      onPressed: state.isLoadingMore
                          ? null
                          : () => context.read<GroupMembersCubit>().loadMore(
                              groupId,
                            ),
                      child: state.isLoadingMore
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Xem thêm'),
                    ),
                  );
                }
                final member = members[index];
                return _MemberCard(
                  member: member,
                  groupId: groupId,
                  currentUserRole: currentUserRole,
                  status: status,
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.groupId,
    required this.currentUserRole,
    required this.status,
  });

  final MemberEntity member;
  final String groupId;
  final String? currentUserRole;
  final String status;

  void _openProfile(BuildContext context, String name) {
    if (member.userId.trim().isEmpty) return;
    context.push(
      '${AppRoutes.publicProfile}/${member.userId}',
      extra: {'name': name},
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final canChangeRole = currentUserRole == 'owner';
    final canKick = status == 'approved' &&
        member.role != 'owner' &&
        (currentUserRole == 'owner' ||
            (currentUserRole == 'moderator' && member.role == 'member'));
    final canUnban = status == 'banned' &&
        member.role == 'member' &&
        (currentUserRole == 'owner' || currentUserRole == 'moderator');

    final name = (member.userName != null && member.userName!.isNotEmpty)
        ? member.userName!
        : 'Thành viên ẩn danh';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => _openProfile(context, name),
            customBorder: const CircleBorder(),
            child: AppAvatar(
              imageUrl: member.userAvatar,
              name: name,
              radius: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => _openProfile(context, name),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _RoleBadge(role: member.role),
                ],
              ),
            ),
          ),
          if (canUnban)
            TextButton(
              onPressed: () => context
                  .read<GroupMembersCubit>()
                  .unbanMember(groupId, member.userId),
              child: const Text('Bỏ cấm'),
            )
          else if (canChangeRole || canKick)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              onSelected: (value) {
                if (value == 'promote') {
                  context.read<GroupMembersCubit>().updateRole(
                    groupId,
                    member.userId,
                    'moderator',
                  );
                } else if (value == 'demote') {
                  context.read<GroupMembersCubit>().updateRole(
                    groupId,
                    member.userId,
                    'member',
                  );
                } else if (value == 'kick') {
                  _confirmKick(context, name);
                }
              },
              itemBuilder: (context) => [
                if (canChangeRole && member.role == 'member')
                  const PopupMenuItem(
                    value: 'promote',
                    child: Text('Cấp quyền kiểm duyệt'),
                  ),
                if (canChangeRole && member.role == 'moderator')
                  const PopupMenuItem(
                    value: 'demote',
                    child: Text('Gỡ quyền kiểm duyệt'),
                  ),
                if (canKick)
                  PopupMenuItem(
                    value: 'kick',
                    child: Text(
                      'Kích khỏi nhóm',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  void _confirmKick(BuildContext context, String name) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kích thành viên'),
        content: Text('Bạn có chắc muốn kích $name khỏi nhóm?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<GroupMembersCubit>().kickMember(
                groupId,
                member.userId,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: const Text('Kích'),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (String label, Color fg, Color bg) = switch (role) {
      'owner' => ('Chủ nhóm', colorScheme.onPrimaryContainer,
          colorScheme.primaryContainer),
      'moderator' => (
          'Kiểm duyệt',
          colorScheme.onSecondaryContainer,
          colorScheme.secondaryContainer,
        ),
      _ => (
          'Thành viên',
          colorScheme.onSurfaceVariant,
          colorScheme.surfaceContainerHigh,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
