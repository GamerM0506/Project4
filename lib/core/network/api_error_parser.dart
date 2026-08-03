import 'package:dio/dio.dart';

String parseApiError(DioException exception, String fallback) {
  final body = exception.response?.data;
  if (body is Map) {
    final error = body['error'];
    final parsedError = _parseErrorValue(error);
    if (parsedError != null) return parsedError;

    final detail = _parseErrorValue(body['detail']);
    if (detail != null) return detail;

    final message = _parseErrorValue(body['message']);
    if (message != null) return message;
  }

  if (exception.response?.statusCode == 401) {
    return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
  }
  if (exception.type == DioExceptionType.connectionTimeout ||
      exception.type == DioExceptionType.receiveTimeout ||
      exception.type == DioExceptionType.sendTimeout) {
    return 'Máy chủ phản hồi quá lâu. Vui lòng thử lại sau.';
  }
  if (exception.type == DioExceptionType.connectionError) {
    return 'Không kết nối được máy chủ. Kiểm tra mạng và thử lại.';
  }
  return fallback;
}

String? _parseErrorValue(dynamic value) {
  if (value is String && value.trim().isNotEmpty) return value;
  if (value is Map) {
    final message = _parseErrorValue(value['message']);
    if (message != null) {
      final details = _parseErrorValue(value['details']);
      return details == null ? message : '$message: $details';
    }
    return _parseErrorValue(value['details']);
  }
  if (value is List && value.isNotEmpty) {
    final messages = value
        .map((item) {
          if (item is Map) {
            return _parseErrorValue(item['msg'] ?? item['message'] ?? item);
          }
          return _parseErrorValue(item);
        })
        .whereType<String>()
        .toList();
    if (messages.isNotEmpty) return messages.join('\n');
  }
  return null;
}
