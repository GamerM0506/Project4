import 'dart:async';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Gắn Bearer token; khi 401 thì gọi `/auth/refresh` rồi retry request.
/// Dùng chung cho mọi Dio (identity, media, ...).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.prefs});

  final SharedPreferences prefs;

  static final Dio _refreshDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static bool _isRefreshing = false;
  static final List<Completer<bool>> _waitQueue = [];

  /// Gọi khi refresh thất bại (session hết) — app có thể điều hướng login.
  static void Function()? onSessionExpired;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = prefs.getString(AppConstants.keyAccessToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;
    final uri = err.requestOptions.uri.toString();

    final isAuthEndpoint =
        path.contains('/auth/login') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/register') ||
        uri.contains('/auth/login') ||
        uri.contains('/auth/refresh') ||
        uri.contains('/auth/register');

    if (status != 401 || isAuthEndpoint) {
      return handler.next(err);
    }

    // Đã retry 1 lần rồi thì thôi
    if (err.requestOptions.extra['retried'] == true) {
      await _forceLogout();
      return handler.next(err);
    }

    final ok = await _refreshTokens();
    if (!ok) {
      await _forceLogout();
      return handler.next(err);
    }

    try {
      final opts = err.requestOptions;
      final newToken = prefs.getString(AppConstants.keyAccessToken);
      if (newToken != null) {
        opts.headers['Authorization'] = 'Bearer $newToken';
      }
      opts.extra['retried'] = true;

      final dio = Dio(
        BaseOptions(
          baseUrl: opts.baseUrl,
          connectTimeout: opts.connectTimeout,
          receiveTimeout: opts.receiveTimeout,
          sendTimeout: opts.sendTimeout,
        ),
      );
      final response = await dio.fetch(opts);
      return handler.resolve(response);
    } catch (e) {
      if (e is DioException) {
        return handler.next(e);
      }
      return handler.next(err);
    }
  }

  Future<bool> _refreshTokens() async {
    if (_isRefreshing) {
      final c = Completer<bool>();
      _waitQueue.add(c);
      return c.future;
    }

    _isRefreshing = true;
    var success = false;

    try {
      final refreshToken = prefs.getString(AppConstants.keyRefreshToken);
      if (refreshToken == null || refreshToken.isEmpty) {
        success = false;
      } else {
        final res = await _refreshDio.post<Map<String, dynamic>>(
          '${AppConstants.authApiBaseUrl}/auth/refresh',
          data: {'refresh_token': refreshToken},
        );

        final body = res.data;
        final data = (body?['data'] is Map)
            ? Map<String, dynamic>.from(body!['data'] as Map)
            : body;

        final access = data?['access_token']?.toString();
        final refresh = data?['refresh_token']?.toString();

        if (access != null && access.isNotEmpty) {
          await prefs.setString(AppConstants.keyAccessToken, access);
          if (refresh != null && refresh.isNotEmpty) {
            await prefs.setString(AppConstants.keyRefreshToken, refresh);
          }
          success = true;
        } else {
          success = false;
        }
      }
    } catch (_) {
      success = false;
    } finally {
      _isRefreshing = false;
      for (final c in _waitQueue) {
        if (!c.isCompleted) c.complete(success);
      }
      _waitQueue.clear();
    }

    return success;
  }

  Future<void> _forceLogout() async {
    await prefs.remove(AppConstants.keyAccessToken);
    await prefs.remove(AppConstants.keyRefreshToken);
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyTwoFactorEnabled);
    onSessionExpired?.call();
  }
}
