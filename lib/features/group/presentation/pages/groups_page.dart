import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../injection_container.dart';
import '../../../user/presentation/cubit/user_cubit.dart';
import '../../../user/presentation/cubit/user_state.dart';
import '../cubit/group_cubit.dart';
import '../widgets/group_card.dart';
import '../widgets/group_filter_chips.dart';
import '../../../../core/network/location_service.dart';

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

class GroupsView extends StatefulWidget {
  const GroupsView({super.key});

  @override
  State<GroupsView> createState() => _GroupsViewState();
}

class _GroupsViewState extends State<GroupsView> {
  final LocationService _locationService = LocationService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _provinces = [];
  Timer? _searchDebounce;
  String? _provinceCode;
  bool _myGroups = false;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 400) {
      context.read<GroupCubit>().loadMore();
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim();
    if (_myGroups) {
      context.read<GroupCubit>().fetchMyGroups(memberStatus: 'approved');
    } else {
      context.read<GroupCubit>().fetchGroups(
        query: query.isEmpty ? null : query,
        provinceCode: _provinceCode,
      );
    }
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _applyFilters);
  }

  Future<void> _onJoinGroup(String groupId) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await context.read<GroupCubit>().joinGroup(groupId);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success
            ? null
            : Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _onCancelJoin(String groupId) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await context.read<GroupCubit>().cancelJoinRequest(groupId);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success
            ? null
            : Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _loadProvinces() async {
    try {
      final data = await _locationService.getProvinces();
      if (mounted) {
        setState(() => _provinces = data);
      }
    } catch (_) {
      // Bỏ qua lỗi tải tỉnh thành
    }
  }

  String _getProvinceName(String? code) {
    if (code == null) return 'Việt Nam';
    if (_provinces.isEmpty) return 'Đang tải...';
    try {
      final province = _provinces.firstWhere(
        (p) => p['code'].toString() == code,
      );
      return province['name'] ?? 'Việt Nam';
    } catch (_) {
      return code;
    }
  }

  Future<void> _onRefresh() async {
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Hội nhóm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Tạo nhóm',
            onPressed: () async {
              final shouldRefresh = await context.push(AppRoutes.createGroup);
              if (shouldRefresh == true && context.mounted) {
                _applyFilters();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: colorScheme.primary,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header + search
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Khám phá hội nhóm\nthiện nguyện',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kết nối với cộng đồng xung quanh bạn',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    AppSearchBar(
                      controller: _searchController,
                      hintText: 'Tìm kiếm hội nhóm...',
                      onChanged: _onSearchChanged,
                      onSubmitted: (_) {
                        _searchDebounce?.cancel();
                        _applyFilters();
                      },
                    ),
                  ],
                ).animate().fade(duration: 350.ms).slideY(begin: -0.04),
              ),
            ),

            // Filter chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child:
                    GroupFilterChips(
                          filters: const [
                            'Tất cả',
                            'Nhóm của tôi',
                            'Gần đây',
                            'Hà Nội',
                            'TP.HCM',
                            'Đà Nẵng',
                          ],
                          onFilterSelected: (filter) {
                            _myGroups = filter == 'Nhóm của tôi';
                            _provinceCode = switch (filter) {
                              'Hà Nội' => '01',
                              'TP.HCM' => '79',
                              'Đà Nẵng' => '48',
                              _ => null,
                            };
                            _applyFilters();
                          },
                        )
                        .animate()
                        .fade(delay: 80.ms, duration: 350.ms)
                        .slideX(begin: 0.06),
              ),
            ),

            // Danh sách
            BlocBuilder<GroupCubit, GroupState>(
              builder: (context, state) {
                if (state is GroupLoading) {
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const Padding(
                          padding: EdgeInsets.only(bottom: 20),
                          child: AppSkeletonCard(),
                        ),
                        childCount: 3,
                      ),
                    ),
                  );
                }

                if (state is GroupError) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'Không tải được danh sách',
                      message: state.message,
                      actionLabel: 'Thử lại',
                      onAction: _applyFilters,
                      isError: true,
                    ),
                  );
                }

                if (state is GroupLoaded) {
                  if (state.groups.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppEmptyState(
                        icon: Icons.groups_outlined,
                        title: 'Chưa có hội nhóm nào',
                        message: _myGroups
                            ? 'Bạn chưa tham gia nhóm nào. Hãy khám phá và tham gia!'
                            : 'Không tìm thấy nhóm phù hợp. Thử đổi bộ lọc hoặc tạo nhóm mới.',
                        actionLabel: _myGroups ? null : 'Tạo nhóm',
                        onAction: _myGroups
                            ? null
                            : () => context.push(AppRoutes.createGroup),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final userState = context.watch<UserCubit>().state;
                        String? currentUserId;
                        if (userState is UserLoaded) {
                          currentUserId = userState.user.id;
                        }

                        final group = state.groups[index];
                        final isOwner =
                            currentUserId != null &&
                            currentUserId == group.ownerId;
                        final isMember = group.myStatus == 'approved';
                        final isPending = group.myStatus == 'pending';
                        final isJoining = state.joiningIds.contains(group.id);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child:
                              GroupCard(
                                    name: group.name,
                                    coverUrl:
                                        group.coverUrl ??
                                        'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?q=80&w=600&auto=format&fit=crop',
                                    logoUrl:
                                        group.avatarUrl ??
                                        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(group.name)}&background=random',
                                    members: '${group.memberCount} thành viên',
                                    location: _getProvinceName(
                                      group.provinceCode,
                                    ),
                                    description:
                                        group.description ?? 'Chưa có mô tả',
                                    isOwner: isOwner,
                                    isMember: isMember,
                                    isPending: isPending,
                                    isJoining: isJoining,
                                    onJoin: () => _onJoinGroup(group.id),
                                    onCancel: () => _onCancelJoin(group.id),
                                    onView: () {
                                      context.push(
                                        '${AppRoutes.groupDetail}/${group.id}',
                                      );
                                    },
                                  )
                                  .animate(
                                    delay: (index % 5 * 60).ms,
                                  )
                                  .fade(duration: 350.ms)
                                  .slideY(begin: 0.05),
                        );
                      }, childCount: state.groups.length),
                    ),
                  );
                }

                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}
