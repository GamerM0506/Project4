import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/post_entity.dart';
import '../cubit/post_comments_cubit.dart';
import '../cubit/post_detail_cubit.dart';

/// Trang chi tiết một bài viết: nội dung đầy đủ + danh sách bình luận inline.
class PostDetailPage extends StatelessWidget {
  const PostDetailPage({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<PostDetailCubit>()..load(postId)),
        BlocProvider(
          create: (_) => sl<PostCommentsCubit>()..fetchComments(postId),
        ),
      ],
      child: _PostDetailView(postId: postId),
    );
  }
}

class _PostDetailView extends StatefulWidget {
  const _PostDetailView({required this.postId});

  final String postId;

  @override
  State<_PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<_PostDetailView> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  bool _sending = false;

  /// Bình luận đang được trả lời; null = bình luận gốc.
  CommentEntity? _replyTo;

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  void _startReply(CommentEntity comment) {
    setState(() => _replyTo = comment);
    _commentFocus.requestFocus();
  }

  void _cancelReply() => setState(() => _replyTo = null);

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    final added = await context.read<PostCommentsCubit>().addComment(
      widget.postId,
      text,
      // Trả lời của trả lời vẫn gắn vào bình luận gốc: backend chỉ hỗ trợ
      // một cấp lồng nhau.
      parentId: _replyTo?.parentId ?? _replyTo?.id,
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (added) _replyTo = null;
    });

    if (added) {
      _commentController.clear();
      context.read<PostDetailCubit>().incrementCommentCount();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài viết'),
        centerTitle: true,
        actions: [
          BlocBuilder<PostDetailCubit, PostDetailState>(
            builder: (context, state) {
              final post = state.post;
              if (post == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Chia sẻ',
                onPressed: () => _sharePost(post),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<PostDetailCubit, PostDetailState>(
        builder: (context, state) {
          return switch (state.status) {
            PostDetailStatus.initial ||
            PostDetailStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            PostDetailStatus.error => AppEmptyState(
              icon: Icons.article_outlined,
              title: 'Không tải được bài viết',
              message: state.errorMessage,
              isError: true,
              actionLabel: 'Thử lại',
              onAction: () =>
                  context.read<PostDetailCubit>().load(widget.postId),
            ),
            PostDetailStatus.loaded => Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await Future.wait([
                        context.read<PostDetailCubit>().load(widget.postId),
                        context.read<PostCommentsCubit>().fetchComments(
                          widget.postId,
                        ),
                      ]);
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        _PostBody(post: state.post!),
                        const SizedBox(height: 24),
                        Text(
                          'Bình luận',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        _CommentsList(onReply: _startReply),
                      ],
                    ),
                  ),
                ),
                _CommentComposer(
                  controller: _commentController,
                  focusNode: _commentFocus,
                  sending: _sending,
                  replyTo: _replyTo,
                  onCancelReply: _cancelReply,
                  onSubmit: _submitComment,
                  surfaceColor: colors.surface,
                ),
              ],
            ),
          };
        },
      ),
    );
  }

  Future<void> _sharePost(PostEntity post) async {
    final text = post.content.trim();
    await Share.share(
      '${text.isEmpty ? 'Bài viết từ ${AppConstants.appName}' : text}\n\n'
      '${AppConstants.publicAppBaseUrl}/posts/${post.id}',
      subject: 'Chia sẻ bài viết từ ${AppConstants.appName}',
    );
  }
}

class _PostBody extends StatelessWidget {
  const _PostBody({required this.post});

  final PostEntity post;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => _openAuthor(context),
              customBorder: const CircleBorder(),
              child: AppAvatar(
                imageUrl: post.authorAvatar,
                name: post.displayAuthorName,
                radius: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => _openAuthor(context),
                    child: Text(
                      post.displayAuthorName,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                      if (post.isPinned) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.push_pin,
                          size: 14,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (post.type != 'normal') _TypeChip(type: post.type),
          ],
        ),
        const SizedBox(height: 16),
        SelectableText(
          post.content,
          style: textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        if (post.imageUrls.isNotEmpty) ...[
          const SizedBox(height: 16),
          for (final url in post.imageUrls) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 160,
                  color: colors.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              post.isLiked ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: post.isLiked ? colors.primary : colors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text('${post.likeCount}', style: textTheme.bodyMedium),
            const SizedBox(width: 20),
            Icon(
              Icons.chat_bubble_outline,
              size: 18,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text('${post.commentCount}', style: textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 8),
        Divider(color: colors.outlineVariant),
      ],
    );
  }

  void _openAuthor(BuildContext context) {
    if (post.authorId.trim().isEmpty) return;
    context.push('${AppRoutes.publicProfile}/${post.authorId}');
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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

class _CommentsList extends StatelessWidget {
  const _CommentsList({required this.onReply});

  final ValueChanged<CommentEntity> onReply;

  /// Gom trả lời vào dưới bình luận gốc, giữ nguyên thứ tự thời gian.
  /// Trả lời mồ côi (mất bình luận cha) được hiển thị như bình luận gốc.
  List<({CommentEntity comment, bool isReply})> _threaded(
    List<CommentEntity> comments,
  ) {
    final repliesByParent = <String, List<CommentEntity>>{};
    final roots = <CommentEntity>[];
    final ids = comments.map((c) => c.id).toSet();

    for (final c in comments) {
      final parent = c.parentId;
      if (parent != null && parent.isNotEmpty && ids.contains(parent)) {
        repliesByParent.putIfAbsent(parent, () => []).add(c);
      } else {
        roots.add(c);
      }
    }

    return [
      for (final root in roots) ...[
        (comment: root, isReply: false),
        for (final reply in repliesByParent[root.id] ?? const [])
          (comment: reply, isReply: true),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostCommentsCubit, PostCommentsState>(
      builder: (context, state) {
        if (state is PostCommentsLoading || state is PostCommentsInitial) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is PostCommentsError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              state.message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }
        if (state is! PostCommentsLoaded) return const SizedBox.shrink();

        if (state.comments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Chưa có bình luận nào.\nHãy là người đầu tiên bình luận!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        final threaded = _threaded(state.comments);

        return Column(
          children: [
            for (final entry in threaded)
              Padding(
                padding: EdgeInsets.only(
                  bottom: 16,
                  left: entry.isReply ? 36 : 0,
                ),
                child: _CommentTile(
                  comment: entry.comment,
                  isReply: entry.isReply,
                  onReply: () => onReply(entry.comment),
                ),
              ),
            if (!state.hasReachedMax)
              TextButton(
                onPressed: state.isLoadingMore
                    ? null
                    : () => context.read<PostCommentsCubit>().loadMore(
                        (context.read<PostDetailCubit>().state.post?.id) ?? '',
                      ),
                child: state.isLoadingMore
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Xem thêm bình luận'),
              ),
          ],
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.onReply,
    this.isReply = false,
  });

  final CommentEntity comment;
  final VoidCallback onReply;
  final bool isReply;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name =
        comment.authorName ?? 'Người dùng ${_shortId(comment.authorId)}';

    void openAuthor() {
      if (comment.authorId.trim().isEmpty) return;
      context.push(
        '${AppRoutes.publicProfile}/${comment.authorId}',
        extra: {'name': comment.authorName},
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: openAuthor,
          customBorder: const CircleBorder(),
          child: AppAvatar(
            imageUrl: comment.authorAvatar,
            name: name,
            radius: isReply ? 14 : 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: openAuthor,
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(comment.content),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  children: [
                    Text(
                      timeago.format(comment.createdAt, locale: 'vi'),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 14),
                    InkWell(
                      onTap: onReply,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Text(
                          'Trả lời',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.replyTo,
    required this.onCancelReply,
    required this.onSubmit,
    required this.surfaceColor,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final CommentEntity? replyTo;
  final VoidCallback onCancelReply;
  final VoidCallback onSubmit;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final target = replyTo;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border(
            top: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (target != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.reply_rounded,
                      size: 15,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Đang trả lời '
                        '${target.authorName ?? 'Người dùng ${_shortId(target.authorId)}'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: onCancelReply,
                      borderRadius: BorderRadius.circular(99),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSubmit(),
                    decoration: InputDecoration(
                      hintText: target == null
                          ? 'Viết bình luận...'
                          : 'Viết câu trả lời...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: colors.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                sending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: Icon(Icons.send, color: colors.primary),
                        onPressed: onSubmit,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _shortId(String id) =>
    id.length >= 4 ? id.substring(0, 4) : id;
