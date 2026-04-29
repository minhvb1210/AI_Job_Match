import 'package:dio/dio.dart';
import 'api_service.dart';

class JobService {
  /// Public: Search jobs with filters.
  Future<List<dynamic>> searchJobs({
    String? query,
    String? location,
    String? category,
    String? jobType,
    String? experienceLevel,
    int? minSalary,
    String sortBy = 'newest',
  }) async {
    final dio = ApiService.public();
    final response = await dio.get('/jobs/search', queryParameters: {
      if (query != null && query.isNotEmpty) 'q': query,
      if (location != null && location.isNotEmpty) 'location': location,
      if (category != null && category != 'All') 'category': category,
      if (jobType != null && jobType != 'All') 'job_type': jobType,
      if (experienceLevel != null && experienceLevel != 'All') 'experience_level': experienceLevel,
      if (minSalary != null) 'min_salary': minSalary,
      'sort_by': sortBy,
    });
    
    print("JOBS API: ${response.data}");
    final data = response.data;
    if (data is Map && data['success'] == true) {
      final innerData = data['data'];
      if (innerData is Map && innerData.containsKey('items')) {
        return innerData['items'] as List<dynamic>;
      }
    }
    return [];
  }

  /// Auth: Get all jobs (Employer).
  Future<List<dynamic>> getAllJobs() async {
    final dio = await ApiService.authenticated();
    final response = await dio.get('/jobs/');
    print("JOBS API (ALL): ${response.data}");
    final data = response.data;
    if (data is Map && data['success'] == true) {
      final innerData = data['data'];
      if (innerData is Map && innerData.containsKey('items')) {
        return innerData['items'] as List<dynamic>;
      }
    }
    return [];
  }

  /// Public: Get individual job by ID.
  Future<Map<String, dynamic>> getJobById(int jobId) async {
    final dio = ApiService.public();
    final response = await dio.get('/jobs/$jobId');
    return response.data['data'] as Map<String, dynamic>;
  }

  /// Auth: Calculate match scores for a batch of jobs.
  Future<Map<int, double?>> matchJobsBatch(List<int> jobIds) async {
    if (jobIds.isEmpty) return {};
    final dio = await ApiService.authenticated();
    final response = await dio.post('/ai/match-jobs-batch', data: {
      'job_ids': jobIds,
    });
    
    final innerData = response.data['data'];
    final scoresData = innerData['scores'] as Map<String, dynamic>;
    return scoresData.map((key, value) => MapEntry(
      int.parse(key), 
      value == null ? null : (value as num).toDouble(),
    ));
  }

  /// Auth: Get saved jobs for current candidate.
  Future<List<dynamic>> getSavedJobs() async {
    final dio = await ApiService.authenticated();
    final response = await dio.get('/jobs/saved');
    final data = response.data;
    if (data is Map && data['success'] == true) {
      final innerData = data['data'];
      if (innerData is Map && innerData.containsKey('items')) {
        return innerData['items'] as List<dynamic>;
      }
    }
    return [];
  }

  /// Auth: Toggle save/unsave a job.
  Future<void> toggleSaveJob(int jobId, bool currentlySaved) async {
    final dio = await ApiService.authenticated();
    if (currentlySaved) {
      await dio.delete('/jobs/$jobId/save');
    } else {
      await dio.post('/jobs/$jobId/save');
    }
  }

  /// Auth: Post a new job (Employer).
  Future<void> createJob(Map<String, dynamic> jobData) async {
    print("JOB PAYLOAD: $jobData");
    print("DEBUG: JOB CREATE ATTEMPT - POST /jobs/ with data: $jobData");
    try {
      final dio = await ApiService.authenticated();
      final response = await dio.post('/jobs/', data: jobData);
      print("DEBUG: JOB CREATE RESPONSE: ${response.data}");
    } catch (e) {
      print("DEBUG: JOB CREATE ERROR: $e");
      rethrow;
    }
  }

  /// Auth: Delete a job posting (Employer).
  Future<void> deleteJob(int jobId) async {
    final dio = await ApiService.authenticated();
    await dio.delete('/jobs/$jobId');
  }

  /// Auth: Get AI sourcing candidates for a job (Employer).
  Future<List<dynamic>> getAiSourcingCandidates(int jobId) async {
    final dio = await ApiService.authenticated();
    final response = await dio.get('/jobs/$jobId/ai-suggested-candidates');
    return response.data['data'] as List<dynamic>;
  }

  /// Public: Get external jobs from Remotive.
  Future<List<dynamic>> getExternalJobs({String? category, int limit = 20}) async {
    final dio = ApiService.public();
    final response = await dio.get('/jobs/external', queryParameters: {
      if (category != null && category != 'All') 'category': category,
      'limit': limit,
    });
    return response.data as List<dynamic>;
  }
}
