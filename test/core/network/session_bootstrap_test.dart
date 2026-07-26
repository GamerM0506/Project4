import 'package:flutter_test/flutter_test.dart';
import 'package:project4_chosv/core/constants/app_constants.dart';
import 'package:project4_chosv/core/network/session_bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('keeps a persistent session at cold start', () async {
    SharedPreferences.setMockInitialValues({
      AppConstants.keyRememberMe: true,
      AppConstants.keyAccessToken: 'access',
      AppConstants.keyRefreshToken: 'refresh',
      AppConstants.keyUserId: 'user-1',
      AppConstants.keyTwoFactorEnabled: true,
      AppConstants.keySessionGeneration: 4,
    });
    final preferences = await SharedPreferences.getInstance();

    await SessionBootstrap.clearNonPersistentSession(preferences);

    expect(preferences.getString(AppConstants.keyAccessToken), 'access');
    expect(preferences.getString(AppConstants.keyRefreshToken), 'refresh');
    expect(preferences.getString(AppConstants.keyUserId), 'user-1');
    expect(preferences.getInt(AppConstants.keySessionGeneration), 4);
  });

  test('clears a nonpersistent session at cold start', () async {
    SharedPreferences.setMockInitialValues({
      AppConstants.keyRememberMe: false,
      AppConstants.keyAccessToken: 'access',
      AppConstants.keyRefreshToken: 'refresh',
      AppConstants.keyUserId: 'user-1',
      AppConstants.keyTwoFactorEnabled: true,
      AppConstants.keySessionGeneration: 4,
      AppConstants.keyRememberedIdentifier: 'old@example.com',
    });
    final preferences = await SharedPreferences.getInstance();

    await SessionBootstrap.clearNonPersistentSession(preferences);

    expect(preferences.getString(AppConstants.keyAccessToken), isNull);
    expect(preferences.getString(AppConstants.keyRefreshToken), isNull);
    expect(preferences.getString(AppConstants.keyUserId), isNull);
    expect(preferences.getBool(AppConstants.keyTwoFactorEnabled), isNull);
    expect(preferences.getInt(AppConstants.keySessionGeneration), isNull);
    expect(preferences.getBool(AppConstants.keyRememberMe), isFalse);
    expect(
      preferences.getString(AppConstants.keyRememberedIdentifier),
      'old@example.com',
    );
  });
}
