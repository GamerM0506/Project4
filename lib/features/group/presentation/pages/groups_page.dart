import 'dart:async';

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

  Future<void> _loadProvinces() async {
    try {
      final data = await _locationService.getProvinces();
      if (mounted) {
        setState(() {
          _provinces = data;
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }

  String _getProvinceName(String? code) {
    if (code == null) return 'Việt Nam';
    if (_provinces.isEmpty) {
      return 'Đang tải...';
    }
    try {
      final province = _provinces.firstWhere(
        (p) => p['code'].toString() == code,
      );
      return province['name'] ?? 'Việt Nam';
    } catch (e) {
      return code; // Fallback to code if not found
    }
  }

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
          'ChoSV',
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
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tìm hội nhóm thiện nguyện',
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
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: _onSearchChanged,
                                  onSubmitted: (_) {
                                    _searchDebounce?.cancel();
                                    _applyFilters();
                                  },
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Tìm kiếm hội nhóm...',
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
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.4,
                          ),
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
                      .fade(delay: 100.ms, duration: 400.ms)
                      .slideX(begin: 0.1),
            ),
          ),

          // Group List
          BlocBuilder<GroupCubit, GroupState>(
            builder: (context, state) {
              if (state is GroupLoading) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              } else if (state is GroupError) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Lỗi: ${state.message}',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  ),
                );
              } else if (state is GroupLoaded) {
                if (state.groups.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Không tìm thấy nhóm nào.'),
                      ),
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

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child:
                            GroupCard(
                                  name: group.name,
                                  coverUrl:
                                      group.coverUrl ??
                                      'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?q=80&w=600&auto=format&fit=crop',
                                  logoUrl:
                                      group.avatarUrl ??
                                      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(group.name)}&background=random',
                                  members: '${group.memberCount} Thành viên',
                                  location: _getProvinceName(
                                    group.provinceCode,
                                  ),
                                  description:
                                      group.description ?? 'Chưa có mô tả',
                                  isOwner: isOwner,
                                  isMember: isMember,
                                  onJoin: () {},
                                  onView: () {
                                    context.push(
                                      '${AppRoutes.groupDetail}/${group.id}',
                                    );
                                  },
                                )
                                .animate(delay: (200 + (index % 5) * 100).ms)
                                .fade(duration: 400.ms)
                                .slideY(begin: 0.1),
                      );
                    }, childCount: state.groups.length),
                  ),
                );
              }

              return const SliverToBoxAdapter(child: SizedBox());
            },
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ), // Bottom padding
        ],
      ),
    );
  }
}
