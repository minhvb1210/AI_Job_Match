import 'package:flutter/material.dart';
import '../models/resume_data.dart';

class ResumeProvider with ChangeNotifier {
  ResumeData _data = ResumeData();

  ResumeData get data => _data;

  void updateData(ResumeData newData) {
    _data = newData;
    notifyListeners();
  }

  void updatePersonalInfo({
    String? fullName,
    String? jobTitle,
    String? email,
    String? phone,
    String? website,
    String? address,
    String? avatarUrl,
    String? objective,
  }) {
    _data = _data.copyWith(
      fullName: fullName,
      jobTitle: jobTitle,
      email: email,
      phone: phone,
      website: website,
      address: address,
      avatarUrl: avatarUrl,
      objective: objective,
    );
    notifyListeners();
  }

  void setTemplate(String templateId) {
    _data = _data.copyWith(templateId: templateId);
    notifyListeners();
  }

  void setAccentColor(String hexColor) {
    _data = _data.copyWith(accentColor: hexColor);
    notifyListeners();
  }

  void setFont(String font) {
    _data = _data.copyWith(fontFamily: font);
    notifyListeners();
  }

  // List updates
  void addEducation(ResumeEducation edu) {
    final newList = List<ResumeEducation>.from(_data.education)..add(edu);
    _data = _data.copyWith(education: newList);
    notifyListeners();
  }

  void removeEducation(int index) {
    final newList = List<ResumeEducation>.from(_data.education)..removeAt(index);
    _data = _data.copyWith(education: newList);
    notifyListeners();
  }

  void updateEducation(int index, ResumeEducation edu) {
    final newList = List<ResumeEducation>.from(_data.education);
    newList[index] = edu;
    _data = _data.copyWith(education: newList);
    notifyListeners();
  }

  void addExperience(ResumeExperience exp) {
    final newList = List<ResumeExperience>.from(_data.experience)..add(exp);
    _data = _data.copyWith(experience: newList);
    notifyListeners();
  }

  void removeExperience(int index) {
    final newList = List<ResumeExperience>.from(_data.experience)..removeAt(index);
    _data = _data.copyWith(experience: newList);
    notifyListeners();
  }

  void updateExperience(int index, ResumeExperience exp) {
    final newList = List<ResumeExperience>.from(_data.experience);
    newList[index] = exp;
    _data = _data.copyWith(experience: newList);
    notifyListeners();
  }

  void addProject(ResumeProject proj) {
    final newList = List<ResumeProject>.from(_data.projects)..add(proj);
    _data = _data.copyWith(projects: newList);
    notifyListeners();
  }

  void removeProject(int index) {
    final newList = List<ResumeProject>.from(_data.projects)..removeAt(index);
    _data = _data.copyWith(projects: newList);
    notifyListeners();
  }

  void updateProject(int index, ResumeProject proj) {
    final newList = List<ResumeProject>.from(_data.projects);
    newList[index] = proj;
    _data = _data.copyWith(projects: newList);
    notifyListeners();
  }

  void updateSkills(List<String> skills) {
    _data = _data.copyWith(skills: skills);
    notifyListeners();
  }

  void updateCertificates(List<String> certs) {
    _data = _data.copyWith(certificates: certs);
    notifyListeners();
  }

  void updateLanguages(List<String> langs) {
    _data = _data.copyWith(languages: langs);
    notifyListeners();
  }
}
