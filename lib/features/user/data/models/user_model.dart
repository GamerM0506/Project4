import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.fullName,
    super.email,
    super.phone,
    super.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    
    return UserModel(
      id: data['id']?.toString() ?? '',
      fullName: data['full_name'] ?? data['name'] ?? 'Người dùng',
      email: data['email'],
      phone: data['phone'],
      avatar: data['avatar'] ?? data['profile_picture'],
    );
  }
}
