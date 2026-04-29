// lib/screens/home_screen.dart
// CV upload screen + animated job recommendation list.

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';

import '../models/job_match.dart';
import '../providers/cv_provider.dart';
import '../providers/application_provider.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CvProvider()),
        ChangeNotifierProvider(create: (_) => ApplicationProvider()),
      ],
      child: const _HomeBody(),
    );
  }
}

class _HomeBody extends StatefulWidget {
  const _HomeBody();
  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    // Pre-load applied job IDs so Apply buttons show correct state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      if (auth.isAuthenticated) {
        context.read<ApplicationProvider>().loadMyApplications();
      }
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload(BuildContext context) async {
    try {
      final provider = context.read<CvProvider>();
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;

      if (bytes == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read file data. Please try again.')),
          );
        }
        return;
      }

      await provider.uploadCV(bytes, file.name);

      if (provider.state == CvUploadState.success) {
        _fadeCtrl.forward(from: 0);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final cv = context.watch<CvProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F16),
      appBar: _buildAppBar(context, auth),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _UploadCard(onUpload: () => _pickAndUpload(context)),
              const SizedBox(height: 24),
              if (cv.state == CvUploadState.loading) ...[
                const _SkeletonList(),
              ] else if (cv.state == CvUploadState.error) ...[
                _ErrorBanner(
                  message: cv.errorMessage,
                  onRetry: () {
                    // If we have a file name, try re-matching (logic depends on CvProvider having path)
                    // For now, let's just trigger a re-pick or standard upload flow if provider allows
                    if (cv.selectedFileName.isNotEmpty) {
                       _pickAndUpload(context);
                    }
                  },
                ),
              ] else if (cv.state == CvUploadState.success &&
                  cv.result != null) ...[
                FadeTransition(
                  opacity: _fadeAnim,
                  child: _ResultsSection(result: cv.result!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, AuthService auth) {
    return AppBar(
      backgroundColor: const Color(0xFF0F0F16),
      elevation: 0,
      title: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF6C63FF), size: 22),
          const SizedBox(width: 8),
          Text(
            'AI Job Match',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
        if (auth.isAuthenticated) ...[          
          IconButton(
            icon: const Icon(Icons.assignment_outlined, color: Colors.white70),
            tooltip: 'My Applications',
            onPressed: () => context.push('/my-applications'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white70),
            color: const Color(0xFF1E1E2C),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'email',
                enabled: false,
                child: Text(
                  auth.email ?? '',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Text('Sign Out', style: TextStyle(color: Colors.redAccent))),
            ],
            onSelected: (v) async {
              if (v == 'logout') {
                await auth.logout();
                if (context.mounted) context.go('/login');
              }
            },
          ),
        ] else
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Sign In', style: TextStyle(color: Color(0xFF6C63FF))),
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Upload Card
// ─────────────────────────────────────────────────────────────────────────────
class _UploadCard extends StatelessWidget {
  final VoidCallback onUpload;
  const _UploadCard({required this.onUpload});

  @override
  Widget build(BuildContext context) {
    final cv = context.watch<CvProvider>();
    final bool hasFile = cv.selectedFileName.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          // Icon with gradient glow
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF3D35A0)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            'Upload Your CV',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Supports PDF, DOCX, PNG, JPG',
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 24),
          if (hasFile) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.insert_drive_file_outlined,
                      color: Color(0xFF6C63FF), size: 16),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      cv.selectedFileName,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFB0AEFF),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: cv.state == CvUploadState.loading ? null : onUpload,
              icon: const Icon(Icons.search_rounded, size: 20),
              label: Text(
                hasFile ? 'Re-analyse CV' : 'Choose File & Match',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF6C63FF).withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Results Section
// ─────────────────────────────────────────────────────────────────────────────
class _ResultsSection extends StatelessWidget {
  final CvMatchResult result;
  const _ResultsSection({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            const Icon(Icons.workspace_premium_rounded,
                color: Color(0xFF00FFC2), size: 22),
            const SizedBox(width: 8),
            Text(
              '${result.matches.length} Matching Jobs Found',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          result.message,
          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 16),
        // Job cards
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: result.matches.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, i) =>
              _JobMatchCard(match: result.matches[i], rank: i + 1),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Job Match Card
// ─────────────────────────────────────────────────────────────────────────────
class _JobMatchCard extends StatelessWidget {
  final JobMatch match;
  final int rank;
  const _JobMatchCard({required this.match, required this.rank});

  @override
  Widget build(BuildContext context) {
    final score = match.score;
    final scoreColor = score >= 80
        ? const Color(0xFF4CAF50) // Green
        : score >= 60
            ? const Color(0xFFFFC107) // Amber
            : const Color(0xFFF44336); // Red

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          context.push('/explain/${match.job.id}',
              extra: match.job.title);
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: scoreColor.withOpacity(0.2),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: rank + title + score badge
              Row(
                children: [
                  _RankBadge(rank: rank),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.job.title,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          match.job.company,
                          style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Score badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: scoreColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: scoreColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      '${score.toStringAsFixed(1)}%',
                      style: GoogleFonts.outfit(
                        color: scoreColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Score bar
              LinearPercentIndicator(
                lineHeight: 6,
                percent: (score / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.white10,
                progressColor: scoreColor,
                barRadius: const Radius.circular(4),
                padding: EdgeInsets.zero,
                animation: true,
                animationDuration: 600,
              ),
              const SizedBox(height: 14),
              // Location & salary
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.location_on_outlined,
                    label: match.job.location.isEmpty ? 'Remote' : match.job.location,
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.payments_outlined,
                    label: match.job.salary.isEmpty ? 'Negotiable' : match.job.salary,
                  ),
                ],
              ),
              // Missing skills
              if (match.missingSkills.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFF44336), size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Missing: ${match.missingSkills.take(4).join(', ')}${match.missingSkills.length > 4 ? ' +${match.missingSkills.length - 4} more' : ''}',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFF44336),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              // Action row: Explain + Apply
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Explain
                  TextButton.icon(
                    onPressed: () =>
                        context.push('/explain/${match.job.id}', extra: match.job.title),
                    icon: const Icon(Icons.analytics_outlined, size: 16),
                    label: Text(
                      'Breakdown',
                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6C63FF),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  // Apply button
                  _ApplyButton(jobId: match.job.id, matchScore: match.score),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFFFFD700), // 1st — gold
      const Color(0xFFC0C0C0), // 2nd — silver
      const Color(0xFFCD7F32), // 3rd — bronze
    ];
    final c = rank <= 3 ? colors[rank - 1] : Colors.white24;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.withOpacity(0.15),
        border: Border.all(color: c, width: 1.5),
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: GoogleFonts.outfit(
            color: c,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white54),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Apply Button
// ─────────────────────────────────────────────────────────────────────────────
class _ApplyButton extends StatelessWidget {
  final int jobId;
  final double matchScore;
  const _ApplyButton({required this.jobId, required this.matchScore});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<ApplicationProvider>();
    final auth        = context.watch<AuthService>();
    final applyState  = appProvider.applyStateFor(jobId);
    final applied     = appProvider.hasApplied(jobId);

    if (applied || applyState == ApplyState.success || applyState == ApplyState.alreadyApplied) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF00FFC2).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF00FFC2).withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF00FFC2), size: 15),
            const SizedBox(width: 6),
            Text('Applied', style: GoogleFonts.outfit(color: const Color(0xFF00FFC2), fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    if (applyState == ApplyState.loading) {
      return const SizedBox(
        width: 80, height: 36,
        child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C63FF)))),
      );
    }

    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: () async {
          if (!auth.isAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sign in to apply for jobs')),
            );
            return;
          }
          final error = await appProvider.applyForJob(jobId: jobId, matchScore: matchScore);
          if (error != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: const Color(0xFFFF6B6B)),
            );
          }
        },
        icon: const Icon(Icons.send_rounded, size: 15),
        label: Text('Apply', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting widgets
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// Skeleton Loading (Lightweight Gray Boxes)
// ─────────────────────────────────────────────────────────────────────────────
class _SkeletonList extends StatelessWidget {
  const _SkeletonList();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (i) => const _JobSkeleton()),
    );
  }
}

class _JobSkeleton extends StatelessWidget {
  const _JobSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
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
              Container(width: 32, height: 32, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white12)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 140, height: 14, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 6),
                    Container(width: 80, height: 10, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
              Container(width: 45, height: 24, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8))),
            ],
          ),
          const SizedBox(height: 20),
          Container(width: double.infinity, height: 6, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(width: 70, height: 20, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6))),
              const SizedBox(width: 8),
              Container(width: 70, height: 20, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF44336).withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF44336).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFF44336), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message.isNotEmpty ? message : 'Analysis failed. Please try again.',
                  style: GoogleFonts.outfit(color: const Color(0xFFF44336), fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry Analysis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF44336),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
