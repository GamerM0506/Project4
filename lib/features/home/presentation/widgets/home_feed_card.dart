import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../donation/presentation/widgets/donation_gate.dart';
import '../../data/models/feed_post_model.dart';

/// Thẻ bài viết trên trang chủ, dạng feed mạng xã hội.
///
/// Khác `PostCardWidget` trong nhóm: thẻ này hiển thị **tên hội nhóm** ở đầu
/// (vì feed trộn bài từ nhiều nhóm) và ẩn các hành động cần quyền thành viên.
class HomeFeedCard extends StatelessWidget {
  const HomeFeedCard({
    super.key,
    required this.item,
    this.onToggleLike,
    this.onJoinRequested,
  });

  final FeedPostModel item;
  final VoidCallback? onToggleLike;

  /// Gọi sau khi gửi yêu cầu tham gia nhóm thành công.
  final ValueChanged<String>? onJoinRequested;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final post = item.post;
    final group = item.group;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: tác giả + nhóm + nút tham gia
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
            child: Row(
              children: [
                InkWell(
                  onTap: () => _openAuthor(context),
                  customBorder: const CircleBorder(),
                  child: AppAvatar(
                    imageUrl: item.author?.avatarUrl ?? group.avatarUrl,
                    name: item.author?.displayName ?? group.name,
                    radius: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "Tên tác giả › Tên nhóm" — mỗi phần bấm được riêng.
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (item.author != null)
                            InkWell(
                              onTap: () => _openAuthor(context),
                              child: Text(
                                item.author!.displayName,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          if (item.author != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Icon(
                                Icons.chevron_right_rounded,
                                size: 15,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          InkWell(
                            onTap: () => _openGroup(context),
                            child: Text(
                              group.name,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: item.author == null
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: item.author == null
                                    ? null
                                    : colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            timeago.format(post.createdAt, locale: 'vi'),
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          if (post.type != 'normal') ...[
                            const SizedBox(width: 6),
                            Text(
                              '·',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _TypeChip(type: post.type),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _JoinGroupButton(
                  group: group,
                  onJoinRequested: onJoinRequested,
                ),
              ],
            ),
          ),

          // Nội dung
          if (post.content.trim().isNotEmpty)
            InkWell(
              onTap: () => _openPost(context),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Text(
                  post.content.trim(),
                  style: textTheme.bodyMedium?.copyWith(height: 1.45),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

          // Ảnh
          if (post.imageUrls.isNotEmpty)
            _FeedImages(
              urls: post.imageUrls,
              onTap: () => _openPost(context),
            ),

          // Số liệu
          if (post.likeCount > 0 || post.commentCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  if (post.likeCount > 0) ...[
                    Icon(Icons.favorite, size: 13, color: colors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likeCount}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (post.commentCount > 0)
                    Text(
                      '${post.commentCount} bình luận',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Divider(
              height: 18,
              color: colors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),

          // Hành động: chỉ thành viên mới thích/bình luận được (backend chặn
          // bằng require_group_member), nên với người ngoài chỉ hiện Chia sẻ
          // kèm lời mời tham gia.
          if (item.canInteract)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
              child: Row(
                children: [
                  Expanded(
                    child: _FeedAction(
                      icon: item.isLiked
                          ? Icons.favorite
                          : Icons.favorite_border,
                      label: 'Thích',
                      active: item.isLiked,
                      onTap: onToggleLike,
                    ),
                  ),
                  Expanded(
                    child: _FeedAction(
                      icon: Icons.mode_comment_outlined,
                      label: 'Bình luận',
                      onTap: () => _openPost(context),
                    ),
                  ),
                  Expanded(
                    child: _FeedAction(
                      icon: Icons.share_outlined,
                      label: 'Chia sẻ',
                      onTap: _share,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 15,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _restrictionHint,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FeedAction(
                    icon: Icons.share_outlined,
                    label: 'Chia sẻ',
                    onTap: _share,
                    compact: true,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String get _restrictionHint {
    if (item.group.isPending) return 'Yêu cầu tham gia đang chờ duyệt.';
    if (item.group.myStatus == 'banned') {
      return 'Bạn không thể tương tác với hội nhóm này.';
    }
    return 'Tham gia hội nhóm để thích và bình luận.';
  }

  void _openPost(BuildContext context) =>
      context.push('${AppRoutes.postDetail}/${item.post.id}');

  void _openGroup(BuildContext context) {
    if (item.group.id.isEmpty) return;
    context.push('${AppRoutes.groupDetail}/${item.group.id}');
  }

  void _openAuthor(BuildContext context) {
    final authorId = item.author?.id ?? item.post.authorId;
    if (authorId.trim().isEmpty) return;
    context.push(
      '${AppRoutes.publicProfile}/$authorId',
      extra: {'name': item.author?.displayName},
    );
  }

  Future<void> _share() async {
    final text = item.post.content.trim();
    await Share.share(
      '${text.isEmpty ? 'Bài viết từ ${AppConstants.appName}' : text}\n\n'
      '${AppConstants.publicAppBaseUrl}/posts/${item.post.id}',
      subject: 'Chia sẻ bài viết từ ${AppConstants.appName}',
    );
  }
}

/// Lưới ảnh: 1 ảnh tràn viền, 2 ảnh chia đôi, 3+ hiện lớp phủ "+N".
class _FeedImages extends StatelessWidget {
  const _FeedImages({required this.urls, required this.onTap});

  final List<String> urls;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (urls.length == 1) {
      return InkWell(
        onTap: onTap,
        child: _Thumb(url: urls.first, height: 220),
      );
    }

    if (urls.length == 2) {
      return InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(child: _Thumb(url: urls[0], height: 160)),
            const SizedBox(width: 2),
            Expanded(child: _Thumb(url: urls[1], height: 160)),
          ],
        ),
      );
    }

    final extra = urls.length - 3;
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          _Thumb(url: urls.first, height: 160),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(child: _Thumb(url: urls[1], height: 110)),
              const SizedBox(width: 2),
              Expanded(
                child: Stack(
                  fit: StackFit.passthrough,
                  children: [
                    _Thumb(url: urls[2], height: 110),
                    if (extra > 0)
                      Positioned.fill(
                        child: ColoredBox(
                          color: Colors.black.withValues(alpha: 0.45),
                          child: Center(
                            child: Text(
                              '+$extra',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.height});

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        height: height,
        color: colors.surfaceContainerHighest,
        child: Icon(
          Icons.broken_image_outlined,
          color: colors.onSurfaceVariant,
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          height: height,
          color: colors.surfaceContainerHighest,
        );
      },
    );
  }
}

class _FeedAction extends StatelessWidget {
  const _FeedAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// Tô màu nhấn khi đang ở trạng thái bật (ví dụ đã thích).
  final bool active;

  /// Thu gọn cho hàng chật (bên cạnh dòng nhắc tham gia nhóm).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tint = active ? colors.primary : colors.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 10,
          horizontal: compact ? 8 : 0,
        ),
        child: Row(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: tint),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: tint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút tham gia hội nhóm đặt cạnh tên nhóm.
///
/// Ẩn khi đã là thành viên; hiện chữ "Đang chờ" khi yêu cầu chưa được duyệt.
class _JoinGroupButton extends StatelessWidget {
  const _JoinGroupButton({required this.group, this.onJoinRequested});

  final FeedGroup group;
  final ValueChanged<String>? onJoinRequested;

  @override
  Widget build(BuildContext context) {
    if (group.isMember) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;

    if (group.isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hourglass_top_rounded,
              size: 13,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'Đang chờ',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (!group.canRequestJoin) return const SizedBox.shrink();

    return FilledButton.tonal(
      onPressed: () async {
        final joined = await showJoinGroupSheet(
          context,
          groupId: group.id,
          groupName: group.name,
        );
        if (joined == true) onJoinRequested?.call(group.id);
      },
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      child: const Text('Tham gia'),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (label, color) = switch (type) {
      'call_for_donation' => ('Kêu gọi quyên góp', colors.primary),
      'thank_you' => ('Cảm ơn', colors.tertiary),
      'announcement' => ('Thông báo', colors.secondary),
      _ => (type, colors.outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
