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

    final accessToken = (data?['access_token'] ?? json['access_token'])
        ?.toString();
    final refreshToken = (data?['refresh_token'] ?? json['refresh_token'])
        ?.toString();
    final twoFactorRequired =
        (data?['two_factor_required'] ?? json['two_factor_required']) == true;
    final challengeToken = (data?['challenge_token'] ?? json['challenge_token'])
        ?.toString();

    if (twoFactorRequired) {
      if (challengeToken == null || challengeToken.isEmpty) {
        throw const FormatException('Phản hồi 2FA thiếu challenge token.');
      }
    } else if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      throw const FormatException('Phản hồi đăng nhập thiếu token bắt buộc.');
    }

    return AuthModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: (data?['user_id'] ?? json['user_id'] ?? data?['sub'])?.toString(),
      twoFactorRequired: twoFactorRequired,
      challengeToken: challengeToken,
    );
  }

  factory AuthModel.fromRegistrationJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map || data['id'] == null) {
      throw const FormatException('Phản hồi đăng ký không hợp lệ.');
    }
    return AuthModel(userId: data['id'].toString());
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
