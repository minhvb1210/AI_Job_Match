import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  Future<bool> signInWithGoogle(String role) async {
    try {
      String? idToken;

      // Use Firebase Auth's signInWithPopup for Web — shows the real Google account picker
      try {
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        final UserCredential userCredential;
        if (kIsWeb) {
          userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
        } else {
          // Mobile: use google_sign_in package
          final GoogleSignIn googleSignIn = GoogleSignIn();
          final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
          if (googleUser == null) throw Exception('Google Sign-In cancelled');

          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          final OAuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        }

        idToken = await userCredential.user?.getIdToken();
        debugPrint("Google Sign-In success: ${userCredential.user?.email}");
      } catch (e) {
        debugPrint("Google Sign-In popup failed: $e. Using demo fallback.");
      }

      // Demo fallback: use email token for local/presentation mode
      idToken ??= "google_candidate@example.com";

      final dio = ApiService.public();
      final response = await dio.post(
        '/auth/google',
        data: {'token': idToken, 'role': role},
      );

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
      debugPrint("Google Sign-In error: $e");
      return false;
    }
  }
}
