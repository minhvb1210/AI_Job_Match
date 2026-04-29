// lib/providers/explain_provider.dart
// State management for the AI explain endpoint.

import 'package:flutter/foundation.dart';
import '../models/job_match.dart';
import '../services/cv_service.dart';
import '../services/api_service.dart';

enum ExplainState { idle, loading, success, error }

class ExplainProvider extends ChangeNotifier {
  final CvService _service = CvService();

  ExplainState _state = ExplainState.idle;
  ExplainResult? _result;
  String _errorMessage = '';

  ExplainState get state => _state;
  ExplainResult? get result => _result;
  String get errorMessage => _errorMessage;

  Future<void> explain({
    required int jobId,
    String? token,
    String? cvText,
  }) async {
    _state = ExplainState.loading;
    _errorMessage = '';
    _result = null;
    notifyListeners();

    try {
      ExplainResult result;
      if (token != null && token.isNotEmpty) {
        result = await _service.explainJob(jobId: jobId, token: token);
      } else if (cvText != null && cvText.isNotEmpty) {
        result = await _service.explainJobFromText(jobId: jobId, cvText: cvText);
      } else {
        throw Exception('Either token or cvText must be provided');
      }
      _result = result;
      _state = ExplainState.success;
    } catch (e) {
      _state = ExplainState.error;
      _errorMessage = ApiService.errorMessage(e);
    }

    notifyListeners();
  }

  void reset() {
    _state = ExplainState.idle;
    _result = null;
    _errorMessage = '';
    notifyListeners();
  }
}
