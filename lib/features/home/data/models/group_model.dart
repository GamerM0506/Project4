class GroupModel {
  final String id;
  final String name;
  final String location;
  final int memberCount;
  final String imageUrl;

  GroupModel({
    required this.id,
    required this.name,
    required this.location,
    required this.memberCount,
    required this.imageUrl,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Group',
      location: json['address'] ?? json['province_code'] ?? 'Unknown Location',
      memberCount: json['member_count'] ?? 0,
      imageUrl: json['avatar_url'] ?? json['cover_url'] ?? 'https://via.placeholder.com/150',
    );
  }
}
