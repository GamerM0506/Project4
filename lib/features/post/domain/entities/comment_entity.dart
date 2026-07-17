class CommentEntity {
  final String id;
  final String content;
  final String authorId;
  final String? authorName;
  final String? authorAvatar;
  final DateTime createdAt;

  CommentEntity({
    required this.id,
    required this.content,
    required this.authorId,
    this.authorName,
    this.authorAvatar,
    required this.createdAt,
  });
}
