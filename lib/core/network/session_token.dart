import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

Map<String, dynamic>? decodeJwtPayload(String? token) {
  if (token == null || token.isEmpty) return null;
  try {
    final parts = token.split('.');
    if (parts.length != 3 || parts.any((part) => part.isEmpty)) return null;
    final decoded = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final payload = jsonDecode(decoded);
    return payload is Map ? Map<String, dynamic>.from(payload) : null;
  } catch (_) {
    return null;
  }
}

String? jwtSubject(String? token) {
  final subject = decodeJwtPayload(token)?['sub']?.toString();
  return normalizeUserId(subject);
}

/// Chuẩn hóa user id (UUID) để so khớp sender_id / JWT sub.
String? normalizeUserId(String? value) {
  if (value == null) return null;
  final normalized = value.trim().toLowerCase();
  return normalized.isEmpty ? null : normalized;
}

bool sameUserId(String? a, String? b) {
  final left = normalizeUserId(a);
  final right = normalizeUserId(b);
  if (left == null || right == null) return false;
  return left == right;
}

/// Ưu tiên JWT `sub` (nguồn đúng với sender_id backend), fallback prefs.
String? resolveCurrentUserId(SharedPreferences prefs) {
  final fromJwt = jwtSubject(prefs.getString(AppConstants.keyAccessToken));
  if (fromJwt != null) return fromJwt;
  return normalizeUserId(prefs.getString(AppConstants.keyUserId));
}

bool isUsableAccessToken(String? token, {DateTime? now}) {
  final payload = decodeJwtPayload(token);
  final subject = payload?['sub']?.toString();
  final expiration = payload?['exp'];
  final expirationSeconds = expiration is num
      ? expiration.toInt()
      : int.tryParse(expiration?.toString() ?? '');
  if (subject == null || subject.isEmpty || expirationSeconds == null) {
    return false;
  }
  final currentSeconds = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
  return expirationSeconds > currentSeconds;
}
