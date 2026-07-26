import 'dart:convert';

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
  return subject == null || subject.isEmpty ? null : subject;
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
