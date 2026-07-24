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
      id: json['id']?.toString() ?? '',
      groupId: json['group_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      message: json['message']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      reviewedBy: json['reviewed_by']?.toString(),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'].toString())
          : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
