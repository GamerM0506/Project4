import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'auth_interceptor.dart';

class MediaUploadResult {
  const MediaUploadResult({required this.mediaId, required this.publicUrl});

  final String mediaId;
  final String publicUrl;
}

class MediaService {
  MediaService({Dio? dio, required SharedPreferences prefs})
    : _dio = dio ?? Dio() {
    _dio.options.baseUrl = AppConstants.mediaApiBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
    _dio.options.sendTimeout = const Duration(seconds: 60);

    _dio.interceptors.add(AuthInterceptor(prefs: prefs));
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.data is! FormData &&
              options.headers[Headers.contentTypeHeader] == null) {
            options.headers[Headers.contentTypeHeader] = 'application/json';
          }
          return handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;

  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  Future<MediaUploadResult> uploadImageResult(
    Uint8List fileBytes,
    String mimeType, {
    String refType = 'avatar',
  }) async {
    final normalizedMime = normalizeMimeType(mimeType, fileBytes);
    if (fileBytes.isEmpty) throw Exception('File ảnh trống.');
    if (fileBytes.length > maxFileSizeBytes) {
      throw Exception(
        'Ảnh vượt quá 5MB. Hãy chọn ảnh nhỏ hơn hoặc giảm chất lượng.',
      );
    }
    try {
      if (kIsWeb) {
        try {
          return await _uploadViaProxy(
            fileBytes: fileBytes,
            mimeType: normalizedMime,
            refType: refType,
          );
        } on DioException catch (e) {
          if (e.response?.statusCode != 404 && e.response?.statusCode != 405) {
            rethrow;
          }
        }
      }
      return await _uploadViaPresign(
        fileBytes: fileBytes,
        mimeType: normalizedMime,
        refType: refType,
      );
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  Future<String> uploadImage(
    Uint8List fileBytes,
    String mimeType, {
    String refType = 'avatar',
  }) async {
    return (await uploadImageResult(
      fileBytes,
      mimeType,
      refType: refType,
    )).publicUrl;
  }

  Future<MediaUploadResult> _uploadViaProxy({
    required Uint8List fileBytes,
    required String mimeType,
    required String refType,
  }) async {
    final ext = switch (mimeType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };

    final form = FormData.fromMap({
      'ref_type': refType,
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: 'avatar.$ext',
        contentType: MediaType.parse(mimeType),
      ),
    });

    final res = await _dio.post<Map<String, dynamic>>(
      '/files/upload',
      data: form,
    );

    final data = _unwrapData(res.data);
    final publicUrl = data['public_url']?.toString();
    final mediaId = data['id']?.toString();
    if (publicUrl == null ||
        publicUrl.isEmpty ||
        mediaId == null ||
        mediaId.isEmpty) {
      throw Exception('Upload thành công nhưng thiếu id/public_url.');
    }
    return MediaUploadResult(mediaId: mediaId, publicUrl: publicUrl);
  }

  Future<MediaUploadResult> _uploadViaPresign({
    required Uint8List fileBytes,
    required String mimeType,
    required String refType,
  }) async {
    final presignRes = await _dio.post<Map<String, dynamic>>(
      '/presign',
      data: {
        'mime_type': mimeType,
        'ref_type': refType,
        'file_size': fileBytes.length,
      },
    );

    final presignData = _unwrapData(presignRes.data);
    final uploadUrl = presignData['upload_url']?.toString();
    final mediaId = presignData['media_id']?.toString();
    final publicUrlFromPresign = presignData['public_url']?.toString();

    if (uploadUrl == null || uploadUrl.isEmpty || mediaId == null) {
      throw Exception('Presign không trả về upload_url/media_id.');
    }

    await _putToStorage(
      uploadUrl: uploadUrl,
      bytes: fileBytes,
      mimeType: mimeType,
    );

    final confirmRes = await _dio.post<Map<String, dynamic>>(
      '/confirm',
      data: {'media_id': mediaId},
    );
    final confirmData = _unwrapData(confirmRes.data);
    final publicUrl =
        confirmData['public_url']?.toString() ?? publicUrlFromPresign;

    if (publicUrl == null || publicUrl.isEmpty) {
      throw Exception('Confirm thành công nhưng thiếu public_url.');
    }
    return MediaUploadResult(mediaId: mediaId, publicUrl: publicUrl);
  }

  Future<void> linkMedia(
    List<String> mediaIds,
    String refType,
    String refId,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/link',
      data: {'media_ids': mediaIds, 'ref_type': refType, 'ref_id': refId},
    );
    _unwrapData(response.data);
  }

  Future<void> unlinkMedia(List<String> mediaIds) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/unlink',
      data: {'media_ids': mediaIds},
    );
    _unwrapData(response.data);
  }

  Future<void> _putToStorage({
    required String uploadUrl,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final uploadDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        responseType: ResponseType.plain,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    try {
      final res = await uploadDio.put<dynamic>(
        uploadUrl,
        data: bytes,
        options: Options(
          headers: {
            'Content-Type': mimeType,
            Headers.contentLengthHeader: bytes.length,
          },
          responseType: ResponseType.plain,
          followRedirects: false,
        ),
      );

      final code = res.statusCode ?? 0;
      if (code == 200 || code == 201 || code == 204) return;

      final body = res.data?.toString() ?? '';
      if (code == 403) {
        throw Exception(
          'Storage từ chối upload (403). Content-Type phải khớp chữ ký ($mimeType). $body',
        );
      }
      throw Exception('Upload storage thất bại (HTTP $code). $body');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final msg = (e.message ?? '').toLowerCase();

      if (status == null &&
          (e.type == DioExceptionType.connectionError ||
              msg.contains('xmlhttprequest'))) {
        throw Exception(
          'Upload bị chặn mạng/CORS tới storage. Thử lại hoặc dùng proxy /files/upload. '
          '${e.message ?? e.type.name}',
        );
      }
      if (status == 403) {
        throw Exception(
          'Storage từ chối upload (403). Mime: $mimeType. '
          '${e.response?.data ?? e.message ?? ''}',
        );
      }
      throw Exception(
        'Lỗi upload storage: ${e.message ?? e.type.name}'
        '${status != null ? ' (HTTP $status)' : ''}',
      );
    } finally {
      uploadDio.close();
    }
  }

  Map<String, dynamic> _unwrapData(Map<String, dynamic>? body) {
    if (body == null) return {};
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return body;
  }

  String _mapDioError(DioException e) {
    final data = e.response?.data;
    final msg = (e.message ?? '').toLowerCase();

    if (kIsWeb &&
        e.response?.statusCode == null &&
        (e.type == DioExceptionType.connectionError ||
            msg.contains('xmlhttprequest'))) {
      return 'Lỗi mạng Web (CORS/XMLHttpRequest). '
          'Đảm bảo media-service đã deploy endpoint /files/upload và Kong CORS mở. '
          'Chi tiết: ${e.message ?? e.type.name}';
    }

    if (data is Map) {
      final error = data['error'] ?? data['detail'] ?? data['message'];
      if (error is String && error.isNotEmpty) return error;
      if (error is Map && error['message'] != null) {
        return error['message'].toString();
      }
    }
    if (e.response?.statusCode == 401) {
      return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
    }
    if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
      return 'API upload chưa có trên server (HTTP ${e.response?.statusCode}). '
          'Cần deploy lại media-service (endpoint POST /files/upload).';
    }
    if (e.response?.statusCode == 413) {
      return 'Ảnh vượt quá dung lượng cho phép (5MB).';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Không kết nối được máy chủ. Kiểm tra mạng và thử lại.';
    }
    return 'Lỗi mạng khi tải ảnh lên: ${e.message ?? e.type.name}';
  }

  static String normalizeMimeType(String declared, Uint8List bytes) {
    final fromBytes = detectMimeFromBytes(bytes);
    final candidate = (fromBytes ?? declared).toLowerCase().trim();

    if (candidate == 'image/jpg' || candidate == 'image/pjpeg') {
      return 'image/jpeg';
    }
    if (candidate == 'image/jpeg' ||
        candidate == 'image/png' ||
        candidate == 'image/webp') {
      return candidate;
    }

    throw Exception(
      'Định dạng ảnh không hỗ trợ ($candidate). '
      'Chỉ chấp nhận JPEG, PNG, WEBP.',
    );
  }

  static String? detectMimeFromBytes(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return null;
  }

  static String mimeFromFileName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'image/jpeg';
  }
}
