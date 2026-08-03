import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../injection_container.dart';
import '../cubit/group_detail_cubit.dart';
import '../../data/models/group_model.dart';
import '../../../user/presentation/cubit/user_cubit.dart';
import '../../../user/presentation/cubit/user_state.dart';
import '../../../post/presentation/cubit/group_feed_cubit.dart';
import '../../../post/presentation/cubit/group_feed_state.dart';
import '../../../post/presentation/widgets/post_card_widget.dart';
import '../../../post/presentation/widgets/create_post_widget.dart';
import '../../../../core/network/location_service.dart';
import '../widgets/group_campaigns_tab.dart';
import '../../../post/domain/entities/post_entity.dart';
import '../widgets/group_members_tab.dart';

class GroupDetailPage extends StatelessWidget {
  final String groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<GroupDetailCubit>()..fetchGroupDetail(groupId),
        ),
        BlocProvider(create: (_) => sl<GroupFeedCubit>()..fetchPosts(groupId)),
      ],
      child: const GroupDetailView(),
    );
  }
}

class GroupDetailView extends StatefulWidget {
  const GroupDetailView({super.key});

  @override
  State<GroupDetailView> createState() => _GroupDetailViewState();
}

class _GroupDetailViewState extends State<GroupDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _resolvedLocation;
  String? _lastResolvedGroupId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  void _resolveLocation(GroupModel group) async {
    if (_lastResolvedGroupId == group.id) return;

    _lastResolvedGroupId = group.id;

    if (group.provinceCode == null) {
      if (mounted) {
        setState(() {
          _resolvedLocation = 'Việt Nam';
        });
      }
      return;
    }

    try {
      // Create local instance since it's not registered in sl
      final locationService = LocationService();
      final provinces = await locationService.getProvinces();

      String? provinceName;
      String? districtName;

      for (final p in provinces) {
        if (p['code'].toString() == group.provinceCode) {
          provinceName = p['name'];
          if (group.districtCode != null && p['districts'] != null) {
            for (final d in p['districts']) {
              if (d['code'].toString() == group.districtCode) {
                districtName = d['name'];
                break;
              }
            }
          }
          break;
        }
      }

      String finalName = '';
      if (districtName != null && provinceName != null) {
        finalName = '$districtName, $provinceName';
      } else if (provinceName != null) {
        finalName = provinceName;
      } else {
        finalName = 'Việt Nam';
      }

      if (mounted) {
        setState(() {
          _resolvedLocation = finalName;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _resolvedLocation = 'Việt Nam';
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      body: BlocConsumer<GroupDetailCubit, GroupDetailState>(
        listener: (context, state) {
          if (state is GroupDetailError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is GroupDetailLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (state is GroupDetailError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Lỗi')),
              body: Center(child: Text(state.message)),
            );
          } else if (state is GroupDetailLoaded) {
            final group = state.group;

            // Resolve location name instead of showing code
            _resolveLocation(group);

            final isJoining = state.isJoining;
            final userState = context.watch<UserCubit>().state;
            String? currentUserId;
            if (userState is UserLoaded) {
              currentUserId = userState.user.id;
            }
            final isMember =
                group.myStatus == 'approved' ||
                (currentUserId != null && currentUserId == group.ownerId);
            final isPending = group.myStatus == 'pending';
            final canModerate =
                (group.myStatus == 'approved' &&
                    (group.myRole == 'owner' || group.myRole == 'moderator')) ||
                (currentUserId != null && currentUserId == group.ownerId);

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 280,
                    pinned: true,
                    backgroundColor: colorScheme.surface,
                    elevation: 0,
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            color: Colors.white.withValues(alpha: 0.2),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              color: Colors.white.withValues(alpha: 0.2),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.share,
                                  color: Colors.white,
                                ),
                                onPressed: () => Share.share(
                                  '${group.name}\nMã nhóm: ${group.id}',
                                  subject: group.name,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.none,
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Cover Image
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            bottom: 48,
                            child: group.coverUrl == null ||
                                    group.coverUrl!.isEmpty
                                ? Container(
                                    color:
                                        colorScheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.groups_rounded,
                                      size: 56,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  )
                                : Image.network(
                                    group.coverUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: colorScheme
                                            .surfaceContainerHighest,
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 56,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          // Gradient Overlay
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            bottom: 48,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black54,
                                    Colors.transparent,
                                    Colors.black26,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Rounded White Container Top
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 48,
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(32),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, -4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Avatar
                          Positioned(
                            left: 24,
                            bottom: 0,
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.surface,
                                border: Border.all(
                                  color: colorScheme.surface,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: group.avatarUrl == null ||
                                        group.avatarUrl!.isEmpty
                                    ? Container(
                                        color:
                                            colorScheme.primaryContainer,
                                        child: Icon(
                                          Icons.group,
                                          color:
                                              colorScheme.onPrimaryContainer,
                                          size: 40,
                                        ),
                                      )
                                    : Image.network(
                                        group.avatarUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                color: colorScheme
                                                    .primaryContainer,
                                                child: Icon(
                                                  Icons.group,
                                                  color: colorScheme
                                                      .onPrimaryContainer,
                                                  size: 40,
                                                ),
                                              );
                                            },
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      color: colorScheme.surface,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    group.name,
                                    style: textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.verified,
                                  color: colorScheme.secondary,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 18,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _resolvedLocation ?? 'Đang tải...',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.group,
                                  size: 18,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${group.memberCount} Thành viên',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                            child: Column(
                              children: [
                                // Primary Action Button (Donate)
                                FilledButton.icon(
                                  onPressed: () {
                                    context.push(
                                      AppRoutes.donate,
                                      extra: {'groupId': group.id},
                                    );
                                  },
                                  icon: const Icon(Icons.favorite),
                                  label: const Text(
                                    'Quyên góp cho nhóm này',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(
                                      double.infinity,
                                      56,
                                    ),
                                    elevation: 4,
                                    shadowColor: colorScheme.primary
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (isMember) ...[
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      context.push(
                                        AppRoutes.chatRoom,
                                        extra: {
                                          'groupId': group.id,
                                          'name': group.name,
                                          'avatarUrl': group.avatarUrl,
                                          'isUserSide': true,
                                        },
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.chat_bubble_outline_rounded,
                                    ),
                                    label: const Text('Nhắn tin với nhóm'),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(
                                        double.infinity,
                                        48,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                // Secondary Actions Row
                                Row(
                                  children: [
                                    if (canModerate)
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () async {
                                            await context.push(
                                              '${AppRoutes.groupDashboard}/${group.id}',
                                            );
                                            if (context.mounted) {
                                              context
                                                  .read<GroupDetailCubit>()
                                                  .fetchGroupDetail(group.id);
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.settings,
                                            size: 18,
                                          ),
                                          label: const Text('Quản lý Nhóm'),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      )
                                    else if (!isMember)
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: isPending || isJoining
                                              ? null
                                              : () {
                                                  context
                                                      .read<GroupDetailCubit>()
                                                      .joinGroup(group.id);
                                                },
                                          icon: isJoining
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : Icon(
                                                  isPending
                                                      ? Icons.access_time
                                                      : Icons.group_add,
                                                  size: 18,
                                                ),
                                          label: Text(
                                            isPending
                                                ? 'Đang chờ duyệt'
                                                : 'Tham gia nhóm',
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      )
                                    else if (isMember && !canModerate)
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {},
                                          icon: const Icon(
                                            Icons.check,
                                            size: 18,
                                          ),
                                          label: const Text('Đã tham gia'),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        labelColor: colorScheme.primary,
                        unselectedLabelColor: colorScheme.onSurfaceVariant,
                        indicatorColor: colorScheme.primary,
                        indicatorWeight: 3,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colorScheme.primary,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        isScrollable: true,
                        tabAlignment: TabAlignment.center,
                        tabs: const [
                          Tab(text: 'Bảng tin'),
                          Tab(text: 'Cửa hàng 0 đồng'),
                          Tab(text: 'Thành viên'),
                          Tab(text: 'Giới thiệu'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
                              body: Container(
                                color: colorScheme.surfaceContainer,
                                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFeedTab(group, colorScheme, textTheme),
                    _buildStoreTab(group, colorScheme, textTheme),
                    GroupMembersTab(
                      groupId: group.id,
                      currentUserRole: group.myRole,
                    ),
                    _buildAboutTab(group, textTheme),
                  ],
                ),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildFeedTab(
    GroupModel group,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final userState = context.watch<UserCubit>().state;
    String? currentUserId;
    if (userState is UserLoaded) {
      currentUserId = userState.user.id;
    }

    final isMember =
        group.myStatus == 'approved' ||
        (currentUserId != null && currentUserId == group.ownerId);

    final canModerate =
        (group.myStatus == 'approved' &&
            (group.myRole == 'owner' || group.myRole == 'moderator')) ||
        (currentUserId != null && currentUserId == group.ownerId);

    return BlocConsumer<GroupFeedCubit, GroupFeedState>(
      listener: (context, state) {
        if (state is GroupFeedDeleteError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        if (state is GroupFeedInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        List<PostEntity> posts = [];
        bool isLoading = false;
        bool hasReachedMax = false;

        if (state is GroupFeedLoading) {
          isLoading = true;
        } else if (state is GroupFeedLoaded) {
          posts = state.posts;
          hasReachedMax = state.hasReachedMax;
        } else if (state is GroupFeedError) {
          return Center(child: Text(state.message));
        }

        return RefreshIndicator(
          onRefresh: () => context.read<GroupFeedCubit>().fetchPosts(
            group.id,
            isRefresh: true,
          ),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.extentAfter < 400) {
                context.read<GroupFeedCubit>().fetchPosts(group.id);
              }
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: posts.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return isMember
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: CreatePostWidget(groupId: group.id),
                        )
                      : const SizedBox.shrink();
                }
                if (index == posts.length + 1) {
                  return isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : hasReachedMax
                      ? const SizedBox.shrink()
                      : const SizedBox.shrink();
                }
                final post = posts[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PostCardWidget(post: post, canModerate: canModerate),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Tab đợt quyên góp của nhóm. Trước đây là gian hàng theo mô hình
  /// marketplace, nay thay bằng luồng campaign.
  Widget _buildStoreTab(
    GroupModel group,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return GroupCampaignsTab(group: group);
  }

  Widget _buildAboutTab(GroupModel group, TextTheme textTheme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Về chúng tôi',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          group.description ?? 'Chưa có thông tin giới thiệu.',
          style: textTheme.bodyLarge?.copyWith(height: 1.6),
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
