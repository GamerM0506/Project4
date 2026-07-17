import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../cubit/group_detail_cubit.dart';
import '../widgets/group_join_requests_tab.dart';
import '../widgets/group_members_tab.dart';

class GroupDashboardPage extends StatefulWidget {
  final String groupId;

  const GroupDashboardPage({super.key, required this.groupId});

  @override
  State<GroupDashboardPage> createState() => _GroupDashboardPageState();
}

class _GroupDashboardPageState extends State<GroupDashboardPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<GroupDetailCubit>()..fetchGroupDetail(widget.groupId),
      child: BlocBuilder<GroupDetailCubit, GroupDetailState>(
        builder: (context, state) {
          String groupName = 'Quản lý nhóm';
          if (state is GroupDetailLoaded) {
            groupName = state.group.name;
          }
          
          return Scaffold(
            appBar: AppBar(
              title: Text(
                groupName,
                style: const TextStyle(color: Color(0xFFB73A41), fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            ),
            body: _buildBody(context),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.teal,
              unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Tổng quan'),
                BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Yêu cầu'),
                BottomNavigationBarItem(icon: Icon(Icons.people_alt), label: 'Thành viên'),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_currentIndex == 1) {
      return GroupJoinRequestsTab(groupId: widget.groupId);
    } else if (_currentIndex == 2) {
      return GroupMembersTab(groupId: widget.groupId);
    } else if (_currentIndex == 3) {
      return const Center(child: Text('Cài đặt'));
    }

    // Default: Tổng quan
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tổng quan nhóm', style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Thống kê hoạt động của nhóm.', style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),

          // Grid Overview
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(context, 'Quyên góp chờ duyệt', '12', Icons.more_horiz, Colors.red),
              _buildStatCard(context, 'Vật phẩm trong kho', '450', Icons.inventory_2_outlined, colorScheme.primary),
              _buildStatCard(context, 'Yêu cầu chờ duyệt', '8', Icons.error_outline, Colors.amber.shade700),
              _buildStatCard(context, 'Đã giúp trong tháng', '32', Icons.volunteer_activism, Colors.teal, backgroundColor: Colors.teal.withValues(alpha: 0.1)),
            ],
          ),
          const SizedBox(height: 32),

          // Action Required
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red),
              const SizedBox(width: 8),
              Text('Hành động cần thiết', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionItem(context, 'Xác nhận 3 lượt gửi đồ mới', 'Gửi hôm nay', 'Kiểm tra', () {}),
          const SizedBox(height: 12),
          _buildActionItem(context, 'Duyệt 5 yêu cầu tham gia', 'Đang chờ phê duyệt', 'Duyệt', () {
            setState(() {
              _currentIndex = 1; // Chuyển sang tab Yêu cầu
            });
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color iconColor, {Color? backgroundColor}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: backgroundColor == null ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, String title, String subtitle, String buttonText, VoidCallback onPressed) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB73A41),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
