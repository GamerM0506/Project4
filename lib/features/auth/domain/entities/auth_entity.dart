class AuthEntity {
  final String? accessToken;
  final String? refreshToken;
  final String? userId;
  final bool twoFactorRequired;
  final String? challengeToken;

  AuthEntity({
    this.accessToken,
    this.refreshToken,
    this.userId,
    this.twoFactorRequired = false,
    this.challengeToken,
  });
}
