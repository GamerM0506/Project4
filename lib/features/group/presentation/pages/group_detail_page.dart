import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
        BlocProvider(
          create: (_) => sl<GroupFeedCubit>()..fetchPosts(groupId),
        ),
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

class _GroupDetailViewState extends State<GroupDetailView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      body: BlocBuilder<GroupDetailCubit, GroupDetailState>(
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
            final isJoining = state.isJoining;
            final userState = context.watch<UserCubit>().state;
            String? currentUserId;
            if (userState is UserLoaded) {
              currentUserId = userState.user.id;
            }
            final isMember = group.myRole != null || (currentUserId != null && currentUserId == group.ownerId);
            final isPending = group.myStatus == 'pending';
            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 250,
                    pinned: true,
                    leading: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    actions: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.share, color: Colors.white, size: 20),
                        ),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Image.network(
                        group.coverUrl ?? 'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?q=80&w=600&auto=format&fit=crop',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)));
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: const Offset(0, -50),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.surface,
                                border: Border.all(color: colorScheme.surface, width: 4),
                              ),
                              child: ClipOval(
                                child: Image.network(
                                  group.avatarUrl ?? 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(group.name)}&background=random',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(color: Colors.grey[300], child: const Icon(Icons.group, color: Colors.grey));
                                  },
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: Text(
                              group.name,
                              style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                            child: Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 20, color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(group.provinceCode ?? 'Vietnam', style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
                                const SizedBox(width: 16),
                                Icon(Icons.people_alt_outlined, size: 20, color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text('${group.memberCount} Thành viên', style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    if (currentUserId == group.ownerId || group.myRole == 'owner' || group.myRole == 'moderator')
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: () async {
                                            await context.push('${AppRoutes.groupDashboard}/${group.id}');
                                            if (context.mounted) {
                                              context.read<GroupDetailCubit>().fetchGroupDetail(group.id);
                                            }
                                          },
                                          icon: const Icon(Icons.settings),
                                          label: const Text('Quản lý Nhóm'),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color(0xFF68E1D2),
                                            foregroundColor: Colors.black87,
                                          ),
                                        ),
                                      )
                                    else if (!isMember)
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: isPending || isJoining ? null : () {
                                            context.read<GroupDetailCubit>().joinGroup(group.id);
                                          },
                                          icon: isJoining 
                                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                            : Icon(isPending ? Icons.access_time : Icons.group_add),
                                          label: Text(isPending ? 'Đang chờ duyệt' : 'Tham gia nhóm'),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: isPending ? Colors.grey : const Color(0xFFB73A41),
                                          ),
                                        ),
                                      ),
                                    if (isMember && currentUserId != group.ownerId && group.myRole != 'owner' && group.myRole != 'moderator')
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {},
                                          icon: const Icon(Icons.check),
                                          label: const Text('Đã tham gia'),
                                        ),
                                      ),
                                     const SizedBox(width: 8),
                                     FilledButton.icon(
                                       onPressed: () {
                                         context.push(AppRoutes.chatRoom, extra: {
                                           'conversationId': group.id,
                                           'name': group.name,
                                         });
                                       },
                                       icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                       label: const Text('Nhắn tin & Quyên góp'),
                                       style: FilledButton.styleFrom(
                                         backgroundColor: colorScheme.primaryContainer,
                                         foregroundColor: colorScheme.onPrimaryContainer,
                                       ),
                                     ),
                                    const SizedBox(width: 12),
                                    IconButton.filledTonal(
                                      onPressed: () {},
                                      icon: const Icon(Icons.share),
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
                        labelColor: const Color(0xFFB73A41),
                        unselectedLabelColor: colorScheme.onSurfaceVariant,
                        indicatorColor: const Color(0xFFB73A41),
                        tabs: const [
                          Tab(text: 'Bảng tin'),
                          Tab(text: 'Cửa hàng'),
                          Tab(text: 'Thành viên'),
                          Tab(text: 'Giới thiệu'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildFeedTab(group, colorScheme, textTheme),
                  const Center(child: Text('Cửa hàng 0 đồng')),
                  const Center(child: Text('Danh sách thành viên')),
                  _buildAboutTab(group, textTheme),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildFeedTab(GroupModel group, ColorScheme colorScheme, TextTheme textTheme) {
    final userState = context.watch<UserCubit>().state;
    String? currentUserId;
    if (userState is UserLoaded) {
      currentUserId = userState.user.id;
    }
    
    final isMember = group.myRole != null || (currentUserId != null && currentUserId == group.ownerId);

    return BlocBuilder<GroupFeedCubit, GroupFeedState>(
      builder: (context, state) {
        if (state is GroupFeedLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is GroupFeedError) {
          return Center(child: Text('Lỗi: ${state.message}', style: TextStyle(color: colorScheme.error)));
        } else if (state is GroupFeedLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<GroupFeedCubit>().fetchPosts(group.id, isRefresh: true);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: state.posts.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return isMember 
                      ? CreatePostWidget(groupId: group.id)
                      : const SizedBox.shrink();
                }

                final post = state.posts[index - 1];
                return PostCardWidget(post: post);
              },
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildAboutTab(GroupModel group, TextTheme textTheme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Về chúng tôi', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(group.description ?? 'Chưa có thông tin giới thiệu.', style: textTheme.bodyLarge),
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
