import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../cubit/group_detail_cubit.dart';
import '../../data/models/group_model.dart';
import '../widgets/group_dashboard_inventory.dart';
import '../widgets/group_dashboard_posts.dart';
import '../widgets/group_dashboard_members.dart';
import '../widgets/group_dashboard_settings.dart';

class GroupDashboardPage extends StatefulWidget {
  final String groupId;

  const GroupDashboardPage({super.key, required this.groupId});

  @override
  State<GroupDashboardPage> createState() => _GroupDashboardPageState();
}

class _GroupDashboardPageState extends State<GroupDashboardPage> {
  final List<_DashboardTab> _tabs = [
    _DashboardTab(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Tổng quan',
    ),
    _DashboardTab(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2,
      label: 'Kho đồ',
    ),
    _DashboardTab(
      icon: Icons.article_outlined,
      activeIcon: Icons.article,
      label: 'Bài đăng',
    ),
    _DashboardTab(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Thành viên',
    ),
    _DashboardTab(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Cài đặt',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<GroupDetailCubit>()..fetchGroupDetail(widget.groupId),
      child: BlocBuilder<GroupDetailCubit, GroupDetailState>(
        builder: (context, state) {
          String groupName = 'Quản lý nhóm';
          GroupModel? currentGroup;
          if (state is GroupDetailLoaded) {
            groupName = state.group.name;
            currentGroup = state.group;
          }

          if (currentGroup == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return DefaultTabController(
            length: _tabs.length,
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  groupName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                centerTitle: true,
                bottom: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: const Color(0xFFB73A41),
                  unselectedLabelColor: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant,
                  indicatorColor: const Color(0xFFB73A41),
                  tabs: _tabs
                      .map((t) => Tab(icon: Icon(t.icon), text: t.label))
                      .toList(),
                ),
              ),
              body: TabBarView(
                children: [
                  _buildOverviewTab(context, currentGroup),
                  _buildInventoryTab(context, currentGroup),
                  _buildPostsTab(context, currentGroup),
                  _buildMembersTab(context, currentGroup),
                  _buildSettingsTab(context, currentGroup),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, GroupModel group) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng quan nhóm',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thống kê hoạt động của ${group.name}',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    context,
                    'Thành viên',
                    '${group.memberCount}',
                    Icons.people,
                    colorScheme.primary,
                  ),
                  _buildStatCard(
                    context,
                    'Vật phẩm',
                    '45',
                    Icons.inventory_2,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    context,
                    'Bài viết chờ duyệt',
                    '12',
                    Icons.article,
                    Colors.red,
                  ),
                  _buildStatCard(
                    context,
                    'Đã giúp',
                    '128',
                    Icons.volunteer_activism,
                    Colors.teal,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Hành động nhanh',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              ActionChip(
                avatar: const Icon(Icons.chat),
                label: const Text('Trò chuyện nhóm'),
                onPressed: () {
                  context.push(
                    AppRoutes.chatRoom,
                    extra: {'conversationId': group.id, 'name': group.name},
                  );
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.add_box),
                label: const Text('Thêm vật phẩm'),
                onPressed: () {
                  DefaultTabController.of(context).animateTo(1);
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.person_add),
                label: const Text('Duyệt thành viên'),
                onPressed: () {
                  DefaultTabController.of(context).animateTo(3);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTab(BuildContext context, GroupModel group) {
    return GroupDashboardInventory(group: group);
  }

  Widget _buildPostsTab(BuildContext context, GroupModel group) {
    return GroupDashboardPosts(group: group);
  }

  Widget _buildMembersTab(BuildContext context, GroupModel group) {
    return GroupDashboardMembers(group: group);
  }

  Widget _buildSettingsTab(BuildContext context, GroupModel group) {
    return GroupDashboardSettings(group: group);
  }
}

class _DashboardTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _DashboardTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
