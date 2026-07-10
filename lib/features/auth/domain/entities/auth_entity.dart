class AuthEntity {
  final String? accessToken;
  final String? refreshToken;
  final String? userId;

  AuthEntity({
    this.accessToken,
    this.refreshToken,
    this.userId,
  });
}
