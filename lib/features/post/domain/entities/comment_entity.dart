class CommentEntity {
  final String id;
  final String content;
  final String authorId;
  final String? authorName;
  final String? authorAvatar;

  /// Bình luận cha khi đây là câu trả lời; null nếu là bình luận gốc.
  final String? parentId;

  final DateTime createdAt;

  CommentEntity({
    required this.id,
    required this.content,
    required this.authorId,
    this.authorName,
    this.authorAvatar,
    this.parentId,
    required this.createdAt,
  });

  bool get isReply => parentId != null && parentId!.isNotEmpty;
}
