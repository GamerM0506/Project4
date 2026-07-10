import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiClient {
  final Dio dio;
  final SharedPreferences sharedPreferences;

  ApiClient({required this.dio, required this.sharedPreferences}) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = sharedPreferences.getString(
            AppConstants.keyAccessToken,
          );
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Content-Type'] = 'application/json';
          return handler.next(options);
        },
      ),
    );
  }
}
