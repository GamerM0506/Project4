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
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      coverUrl: json['cover_url']?.toString(),
      address: json['address']?.toString(),
      provinceCode: json['province_code']?.toString(),
      districtCode: json['district_code']?.toString(),
      ownerId: json['owner_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      allowMemberPost: json['allow_member_post'] as bool? ?? true,
      requirePostReview: json['require_post_review'] as bool? ?? false,
      memberCount: json['member_count'] is int
          ? json['member_count'] as int
          : int.tryParse(json['member_count']?.toString() ?? '') ?? 0,
      reputationScore: json['reputation_score'] is int
          ? json['reputation_score'] as int
          : int.tryParse(json['reputation_score']?.toString() ?? '') ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      myRole: json['my_role']?.toString(),
      myStatus: json['my_status']?.toString(),
    );
  }

  GroupModel copyWith({
    String? myRole,
    String? myStatus,
    int? memberCount,
  }) {
    return GroupModel(
      id: id,
      name: name,
      slug: slug,
      description: description,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
      address: address,
      provinceCode: provinceCode,
      districtCode: districtCode,
      ownerId: ownerId,
      status: status,
      allowMemberPost: allowMemberPost,
      requirePostReview: requirePostReview,
      memberCount: memberCount ?? this.memberCount,
      reputationScore: reputationScore,
      createdAt: createdAt,
      updatedAt: updatedAt,
      myRole: myRole ?? this.myRole,
      myStatus: myStatus ?? this.myStatus,
    );
  }

  bool get isApprovedMember =>
      myStatus == 'approved' || myRole == 'owner' || myRole == 'moderator';

  bool get isJoinPending => myStatus == 'pending';

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
