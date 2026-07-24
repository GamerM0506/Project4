import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/widgets/app_network_image.dart';
import '../../../../injection_container.dart';
import '../../data/models/group_model.dart';
import '../../../post/domain/entities/post_entity.dart';
import '../cubit/group_dashboard_posts_cubit.dart';
import '../cubit/group_dashboard_posts_state.dart';

class GroupDashboardPosts extends StatelessWidget {
  final GroupModel group;

  const GroupDashboardPosts({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<GroupDashboardPostsCubit>()..fetchPosts(group.id),
      child: _GroupDashboardPostsView(group: group),
    );
  }
}

class _GroupDashboardPostsView extends StatelessWidget {
  final GroupModel group;

  const _GroupDashboardPostsView({required this.group});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Quản lý Bài đăng', style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          TabBar(
            labelColor: const Color(0xFFB73A41),
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: const Color(0xFFB73A41),
            tabs: const [
              Tab(text: 'Chờ duyệt'),
              Tab(text: 'Đã xuất bản'),
            ],
          ),
          Expanded(
            child: BlocConsumer<GroupDashboardPostsCubit, GroupDashboardPostsState>(
              listener: (context, state) {
                if (state is GroupDashboardPostsError) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              builder: (context, state) {
                if (state is GroupDashboardPostsLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is GroupDashboardPostsLoaded) {
                  return TabBarView(
                    children: [
                      _buildPostsList(context, state.pendingPosts, true),
                      _buildPostsList(context, state.publishedPosts, false),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList(BuildContext context, List<PostEntity> posts, bool isPending) {
    if (posts.isEmpty) {
      return Center(
        child: Text(
          isPending ? 'Không có bài đăng chờ duyệt' : 'Chưa có bài đăng nào',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: posts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildPostItem(context, posts[index], isPending);
      },
    );
  }

  Widget _buildPostItem(BuildContext context, PostEntity post, bool isPending) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                child: Icon(Icons.person),
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorId, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(timeago.format(post.createdAt, locale: 'vi'), style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
              if (isPending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Chờ duyệt', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(post.content),
          if (post.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            AppImageGallery(
              urls: post.imageUrls,
              maxHeight: 180,
              borderRadius: BorderRadius.circular(10),
            ),
          ],
          const SizedBox(height: 16),
          if (isPending)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    context.read<GroupDashboardPostsCubit>().rejectPost(group.id, post.id);
                  },
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Từ chối', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                     context.read<GroupDashboardPostsCubit>().approvePost(group.id, post.id);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Phê duyệt'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    context.read<GroupDashboardPostsCubit>().deletePost(group.id, post.id);
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Xóa bài', style: TextStyle(color: Colors.red)),
                ),
              ],
            )
        ],
      ),
    );
  }
}

