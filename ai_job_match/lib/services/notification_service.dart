import '../services/api_service.dart';

class NotificationService {
  /// Fetch all notifications for the current user
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final dio = await ApiService.authenticated();
    final res = await dio.get('/notifications/');
    if (res.data is Map && res.data['success'] == true) {
      return List<Map<String, dynamic>>.from(res.data['data'] ?? []);
    }
    return [];
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    final dio = await ApiService.authenticated();
    final res = await dio.get('/notifications/unread-count');
    if (res.data is Map && res.data['success'] == true) {
      return res.data['data']['count'] ?? 0;
    }
    return 0;
  }

  /// Mark a single notification as read
  Future<void> markAsRead(int notificationId) async {
    final dio = await ApiService.authenticated();
    await dio.put('/notifications/$notificationId/read');
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final dio = await ApiService.authenticated();
    await dio.put('/notifications/read-all');
  }
}
