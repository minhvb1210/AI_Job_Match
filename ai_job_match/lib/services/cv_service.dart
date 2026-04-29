import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/job_match.dart';
import 'api_service.dart';

class CvService {
  /// Check if current user has a CV profile.
  Future<Map<String, dynamic>?> checkCV() async {
    final dio = await ApiService.authenticated();
    final response = await dio.get('/cv/me');
    if (response.data is Map && response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  /// Upload a CV file (PDF/DOCX) using raw bytes.
  Future<CvMatchResult> uploadCV(Uint8List bytes, String fileName) async {
    final dio = ApiService.public();

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
      ),
    });

    final response = await dio.post(
      '/cv/upload-match',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    final data = response.data;
    if (data is Map && data['success'] == true) {
       return CvMatchResult.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(data['message'] ?? "Upload failed");
  }

  /// Fetch the full scoring breakdown for a specific job.
  Future<ExplainResult> explainJob({
    required int jobId,
    required String token,
  }) async {
    final dio = await ApiService.authenticated();
    final response = await dio.get('/ai/explain/$jobId');
    final data = response.data;
    if (data is Map && data['success'] == true) {
       return ExplainResult.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(data['message'] ?? "Explain failed");
  }

  /// Fetch explain breakdown for arbitrary CV text.
  Future<ExplainResult> explainJobFromText({
    required int jobId,
    required String cvText,
  }) async {
    final dio = ApiService.public();
    final response = await dio.post(
      '/ai/explain/$jobId',
      data: {'cv_text': cvText},
    );
    final data = response.data;
    if (data is Map && data['success'] == true) {
       return ExplainResult.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(data['message'] ?? "Explain failed");
  }

  /// Get AI suggestions to improve current CV profile.
  Future<List<String>> getSuggestions() async {
    final dio = await ApiService.authenticated();
    final response = await dio.post('/ai/cv-suggestions');
    final data = response.data;
    if (data is Map && data['success'] == true) {
       final suggestions = data['data']['suggestions'] as List<dynamic>;
       return suggestions.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Fetch saved matches for the current user's profile.
  Future<CvMatchResult> getSavedMatches() async {
    final dio = await ApiService.authenticated();
    final response = await dio.get('/cv/saved-matches');
    final data = response.data;
    if (data is Map && data['success'] == true) {
       return CvMatchResult.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(data['message'] ?? "Failed to get matches");
  }

  /// Update the user's skills text profile.
  Future<void> updateProfile(String skillsText) async {
    final dio = await ApiService.authenticated();
    await dio.put('/cv/profile', data: {'skills_text': skillsText});
  }
}
