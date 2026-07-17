import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../constants/app_constants.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

abstract class MediaService {
  Future<String> uploadImage(XFile file, {String refType = 'avatar'});
}

class MediaServiceImpl implements MediaService {
  final ApiClient apiClient;

  MediaServiceImpl(this.apiClient);

  @override
  Future<String> uploadImage(XFile file, {String refType = 'avatar'}) async {
    try {
      final formData = FormData.fromMap({
        'ref_type': refType,
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.name,
        ),
      });

      final response = await apiClient.dio.post(
        '${AppConstants.mediaApiBaseUrl}/files/upload',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // According to DataEnvelope_MediaOut_, response.data['data']['public_url']
        return response.data['data']['public_url'] as String;
      } else {
        throw Exception('Failed to upload image');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail']?[0]?['msg'] ?? 'Lỗi kết nối máy chủ');
    } catch (e) {
      throw Exception('Đã xảy ra lỗi: ${e.toString()}');
    }
  }
}
