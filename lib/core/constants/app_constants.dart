class AppConstants {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://161.118.247.84:8000/api',
  );
  static const String publicAppBaseUrl = String.fromEnvironment(
    'APP_PUBLIC_URL',
    defaultValue: 'https://chosv.vn',
  );

  static String get socketBaseUrl {
    final uri = Uri.parse(apiBaseUrl);
    return uri.replace(path: '', query: null, fragment: null).toString();
  }

  static String get apiHost => Uri.parse(apiBaseUrl).host;

  static const String authApiBaseUrl = '$apiBaseUrl/identity';
  static const String mediaApiBaseUrl = '$apiBaseUrl/media';
  static const String productApiBaseUrl = '$apiBaseUrl/product';
  static const String chatApiBaseUrl = '$apiBaseUrl/communication';
  static const String communityApiBaseUrl = '$apiBaseUrl/community';
  static const String donationApiBaseUrl = '$apiBaseUrl/donation';
  static const String aiApiBaseUrl = '$apiBaseUrl/ai';

  static const String supportEmail = 'support@chosv.vn';
  static const String supportPhone = '1900 1000';

  static const String keyAccessToken = 'ACCESS_TOKEN';
  static const String keyRefreshToken = 'REFRESH_TOKEN';
  static const String keyUserId = 'USER_ID';
  static const String keyTwoFactorEnabled = 'TWO_FACTOR_ENABLED';
  static const String keySessionGeneration = 'SESSION_GENERATION';
  static const String keyRememberMe = 'REMEMBER_ME';
  static const String keyRememberedIdentifier = 'REMEMBERED_IDENTIFIER';
  static const String keyFcmToken = 'FCM_TOKEN';
  static const String keyFcmTokenUserId = 'FCM_TOKEN_USER_ID';

  static const String appName = 'Chợ Tử Tế';
}
