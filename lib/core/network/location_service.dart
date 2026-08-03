import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// Danh mục tỉnh/huyện Việt Nam từ dịch vụ công khai `provinces.open-api.vn`.
///
/// Dữ liệu gần như không đổi nên kết quả được nhớ trong bộ nhớ tiến trình:
/// bốn màn hình cùng dùng service này (chọn tỉnh khi lọc nhóm, sửa hồ sơ,
/// cài đặt nhóm), trước đây mỗi màn tải lại toàn bộ cây tỉnh/huyện.
class LocationService {
  LocationService({Dio? dio, String? baseUrl})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              // Dịch vụ bên thứ ba: bắt buộc có timeout để không treo UI.
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
            ),
          ),
      _baseUrl = baseUrl ?? _defaultBaseUrl;

  static const _defaultBaseUrl = 'https://provinces.open-api.vn/api';

  final Dio _dio;
  final String _baseUrl;

  List<dynamic>? _cache;
  Future<List<dynamic>>? _inFlight;

  Future<List<dynamic>> getProvinces() {
    final cached = _cache;
    if (cached != null) return Future.value(cached);
    // Nhiều màn mở cùng lúc thì dùng chung một request đang bay.
    return _inFlight ??= _fetch();
  }

  Future<List<dynamic>> _fetch() async {
    try {
      final response = await _dio.get('$_baseUrl/?depth=2');
      final data = response.data;
      if (response.statusCode == 200 && data is List) {
        _cache = data;
        return data;
      }
      return const [];
    } on DioException catch (e) {
      developer.log(
        'Không tải được danh sách tỉnh/thành',
        name: 'LocationService',
        error: e,
      );
      return const [];
    } finally {
      _inFlight = null;
    }
  }

  /// Xoá cache — dùng khi người dùng chủ động tải lại.
  void invalidate() => _cache = null;
}
