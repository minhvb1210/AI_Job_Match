import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final data = await _service.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(int id, int index) async {
    setState(() {
      _notifications[index]['is_read'] = true;
    });
    await _service.markAsRead(id);
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      for (var n in _notifications) {
        n['is_read'] = true;
      }
    });
    await _service.markAllAsRead();
  }

  int get _unreadCount =>
      _notifications.where((n) => n['is_read'] != true).length;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(LucideIcons.bell, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (!_isLoading)
                      Text(
                        _unreadCount > 0
                            ? '$_unreadCount unread notification${_unreadCount > 1 ? 's' : ''}'
                            : 'All caught up!',
                        style: TextStyle(
                          color: _unreadCount > 0 ? AppColors.primary : AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              if (_unreadCount > 0)
                ShadButton.outline(
                  onPressed: _markAllAsRead,
                  leading: const Icon(LucideIcons.checkCheck, size: 16),
                  child: const Text('Mark all read'),
                ),
            ],
          ),

          const SizedBox(height: 32),

          // Notification list
          if (_isLoading)
            Skeletonizer(
              enabled: true,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                itemBuilder: (_, __) => Container(
                  height: 80,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            )
          else if (_notifications.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 64),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.bellOff, size: 48, color: AppColors.textPlaceholder),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No notifications yet',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You\'ll receive notifications here when there are updates.',
                    style: TextStyle(color: AppColors.textPlaceholder),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final n = _notifications[index];
                final isRead = n['is_read'] == true;
                final message = n['message'] ?? '';
                final createdAt = n['created_at'];

                return _NotificationCard(
                  message: message,
                  createdAt: createdAt,
                  isRead: isRead,
                  onTap: () {
                    if (!isRead) _markAsRead(n['id'], index);
                    _showNotificationDetail(context, message, createdAt);
                  },
                )
                    .animate()
                    .fadeIn(delay: (index * 60).ms)
                    .slideX(begin: 0.05);
              },
            ),
        ],
      ),
    );
  }

  void _showNotificationDetail(BuildContext context, String message, String? createdAt) {
    // Parse interview notification details
    final isInterview = message.contains('Interview') || message.contains('📅');
    
    String title = 'Notification Details';
    List<Widget> details = [];
    
    if (isInterview) {
      title = '📅 Interview Invitation';
      
      // Extract job title
      final jobMatch = RegExp(r"for '(.+?)'").firstMatch(message);
      final jobTitle = jobMatch?.group(1) ?? 'N/A';
      
      // Extract date/time
      final dateMatch = RegExp(r"on (.+?)\. Location").firstMatch(message);
      final dateTime = dateMatch?.group(1) ?? 'TBD';
      
      // Extract location
      final locMatch = RegExp(r"Location: (.+?)\. Scheduled").firstMatch(message);
      final location = locMatch?.group(1) ?? 'TBD';
      
      // Extract recruiter
      final recruiterMatch = RegExp(r"Scheduled by (.+)\.?$").firstMatch(message);
      final recruiter = recruiterMatch?.group(1) ?? 'N/A';
      
      details = [
        _detailRow(LucideIcons.briefcase, 'Position', jobTitle),
        const SizedBox(height: 16),
        _detailRow(LucideIcons.calendarCheck, 'Date & Time', dateTime),
        const SizedBox(height: 16),
        _detailRow(LucideIcons.mapPin, 'Location', location),
        const SizedBox(height: 16),
        _detailRow(LucideIcons.user, 'Scheduled by', recruiter),
      ];
    } else {
      // For non-interview notifications
      if (message.contains('application') || message.contains('📩')) {
        title = '📩 Application Update';
      } else if (message.contains('updated')) {
        title = '🔄 Status Update';
      }
      details = [
        Text(
          message,
          style: const TextStyle(fontSize: 15, height: 1.6, color: AppColors.textPrimary),
        ),
      ];
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...details,
            if (createdAt != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(LucideIcons.clock, size: 14, color: AppColors.textPlaceholder),
                  const SizedBox(width: 6),
                  Text(
                    'Received: ${_formatCreatedAt(createdAt)}',
                    style: const TextStyle(color: AppColors.textPlaceholder, fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          ShadButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textPlaceholder, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatCreatedAt(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoTime;
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final String message;
  final String? createdAt;
  final bool isRead;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.message,
    this.createdAt,
    required this.isRead,
    required this.onTap,
  });

  String _formatTime(String? isoTime) {
    if (isoTime == null) return '';
    try {
      final dt = DateTime.parse(isoTime);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  IconData _getIcon() {
    if (message.contains('Interview') || message.contains('📅')) {
      return LucideIcons.calendarCheck;
    } else if (message.contains('application') || message.contains('📩')) {
      return LucideIcons.fileCheck;
    } else if (message.contains('updated')) {
      return LucideIcons.refreshCw;
    }
    return LucideIcons.bellRing;
  }

  Color _getIconColor() {
    if (message.contains('Interview') || message.contains('📅')) {
      return const Color(0xFF8B5CF6); // purple
    } else if (message.contains('application') || message.contains('📩')) {
      return const Color(0xFF3B82F6); // blue
    } else if (message.contains('accepted') || message.contains('Accepted')) {
      return AppColors.success;
    } else if (message.contains('rejected') || message.contains('Rejected')) {
      return AppColors.error;
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getIconColor();
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : AppColors.primary.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? const Color(0xFFE2E8F0) : AppColors.primary.withOpacity(0.15),
            width: isRead ? 1 : 1.5,
          ),
          boxShadow: isRead
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getIcon(), size: 20, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(createdAt),
                      style: const TextStyle(
                        color: AppColors.textPlaceholder,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
