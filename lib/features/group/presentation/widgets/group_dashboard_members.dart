import 'package:flutter/material.dart';
import '../../data/models/group_model.dart';
import 'group_members_tab.dart';
import 'group_join_requests_tab.dart';

class GroupDashboardMembers extends StatelessWidget {
  final GroupModel group;

  const GroupDashboardMembers({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Cộng đồng',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TabBar(
            labelColor: const Color(0xFFB73A41),
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: const Color(0xFFB73A41),
            tabs: const [
              Tab(text: 'Thành viên'),
              Tab(text: 'Yêu cầu tham gia'),
              Tab(text: 'Đã cấm'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                GroupMembersTab(
                  groupId: group.id,
                  currentUserRole: group.myRole,
                ),
                GroupJoinRequestsTab(groupId: group.id),
                GroupMembersTab(
                  groupId: group.id,
                  currentUserRole: group.myRole,
                  status: 'banned',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
