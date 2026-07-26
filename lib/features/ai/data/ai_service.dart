import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error_parser.dart';

class AiService {
  final ApiClient apiClient;

  AiService({required this.apiClient});

  Future<Map<String, dynamic>> detectItem(List<int> imageBytes) async {
    if (imageBytes.length > 5 * 1024 * 1024) {
      throw Exception('Ảnh quá lớn. Vui lòng chọn ảnh dưới 5 MB.');
    }
    try {
      final response = await apiClient.dio.post(
        '${AppConstants.aiApiBaseUrl}/detect-item',
        data: {
          'imageUrl': 'data:image/jpeg;base64,${base64Encode(imageBytes)}',
        },
      );
      final data = response.data;
      if (data is! Map || data['error'] != null) {
        throw Exception(data is Map ? data['error']?.toString() : null);
      }
      return Map<String, dynamic>.from(data);
    } on DioException catch (e) {
      throw Exception(parseApiError(e, 'AI không thể nhận diện ảnh này.'));
    }
  }

  Future<String> generateDescription({
    required String name,
    required String condition,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '${AppConstants.aiApiBaseUrl}/generate-description',
        data: {'name': name, 'condition': condition},
      );
      final data = response.data;
      if (data is! Map ||
          data['error'] != null ||
          data['description'] == null) {
        throw Exception(data is Map ? data['error']?.toString() : null);
      }
      return data['description'].toString();
    } on DioException catch (e) {
      throw Exception(parseApiError(e, 'Không thể tạo mô tả bằng AI.'));
    }
  }
}
