class PostEntity {
  final String id;
  final String groupId;
  final String authorId;

  /// Tên hiển thị và avatar người viết; backend nạp từ identity-service nên
  /// có thể null khi dịch vụ đó không phản hồi.
  final String? authorName;
  final String? authorAvatar;

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
    this.authorName,
    this.authorAvatar,
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

  /// Tên để hiển thị, lùi về mã rút gọn khi chưa có hồ sơ tác giả.
  String get displayAuthorName {
    final name = authorName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final id = authorId.trim();
    return id.length >= 4 ? 'Người dùng ${id.substring(0, 4)}' : 'Người dùng';
  }

  PostEntity copyWith({
    String? id,
    String? groupId,
    String? authorId,
    String? authorName,
    String? authorAvatar,
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
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
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
