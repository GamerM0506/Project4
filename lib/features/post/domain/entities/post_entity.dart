class PostEntity {
  final String id;
  final String groupId;
  final String authorId;
  final String content;
  final String type; // normal, call_for_donation, thank_you, announcement
  final String? refId;
  final String status;
  final bool isPinned;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  PostEntity({
    required this.id,
    required this.groupId,
    required this.authorId,
    required this.content,
    required this.type,
    this.refId,
    required this.status,
    required this.isPinned,
    required this.likeCount,
    required this.commentCount,
    this.isLiked = false,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  PostEntity copyWith({
    String? id,
    String? groupId,
    String? authorId,
    String? content,
    String? type,
    String? refId,
    String? status,
    bool? isPinned,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostEntity(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      type: type ?? this.type,
      refId: refId ?? this.refId,
      status: status ?? this.status,
      isPinned: isPinned ?? this.isPinned,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
