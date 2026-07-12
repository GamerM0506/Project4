import '../../domain/entities/two_factor_setup_entity.dart';

class TwoFactorSetupModel extends TwoFactorSetupEntity {
  const TwoFactorSetupModel({
    required super.secret,
    required super.otpauthUrl,
  });

  factory TwoFactorSetupModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    return TwoFactorSetupModel(
      secret: data['secret']?.toString() ?? '',
      otpauthUrl: data['otpauth_url']?.toString() ?? '',
    );
  }
}
