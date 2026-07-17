import '../../domain/entities/post_entity.dart';

class PostModel extends PostEntity {
  PostModel({
    required super.id,
    required super.groupId,
    required super.authorId,
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
    List<String> imageUrlsList = [];
    if (images != null) {
      for (var img in images) {
        if (img is Map<String, dynamic> && img['image_url'] != null) {
          imageUrlsList.add(img['image_url'] as String);
        }
      }
    }

    return PostModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      authorId: json['author_id'] as String,
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
}
