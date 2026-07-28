import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_status_badge.dart';
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
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Chờ duyệt'),
              Tab(text: 'Đã xuất bản'),
            ],
          ),
          Expanded(
            child:
                BlocConsumer<
                  GroupDashboardPostsCubit,
                  GroupDashboardPostsState
                >(
                  listener: (context, state) {
                    if (state is GroupDashboardPostsError) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(state.message)));
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

  Widget _buildPostsList(
    BuildContext context,
    List<PostEntity> posts,
    bool isPending,
  ) {
    if (posts.isEmpty) {
      return AppEmptyState(
        icon: isPending
            ? Icons.rate_review_outlined
            : Icons.article_outlined,
        title: isPending ? 'Không có bài chờ duyệt' : 'Chưa có bài đăng nào',
        message: isPending
            ? 'Bài viết của thành viên sẽ hiện ở đây khi cần kiểm duyệt.'
            : 'Bài đã xuất bản sẽ hiện ở đây.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildPostItem(context, posts[index], isPending);
      },
    );
  }

  Widget _buildPostItem(BuildContext context, PostEntity post, bool isPending) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppAvatar(radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorId,
                      style: textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeago.format(post.createdAt, locale: 'vi'),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPending) const AppStatusBadge(status: 'pending'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.content,
            style: textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          if (post.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: post.imageUrls.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      post.imageUrls[index],
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 96,
                        height: 96,
                        color: colorScheme.surfaceContainerHigh,
                        child: Icon(
                          Icons.image_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (isPending)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<GroupDashboardPostsCubit>().rejectPost(
                      group.id,
                      post.id,
                    );
                  },
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: colorScheme.error),
                  label: Text(
                    'Từ chối',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    context.read<GroupDashboardPostsCubit>().approvePost(
                      group.id,
                      post.id,
                    );
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Phê duyệt'),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<GroupDashboardPostsCubit>().deletePost(
                      group.id,
                      post.id,
                    );
                  },
                  icon: Icon(Icons.visibility_off_outlined,
                      size: 18, color: colorScheme.error),
                  label: Text(
                    'Ẩn bài',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
