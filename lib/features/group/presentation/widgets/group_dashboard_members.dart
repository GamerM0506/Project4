import 'package:flutter/material.dart';
import '../../data/models/group_model.dart';
import 'group_members_tab.dart';
import 'group_join_requests_tab.dart';

class GroupDashboardMembers extends StatelessWidget {
  final GroupModel group;

  const GroupDashboardMembers({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TabBar(
            tabs: [
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
