import '../../domain/entities/auth_entity.dart';

class AuthModel extends AuthEntity {
  AuthModel({
    super.accessToken,
    super.refreshToken,
    super.userId,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    // API có thể trả về trực tiếp trong json, hoặc bọc trong "data"
    final data = json['data'] as Map<String, dynamic>?;
    
    return AuthModel(
      accessToken: json['access_token'] ?? data?['access_token'],
      refreshToken: json['refresh_token'] ?? data?['refresh_token'],
      userId: json['user_id']?.toString() ?? data?['user_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'user_id': userId,
    };
  }
}
