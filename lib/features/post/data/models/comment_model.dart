import '../../domain/entities/comment_entity.dart';

class CommentModel extends CommentEntity {
  CommentModel({
    required String id,
    required String content,
    required String authorId,
    String? authorName,
    String? authorAvatar,
    required DateTime createdAt,
  }) : super(
          id: id,
          content: content,
          authorId: authorId,
          authorName: authorName,
          authorAvatar: authorAvatar,
          createdAt: createdAt,
        );

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      authorId: json['author_id'] ?? '',
      authorName: json['author_name'],
      authorAvatar: json['author_avatar'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
