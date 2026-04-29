// lib/screens/applicants_screen.dart
// Recruiter: view applicants for a job, sorted by AI score, with status actions.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/application.dart';
import '../providers/recruiter_provider.dart';

class ApplicantsScreen extends StatefulWidget {
  final int jobId;
  final String jobTitle;
  const ApplicantsScreen({super.key, required this.jobId, required this.jobTitle});

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecruiterProvider>().loadApplicants(widget.jobId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F16),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _FilterBar(),
          Expanded(child: _ApplicantBody(jobId: widget.jobId)),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0F0F16),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Applicants',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          Text(
            widget.jobTitle,
            style: GoogleFonts.outfit(
                color: const Color(0xFF6C63FF), fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
          onPressed: () =>
              context.read<RecruiterProvider>().loadApplicants(widget.jobId),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter bar
// ─────────────────────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final _filters = const [
    ('All', ''),
    ('Pending', 'pending'),
    ('Reviewing', 'reviewing'),
    ('Interviewing', 'interviewing'),
    ('Accepted', 'accepted'),
    ('Rejected', 'rejected'),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecruiterProvider>();
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (label, value) = _filters[i];
          final isActive = provider.filterStatus == value;
          return GestureDetector(
            onTap: () => context.read<RecruiterProvider>().setFilter(value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF6C63FF)
                    : const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF6C63FF)
                      : Colors.white12,
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  color: isActive ? Colors.white : Colors.white54,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────
class _ApplicantBody extends StatelessWidget {
  final int jobId;
  const _ApplicantBody({required this.jobId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecruiterProvider>();
    switch (provider.state) {
      case RecruiterLoadState.loading:
        return const _SkeletonList();
      case RecruiterLoadState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFF44336), size: 48),
                const SizedBox(height: 16),
                Text(
                  provider.errorMessage,
                  style: GoogleFonts.outfit(color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => provider.loadApplicants(jobId),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry Loading'),
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
      case RecruiterLoadState.success:
        final applicants = provider.filteredApplicants;
        if (applicants.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.group_outlined, color: Colors.white24, size: 64),
                const SizedBox(height: 16),
                Text(
                  provider.filterStatus.isEmpty
                      ? 'No applications yet'
                      : 'No ${provider.filterStatus} applications',
                  style: GoogleFonts.outfit(color: Colors.white54),
                ),
              ],
            ),
          );
        }
        return _ApplicantList(applicants: applicants);
      default:
        return const SizedBox();
    }
  }
}

class _ApplicantList extends StatelessWidget {
  final List<ApplicantInfo> applicants;
  const _ApplicantList({required this.applicants});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: applicants.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _ApplicantCard(applicant: applicants[i]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Applicant Card
// ─────────────────────────────────────────────────────────────────────────────
class _ApplicantCard extends StatelessWidget {
  final ApplicantInfo applicant;
  const _ApplicantCard({required this.applicant});

  static const _rankColors = [
    Color(0xFFFFD700), // 1st
    Color(0xFFC0C0C0), // 2nd
    Color(0xFFCD7F32), // 3rd
  ];
  static const _statusColors = {
    'pending':      Color(0xFFFFB347), // amber
    'reviewing':    Color(0xFFFF9800), // orange
    'interviewing': Color(0xFF2196F3), // blue
    'accepted':     Color(0xFF4CAF50), // green
    'rejected':     Color(0xFFF44336), // red
  };

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<RecruiterProvider>();
    final isUpdating = provider.isUpdating(applicant.id);
    final score      = applicant.matchScore;
    final scoreColor = score >= 80
        ? const Color(0xFF4CAF50)
        : score >= 60
            ? const Color(0xFFFFC107)
            : const Color(0xFFF44336);
    final rankColor = applicant.isTopCandidate && applicant.rank <= 3
        ? _rankColors[applicant.rank - 1]
        : Colors.white24;
    final statusColor =
        _statusColors[applicant.status] ?? const Color(0xFFFFB347);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: applicant.isTopCandidate
              ? rankColor.withValues(alpha: 0.4)
              : Colors.white10,
          width: applicant.isTopCandidate ? 1.5 : 1,
        ),
        boxShadow: applicant.isTopCandidate
            ? [
                BoxShadow(
                  color: rankColor.withValues(alpha: 0.1),
                  blurRadius: 16,
                )
              ]
            : null,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: rank + email + score ─────────────────────────────────
          Row(
            children: [
              if (applicant.isTopCandidate) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rankColor.withValues(alpha: 0.15),
                    border: Border.all(color: rankColor, width: 2),
                    boxShadow: [
                      BoxShadow(color: rankColor.withValues(alpha: 0.2), blurRadius: 8)
                    ],
                  ),
                  child: Center(
                    child: applicant.rank == 1 
                      ? Icon(Icons.emoji_events_rounded, color: rankColor, size: 18)
                      : Text(
                          '#${applicant.rank}',
                          style: GoogleFonts.outfit(
                              color: rankColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w900),
                        ),
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      applicant.candidateEmail,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (applicant.isTopCandidate)
                      Row(
                        children: [
                          Icon(applicant.rank == 1 ? Icons.auto_awesome : Icons.star_rounded,
                              color: rankColor, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            applicant.rank == 1 ? 'Best Match' : 'Top Candidate',
                            style: GoogleFonts.outfit(
                                color: rankColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Score badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: scoreColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${score.toStringAsFixed(1)}%',
                  style: GoogleFonts.outfit(
                    color: scoreColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Status pill ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              applicant.status.toUpperCase(),
              style: GoogleFonts.outfit(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── CV preview ───────────────────────────────────────────────────
          if (applicant.candidateSkills.isNotEmpty) ...[
            Text(
              'CV Preview',
              style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                applicant.candidateSkills.length > 200
                    ? '${applicant.candidateSkills.substring(0, 200)}…'
                    : applicant.candidateSkills,
                style: GoogleFonts.outfit(
                    color: Colors.white60, fontSize: 12, height: 1.4),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // ── Missing skills ───────────────────────────────────────────────
          if (applicant.missingSkills.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFF44336), size: 14),
                const SizedBox(width: 6),
                Text(
                  'Missing Skills',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFF44336),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: applicant.missingSkills
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF44336).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color:
                                const Color(0xFFF44336).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        s,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFF44336),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],

          // ── Action buttons ───────────────────────────────────────────────
          if (applicant.status == 'pending' || applicant.status == 'reviewing')
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (applicant.status == 'pending') ...[
                  _ActionButton(
                    label: 'Review',
                    icon: Icons.manage_search_rounded,
                    color: const Color(0xFF6C63FF),
                    loading: isUpdating,
                    onPressed: () => _updateStatus(context, 'reviewing'),
                  ),
                  const SizedBox(width: 8),
                ],
                if (applicant.status == 'reviewing') ...[
                  _ActionButton(
                    label: 'Interview',
                    icon: Icons.calendar_today_rounded,
                    color: const Color(0xFF2196F3),
                    loading: isUpdating,
                    onPressed: () => _showScheduleDialog(context),
                  ),
                  const SizedBox(width: 8),
                ],
                _ActionButton(
                  label: 'Reject',
                  icon: Icons.close_rounded,
                  color: const Color(0xFFF44336),
                  loading: isUpdating,
                  onPressed: () => _updateStatus(context, 'rejected'),
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  label: 'Accept',
                  icon: Icons.check_rounded,
                  color: const Color(0xFF4CAF50),
                  loading: isUpdating,
                  onPressed: () => _updateStatus(context, 'accepted'),
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Decision: ${applicant.status.toUpperCase()}',
                style: GoogleFonts.outfit(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showScheduleDialog(BuildContext context) async {
    final provider = context.read<RecruiterProvider>();
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6C63FF),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E2C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null || !context.mounted) return;

    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6C63FF),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E2C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime == null || !context.mounted) return;

    final fullDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    final locationController = TextEditingController();
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: Text('Interview Details',
            style: GoogleFonts.outfit(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: locationController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Location / Link',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            TextField(
              controller: noteController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF)),
            child: const Text('Schedule'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final error = await provider.scheduleInterview(
        applicationId: applicant.id,
        time: fullDateTime,
        location: locationController.text.isEmpty
            ? 'Online Meeting'
            : locationController.text,
        note: noteController.text,
      );
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  void _updateStatus(BuildContext context, String status) async {
    final provider = context.read<RecruiterProvider>();
    final error = await provider.updateStatus(
      applicationId: applicant.id,
      status: status,
    );
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFF44336),
        ),
      );
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: color),
              )
            : Icon(icon, size: 15),
        label: Text(label,
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600, fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.15),
          foregroundColor: color,
          elevation: 0,
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => const _ApplicantSkeleton(),
    );
  }
}

class _ApplicantSkeleton extends StatelessWidget {
  const _ApplicantSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 28, height: 28, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white12)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 160, height: 14, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 6),
                    Container(width: 90, height: 10, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
              Container(width: 50, height: 26, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10))),
            ],
          ),
          const SizedBox(height: 16),
          Container(width: 80, height: 18, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 16),
          Container(width: double.infinity, height: 60, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(width: 80, height: 36, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10))),
              const SizedBox(width: 8),
              Container(width: 80, height: 36, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10))),
            ],
          ),
        ],
      ),
    );
  }
}
