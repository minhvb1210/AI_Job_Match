import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  String? _role;
  String? _email;
  
  bool get isAuthenticated => _token != null && !JwtDecoder.isExpired(_token!);
  String? get role => _role;
  String? get token => _token;
  String? get email => _email;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    if (_token != null && !JwtDecoder.isExpired(_token!)) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(_token!);
      _role = decodedToken['role'];
      _email = decodedToken['sub'];
    } else {
      _token = null;
      _role = null;
      _email = null;
    }
    notifyListeners();
  }
  Future<bool> login(String email, String password) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final dio = ApiService.public();
      final response = await dio.post(
        '/auth/login',
        data: {'email': normalizedEmail, 'password': password},
      );

      print("AUTH API: ${response.data}");
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
         _token = data['data']['access_token'];
         
         final prefs = await SharedPreferences.getInstance();
         await prefs.setString('access_token', _token!);
         
         Map<String, dynamic> decodedToken = JwtDecoder.decode(_token!);
         _role = decodedToken['role'];
         _email = decodedToken['sub'];
         
         notifyListeners();
         return true;
      }
      return false;
    } catch (e) {
      debugPrint("Login error: $e");
      return false;
    }
  }

  Future<bool> register(String email, String password, String role) async {
    final data = {
      "email": email.trim(),
      "password": password,
      "role": role.toLowerCase().trim(),
    };
    
    print("REGISTER JSON: ${jsonEncode(data)}");

    try {
      final dio = ApiService.public();
      final response = await dio.post('/auth/register', data: data);
      print("REGISTER API: ${response.data}");
      
      // Success response implies successful registration
      return await login(email.trim(), password);
    } catch (e) {
      if (e is DioException) {
        final dioError = e as DioException;
        print("REGISTER ERROR: ${dioError.response?.data}");
      }
      debugPrint("Registration error: $e");
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    _token = null;
    _role = null;
    _email = null;
    notifyListeners();
  }
}
