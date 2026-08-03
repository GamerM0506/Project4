import '../../../post/data/models/post_model.dart';

/// Hội nhóm gắn kèm mỗi bài trong feed tổng hợp.
class FeedGroup {
  const FeedGroup({
    required this.id,
    required this.name,
    this.slug,
    this.avatarUrl,
    this.myRole,
    this.myStatus,
  });

  final String id;
  final String name;
  final String? slug;
  final String? avatarUrl;

  /// Vai trò/trạng thái của người đang xem với nhóm. null = chưa tham gia.
  final String? myRole;
  final String? myStatus;

  bool get isMember => myStatus == 'approved' || myRole == 'owner';

  /// Đã gửi yêu cầu, đang chờ hội nhóm duyệt.
  bool get isPending => myStatus == 'pending';

  /// Có nên mời tham gia không. Người bị cấm thì không mời.
  bool get canRequestJoin =>
      !isMember && !isPending && myStatus != 'banned' && id.isNotEmpty;

  factory FeedGroup.fromJson(Map<String, dynamic> json) {
    return FeedGroup(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Hội nhóm',
      slug: json['slug']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      myRole: json['my_role']?.toString(),
      myStatus: json['my_status']?.toString(),
    );
  }

  FeedGroup copyWith({String? myRole, String? myStatus}) => FeedGroup(
    id: id,
    name: name,
    slug: slug,
    avatarUrl: avatarUrl,
    myRole: myRole ?? this.myRole,
    myStatus: myStatus ?? this.myStatus,
  );
}

/// Người viết bài, nạp kèm từ backend.
class FeedAuthor {
  const FeedAuthor({
    required this.id,
    this.fullName,
    this.username,
    this.avatarUrl,
  });

  final String id;
  final String? fullName;
  final String? username;
  final String? avatarUrl;

  /// Tên hiển thị, ưu tiên họ tên rồi đến username.
  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final handle = username?.trim();
    if (handle != null && handle.isNotEmpty) return '@$handle';
    return 'Người dùng';
  }

  factory FeedAuthor.fromJson(Map<String, dynamic> json) {
    return FeedAuthor(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString(),
      username: json['username']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
    );
  }
}

/// Bài viết trong feed trang chủ.
///
/// Backend `GET /community/feed` trả kèm thông tin nhóm, tác giả, trạng thái
/// thành viên và trạng thái thích, nên dựng được thẻ bài viết mà không cần
/// request nào thêm.
class FeedPostModel {
  const FeedPostModel({
    required this.post,
    required this.group,
    this.author,
    this.isLiked = false,
    this.canInteract = false,
  });

  final PostModel post;
  final FeedGroup group;

  /// null khi identity-service không phản hồi — bài viết vẫn hiển thị được.
  final FeedAuthor? author;

  /// Người xem đã thích bài này chưa.
  final bool isLiked;

  /// Được phép thích/bình luận không. Backend yêu cầu là thành viên đã duyệt.
  final bool canInteract;

  factory FeedPostModel.fromJson(Map<String, dynamic> json) {
    final rawGroup = json['group'];
    final rawAuthor = json['author'];
    return FeedPostModel(
      post: PostModel.fromJson(json),
      group: rawGroup is Map
          ? FeedGroup.fromJson(Map<String, dynamic>.from(rawGroup))
          : FeedGroup(
              id: json['group_id']?.toString() ?? '',
              name: 'Hội nhóm',
            ),
      author: rawAuthor is Map
          ? FeedAuthor.fromJson(Map<String, dynamic>.from(rawAuthor))
          : null,
      isLiked: json['is_liked'] as bool? ?? false,
      canInteract: json['can_interact'] as bool? ?? false,
    );
  }

  FeedPostModel copyWith({
    PostModel? post,
    FeedGroup? group,
    FeedAuthor? author,
    bool? isLiked,
    bool? canInteract,
  }) {
    return FeedPostModel(
      post: post ?? this.post,
      group: group ?? this.group,
      author: author ?? this.author,
      isLiked: isLiked ?? this.isLiked,
      canInteract: canInteract ?? this.canInteract,
    );
  }
}
