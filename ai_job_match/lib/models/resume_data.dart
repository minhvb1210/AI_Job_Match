import 'dart:convert';

class ResumeData {
  String fullName;
  String jobTitle;
  String email;
  String phone;
  String website;
  String address;
  String avatarUrl;
  String objective;
  List<String> skills;
  List<ResumeEducation> education;
  List<ResumeExperience> experience;
  List<ResumeProject> projects;
  List<String> certificates;
  List<String> languages;
  Map<String, String> socialLinks;
  
  // Customization
  String templateId; // 'modern', 'professional', 'creative'
  String accentColor; // Hex string
  String fontFamily; // Font name

  ResumeData({
    this.fullName = "Your Name",
    this.jobTitle = "Software Engineer",
    this.email = "you@example.com",
    this.phone = "+84 123 456 789",
    this.website = "www.yourportfolio.com",
    this.address = "Hanoi, Vietnam",
    this.avatarUrl = "",
    this.objective = "Passionate developer with expertise in building modern web and mobile applications.",
    this.skills = const ["Flutter", "Dart", "Firebase", "FastAPI", "Python"],
    this.education = const [],
    this.experience = const [],
    this.projects = const [],
    this.certificates = const [],
    this.languages = const ["English", "Vietnamese"],
    this.socialLinks = const {"LinkedIn": "", "GitHub": ""},
    this.templateId = "modern",
    this.accentColor = "#3B82F6",
    this.fontFamily = "Inter",
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'jobTitle': jobTitle,
      'email': email,
      'phone': phone,
      'website': website,
      'address': address,
      'avatarUrl': avatarUrl,
      'objective': objective,
      'skills': skills,
      'education': education.map((x) => x.toMap()).toList(),
      'experience': experience.map((x) => x.toMap()).toList(),
      'projects': projects.map((x) => x.toMap()).toList(),
      'certificates': certificates,
      'languages': languages,
      'socialLinks': socialLinks,
      'templateId': templateId,
      'accentColor': accentColor,
      'fontFamily': fontFamily,
    };
  }

  factory ResumeData.fromMap(Map<String, dynamic> map) {
    return ResumeData(
      fullName: map['fullName'] ?? '',
      jobTitle: map['jobTitle'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      website: map['website'] ?? '',
      address: map['address'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      objective: map['objective'] ?? '',
      skills: List<String>.from(map['skills'] ?? []),
      education: List<ResumeEducation>.from(map['education']?.map((x) => ResumeEducation.fromMap(x)) ?? []),
      experience: List<ResumeExperience>.from(map['experience']?.map((x) => ResumeExperience.fromMap(x)) ?? []),
      projects: List<ResumeProject>.from(map['projects']?.map((x) => ResumeProject.fromMap(x)) ?? []),
      certificates: List<String>.from(map['certificates'] ?? []),
      languages: List<String>.from(map['languages'] ?? []),
      socialLinks: Map<String, String>.from(map['socialLinks'] ?? {}),
      templateId: map['templateId'] ?? 'modern',
      accentColor: map['accentColor'] ?? '#3B82F6',
      fontFamily: map['fontFamily'] ?? 'Inter',
    );
  }

  String toJson() => json.encode(toMap());

  factory ResumeData.fromJson(String source) => ResumeData.fromMap(json.decode(source));

  ResumeData copyWith({
    String? fullName,
    String? jobTitle,
    String? email,
    String? phone,
    String? website,
    String? address,
    String? avatarUrl,
    String? objective,
    List<String>? skills,
    List<ResumeEducation>? education,
    List<ResumeExperience>? experience,
    List<ResumeProject>? projects,
    List<String>? certificates,
    List<String>? languages,
    Map<String, String>? socialLinks,
    String? templateId,
    String? accentColor,
    String? fontFamily,
  }) {
    return ResumeData(
      fullName: fullName ?? this.fullName,
      jobTitle: jobTitle ?? this.jobTitle,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      objective: objective ?? this.objective,
      skills: skills ?? this.skills,
      education: education ?? this.education,
      experience: experience ?? this.experience,
      projects: projects ?? this.projects,
      certificates: certificates ?? this.certificates,
      languages: languages ?? this.languages,
      socialLinks: socialLinks ?? this.socialLinks,
      templateId: templateId ?? this.templateId,
      accentColor: accentColor ?? this.accentColor,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }
}

class ResumeEducation {
  String school;
  String degree;
  String startYear;
  String endYear;
  String gpa;

  ResumeEducation({
    this.school = "",
    this.degree = "",
    this.startYear = "",
    this.endYear = "",
    this.gpa = "",
  });

  Map<String, dynamic> toMap() {
    return {
      'school': school,
      'degree': degree,
      'startYear': startYear,
      'endYear': endYear,
      'gpa': gpa,
    };
  }

  factory ResumeEducation.fromMap(Map<String, dynamic> map) {
    return ResumeEducation(
      school: map['school'] ?? '',
      degree: map['degree'] ?? '',
      startYear: map['startYear'] ?? '',
      endYear: map['endYear'] ?? '',
      gpa: map['gpa'] ?? '',
    );
  }
}

class ResumeExperience {
  String company;
  String position;
  String startYear;
  String endYear;
  String description;

  ResumeExperience({
    this.company = "",
    this.position = "",
    this.startYear = "",
    this.endYear = "",
    this.description = "",
  });

  Map<String, dynamic> toMap() {
    return {
      'company': company,
      'position': position,
      'startYear': startYear,
      'endYear': endYear,
      'description': description,
    };
  }

  factory ResumeExperience.fromMap(Map<String, dynamic> map) {
    return ResumeExperience(
      company: map['company'] ?? '',
      position: map['position'] ?? '',
      startYear: map['startYear'] ?? '',
      endYear: map['endYear'] ?? '',
      description: map['description'] ?? '',
    );
  }
}

class ResumeProject {
  String name;
  String description;
  String link;

  ResumeProject({
    this.name = "",
    this.description = "",
    this.link = "",
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'link': link,
    };
  }

  factory ResumeProject.fromMap(Map<String, dynamic> map) {
    return ResumeProject(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      link: map['link'] ?? '',
    );
  }
}
