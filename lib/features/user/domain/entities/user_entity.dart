class UserEntity {
  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? avatar;

  UserEntity({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.avatar,
  });
}
