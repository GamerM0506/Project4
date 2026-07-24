import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  static const String apiHost = '216.108.237.20';
  static const String apiBaseUrl = 'http://$apiHost:8000/api';

  static const String authApiBaseUrl = '$apiBaseUrl/identity';
  static const String mediaApiBaseUrl = '$apiBaseUrl/media';
  static const String productApiBaseUrl = '$apiBaseUrl/product';
  static const String chatApiBaseUrl = '$apiBaseUrl/communication';
  static const String communityApiBaseUrl = '$apiBaseUrl/community';
  static const String marketplaceApiBaseUrl = '$apiBaseUrl/marketplace';
  static const String donationApiBaseUrl = '$apiBaseUrl/donation';
  static const String aiApiBaseUrl = '$apiBaseUrl/ai';

  static const String supportEmail = 'support@chosv.vn';
  static const String supportPhone = '1900 1000';

  static const String keyAccessToken = 'ACCESS_TOKEN';
  static const String keyRefreshToken = 'REFRESH_TOKEN';
  static const String keyUserId = 'USER_ID';
  static const String keyTwoFactorEnabled = 'TWO_FACTOR_ENABLED';

  static const String appName = 'ChoSV';
}
