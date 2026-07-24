import '../../domain/entities/auth_entity.dart';

class AuthModel extends AuthEntity {
  AuthModel({
    super.accessToken,
    super.refreshToken,
    super.userId,
    super.twoFactorRequired,
    super.challengeToken,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : null;
    final source = data ?? json;

    final twoFactor = source['two_factor_required'] == true;
    final challenge = source['challenge_token']?.toString();

    return AuthModel(
      accessToken: source['access_token']?.toString(),
      refreshToken: source['refresh_token']?.toString(),
      userId: (source['user_id'] ?? source['sub'])?.toString(),
      twoFactorRequired: twoFactor ||
          (challenge != null && challenge.isNotEmpty),
      challengeToken: challenge,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'user_id': userId,
      'two_factor_required': twoFactorRequired,
      'challenge_token': challengeToken,
    };
  }
}
