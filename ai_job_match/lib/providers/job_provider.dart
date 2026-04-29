import 'package:flutter/material.dart';
import '../services/job_service.dart';
import '../services/cv_service.dart';

class JobProvider extends ChangeNotifier {
  final _jobService = JobService();
  final _cvService = CvService();

  List<dynamic> _jobs = [];
  Map<int, double?> _matchScores = {};
  bool _isLoading = false;
  bool _isMatching = false;
  bool _hasCV = false;

  List<dynamic> get jobs => _jobs;
  Map<int, double?> get matchScores => _matchScores;
  bool get isLoading => _isLoading;
  bool get isMatching => _isMatching;
  bool get hasCV => _hasCV;

  String _query = '';
  String? _location;
  int? _minSalary;
  String _sortBy = 'newest';

  void updateFilters({String? query, String? location, int? minSalary, String? sortBy}) {
    if (query != null) _query = query;
    if (location != null) _location = location;
    if (minSalary != null) _minSalary = minSalary;
    if (sortBy != null) _sortBy = sortBy;
    fetchJobs();
  }

  Future<void> fetchJobs() async {
    _isLoading = true;
    _matchScores = {}; // Reset scores for new search
    notifyListeners();

    try {
      final result = await _jobService.searchJobs(
        query: _query,
        location: _location,
        minSalary: _minSalary,
        sortBy: _sortBy,
      );
      _jobs = result;
      _isLoading = false;
      notifyListeners();

      // Chain CV check and matching
      await checkCV();
      if (_hasCV && _jobs.isNotEmpty) {
        fetchMatchScores();
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkCV() async {
    try {
      final profile = await _cvService.checkCV();
      _hasCV = profile != null;
    } catch (_) {
      _hasCV = false;
    }
  }

  Future<void> fetchMatchScores() async {
    if (_isMatching || !_hasCV || _jobs.isEmpty) return;

    _isMatching = true;
    notifyListeners();

    try {
      // Rule: Only send first 20 job_ids
      final idsToMatch = _jobs.take(20).map((j) => j['id'] as int).toList();
      
      final scores = await _jobService.matchJobsBatch(idsToMatch);
      _matchScores.addAll(scores);
    } catch (_) {
      // Rule: No crash if scoring fails
    } finally {
      _isMatching = false;
      notifyListeners();
    }
  }

  double? getScore(int jobId) => _matchScores[jobId];
}
