import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../injection_container.dart';
import '../../../user/presentation/cubit/user_cubit.dart';
import '../../../user/presentation/cubit/user_state.dart';
import '../cubit/group_cubit.dart';
import '../widgets/group_card.dart';
import '../widgets/group_filter_chips.dart';

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<GroupCubit>()..fetchGroups(),
      child: const GroupsView(),
    );
  }
}

class GroupsView extends StatelessWidget {
  const GroupsView({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          'KindHeart',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.menu, color: colorScheme.onSurface),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: colorScheme.onSurface),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final shouldRefresh = await context.push(AppRoutes.createGroup);
          if (shouldRefresh == true && context.mounted) {
            context.read<GroupCubit>().fetchGroups();
          }
        },
        backgroundColor: colorScheme.primary,
        child: Icon(Icons.add, color: colorScheme.onPrimary),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find Charity Groups',
                    style: textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          height: 48,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Search groups...',
                                    hintStyle: textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.tune, color: colorScheme.onSurface),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ).animate().fade(duration: 400.ms).slideY(begin: -0.1),
            ),
          ),
          
          // Filters
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: GroupFilterChips(
                filters: const ['Tất cả', 'Nhóm của tôi', 'Gần đây', 'Hà Nội', 'TP.HCM', 'Đà Nẵng'],
                onFilterSelected: (filter) {
                  if (filter == 'Nhóm của tôi') {
                    context.read<GroupCubit>().fetchMyGroups();
                  } else {
                    // For now 'All' and others fetch all
                    context.read<GroupCubit>().fetchGroups();
                  }
                },
              ).animate().fade(delay: 100.ms, duration: 400.ms).slideX(begin: 0.1),
            ),
          ),
          
          // Group List
          BlocBuilder<GroupCubit, GroupState>(
            builder: (context, state) {
              if (state is GroupLoading) {
                return const SliverToBoxAdapter(
                  child: Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
                );
              } else if (state is GroupError) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('Lỗi: ${state.message}', style: TextStyle(color: colorScheme.error)),
                    ),
                  ),
                );
              } else if (state is GroupLoaded) {
                if (state.groups.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Không tìm thấy nhóm nào.'))),
                  );
                }
                
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final userState = context.watch<UserCubit>().state;
                        String? currentUserId;
                        if (userState is UserLoaded) {
                          currentUserId = userState.user.id;
                        }

                        final group = state.groups[index];
                        final isOwner = currentUserId != null && currentUserId == group.ownerId;
                        final isMember = group.myRole != null;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: GroupCard(
                            name: group.name,
                            coverUrl: group.coverUrl ?? 'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?q=80&w=600&auto=format&fit=crop',
                            logoUrl: group.avatarUrl ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(group.name)}&background=random',
                            members: '${group.memberCount} Thành viên',
                            location: group.provinceCode ?? 'Vietnam',
                            description: group.description ?? 'Chưa có mô tả',
                            isOwner: isOwner,
                            isMember: isMember,
                            onJoin: () {},
                            onView: () {
                              context.push('${AppRoutes.groupDetail}/${group.id}');
                            },
                          ).animate(delay: (200 + (index % 5) * 100).ms).fade(duration: 400.ms).slideY(begin: 0.1),
                        );
                      },
                      childCount: state.groups.length,
                    ),
                  ),
                );
              }
              
              return const SliverToBoxAdapter(child: SizedBox());
            },
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom padding
        ],
      ),
    );
  }
}
