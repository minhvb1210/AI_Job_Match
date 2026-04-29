import 'package:dio/dio.dart';
import 'api_service.dart';

class CompanyService {
  /// Public: Get list of all companies.
  Future<List<dynamic>> getCompanies() async {
    final dio = ApiService.public();
    final response = await dio.get('/companies/');
    final data = response.data;
    if (data is Map && data['success'] == true) {
      final innerData = data['data'];
      if (innerData is Map && innerData.containsKey('items')) {
        return innerData['items'] as List<dynamic>;
      }
    }
    return [];
  }

  /// Public: Get jobs for a specific company.
  Future<List<dynamic>> getCompanyJobs(int companyId) async {
    final dio = ApiService.public();
    final response = await dio.get('/companies/$companyId/jobs');
    final data = response.data;
    if (data is Map && data['success'] == true) {
      final innerData = data['data'];
      if (innerData is Map && innerData.containsKey('items')) {
        return innerData['items'] as List<dynamic>;
      }
    }
    return [];
  }

  /// Auth: Check follow status for a company.
  Future<bool> getFollowStatus(int companyId) async {
    final dio = await ApiService.authenticated();
    final response = await dio.get('/companies/$companyId/follow-status');
    if (response.data is Map && response.data['success'] == true) {
       return (response.data['data'] as Map<String, dynamic>)['is_following'] ?? false;
    }
    return false;
  }

  /// Auth: Follow/Unfollow a company.
  Future<void> toggleFollow(int companyId) async {
    final dio = await ApiService.authenticated();
    await dio.post('/companies/$companyId/follow');
  }

  /// Auth: Get current user's company profile (Employer).
  Future<Map<String, dynamic>?> getMyCompany() async {
    print("DEBUG: COMPANY API CALL - GET /companies/my-company");
    try {
      final dio = await ApiService.authenticated();
      final response = await dio.get('/companies/my-company');
      print("COMPANY RESPONSE: ${response.data}");
      if (response.data['success'] == true) {
        return (response.data['data'] ?? {}) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("DEBUG: COMPANY API ERROR: $e");
      // If 404, it means company doesn't exist yet
      return null;
    }
  }

  /// Auth: Create company profile (Employer).
  Future<void> createMyCompany(Map<String, dynamic> companyData) async {
    print("CREATE COMPANY...");
    print("DEBUG: COMPANY API ATTEMPT - POST /companies/my-company with data: $companyData");
    final dio = await ApiService.authenticated();
    final response = await dio.post('/companies/my-company', data: companyData);
    print("COMPANY RESPONSE: ${response.data}");
  }

  /// Auth: Update company profile (Employer).
  Future<void> updateMyCompany(Map<String, dynamic> companyData) async {
    print("UPDATE COMPANY...");
    print("DEBUG: COMPANY API ATTEMPT - PUT /companies/my-company with data: $companyData");
    final dio = await ApiService.authenticated();
    final response = await dio.put('/companies/my-company', data: companyData);
    print("COMPANY RESPONSE: ${response.data}");
  }
}
