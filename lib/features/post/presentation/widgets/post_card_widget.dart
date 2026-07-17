import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/post_entity.dart';
import '../cubit/group_feed_cubit.dart';
import 'comments_bottom_sheet.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCardWidget extends StatelessWidget {
  final PostEntity post;

  const PostCardWidget({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Author & Time
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    post.authorId.substring(0, 2).toUpperCase(),
                    style: TextStyle(color: colorScheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User ${post.authorId.substring(0, 4)}',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Text(
                            timeago.format(post.createdAt, locale: 'en_short'),
                            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          if (post.type != 'normal') ...[
                            const SizedBox(width: 8),
                            _buildPostTypeChip(post.type, colorScheme),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (value) {
                    if (value == 'delete') {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Xóa bài đăng?'),
                          content: const Text('Bạn có chắc chắn muốn xóa bài đăng này không? Hành động này không thể hoàn tác.'),
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
                              child: const Text('Xóa'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Xóa bài viết', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Content
            Text(
              post.content,
              style: textTheme.bodyLarge,
            ),
            
            // Images
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildImageGallery(post.imageUrls),
            ],

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Actions
            Row(
              children: [
                InkWell(
                  onTap: () {
                    context.read<GroupFeedCubit>().toggleLike(post.id);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          post.isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 20, 
                          color: post.isLiked ? Colors.red : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text('${post.likeCount}', style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () {
                    CommentsBottomSheet.show(context, post.id);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 20, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('${post.commentCount}', style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                _buildActionBtn(Icons.share_outlined, 'Chia sẻ', colorScheme),
              ],
            ),
          ],
        ),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildImageGallery(List<String> imageUrls) {
    if (imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrls[0],
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return SizedBox(
        height: 200,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: imageUrls.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrls[index],
                width: 150,
                height: 200,
                fit: BoxFit.cover,
              ),
            );
          },
        ),
      );
    }
  }

  Widget _buildActionBtn(IconData icon, String label, ColorScheme colorScheme) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
