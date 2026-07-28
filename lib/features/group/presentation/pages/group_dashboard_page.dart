import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../injection_container.dart';
import '../../../user/presentation/cubit/user_cubit.dart';
import '../../../user/presentation/cubit/user_state.dart';
import '../../data/models/group_model.dart';
import '../cubit/group_detail_cubit.dart';
import '../widgets/group_dashboard_inventory.dart';
import '../widgets/group_dashboard_members.dart';
import '../widgets/group_dashboard_posts.dart';
import '../widgets/group_dashboard_settings.dart';

class GroupDashboardPage extends StatelessWidget {
  final String groupId;

  const GroupDashboardPage({super.key, required this.groupId});

  static const _tabs = [
    (icon: Icons.dashboard_outlined, label: 'Tổng quan'),
    (icon: Icons.inventory_2_outlined, label: 'Kho đồ'),
    (icon: Icons.article_outlined, label: 'Bài đăng'),
    (icon: Icons.people_outline, label: 'Thành viên'),
    (icon: Icons.settings_outlined, label: 'Cài đặt'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<GroupDetailCubit>()..fetchGroupDetail(groupId),
      child: BlocBuilder<GroupDetailCubit, GroupDetailState>(
        builder: (context, state) {
          if (state is! GroupDetailLoaded) {
            return Scaffold(
              appBar: AppBar(title: const Text('Quản lý nhóm')),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          final group = state.group;
          final userState = context.watch<UserCubit>().state;
          final currentUserId =
              userState is UserLoaded ? userState.user.id : null;
          final canModerate =
              (group.myStatus == 'approved' &&
                  (group.myRole == 'owner' || group.myRole == 'moderator')) ||
              currentUserId == group.ownerId;

          if (!canModerate) {
            return Scaffold(
              appBar: AppBar(title: const Text('Quản lý nhóm')),
              body: AppEmptyState(
                icon: Icons.lock_outline_rounded,
                title: 'Không có quyền truy cập',
                message:
                    'Chỉ chủ nhóm và kiểm duyệt viên mới vào được trang này.',
                actionLabel: 'Quay lại',
                onAction: () => context.pop(),
              ),
            );
          }

          return DefaultTabController(
            length: _tabs.length,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Quản lý nhóm'),
                bottom: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: _tabs
                      .map(
                        (tab) => Tab(
                          icon: Icon(tab.icon, size: 20),
                          text: tab.label,
                          height: 56,
                          iconMargin: const EdgeInsets.only(bottom: 2),
                        ),
                      )
                      .toList(),
                ),
              ),
              body: TabBarView(
                children: [
                  _OverviewTab(group: group),
                  GroupDashboardInventory(group: group),
                  GroupDashboardPosts(group: group),
                  GroupDashboardMembers(group: group),
                  GroupDashboardSettings(group: group),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final GroupModel group;

  const _OverviewTab({required this.group});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AdminHeader(group: group),
          const SizedBox(height: 16),
          _CommunitySummary(group: group),
          const SizedBox(height: 28),
          Text('Công cụ quản lý', style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Đi thẳng đến công việc bạn cần xử lý',
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              _ManagementCard(
                icon: Icons.inventory_2_outlined,
                title: 'Kho đồ',
                subtitle: 'Tiếp nhận và đăng vật phẩm',
                onTap: () => DefaultTabController.of(context).animateTo(1),
              ),
              _ManagementCard(
                icon: Icons.rate_review_outlined,
                title: 'Bài đăng',
                subtitle: 'Duyệt nội dung thành viên',
                onTap: () => DefaultTabController.of(context).animateTo(2),
              ),
              _ManagementCard(
                icon: Icons.group_outlined,
                title: 'Thành viên',
                subtitle: 'Vai trò và yêu cầu tham gia',
                onTap: () => DefaultTabController.of(context).animateTo(3),
              ),
              _ManagementCard(
                icon: Icons.tune_rounded,
                title: 'Thiết lập',
                subtitle: 'Thông tin và quyền đăng bài',
                onTap: () => DefaultTabController.of(context).animateTo(4),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text('Trạng thái nhóm', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          _ConfigurationCard(group: group),
        ],
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  final GroupModel group;

  const _AdminHeader({required this.group});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final roleLabel = group.myRole == 'moderator'
        ? 'Kiểm duyệt viên'
        : 'Chủ nhóm';

    return Material(
      color: colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => context.push('${AppRoutes.groupDetail}/${group.id}'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              AppAvatar(
                imageUrl: group.avatarUrl,
                name: group.name,
                radius: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BẢNG ĐIỀU KHIỂN',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      group.name,
                      style: textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      roleLabel,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunitySummary extends StatelessWidget {
  final GroupModel group;

  const _CommunitySummary({required this.group});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${group.memberCount}',
                  style: textTheme.displaySmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'thành viên đang kết nối',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: () {
                    context.push(
                      AppRoutes.chatInbox,
                      extra: {'groupId': group.id, 'name': group.name},
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Mở trò chuyện'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    backgroundColor: colorScheme.onPrimary,
                    foregroundColor: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.groups_rounded,
            size: 76,
            color: colorScheme.onPrimary.withValues(alpha: 0.16),
          ),
        ],
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ManagementCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 19, color: colorScheme.primary),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 17,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const Spacer(),
              Text(title, style: textTheme.titleSmall),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfigurationCard extends StatelessWidget {
  final GroupModel group;

  const _ConfigurationCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _ConfigRow(
            icon: Icons.circle,
            iconColor: group.status == 'active'
                ? const Color(0xFF1B8A5A)
                : colorScheme.error,
            title: 'Trạng thái nhóm',
            value: group.status == 'active' ? 'Đang hoạt động' : 'Tạm dừng',
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: colorScheme.outlineVariant,
          ),
          _ConfigRow(
            icon: Icons.edit_note_rounded,
            title: 'Thành viên đăng bài',
            value: group.allowMemberPost ? 'Được phép' : 'Đã tắt',
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: colorScheme.outlineVariant,
          ),
          _ConfigRow(
            icon: Icons.fact_check_outlined,
            title: 'Kiểm duyệt bài viết',
            value: group.requirePostReview ? 'Bắt buộc' : 'Không yêu cầu',
          ),
        ],
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String value;

  const _ConfigRow({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            icon,
            size: icon == Icons.circle ? 10 : 19,
            color: iconColor ?? colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: textTheme.bodyMedium)),
          Text(
            value,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
