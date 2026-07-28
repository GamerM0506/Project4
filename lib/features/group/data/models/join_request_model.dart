import '../../domain/entities/join_request_entity.dart';

class JoinRequestModel extends JoinRequestEntity {
  JoinRequestModel({
    required super.id,
    required super.groupId,
    required super.userId,
    super.userName,
    super.userAvatar,
    super.message,
    required super.status,
    super.reviewedBy,
    super.reviewedAt,
    required super.createdAt,
  });

  factory JoinRequestModel.fromJson(Map<String, dynamic> json) {
    return JoinRequestModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      userName:
          json['user_name'] as String? ??
          (json['user'] != null
              ? json['user']['name'] ?? json['user']['full_name']
              : null),
      userAvatar:
          json['user_avatar'] as String? ??
          (json['user'] != null ? json['user']['avatar_url'] : null),
      message: json['message'] as String?,
      status: json['status'] as String,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  JoinRequestModel withProfile({String? name, String? avatarUrl}) {
    return JoinRequestModel(
      id: id,
      groupId: groupId,
      userId: userId,
      userName: name ?? userName,
      userAvatar: avatarUrl ?? userAvatar,
      message: message,
      status: status,
      reviewedBy: reviewedBy,
      reviewedAt: reviewedAt,
      createdAt: createdAt,
    );
  }
}
