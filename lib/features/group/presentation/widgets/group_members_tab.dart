import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../injection_container.dart';
import '../cubit/group_members_cubit.dart';
import '../cubit/group_members_state.dart';

class GroupMembersTab extends StatelessWidget {
  final String groupId;

  const GroupMembersTab({Key? key, required this.groupId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<GroupMembersCubit>()..fetchMembers(groupId, status: 'approved'),
      child: BlocBuilder<GroupMembersCubit, GroupMembersState>(
        builder: (context, state) {
          if (state is GroupMembersLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GroupMembersError) {
            return Center(child: Text(state.message));
          }

          if (state is GroupMembersLoaded) {
            final members = state.members;

            if (members.isEmpty) {
              return const Center(child: Text('Không có thành viên nào'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: members.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final member = members[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: member.userAvatar != null
                        ? NetworkImage(member.userAvatar!)
                        : null,
                    child: member.userAvatar == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    member.userName != null && member.userName!.isNotEmpty
                        ? member.userName!
                        : 'Thành viên ẩn danh',
                  ), // Display User Name or anonymous
                  subtitle: Text('Vai trò: ${_roleText(member.role)}'),
                  trailing: member.role != 'owner'
                      ? PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
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
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Kích thành viên'),
                                  content: const Text(
                                    'Bạn có chắc muốn kích thành viên này khỏi nhóm?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Hủy'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        context
                                            .read<GroupMembersCubit>()
                                            .kickMember(groupId, member.userId);
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Kích'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            if (member.role != 'moderator')
                              const PopupMenuItem(
                                value: 'promote',
                                child: Text('Cấp quyền kiểm duyệt viên'),
                              ),
                            if (member.role == 'moderator')
                              const PopupMenuItem(
                                value: 'demote',
                                child: Text('Gỡ quyền Kiểm duyệt'),
                              ),
                            const PopupMenuItem(
                              value: 'kick',
                              child: Text(
                                'Kích khỏi nhóm',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Chủ nhóm',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

String _roleText(String role) {
  return switch (role) {
    'owner' => 'Chủ nhóm',
    'moderator' => 'Kiểm duyệt viên',
    'member' => 'Thành viên',
    _ => 'Không xác định',
  };
}
