class GroupModel {
  final String id;
  final String name;
  final String location;
  final int memberCount;
  final String? imageUrl;

  /// Ảnh bìa riêng, dùng làm nền thẻ; khác [imageUrl] vốn ưu tiên avatar.
  final String? coverUrl;

  /// Giới thiệu ngắn hiển thị trên thẻ.
  final String? description;

  /// Trạng thái thành viên của người đang xem: null nếu chưa tham gia.
  final String? myStatus;
  final String? myRole;

  GroupModel({
    required this.id,
    required this.name,
    required this.location,
    required this.memberCount,
    required this.imageUrl,
    this.coverUrl,
    this.description,
    this.myStatus,
    this.myRole,
  });

  bool get isMember => myStatus == 'approved' || myRole == 'owner';
  bool get isPending => myStatus == 'pending';

  /// Chỉ mời tham gia khi thật sự chưa có quan hệ nào với nhóm.
  bool get canRequestJoin => !isMember && !isPending && myStatus != 'banned';

  GroupModel copyWith({String? myStatus}) => GroupModel(
    id: id,
    name: name,
    location: location,
    memberCount: memberCount,
    imageUrl: imageUrl,
    coverUrl: coverUrl,
    description: description,
    myStatus: myStatus ?? this.myStatus,
    myRole: myRole,
  );

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    final avatarUrl = _validImageUrl(json['avatar_url']);
    final coverUrl = _validImageUrl(json['cover_url']);
    final description = json['description']?.toString().trim();
    return GroupModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Hội nhóm chưa đặt tên',
      location: json['address'] ?? json['province_code'] ?? 'Chưa có địa điểm',
      memberCount: json['member_count'] ?? 0,
      imageUrl: avatarUrl ?? coverUrl,
      coverUrl: coverUrl,
      description: description?.isEmpty ?? true ? null : description,
      myStatus: json['my_status']?.toString(),
      myRole: json['my_role']?.toString(),
    );
  }

  static String? _validImageUrl(dynamic value) {
    final url = value?.toString().trim() ?? '';
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    return url;
  }
}
