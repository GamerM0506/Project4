class JoinRequestEntity {
  final String id;
  final String groupId;
  final String userId;
  final String? userName;
  final String? userAvatar;
  final String? message;
  final String status; // pending, approved, rejected
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  JoinRequestEntity({
    required this.id,
    required this.groupId,
    required this.userId,
    this.userName,
    this.userAvatar,
    this.message,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
  });
}
