// lib/providers/recruiter_provider.dart
// State for recruiter applicant list and status updates.

import 'package:flutter/foundation.dart';
import '../models/application.dart';
import '../services/application_service.dart';
import '../services/api_service.dart';

enum RecruiterLoadState { idle, loading, success, error }

class RecruiterProvider extends ChangeNotifier {
  final ApplicationService _service = ApplicationService();

  RecruiterLoadState _state = RecruiterLoadState.idle;
  List<ApplicantInfo> _applicants = [];
  String _errorMessage = '';
  final Map<int, bool> _updatingStatus = {};

  RecruiterLoadState get state => _state;
  List<ApplicantInfo> get applicants => _applicants;
  String get errorMessage => _errorMessage;

  bool isUpdating(int applicationId) => _updatingStatus[applicationId] ?? false;

  // Filter: '' = all, or 'pending', 'reviewing', 'accepted', 'rejected'
  String _filterStatus = '';
  String get filterStatus => _filterStatus;

  List<ApplicantInfo> get filteredApplicants {
    if (_filterStatus.isEmpty) return _applicants;
    return _applicants
        .where((a) => a.status == _filterStatus)
        .toList();
  }

  void setFilter(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  Future<void> loadApplicants(int jobId) async {
    _state = RecruiterLoadState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      _applicants = await _service.getJobApplicants(jobId: jobId);
      _state = RecruiterLoadState.success;
    } catch (e) {
      _state = RecruiterLoadState.error;
      _errorMessage = ApiService.errorMessage(e);
    }

    notifyListeners();
  }

  Future<String?> updateStatus({
    required int applicationId,
    required String status,
  }) async {
    _updatingStatus[applicationId] = true;
    notifyListeners();

    try {
      await _service.updateStatus(applicationId: applicationId, status: status);
      // Update local state immediately
      final idx = _applicants.indexWhere((a) => a.id == applicationId);
      if (idx != -1) {
        _applicants[idx] = ApplicantInfo(
          id:              _applicants[idx].id,
          rank:            _applicants[idx].rank,
          status:          status,
          matchScore:      _applicants[idx].matchScore,
          createdAt:       _applicants[idx].createdAt,
          candidateId:     _applicants[idx].candidateId,
          candidateEmail:  _applicants[idx].candidateEmail,
          candidateSkills: _applicants[idx].candidateSkills,
          missingSkills:   _applicants[idx].missingSkills,
          isTopCandidate:  _applicants[idx].isTopCandidate,
        );
      }
      _updatingStatus[applicationId] = false;
      notifyListeners();
      return null;
    } catch (e) {
      _updatingStatus[applicationId] = false;
      notifyListeners();
      return ApiService.errorMessage(e);
    }
  }

  Future<String?> scheduleInterview({
    required int applicationId,
    required DateTime time,
    required String location,
    String? note,
  }) async {
    _updatingStatus[applicationId] = true;
    notifyListeners();

    try {
      await _service.scheduleInterview(
        applicationId: applicationId,
        time:          time,
        location:      location,
        note:          note,
      );
      
      // Update local state to 'interviewing'
      final idx = _applicants.indexWhere((a) => a.id == applicationId);
      if (idx != -1) {
        _applicants[idx] = ApplicantInfo(
          id:              _applicants[idx].id,
          rank:            _applicants[idx].rank,
          status:          'interviewing',
          matchScore:      _applicants[idx].matchScore,
          createdAt:       _applicants[idx].createdAt,
          candidateId:     _applicants[idx].candidateId,
          candidateEmail:  _applicants[idx].candidateEmail,
          candidateSkills: _applicants[idx].candidateSkills,
          missingSkills:   _applicants[idx].missingSkills,
          isTopCandidate:  _applicants[idx].isTopCandidate,
        );
      }
      
      _updatingStatus[applicationId] = false;
      notifyListeners();
      return null;
    } catch (e) {
      _updatingStatus[applicationId] = false;
      notifyListeners();
      return ApiService.errorMessage(e);
    }
  }
}
