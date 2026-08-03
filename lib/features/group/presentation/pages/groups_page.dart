import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_hero_banner.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../injection_container.dart';
import '../../../user/presentation/cubit/user_cubit.dart';
import '../../../user/presentation/cubit/user_state.dart';
import '../cubit/group_cubit.dart';
import '../widgets/group_card.dart';
import '../widgets/group_filter_chips.dart';
import '../../../../core/network/location_service.dart';

/// Chieu cao banner khi mo rong va thanh tim kiem duoi banner.
const double _kBannerHeight = 214;
const double _kSearchBarHeight = 72;

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
  final LocationService _locationService = sl<LocationService>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _provinces = [];
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
    final result = await context.read<GroupCubit>().joinGroup(groupId);
    if (!mounted) return;
    if (result.success) {
      context.showSuccessSnack(result.message);
    } else {
      context.showErrorSnack(result.message);
    }
  }

  Future<void> _onCancelJoin(String groupId) async {
    final result = await context.read<GroupCubit>().cancelJoinRequest(groupId);
    if (!mounted) return;
    if (result.success) {
      context.showSnack(result.message);
    } else {
      context.showErrorSnack(result.message);
    }
  }

  Future<void> _loadProvinces() async {
    try {
      final data = await _locationService.getProvinces();
      if (mounted) {
        setState(
          () => _provinces = data
              .whereType<Map>()
              .map((p) => Map<String, dynamic>.from(p))
              .toList(),
        );
      }
    } catch (_) {
      // Bỏ qua lỗi tải tỉnh thành: danh sách nhóm vẫn xem được.
    }
  }

  String _getProvinceName(String? code) {
    if (code == null || code.isEmpty) return 'Việt Nam';
    if (_provinces.isEmpty) return 'Đang tải...';
    for (final province in _provinces) {
      if (province['code']?.toString() == code) {
        return province['name']?.toString() ?? 'Việt Nam';
      }
    }
    return code;
  }

  Future<void> _onRefresh() async {
    _applyFilters();
  }

  /// Số liệu tổng quan trên banner, đọc từ state hiện tại của cubit.
  List<AppHeroStat> _statsOf() {
    final state = context.read<GroupCubit>().state;
    if (state is! GroupLoaded || state.groups.isEmpty) return const [];
    final joined = state.groups.where((g) => g.myStatus == 'approved').length;
    return [
      AppHeroStat(value: '${state.groups.length}', label: 'hội nhóm'),
      if (joined > 0) AppHeroStat(value: '$joined', label: 'đã tham gia'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: colorScheme.primary,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Cùng khuôn banner với trang Đợt quyên góp để hai tab không nhìn
            // như hai ứng dụng khác nhau.
            SliverAppBar(
              expandedHeight: _kBannerHeight,
              pinned: true,
              stretch: true,
              foregroundColor: Colors.white,
              backgroundColor: colorScheme.primary,
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'Tạo nhóm',
                  onPressed: () async {
                    final shouldRefresh = await context.push(
                      AppRoutes.createGroup,
                    );
                    if (shouldRefresh == true && context.mounted) {
                      _applyFilters();
                    }
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              flexibleSpace: AppHeroBanner(
                title: 'Tìm hội nhóm gần bạn',
                subtitle:
                    'Tham gia để quyên góp và theo dõi hoạt động thiện nguyện.',
                collapsedTitle: 'Hội nhóm',
                icon: Icons.groups_rounded,
                expandedHeight: _kBannerHeight,
                bottomBarHeight: _kSearchBarHeight,
                stats: _statsOf(),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(_kSearchBarHeight),
                child: Container(
                  color: colorScheme.surface,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: AppSearchBar(
                    controller: _searchController,
                    hintText: 'Tìm kiếm hội nhóm...',
                    onChanged: _onSearchChanged,
                    onSubmitted: (_) {
                      _searchDebounce?.cancel();
                      _applyFilters();
                    },
                  ),
                ),
              ),
            ),

            // Bộ lọc
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.lg,
                ),
                child: GroupFilterChips(
                  filters: const [
                    'Tất cả',
                    'Nhóm của tôi',
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
                ),
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
                          child: GroupCard(
                            name: group.name,
                            // Để null khi nhóm chưa có ảnh: GroupCard tự vẽ
                            // nền thay thế. Trước đây chèn ảnh Unsplash cố
                            // định nên mọi nhóm trông giống hệt nhau và phụ
                            // thuộc dịch vụ ngoài.
                            coverUrl: group.coverUrl,
                            logoUrl: group.avatarUrl,
                            members: '${group.memberCount} thành viên',
                            location: _getProvinceName(group.provinceCode),
                            description: group.description ?? 'Chưa có mô tả',
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
                          ),
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
