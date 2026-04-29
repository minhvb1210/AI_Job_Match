// lib/models/job_match.dart
// Data models for CV matching results and AI explanations.

class JobBrief {
  final int id;
  final String title;
  final String company;
  final String location;
  final String salary;
  final List<String> skills;

  JobBrief({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.skills,
  });

  factory JobBrief.fromJson(Map<String, dynamic> json) {
    return JobBrief(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Untitled',
      company: json['company'] as String? ?? 'Unknown',
      location: json['location'] as String? ?? 'Remote',
      salary: json['salary'] as String? ?? 'Competitive',
      skills: (json['skills'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          [],
    );
  }
}

class JobMatch {
  final double score;
  final List<String> missingSkills;
  final JobBrief job;

  JobMatch({
    required this.score,
    required this.missingSkills,
    required this.job,
  });

  factory JobMatch.fromJson(Map<String, dynamic> json) {
    return JobMatch(
      score: (json['score'] as num?)?.toDouble() ?? 0,
      missingSkills: (json['missing_skills'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          [],
      job: JobBrief.fromJson(json['job'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class CvMatchResult {
  final String extractedTextPreview;
  final List<JobMatch> matches;
  final bool success;
  final String message;

  CvMatchResult({
    required this.extractedTextPreview,
    required this.matches,
    this.success = true,
    this.message = '',
  });

  factory CvMatchResult.fromJson(Map<String, dynamic> json) {
    // Interceptor already unwrapped 'data', so json is the inner object
    final matchList = (json['matches'] as List<dynamic>?) ?? [];
    return CvMatchResult(
      extractedTextPreview: json['extracted_text_preview'] as String? ?? '',
      matches: matchList
          .map((m) => JobMatch.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ExplainResult {
  final int jobId;
  final String jobTitle;
  final String jobCategory;
  final String cvIndustry;
  final double industryConfidence;
  final double cosineRaw;
  final double cosinePct;
  final List<String> matchedKeywords;
  final int kwBonus;
  final bool industryMatch;
  final int industryAdjustment;
  final double finalScore;
  final List<String> missingSkills;
  final String narrative;

  ExplainResult({
    required this.jobId,
    required this.jobTitle,
    required this.jobCategory,
    required this.cvIndustry,
    required this.industryConfidence,
    required this.cosineRaw,
    required this.cosinePct,
    required this.matchedKeywords,
    required this.kwBonus,
    required this.industryMatch,
    required this.industryAdjustment,
    required this.finalScore,
    required this.missingSkills,
    required this.narrative,
  });

  factory ExplainResult.fromJson(Map<String, dynamic> json) {
    // Interceptor already unwrapped 'data', so json is the inner object
    return ExplainResult(
      jobId: json['job_id'] as int? ?? 0,
      jobTitle: json['job_title'] as String? ?? '',
      jobCategory: json['job_category'] as String? ?? '',
      cvIndustry: json['cv_industry'] as String? ?? '',
      industryConfidence: (json['industry_confidence'] as num?)?.toDouble() ?? 0,
      cosineRaw: (json['cosine_raw'] as num?)?.toDouble() ?? 0,
      cosinePct: (json['cosine_pct'] as num?)?.toDouble() ?? 0,
      matchedKeywords: (json['matched_keywords'] as List<dynamic>?)
              ?.map((k) => k.toString())
              .toList() ??
          [],
      kwBonus: (json['kw_bonus'] as num?)?.toInt() ?? 0,
      industryMatch: json['industry_match'] as bool? ?? false,
      industryAdjustment: (json['industry_adjustment'] as num?)?.toInt() ?? 0,
      finalScore: (json['final_score'] as num?)?.toDouble() ?? 0,
      missingSkills: (json['missing_skills'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          [],
      narrative: json['narrative'] as String? ?? 'No detailed analysis available.',
    );
  }
}
