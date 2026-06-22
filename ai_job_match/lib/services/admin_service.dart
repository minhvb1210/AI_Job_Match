import 'api_service.dart';

class AdminService {
  /// Get platform statistics.
  Future<Map<String, dynamic>> getStats() async {
    final dio = await ApiService.authenticated();
    final response = await dio.get('/admin/stats');
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Get paginated user list.
  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int limit = 20,
    String? role,
    String? query,
  }) async {
    final dio = await ApiService.authenticated();
    final response = await dio.get('/admin/users', queryParameters: {
      'page': page,
      'limit': limit,
      if (role != null && role != 'all') 'role': role,
      if (query != null && query.isNotEmpty) 'q': query,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Delete a user by ID.
  Future<void> deleteUser(int userId) async {
    final dio = await ApiService.authenticated();
    await dio.delete('/admin/users/$userId');
  }

  /// Get paginated job list.
  Future<Map<String, dynamic>> getJobs({
    int page = 1,
    int limit = 20,
    String? query,
  }) async {
    final dio = await ApiService.authenticated();
    final response = await dio.get('/admin/jobs', queryParameters: {
      'page': page,
      'limit': limit,
      if (query != null && query.isNotEmpty) 'q': query,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Delete a job by ID.
  Future<void> deleteJob(int jobId) async {
    final dio = await ApiService.authenticated();
    await dio.delete('/admin/jobs/$jobId');
  }
}
