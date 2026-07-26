import 'package:dio/dio.dart';

String apiErrorMessage(Object error, {required String fallback}) {
  if (error is DioException) {
    final body = error.response?.data;
    if (body is Map) {
      final detail = body['error'] ?? body['message'] ?? body['detail'];
      if (detail is String && detail.trim().isNotEmpty) return detail.trim();
      if (detail is Map && detail['message'] != null) {
        return detail['message'].toString();
      }
    }
  }
  if (error is Exception) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isNotEmpty && !message.startsWith('DioException')) {
      return message;
    }
  }
  return fallback;
}
