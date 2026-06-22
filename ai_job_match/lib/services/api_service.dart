import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiService {
  // ── Set this to your Render backend URL after deploying ──
  // Example: 'https://aijobmatch-api.onrender.com'
  // Leave empty string to use localhost (local development)
  static const String _productionApiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    // If production URL is set (via --dart-define), use it
    if (_productionApiUrl.isNotEmpty) {
      return _productionApiUrl;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://localhost:8000';
    }
  }

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
        onRequest: (options, handler) {
          debugPrint('🚀 API [${options.method}] => ${options.baseUrl}${options.path}');
          if (options.queryParameters.isNotEmpty) debugPrint('❓ Query: ${options.queryParameters}');
          debugPrint('🔑 Auth: ${options.headers['Authorization'] != null ? 'PRESENT' : 'MISSING'}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('✅ API [${response.statusCode}] <= ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException e, ErrorInterceptorHandler handler) {
          debugPrint('❌ API ERROR [${e.response?.statusCode}] <= ${e.requestOptions.path}');
          debugPrint('❌ Response Body: ${e.response?.data}');
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
      
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          return "Connection timed out. Check your server/network.";
        case DioExceptionType.sendTimeout:
          return "Send timeout.";
        case DioExceptionType.receiveTimeout:
          return "Server is taking too long to respond.";
        case DioExceptionType.badResponse:
          return "Server error: ${e.response?.statusCode}";
        case DioExceptionType.cancel:
          return "Request was cancelled.";
        case DioExceptionType.connectionError:
          return "Connection error. Ensure backend is running at $baseUrl";
        default:
          return e.message ?? "An unexpected network error occurred.";
      }
    }
    return e.toString();
  }
}
