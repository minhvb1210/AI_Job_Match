import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/application_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

class ApplicantsView extends StatefulWidget {
  final int jobId;
  final String jobTitle;
  const ApplicantsView({super.key, required this.jobId, required this.jobTitle});

  @override
  State<ApplicantsView> createState() => _ApplicantsViewState();
}

class _ApplicantsViewState extends State<ApplicantsView> {
  bool _isLoading = true;
  List<dynamic> _applicants = [];
  String _filterKeyword = '';
  final _appService = ApplicationService();

  @override
  void initState() {
    super.initState();
    _fetchApplicants();
  }

  Future<void> _fetchApplicants() async {
    try {
      final items = await _appService.getJobApplicants(jobId: widget.jobId);
      setState(() {
        _applicants = items.map((a) => {
          'id': a.id,
          'status': a.status,
          'match_score': a.matchScore,
          'candidate_email': a.candidateEmail,
          'candidate_skills': a.candidateSkills,
          'candidate_name': a.candidateName,
          'candidate_phone': a.candidatePhone,
          'candidate_avatar': a.candidateAvatar,
          'applied_at': a.appliedAt,
        }).toList();
        // Sort by match score by default (AI Power)
        _applicants.sort((a, b) => b['match_score'].compareTo(a['match_score']));
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int applicationId, String status) async {
    try {
      await _appService.updateStatus(applicationId: applicationId, status: status);
      _fetchApplicants();
      ShadToaster.of(context).show(ShadToast(title: const Text("Status Updated"), description: Text("Applicant is now marked as $status.")));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Applicants: ${widget.jobTitle}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: ShadInput(
              onChanged: (val) => setState(() => _filterKeyword = val.toLowerCase()),
              placeholder: const Text("Search applicants by skills or status..."),
              leading: const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(LucideIcons.search, size: 20, color: AppColors.textPlaceholder),
              ),
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _applicants.isEmpty 
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(32),
                    itemCount: _applicants.length,
                    itemBuilder: (context, index) {
                      var app = _applicants[index];
                      bool matchesSearch = app['candidate_skills'].toString().toLowerCase().contains(_filterKeyword) || 
                                         app['status'].toString().toLowerCase().contains(_filterKeyword) ||
                                         (app['candidate_name']?.toString().toLowerCase().contains(_filterKeyword) ?? false);
                      if (!matchesSearch) return const SizedBox.shrink();
                      
                      return _buildApplicantCard(app, index);
                    }
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicantCard(dynamic app, int index) {
    final score = app['match_score'];
    Color scoreColor = AppColors.success;
    if (score < 15) scoreColor = AppColors.warning;
    if (score < 8) scoreColor = AppColors.error;
    
    final avatarUrl = app['candidate_avatar'];
    final name = app['candidate_name'] ?? 'Candidate';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFF1F5F9),
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? const Icon(LucideIcons.user, color: AppColors.textSecondary, size: 24)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(app['candidate_email'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    if (app['candidate_phone'] != null && app['candidate_phone'].toString().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(LucideIcons.phone, size: 12, color: AppColors.textPlaceholder),
                          const SizedBox(width: 4),
                          Text(app['candidate_phone'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusChip(app['status']),
                        if (app['applied_at'] != null) ...[
                          const SizedBox(width: 12),
                          const Icon(LucideIcons.clock, size: 12, color: AppColors.textPlaceholder),
                          const SizedBox(width: 4),
                          Text("Applied ${app['applied_at']}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    "${score.toStringAsFixed(1)}%",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: scoreColor),
                  ),
                  const Text("AI Match", style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text("Candidate Expertise", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              app['candidate_skills'],
              style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (app['status'] == 'pending') ...[
                ShadButton.outline(
                  onPressed: () => _updateStatus(app['id'], 'rejected'),
                  child: const Text("Decline", style: TextStyle(color: AppColors.error)),
                ),
                const SizedBox(width: 12),
                ShadButton(
                  onPressed: () => _updateStatus(app['id'], 'accepted'),
                  child: const Text("Shortlist Candidate"),
                ),
              ] else if (app['status'] == 'accepted') ...[
                ShadButton.outline(
                  leading: const Icon(LucideIcons.calendar, size: 16),
                  onPressed: () => _showScheduleInterviewDialog(app['id']),
                  child: const Text("Invite for Interview"),
                ),
              ] else ...[
                Text("Decision: ${app['status'].toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              ]
            ],
          ),
        ],
      ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1),
    );
  }

  void _showScheduleInterviewDialog(int applicationId) {
    final dateController = TextEditingController();
    final timeController = TextEditingController();
    final locationController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Schedule Interview"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField("Date", ShadInput(
                controller: dateController,
                placeholder: const Text("YYYY-MM-DD"),
              )),
              const SizedBox(height: 16),
              _buildDialogField("Time", ShadInput(
                controller: timeController,
                placeholder: const Text("HH:MM"),
              )),
              const SizedBox(height: 16),
              _buildDialogField("Location", ShadInput(
                controller: locationController,
                placeholder: const Text("Google Meet link or Office Address"),
              )),
              const SizedBox(height: 16),
              _buildDialogField("Notes (Optional)", ShadInput(
                controller: noteController,
                placeholder: const Text("Any additional notes..."),
                maxLines: 3,
              )),
            ],
          ),
        ),
        actions: [
          ShadButton.ghost(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ShadButton(
            onPressed: () async {
              final scheduledTime = "${dateController.text}T${timeController.text}:00Z";
              try {
                final dio = await ApiService.authenticated();
                await dio.post('/interviews/schedule', data: {
                  "application_id": applicationId,
                  "scheduled_time": scheduledTime,
                  "location": locationController.text,
                  "note": noteController.text,
                });
                Navigator.pop(context);
                _fetchApplicants();
                ShadToaster.of(context).show(const ShadToast(
                  title: Text("Interview Scheduled"),
                  description: Text("Invitation email has been sent to the candidate."),
                ));
              } catch (e) {
                ShadToaster.of(context).show(ShadToast.destructive(
                  title: const Text("Error"),
                  description: Text("Failed to schedule: $e"),
                ));
              }
            },
            child: const Text("Send Invitation"),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = AppColors.warning;
    if (status == 'accepted') color = AppColors.success;
    if (status == 'rejected') color = AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.users, size: 64, color: AppColors.textPlaceholder.withOpacity(0.3)),
          const SizedBox(height: 24),
          const Text("No applicants yet", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("We'll notify you when someone applies to this role.", style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
