// lib/providers/application_provider.dart
// State for candidate application workflow.

import 'package:flutter/foundation.dart';
import '../models/application.dart';
import '../services/application_service.dart';
import '../services/api_service.dart';

enum ApplyState { idle, loading, success, error, alreadyApplied }

class ApplicationProvider extends ChangeNotifier {
  final ApplicationService _service = ApplicationService();

  // ── My Applications list ───────────────────────────────────────────────────
  List<MyApplication> _myApplications = [];
  bool _loadingApplications = false;
  String _applicationsError = '';

  List<MyApplication> get myApplications => _myApplications;
  bool get loadingApplications => _loadingApplications;
  String get applicationsError => _applicationsError;

  /// Set of job IDs the user has already applied to (for instant UI feedback).
  final Set<int> _appliedJobIds = {};
  bool hasApplied(int jobId) => _appliedJobIds.contains(jobId);

  // ── Per-job apply state ───────────────────────────────────────────────────
  final Map<int, ApplyState> _applyStates = {};
  ApplyState applyStateFor(int jobId) =>
      _applyStates[jobId] ?? ApplyState.idle;

  // ── Load my applications ──────────────────────────────────────────────────
  Future<void> loadMyApplications() async {
    _loadingApplications = true;
    _applicationsError = '';
    notifyListeners();

    try {
      _myApplications = await _service.getMyApplications();
      // Populate applied set from loaded data
      _appliedJobIds.addAll(_myApplications.map((a) => a.jobId));
    } catch (e) {
      _applicationsError = ApiService.errorMessage(e);
    }

    _loadingApplications = false;
    notifyListeners();
  }

  // ── Apply for a job ───────────────────────────────────────────────────────
  Future<String?> applyForJob({
    required int jobId,
    double matchScore = 0,
  }) async {
    if (_appliedJobIds.contains(jobId)) {
      _applyStates[jobId] = ApplyState.alreadyApplied;
      notifyListeners();
      return 'Already applied';
    }

    _applyStates[jobId] = ApplyState.loading;
    notifyListeners();

    try {
      final result = await _service.applyForJob(
        jobId: jobId,
        matchScore: matchScore,
      );

      if (result['success'] == true) {
        _applyStates[jobId] = ApplyState.success;
        _appliedJobIds.add(jobId);
        // Add optimistic entry
        _myApplications.insert(
          0,
          MyApplication(
            id: result['data']?['id'] ?? 0,
            jobId: jobId,
            status: 'pending',
            matchScore: matchScore,
            jobTitle: '',
            company: '',
          ),
        );
        notifyListeners();
        return null; // success
      } else {
        _applyStates[jobId] = ApplyState.error;
        notifyListeners();
        return result['message'] as String? ?? 'Application failed';
      }
    } catch (e) {
      final msg = ApiService.errorMessage(e);
      // 400 "already applied" → treat as applied state
      if (msg.toLowerCase().contains('already')) {
        _applyStates[jobId] = ApplyState.alreadyApplied;
        _appliedJobIds.add(jobId);
      } else {
        _applyStates[jobId] = ApplyState.error;
      }
      notifyListeners();
      return msg;
    }
  }
}
