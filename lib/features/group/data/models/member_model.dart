import '../../domain/entities/member_entity.dart';

class MemberModel extends MemberEntity {
  MemberModel({
    required super.id,
    required super.groupId,
    required super.userId,
    required super.role,
    required super.status,
    super.joinedAt,
    required super.createdAt,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      joinedAt: json['joined_at'] != null ? DateTime.parse(json['joined_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
