import 'api_service.dart';

class ProfileService {
  /// Fetch the current user's profile
  Future<Map<String, dynamic>?> getMyProfile() async {
    try {
      final dio = await ApiService.authenticated();
      final response = await dio.get('/profile/me');
      if (response.data is Map && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("DEBUG: PROFILE API ERROR: $e");
      return null;
    }
  }

  /// Update the current user's profile
  Future<Map<String, dynamic>?> updateProfile(Map<String, dynamic> updateData) async {
    try {
      final dio = await ApiService.authenticated();
      final response = await dio.put('/profile/update', data: updateData);
      if (response.data is Map && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("DEBUG: PROFILE UPDATE ERROR: $e");
      rethrow;
    }
  }
}
