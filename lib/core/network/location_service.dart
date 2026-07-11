import 'package:dio/dio.dart';

class LocationService {
  final Dio _dio = Dio();

  Future<List<dynamic>> getProvinces() async {
    try {
      final response = await _dio.get('https://provinces.open-api.vn/api/?depth=2');
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error fetching provinces: $e');
      return [];
    }
  }
}
