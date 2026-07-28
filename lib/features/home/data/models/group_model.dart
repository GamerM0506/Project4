class GroupModel {
  final String id;
  final String name;
  final String location;
  final int memberCount;
  final String? imageUrl;

  GroupModel({
    required this.id,
    required this.name,
    required this.location,
    required this.memberCount,
    required this.imageUrl,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    final avatarUrl = _validImageUrl(json['avatar_url']);
    final coverUrl = _validImageUrl(json['cover_url']);
    return GroupModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Hội nhóm chưa đặt tên',
      location: json['address'] ?? json['province_code'] ?? 'Chưa có địa điểm',
      memberCount: json['member_count'] ?? 0,
      imageUrl: avatarUrl ?? coverUrl,
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
