import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/app_routes.dart';
import '../domain/repositories/notification_repository.dart';
import 'notification_navigator.dart';

class PushNotificationService {
  static const androidChannelId = 'chosv_high_importance';

  PushNotificationService({
    required NotificationRepository repository,
    required SharedPreferences preferences,
    required NotificationNavigator navigator,
  }) : _repository = repository,
       _preferences = preferences,
       _navigator = navigator;

  final NotificationRepository _repository;
  final SharedPreferences _preferences;
  final NotificationNavigator _navigator;

  RemoteMessage? _pendingMessage;
  bool _firebaseReady = false;
  bool _initialized = false;
  bool _registering = false;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize({required bool firebaseReady}) async {
    if (_initialized) return;
    _initialized = true;
    _firebaseReady = firebaseReady && _supportsFirebaseMessaging;
    if (!_firebaseReady) return;

    await _initializeLocalNotifications();
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
    FirebaseMessaging.instance.onTokenRefresh.listen(_handleTokenRefresh);
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
    _pendingMessage = await FirebaseMessaging.instance.getInitialMessage();
  }

  Future<void> onAuthenticated() async {
    if (!_firebaseReady || _registering) return;
    final userId = _preferences.getString(AppConstants.keyUserId);
    final accessToken = _preferences.getString(AppConstants.keyAccessToken);
    if (userId == null ||
        userId.isEmpty ||
        accessToken == null ||
        accessToken.isEmpty) {
      return;
    }

    _registering = true;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint(
          'FCM notification permission denied. Enable notifications in system settings.',
        );
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _registerToken(token, userId);
      }
      await _openPendingMessage();
    } catch (error) {
      debugPrint('FCM registration failed: $error');
    } finally {
      _registering = false;
    }
  }

  Future<void> unregisterBeforeLogout() async {
    String? token = _preferences.getString(AppConstants.keyFcmToken);
    if ((token == null || token.isEmpty) && _firebaseReady) {
      try {
        token = await FirebaseMessaging.instance.getToken();
      } catch (error) {
        debugPrint('Could not read FCM token during logout: $error');
      }
    }

    if (token != null && token.isNotEmpty) {
      final result = await _repository.unregisterDeviceToken(token);
      result.fold(
        (failure) => debugPrint('FCM token unregister failed: $failure'),
        (_) {},
      );
    }
    if (_firebaseReady) {
      try {
        await FirebaseMessaging.instance.deleteToken();
      } catch (error) {
        debugPrint('Could not delete FCM token during logout: $error');
      }
    }
    await _clearTokenBinding();
  }

  Future<void> onSessionEnded() async {
    _pendingMessage = null;
    await _preferences.remove(AppConstants.keyFcmTokenUserId);
  }

  Future<void> _handleTokenRefresh(String token) async {
    final userId = _preferences.getString(AppConstants.keyUserId);
    final accessToken = _preferences.getString(AppConstants.keyAccessToken);
    if (userId == null ||
        userId.isEmpty ||
        accessToken == null ||
        accessToken.isEmpty) {
      return;
    }
    final previousToken = _preferences.getString(AppConstants.keyFcmToken);
    if (previousToken != null &&
        previousToken.isNotEmpty &&
        previousToken != token) {
      final result = await _repository.unregisterDeviceToken(previousToken);
      result.fold(
        (failure) => debugPrint('Old FCM token unregister failed: $failure'),
        (_) {},
      );
    }
    await _registerToken(token, userId);
  }

  Future<void> _registerToken(String token, String userId) async {
    final registeredToken = _preferences.getString(AppConstants.keyFcmToken);
    final registeredUserId = _preferences.getString(
      AppConstants.keyFcmTokenUserId,
    );
    if (registeredToken == token && registeredUserId == userId) return;

    final result = await _repository.registerDeviceToken(token, _platformName);
    await result.fold(
      (failure) async => debugPrint('FCM token registration failed: $failure'),
      (_) async {
        await _preferences.setString(AppConstants.keyFcmToken, token);
        await _preferences.setString(AppConstants.keyFcmTokenUserId, userId);
      },
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _showLocalNotification(message);
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    final title = message.notification?.title ?? 'Thông báo mới';
    final body = message.notification?.body ?? '';
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(body.isEmpty ? title : '$title\n$body'),
        action: SnackBarAction(
          label: 'Mở',
          onPressed: () => _openMessage(message),
        ),
      ),
    );
  }

  Future<void> _initializeLocalNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (_) async {
        final message = _pendingMessage;
        if (message != null) await _openMessage(message);
      },
    );

    const channel = AndroidNotificationChannel(
      androidChannelId,
      'Thông báo quan trọng',
      description: 'Thông báo tin nhắn và hoạt động quan trọng từ Chợ Tử Tế.',
      importance: Importance.max,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    _pendingMessage = message;
    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannelId,
          'Thông báo quan trọng',
          channelDescription:
              'Thông báo tin nhắn và hoạt động quan trọng từ Chợ Tử Tế.',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> _handleOpenedMessage(RemoteMessage message) async {
    if (!_hasAuthenticatedSession) {
      _pendingMessage = message;
      return;
    }
    await _openMessage(message);
  }

  Future<void> _openPendingMessage() async {
    final message = _pendingMessage;
    if (message == null || !_hasAuthenticatedSession) return;
    _pendingMessage = null;
    await _openMessage(message);
  }

  Future<void> _openMessage(RemoteMessage message) async {
    final data = message.data;
    final opened = await _navigator.open(
      refType: data['refType'] ?? data['ref_type'],
      refId: data['refId'] ?? data['ref_id'],
      title: message.notification?.title,
    );
    if (!opened) await appRouter.push(AppRoutes.notifications);
  }

  Future<void> _clearTokenBinding() async {
    await _preferences.remove(AppConstants.keyFcmToken);
    await _preferences.remove(AppConstants.keyFcmTokenUserId);
  }

  bool get _hasAuthenticatedSession {
    final accessToken = _preferences.getString(AppConstants.keyAccessToken);
    return accessToken != null && accessToken.isNotEmpty;
  }

  bool get _supportsFirebaseMessaging {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  String get _platformName => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'ios',
    _ => 'android',
  };
}
