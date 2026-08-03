import '../../domain/entities/comment_entity.dart';

class CommentModel extends CommentEntity {
  CommentModel({
    required super.id,
    required super.content,
    required super.authorId,
    super.authorName,
    super.authorAvatar,
    super.parentId,
    required super.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    // Backend trả khối `author` (full_name/username/avatar_url); giữ thêm
    // author_name/author_avatar phẳng cho tương thích ngược.
    final author = json['author'];
    String? name;
    String? avatar;
    if (author is Map) {
      final full = author['full_name']?.toString().trim();
      final handle = author['username']?.toString().trim();
      name = (full != null && full.isNotEmpty)
          ? full
          : (handle != null && handle.isNotEmpty ? '@$handle' : null);
      avatar = author['avatar_url']?.toString();
    }

    return CommentModel(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      authorId: json['author_id']?.toString() ?? '',
      authorName: name ?? json['author_name']?.toString(),
      authorAvatar: avatar ?? json['author_avatar']?.toString(),
      parentId: json['parent_id']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      if (parentId != null) 'parent_id': parentId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
