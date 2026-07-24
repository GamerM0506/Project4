import 'package:dio/dio.dart';

/// Chuẩn hóa lỗi API (FastAPI detail / Nest error) thành message tiếng Việt.
class ApiErrorMapper {
  static String message(
    Object error, {
    String fallback = 'Đã xảy ra lỗi. Vui lòng thử lại.',
  }) {
    if (error is DioException) {
      return fromDio(error, fallback: fallback);
    }
    final s = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
    if (s.isEmpty || s == 'null') return fallback;
    return s;
  }

  static String fromDio(
    DioException e, {
    String fallback = 'Đã xảy ra lỗi. Vui lòng thử lại.',
  }) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    final extracted = _extractDetail(data);
    if (extracted != null && extracted.isNotEmpty) {
      return _localize(extracted, status);
    }

    if (status == 401) {
      return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
    }
    if (status == 403) {
      return 'Không có quyền thực hiện. Cần là thành viên đã được duyệt của nhóm.';
    }
    if (status == 404) return 'Không tìm thấy dữ liệu.';
    if (status == 409) return 'Yêu cầu đã tồn tại hoặc xung đột dữ liệu.';
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Kết nối chậm. Kiểm tra mạng và thử lại.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Không kết nối được máy chủ.';
    }
    return fallback;
  }

  static String? _extractDetail(dynamic data) {
    if (data == null) return null;
    if (data is String && data.isNotEmpty) return data;
    if (data is! Map) return data.toString();

    final map = Map<String, dynamic>.from(data);
    final detail = map['detail'] ?? map['message'] ?? map['error'];

    if (detail is String && detail.isNotEmpty) return detail;
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map) {
        return (first['msg'] ?? first['message'] ?? first.toString()).toString();
      }
      return first.toString();
    }
    if (detail is Map) {
      return (detail['message'] ?? detail['msg'] ?? detail.toString()).toString();
    }
    return null;
  }

  static String _localize(String raw, int? status) {
    final lower = raw.toLowerCase();
    if (lower.contains('tham gia nhóm để nhận') ||
        lower.contains('group membership') ||
        lower.contains('join the group')) {
      return 'Bạn cần tham gia nhóm và được duyệt trước khi nhận đồ.';
    }
    if (lower.contains('already a member')) {
      return 'Bạn đã là thành viên của nhóm này.';
    }
    if (lower.contains('join request already pending') ||
        lower.contains('already pending')) {
      return 'Bạn đã gửi yêu cầu tham gia, đang chờ duyệt.';
    }
    if (lower.contains('banned')) {
      return 'Bạn đã bị cấm khỏi nhóm này.';
    }
    if (lower.contains('not active')) {
      return 'Nhóm hiện không hoạt động.';
    }
    if (status == 403) {
      return raw.contains('Tham gia') || raw.contains('nhóm')
          ? raw
          : 'Không có quyền: $raw';
    }
    return raw;
  }
}
