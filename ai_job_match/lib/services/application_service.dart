import '../models/application.dart';
import 'api_service.dart';

class ApplicationService {
  /// Candidate: submit a job application.
  Future<Map<String, dynamic>> applyForJob({
    required int jobId,
    double matchScore = 0,
  }) async {
    final dio = await ApiService.authenticated();
    final response = await dio.post('/applications/', data: {
      'job_id':      jobId,
      'match_score': matchScore,
    });
    if (response.data is Map && response.data['success'] == true) {
       return response.data['data'] as Map<String, dynamic>;
    }
    return response.data as Map<String, dynamic>;
  }

  /// Candidate: get my submitted applications (paginated).
  Future<List<MyApplication>> getMyApplications({
    int page = 1,
    int limit = 20,
  }) async {
    final dio = await ApiService.authenticated();
    final response = await dio.get(
      '/applications/my-applications',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true) {
      final items = data['data']['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => MyApplication.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Recruit: get applicants for a specific job, sorted by AI score.
  Future<List<ApplicantInfo>> getJobApplicants({
    required int jobId,
    int page = 1,
    int limit = 50,
  }) async {
    final dio = await ApiService.authenticated();
    final response = await dio.get(
      '/applications/employer-job/$jobId',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true) {
      final items = data['data']['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => ApplicantInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Recruiter: update application status.
  Future<void> updateStatus({
    required int applicationId,
    required String status,
  }) async {
    final dio = await ApiService.authenticated();
    await dio.put(
      '/applications/$applicationId/status',
      data: {'status': status},
    );
  }

  /// Schedule an interview for an application (Recruiter).
  Future<Map<String, dynamic>> scheduleInterview({
    required int applicationId,
    required DateTime time,
    required String location,
    String? note,
  }) async {
    final dio = await ApiService.authenticated();
    final response = await dio.post('/interviews/create', data: {
      'application_id': applicationId,
      'scheduled_time': time.toIso8601String(),
      'location': location,
      'note': note,
    });
    if (response.data is Map && response.data['success'] == true) {
       return response.data['data'] as Map<String, dynamic>;
    }
    return response.data as Map<String, dynamic>;
  }
}
