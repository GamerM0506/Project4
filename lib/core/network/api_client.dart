import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_interceptor.dart';

class ApiClient {
  final Dio dio;
  final SharedPreferences sharedPreferences;

  ApiClient({required this.dio, required this.sharedPreferences}) {
    dio.interceptors.add(AuthInterceptor(prefs: sharedPreferences));
  }
}
