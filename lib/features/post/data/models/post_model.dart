import '../../domain/entities/post_entity.dart';

class PostModel extends PostEntity {
  PostModel({
    required super.id,
    required super.groupId,
    required super.authorId,
    super.authorName,
    super.authorAvatar,
    required super.content,
    required super.type,
    super.refId,
    required super.status,
    required super.isPinned,
    required super.likeCount,
    required super.commentCount,
    required super.isLiked,
    required super.imageUrls,
    required super.createdAt,
    required super.updatedAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>?;
    final imageUrlsList = <String>[];
    if (images != null) {
      for (final img in images) {
        if (img is Map && img['image_url'] != null) {
          imageUrlsList.add(img['image_url'].toString());
        }
      }
    }

    // Backend trả khối `author` (full_name/username/avatar_url).
    final author = json['author'];
    String? authorName;
    String? authorAvatar;
    if (author is Map) {
      final full = author['full_name']?.toString().trim();
      final handle = author['username']?.toString().trim();
      authorName = (full != null && full.isNotEmpty)
          ? full
          : (handle != null && handle.isNotEmpty ? '@$handle' : null);
      authorAvatar = author['avatar_url']?.toString();
    }

    return PostModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      authorId: json['author_id'] as String,
      authorName: authorName,
      authorAvatar: authorAvatar,
      content: json['content'] as String,
      type: json['type'] as String,
      refId: json['ref_id'] as String?,
      status: json['status'] as String,
      isPinned: json['is_pinned'] as bool? ?? false,
      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      imageUrls: imageUrlsList,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Bản sao chỉ đổi trạng thái thích — dùng cho cập nhật lạc quan ở feed.
  PostModel copyWithLike({required bool isLiked, required int likeCount}) {
    return PostModel(
      id: id,
      groupId: groupId,
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      content: content,
      type: type,
      refId: refId,
      status: status,
      isPinned: isPinned,
      likeCount: likeCount,
      commentCount: commentCount,
      isLiked: isLiked,
      imageUrls: imageUrls,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
