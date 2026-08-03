import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/post_entity.dart';
import '../cubit/group_feed_cubit.dart';
import 'comments_bottom_sheet.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';

class PostCardWidget extends StatelessWidget {
  final PostEntity post;
  final bool canModerate;

  const PostCardWidget({
    super.key,
    required this.post,
    required this.canModerate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.onSurfaceVariant.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F2F2F).withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Author & Time
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  child: Text(
                    post.authorId.substring(0, 2).toUpperCase(),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Người dùng ${post.authorId.substring(0, 4)}',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            timeago.format(post.createdAt, locale: 'vi'),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          if (post.type != 'normal') ...[
                            const SizedBox(width: 8),
                            _buildPostTypeChip(post.type, colorScheme),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (canModerate)
                  IconButton(
                    icon: Icon(
                      Icons.more_horiz,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      _showModerationMenu(context);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            Text(
              post.content,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
                height: 1.5,
              ),
            ),

            // Images
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildImageGallery(post.imageUrls, colorScheme),
            ],

            const SizedBox(height: 16),
            Divider(
              color: colorScheme.onSurfaceVariant.withOpacity(0.1),
              height: 1,
            ),
            const SizedBox(height: 8),

            // Actions
            Row(
              children: [
                InkWell(
                  onTap: () {
                    context.read<GroupFeedCubit>().toggleLike(post.id);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          post.isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: post.isLiked
                              ? const Color(0xFFAE2F34) // primary heart
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.likeCount}',
                          style: TextStyle(
                            color: post.isLiked
                                ? const Color(0xFFAE2F34)
                                : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () {
                    CommentsBottomSheet.show(
                      context,
                      post.id,
                      onCommentAdded: () => context
                          .read<GroupFeedCubit>()
                          .incrementCommentCount(post.id),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.commentCount}',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _sharePost(),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.share_outlined,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showModerationMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_off, color: Colors.red),
              title: const Text(
                'Ẩn bài viết',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ẩn bài đăng?'),
        content: const Text('Bạn có chắc chắn muốn ẩn bài đăng này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<GroupFeedCubit>().deletePost(post.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ẩn'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostTypeChip(String type, ColorScheme colorScheme) {
    Color color;
    String label;
    switch (type) {
      case 'call_for_donation':
        color = Colors.red;
        label = 'Kêu gọi quyên góp';
        break;
      case 'thank_you':
        color = Colors.teal;
        label = 'Cảm ơn';
        break;
      case 'announcement':
        color = Colors.orange;
        label = 'Thông báo';
        break;
      default:
        color = colorScheme.primary;
        label = 'Bình thường';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildImageGallery(List<String> imageUrls, ColorScheme colorScheme) {
    if (imageUrls.length == 1) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.surfaceContainerHighest,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          imageUrls[0],
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return SizedBox(
        height: 250,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: imageUrls.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.surfaceContainerHighest,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                imageUrls[index],
                width: 200,
                height: 250,
                fit: BoxFit.cover,
              ),
            );
          },
        ),
      );
    }
  }

  Future<void> _sharePost() async {
    final text = post.content.trim();
    await Share.share(
      '${text.isEmpty ? 'Bài viết từ Chợ Tử Tế' : text}\n\n'
      'Mã bài viết: ${post.id}\n'
      'Nhóm: ${post.groupId}',
      subject: 'Chia sẻ bài viết từ Chợ Tử Tế',
    );
  }
}
