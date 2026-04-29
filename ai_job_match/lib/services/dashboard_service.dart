import 'package:flutter/foundation.dart';
import 'api_service.dart';

class DashboardService {
  Future<Map<String, dynamic>> getStats() async {
    final dio = await ApiService.authenticated();
    final response = await dio.get('/dashboard/stats');
    if (response.data is Map && response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    }
    return {};
  }
}


class DashboardProvider extends ChangeNotifier {
  final _service = DashboardService();
  
  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  String _errorMessage = '';

  Map<String, dynamic>? get stats => _stats;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> loadStats() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _stats = await _service.getStats();
    } catch (e) {
      _errorMessage = ApiService.errorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
