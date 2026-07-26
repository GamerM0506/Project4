import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class SessionBootstrap {
  const SessionBootstrap._();

  static Future<void> clearNonPersistentSession(
    SharedPreferences preferences,
  ) async {
    final rememberMe = preferences.getBool(AppConstants.keyRememberMe) ?? true;
    if (rememberMe) return;

    await preferences.remove(AppConstants.keyAccessToken);
    await preferences.remove(AppConstants.keyRefreshToken);
    await preferences.remove(AppConstants.keyUserId);
    await preferences.remove(AppConstants.keyTwoFactorEnabled);
    await preferences.remove(AppConstants.keySessionGeneration);
  }
}
