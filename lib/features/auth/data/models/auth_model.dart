import '../../domain/entities/auth_entity.dart';

class AuthModel extends AuthEntity {
  AuthModel({
    super.accessToken,
    super.refreshToken,
    super.userId,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : null;

    return AuthModel(
      accessToken:
          (data?['access_token'] ?? json['access_token'])?.toString(),
      refreshToken:
          (data?['refresh_token'] ?? json['refresh_token'])?.toString(),
      userId: (data?['user_id'] ?? json['user_id'] ?? data?['sub'])
          ?.toString(),
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
