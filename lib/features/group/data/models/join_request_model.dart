import '../../domain/entities/join_request_entity.dart';

class JoinRequestModel extends JoinRequestEntity {
  JoinRequestModel({
    required super.id,
    required super.groupId,
    required super.userId,
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
      message: json['message'] as String?,
      status: json['status'] as String,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
