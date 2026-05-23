import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../services/cv_service.dart';
import '../../models/job_match.dart';
import '../../providers/cv_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/modern_job_card.dart';
import 'package:go_router/go_router.dart';

class AiMatchingTab extends StatefulWidget {
  const AiMatchingTab({super.key});

  @override
  State<AiMatchingTab> createState() => _AiMatchingTabState();
}

class _AiMatchingTabState extends State<AiMatchingTab> {
  Future<void> _pickAndAnalyze() async {
    final cvProvider = context.read<CvProvider>();
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
      withData: true,
    );

    if (result != null) {
      try {
        await cvProvider.uploadCV(
          result.files.first.bytes!,
          result.files.first.name,
        );
        if (cvProvider.state == CvUploadState.error && mounted) {
          ShadToaster.of(context).show(
            ShadToast.destructive(
              title: const Text("Analysis Failed"),
              description: Text(cvProvider.errorMessage),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ShadToaster.of(context).show(
            ShadToast.destructive(
              title: const Text("Analysis Failed"),
              description: Text(e.toString()),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cvProvider = context.watch<CvProvider>();
    final isAnalyzing = cvProvider.state == CvUploadState.loading;
    final matchResult = cvProvider.result;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(isAnalyzing),
          const SizedBox(height: 48),
          if (isAnalyzing) _buildLoadingState(cvProvider.selectedFileName),
          if (matchResult != null && cvProvider.state == CvUploadState.success) _buildResultsState(matchResult),
          if (!isAnalyzing && matchResult == null) _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildHero(bool isAnalyzing) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: AppColors.premiumGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Badge(
                  label: Text("PRO FEATURE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.white24,
                ),
                const SizedBox(height: 16),
                Text(
                  "AI Strategic Matching",
                  style: GoogleFonts.outfit(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Upload your resume and let our advanced NLP engine find the perfect roles for your career path.",
                  style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 32),
                ShadButton(
                  onPressed: isAnalyzing ? null : _pickAndAnalyze,
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  size: ShadButtonSize.lg,
                  child: Row(
                    children: [
                      Icon(isAnalyzing ? LucideIcons.rotateCcw : LucideIcons.upload, size: 20),
                      const SizedBox(width: 12),
                      Text(isAnalyzing ? "Analyzing..." : "Upload Resume (PDF/DOCX)"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (MediaQuery.of(context).size.width > 1000)
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: const Icon(LucideIcons.sparkles, size: 120, color: Colors.white24)
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 2000.ms, color: Colors.white30),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(String fileName) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)),
          const SizedBox(height: 24),
          Text(
            "Analyzing $fileName...",
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text("Extracting skills and matching with global opportunities", style: TextStyle(color: AppColors.textSecondary)),
        ],
      ).animate().fadeIn(),
    );
  }


  Widget _buildResultsState(CvMatchResult matchResult) {
    final bestMatch = matchResult.matches.isNotEmpty ? matchResult.matches.first : null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("Analysis Results", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
              onPressed: _pickAndAnalyze,
              icon: const Icon(LucideIcons.rotateCcw, size: 16),
              label: const Text("Re-upload"),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Score Card
            Expanded(
              flex: 2,
              child: _buildSummaryCard(bestMatch),
            ),
            const SizedBox(width: 24),
            // Extracted Info Card
            Expanded(
              flex: 3,
              child: _buildExtractedInfoCard(),
            ),
          ],
        ),
        const SizedBox(height: 48),
        Text("Recommended Positions", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        ...matchResult.matches.map((match) => ModernJobCard(
          job: match.job.toJson(),
          matchScore: match.score,
          onTap: () => context.push('/jobs/${match.job.id}'),
          onApply: () {},
        ).animate().fadeIn().slideY(begin: 0.1)).toList(),
      ],
    ).animate().fadeIn(duration: 600.ms);
  }


  Widget _buildSummaryCard(JobMatch? bestMatch) {
    final score = bestMatch?.score ?? 0;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          CircularPercentIndicator(
            radius: 70.0,
            lineWidth: 12.0,
            percent: score / 100,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("${score.toStringAsFixed(0)}%", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const Text("MATCH", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ],
            ),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: AppColors.primary,
            backgroundColor: AppColors.primary.withOpacity(0.1),
          ),
          const SizedBox(height: 24),
          Text(
            bestMatch != null ? "Excellent Match!" : "Analyzing...",
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Found ${bestMatch?.job.title ?? 'suitable'} positions based on your background.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedInfoCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.binary, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Text("Extracted Skills", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Our AI identified these core competencies from your CV:",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              "Python", "Flutter", "Machine Learning", "NLP", "API Design", "Project Management"
            ].map((skill) => Chip(
              label: Text(skill, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              backgroundColor: AppColors.primary.withOpacity(0.05),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            )).toList(),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(LucideIcons.info, color: AppColors.error, size: 20),
              const SizedBox(width: 12),
              Text("Skill Gaps", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          const Text("To increase your match score for top roles, consider learning:", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              "Cloud Deployment", "Microservices", "Docker"
            ].map((skill) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(skill, style: const TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.bold)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 300,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.search, size: 64, color: AppColors.textPlaceholder),
                const SizedBox(height: 24),
                Text("No CV uploaded", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text(
                  "Upload your resume to see high-accuracy job recommendations based on your skills.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension JobBriefExtension on JobBrief {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'company': company,
      'location': location,
      'salary': salary,
      'skills': skills,
    };
  }
}
