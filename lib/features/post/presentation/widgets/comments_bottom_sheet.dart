import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/router/app_routes.dart';
import '../../../../injection_container.dart';
import '../cubit/post_comments_cubit.dart';

class CommentsBottomSheet extends StatefulWidget {
  final String postId;
  final VoidCallback? onCommentAdded;

  const CommentsBottomSheet({
    super.key,
    required this.postId,
    this.onCommentAdded,
  });

  static void show(
    BuildContext context,
    String postId, {
    VoidCallback? onCommentAdded,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CommentsBottomSheet(postId: postId, onCommentAdded: onCommentAdded),
    );
  }

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return BlocProvider(
      create: (_) => sl<PostCommentsCubit>()..fetchComments(widget.postId),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7 + keyboardHeight,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bình luận',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Comments List
            Expanded(
              child: BlocBuilder<PostCommentsCubit, PostCommentsState>(
                builder: (context, state) {
                  if (state is PostCommentsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is PostCommentsError) {
                    return Center(child: Text(state.message));
                  } else if (state is PostCommentsLoaded) {
                    final comments = state.comments;
                    if (comments.isEmpty) {
                      return const Center(
                        child: Text(
                          'Chưa có bình luận nào.\nHãy là người đầu tiên bình luận!',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.metrics.extentAfter < 200) {
                          context.read<PostCommentsCubit>().loadMore(
                            widget.postId,
                          );
                        }
                        return false;
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            comments.length + (state.isLoadingMore ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          if (index == comments.length) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final comment = comments[index];
                          void openAuthor() {
                            if (comment.authorId.trim().isEmpty) return;
                            Navigator.pop(context);
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
                                child: CircleAvatar(
                                  backgroundColor: colorScheme.primaryContainer,
                                  child: Text(
                                    comment.authorName != null
                                        ? comment.authorName![0].toUpperCase()
                                        : comment.authorId
                                              .substring(0, 2)
                                              .toUpperCase(),
                                    style: TextStyle(
                                      color: colorScheme.onPrimaryContainer,
                                      fontSize: 12,
                                    ),
                                  ),
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
                                        color: colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          InkWell(
                                            onTap: openAuthor,
                                            child: Text(
                                              comment.authorName ??
                                                  'Người dùng ${comment.authorId.substring(0, 4)}',
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
                                      child: Text(
                                        timeago.format(
                                          comment.createdAt,
                                          locale: 'vi',
                                        ),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),

            // Input Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Builder(
                builder: (ctx) {
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Viết bình luận...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.send, color: colorScheme.primary),
                        onPressed: () async {
                          final text = _commentController.text.trim();
                          if (text.isNotEmpty) {
                            final added = await ctx
                                .read<PostCommentsCubit>()
                                .addComment(widget.postId, text);
                            if (added) {
                              _commentController.clear();
                              widget.onCommentAdded?.call();
                            }
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
