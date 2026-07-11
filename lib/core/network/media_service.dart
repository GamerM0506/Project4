import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class MediaService {
  final Dio _dio;

  MediaService() : _dio = Dio() {
    _dio.options.baseUrl = AppConstants.mediaApiBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    
    // Add token interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AppConstants.keyAccessToken);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  /// Tải ảnh lên và trả về public_url
  Future<String?> uploadImage(Uint8List fileBytes, String mimeType) async {
    try {
      // 1. Presign
      final presignRes = await _dio.post('/presign', data: {
        'mime_type': mimeType,
        'ref_type': 'avatar',
        'file_size': fileBytes.length,
      });

      if (presignRes.statusCode != 201 && presignRes.statusCode != 200) {
        throw Exception('Lỗi khi lấy link upload (presign)');
      }

      final data = presignRes.data['data'];
      final uploadUrl = data['upload_url'] as String;
      final mediaId = data['media_id'] as String;
      final headers = Map<String, dynamic>.from(data['headers'] ?? {});

      // 2. Upload to storage using the presigned url
      // We must use a clean Dio instance here so our interceptors don't mess up S3/GCS request
      final uploadDio = Dio();
      final uploadRes = await uploadDio.put(
        uploadUrl,
        data: fileBytes,
        options: Options(
          headers: headers,
          contentType: mimeType,
        ),
      );

      if (uploadRes.statusCode != 200 && uploadRes.statusCode != 201) {
        throw Exception('Lỗi khi tải file lên Storage');
      }

      // 3. Confirm
      final confirmRes = await _dio.post('/confirm', data: {
        'media_id': mediaId,
      });

      if (confirmRes.statusCode == 200 || confirmRes.statusCode == 201) {
        return confirmRes.data['data']['public_url'] as String?;
      }
      
      return null;
    } on DioException catch (e) {
      throw Exception('Lỗi mạng khi tải ảnh lên: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi không xác định khi tải ảnh lên: $e');
    }
  }
}
