// lib/screens/my_applications_screen.dart
// Candidate: list of submitted applications with status tracking.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/application.dart';
import '../providers/application_provider.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ApplicationProvider>().loadMyApplications(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F16),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'My Applications',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            onPressed: () => context.read<ApplicationProvider>().loadMyApplications(),
          ),
        ],
      ),
      body: Consumer<ApplicationProvider>(
        builder: (context, provider, _) {
          if (provider.loadingApplications) {
            return const _SkeletonList();
          }
          if (provider.applicationsError.isNotEmpty) {
            return _ErrorView(
              message: provider.applicationsError,
              onRetry: provider.loadMyApplications,
            );
          }
          if (provider.myApplications.isEmpty) {
            return _EmptyView();
          }
          return _ApplicationList(applications: provider.myApplications);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ApplicationList extends StatelessWidget {
  final List<MyApplication> applications;
  const _ApplicationList({required this.applications});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: applications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _AppCard(app: applications[i]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _AppCard extends StatelessWidget {
  final MyApplication app;
  const _AppCard({required this.app});

  static const _statusColors = {
    'pending':      Color(0xFFFFB347), // amber
    'reviewing':    Color(0xFFFF9800), // orange
    'interviewing': Color(0xFF2196F3), // blue
    'accepted':     Color(0xFF4CAF50), // green
    'rejected':     Color(0xFFF44336), // red
  };

  static const _statusIcons = {
    'pending':      Icons.hourglass_empty_rounded,
    'reviewing':    Icons.manage_search_rounded,
    'interviewing': Icons.calendar_today_rounded,
    'accepted':     Icons.check_circle_outline_rounded,
    'rejected':     Icons.cancel_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[app.status] ?? const Color(0xFF6C63FF);
    final icon  = _statusIcons[app.status]  ?? Icons.info_outline;
    final score = app.matchScore;
    final scoreColor = score >= 80
        ? const Color(0xFF4CAF50)
        : score >= 60
            ? const Color(0xFFFFC107)
            : const Color(0xFFF44336);

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // Status icon bubble
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              // Job info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.jobTitle.isEmpty ? 'Job #${app.jobId}' : app.jobTitle,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (app.company.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        app.company,
                        style: GoogleFonts.outfit(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: color.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            app.statusLabel,
                            style: GoogleFonts.outfit(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (app.createdAt != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(app.createdAt!),
                            style: GoogleFonts.outfit(
                              color: Colors.white30,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Score
              if (score > 0) ...[
                const SizedBox(width: 12),
                Column(
                  children: [
                    Text(
                      '${score.toStringAsFixed(0)}%',
                      style: GoogleFonts.outfit(
                        color: scoreColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Match',
                      style: GoogleFonts.outfit(
                        color: Colors.white30,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (app.status == 'interviewing') ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF2196F3), size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Interview scheduled. Check your email for full details and meeting links.',
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, color: Colors.white24, size: 72),
          const SizedBox(height: 16),
          Text(
            'No applications yet',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your CV and apply to matched jobs',
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Go to CV Matching'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFF44336), size: 56),
            const SizedBox(height: 16),
            Text(
              'Failed to load applications',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF44336),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton Loading (Lightweight Gray Boxes)
// ─────────────────────────────────────────────────────────────────────────────
class _SkeletonList extends StatelessWidget {
  const _SkeletonList();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => const _AppSkeleton(),
    );
  }
}

class _AppSkeleton extends StatelessWidget {
  const _AppSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white12)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 150, height: 14, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Container(width: 100, height: 10, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 10),
                Container(width: 60, height: 18, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6))),
              ],
            ),
          ),
          Column(
            children: [
              Container(width: 40, height: 16, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 4),
              Container(width: 30, height: 10, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
            ],
          ),
        ],
      ),
    );
  }
}
