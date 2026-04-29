// lib/services/api_service.dart
// Central Dio HTTP client with auth header injection and error handling.

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.2.182:8000';

  static Dio _buildDio({String? token}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );

    // Response interceptor — logging and error check
    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          // We will NOT unwrap 'data' here anymore to follow the USER's strict parsing requirement
          return handler.next(response);
        },
        onError: (DioException e, ErrorInterceptorHandler handler) {
          return handler.next(e);
        },
      ),
    );

    return dio;
  }

  /// Returns a Dio instance with the stored auth token.
  static Future<Dio> authenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return _buildDio(token: token);
  }

  /// Returns a Dio instance without auth (public endpoints).
  static Dio public() => _buildDio();

  /// Convenience: extract error message from a DioException.
  static String errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      if (e.response?.statusCode != null) {
        return 'Server error ${e.response!.statusCode}';
      }
      return e.message ?? 'Network error';
    }
    return e.toString();
  }
}
