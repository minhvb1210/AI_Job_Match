// lib/models/application.dart
// Models for candidate applications and recruiter applicant view.

class MyApplication {
  final int id;
  final int jobId;
  final String status;
  final double matchScore;
  final String? createdAt;
  final String jobTitle;
  final String company;
  final dynamic job; // Object for UI fallback

  MyApplication({
    required this.id,
    required this.jobId,
    required this.status,
    required this.matchScore,
    this.createdAt,
    required this.jobTitle,
    required this.company,
    this.job,
  });

  factory MyApplication.fromJson(Map<String, dynamic> json) {
    final job = json['job'] as Map<String, dynamic>? ?? {};
    return MyApplication(
      id:         json['id'] as int? ?? 0,
      jobId:      json['job_id'] as int? ?? job['id'] as int? ?? 0,
      status:     json['status'] as String? ?? 'pending',
      matchScore: (json['match_score'] as num?)?.toDouble() ?? 0,
      createdAt:  json['created_at'] as String?,
      jobTitle:   job['title'] as String? ?? 'Unknown Job',
      company:    job['company'] as String? ?? '',
      job:        job,
    );
  }

  /// Status display helpers
  String get statusLabel => status.toUpperCase();
}

class ApplicantInfo {
  final int id;
  final int rank;
  final String status;
  final double matchScore;
  final String? createdAt;
  final int? candidateId;
  final String candidateEmail;
  final String candidateSkills;
  final List<String> missingSkills;
  final bool isTopCandidate;

  ApplicantInfo({
    required this.id,
    required this.rank,
    required this.status,
    required this.matchScore,
    this.createdAt,
    this.candidateId,
    required this.candidateEmail,
    required this.candidateSkills,
    required this.missingSkills,
    required this.isTopCandidate,
  });

  factory ApplicantInfo.fromJson(Map<String, dynamic> json) {
    return ApplicantInfo(
      id:               json['id'] as int? ?? 0,
      rank:             json['rank'] as int? ?? 0,
      status:           json['status'] as String? ?? 'pending',
      matchScore:       (json['match_score'] as num?)?.toDouble() ?? 0,
      createdAt:        json['created_at'] as String?,
      candidateId:      json['candidate_id'] as int?,
      candidateEmail:   json['candidate_email'] as String? ?? 'Unknown',
      candidateSkills:  json['candidate_skills'] as String? ?? '',
      missingSkills: (json['missing_skills'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          [],
      isTopCandidate: json['is_top_candidate'] as bool? ?? false,
    );
  }
}
