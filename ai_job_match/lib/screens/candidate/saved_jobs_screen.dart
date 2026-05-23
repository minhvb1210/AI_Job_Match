import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../services/job_service.dart';
import '../../widgets/modern_job_card.dart';
import '../../theme/app_colors.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SavedJobsScreen extends StatefulWidget {
  const SavedJobsScreen({super.key});

  @override
  State<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends State<SavedJobsScreen> {
  final _jobService = JobService();
  List<dynamic> _savedJobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSavedJobs();
  }

  Future<void> _fetchSavedJobs() async {
    setState(() => _isLoading = true);
    try {
      final jobs = await _jobService.getSavedJobs();
      if (mounted) {
        setState(() {
          _savedJobs = jobs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unsaveJob(int jobId) async {
    try {
      await _jobService.toggleSaveJob(jobId, true);
      _fetchSavedJobs();
    } catch (e) {
      // Error handling
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Saved Jobs",
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Keep track of the opportunities you're interested in.",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Skeletonizer(
                    enabled: true,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      itemCount: 3,
                      itemBuilder: (context, index) => _buildSkeletonCard(),
                    ),
                  )
                : _savedJobs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        itemCount: _savedJobs.length,
                        itemBuilder: (context, index) {
                          final job = _savedJobs[index];
                          return ModernJobCard(
                            job: job,
                            isSaved: true,
                            onSave: () => _unsaveJob(job['id']),
                            onTap: () => context.push('/jobs/${job['id']}'),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.heart, size: 64, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            "No saved jobs yet",
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            "When you find a job you like, click the heart icon to save it here.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ShadButton(
            onPressed: () => context.go('/candidate'),
            child: const Text("Browse Jobs"),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
    );
  }
}
