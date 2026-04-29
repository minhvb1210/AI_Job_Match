// lib/providers/cv_provider.dart
// State management for CV upload + job match results.

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/job_match.dart';
import '../services/cv_service.dart';
import '../services/api_service.dart';

enum CvUploadState { idle, loading, success, error }

class CvProvider extends ChangeNotifier {
  final CvService _service = CvService();

  CvUploadState _state = CvUploadState.idle;
  CvMatchResult? _result;
  String _errorMessage = '';
  String _selectedFileName = '';

  CvUploadState get state => _state;
  CvMatchResult? get result => _result;
  String get errorMessage => _errorMessage;
  String get selectedFileName => _selectedFileName;
  bool get hasResults => _result != null && _result!.matches.isNotEmpty;

  void setSelectedFile(String name) {
    _selectedFileName = name;
    notifyListeners();
  }

  Future<void> uploadCV(Uint8List bytes, String fileName) async {
    _state = CvUploadState.loading;
    _errorMessage = '';
    _selectedFileName = fileName;
    notifyListeners();

    try {
      final result = await _service.uploadCV(bytes, fileName);
      _result = result;
      _state = result.success ? CvUploadState.success : CvUploadState.error;
      if (!result.success) _errorMessage = result.message;
    } catch (e) {
      _state = CvUploadState.error;
      _errorMessage = ApiService.errorMessage(e);
    }

    notifyListeners();
  }

  void reset() {
    _state = CvUploadState.idle;
    _result = null;
    _errorMessage = '';
    _selectedFileName = '';
    notifyListeners();
  }
}
