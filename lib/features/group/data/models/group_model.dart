class GroupModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? avatarUrl;
  final String? coverUrl;
  final String? address;
  final String? provinceCode;
  final String? districtCode;
  final String ownerId;
  final String status;
  final bool allowMemberPost;
  final bool requirePostReview;
  final int memberCount;
  final int reputationScore;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? myRole;
  final String? myStatus;

  GroupModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.avatarUrl,
    this.coverUrl,
    this.address,
    this.provinceCode,
    this.districtCode,
    required this.ownerId,
    required this.status,
    required this.allowMemberPost,
    required this.requirePostReview,
    required this.memberCount,
    required this.reputationScore,
    required this.createdAt,
    required this.updatedAt,
    this.myRole,
    this.myStatus,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      address: json['address'] as String?,
      provinceCode: json['province_code'] as String?,
      districtCode: json['district_code'] as String?,
      ownerId: json['owner_id'] as String,
      status: json['status'] as String,
      allowMemberPost: json['allow_member_post'] as bool? ?? true,
      requirePostReview: json['require_post_review'] as bool? ?? false,
      memberCount: json['member_count'] as int? ?? 0,
      reputationScore: json['reputation_score'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      myRole: json['my_role'] as String?,
      myStatus: json['my_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'avatar_url': avatarUrl,
      'cover_url': coverUrl,
      'address': address,
      'province_code': provinceCode,
      'district_code': districtCode,
      'owner_id': ownerId,
      'status': status,
      'allow_member_post': allowMemberPost,
      'require_post_review': requirePostReview,
      'member_count': memberCount,
      'reputation_score': reputationScore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (myRole != null) 'my_role': myRole,
      if (myStatus != null) 'my_status': myStatus,
    };
  }
}
