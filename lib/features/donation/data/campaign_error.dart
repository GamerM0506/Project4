import 'package:dio/dio.dart';

import '../../../core/network/api_error_parser.dart';

/// Dịch lỗi từ donation-service sang thông điệp tiếng Việt cho người dùng.
///
/// Backend trả lỗi tiếng Anh khá cụ thể (`Moderator or owner of the group
/// required`, `Group is not active (status=pending)`, ...). Nếu ném thẳng
/// `DioException.toString()` ra SnackBar thì người dùng không hiểu gì.
String campaignErrorMessage(Object error, {String? fallback}) {
  final defaultMessage = fallback ?? 'Không thực hiện được. Vui lòng thử lại.';

  if (error is! DioException) {
    return defaultMessage;
  }

  final status = error.response?.statusCode;
  final raw = parseApiError(error, defaultMessage);
  final lowered = raw.toLowerCase();

  // Backend chặn quyên góp khi chưa là thành viên đã duyệt của hội nhóm.
  // UI đã kiểm tra sớm, đây là lớp phòng vệ cuối (vd: vừa bị kick).
  if (lowered.contains('join this group')) {
    return 'Bạn cần tham gia hội nhóm này trước khi quyên góp. '
        'Hãy gửi yêu cầu tham gia và chờ hội nhóm duyệt.';
  }
  if (status == 403 || lowered.contains('moderator')) {
    return 'Bạn cần là quản trị viên hoặc chủ nhóm để thực hiện thao tác này.';
  }
  if (lowered.contains('group is not active')) {
    return 'Nhóm chưa được kích hoạt nên chưa thể tạo đợt quyên góp.';
  }
  if (lowered.contains('group not found')) {
    return 'Không tìm thấy nhóm. Vui lòng tải lại trang.';
  }
  if (status == 503 || lowered.contains('community service unavailable')) {
    return 'Dịch vụ hội nhóm đang bận. Vui lòng thử lại sau ít phút.';
  }
  if (status == 502) {
    return 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.';
  }
  if (status == 422) {
    // FastAPI trả mảng chi tiết; parseApiError đã gộp thành chuỗi đọc được.
    return 'Dữ liệu chưa hợp lệ: $raw';
  }

  return raw;
}
