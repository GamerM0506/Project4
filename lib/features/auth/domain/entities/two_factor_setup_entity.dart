class TwoFactorSetupEntity {
  final String secret;
  final String otpauthUrl;

  const TwoFactorSetupEntity({
    required this.secret,
    required this.otpauthUrl,
  });
}
