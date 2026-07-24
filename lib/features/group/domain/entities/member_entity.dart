class MemberEntity {
  final String id;
  final String groupId;
  final String userId;
  final String? userName;
  final String? userAvatar;
  final String role; // owner, moderator, member
  final String status; // pending, approved, rejected, left, banned
  final DateTime? joinedAt;
  final DateTime createdAt;

  MemberEntity({
    required this.id,
    required this.groupId,
    required this.userId,
    this.userName,
    this.userAvatar,
    required this.role,
    required this.status,
    this.joinedAt,
    required this.createdAt,
  });
}
