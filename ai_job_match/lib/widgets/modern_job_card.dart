import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';

class ModernJobCard extends StatelessWidget {
  final dynamic job;
  final double? matchScore;
  final VoidCallback? onApply;
  final VoidCallback? onSave;
  final bool isSaved;
  final bool hasApplied;
  final VoidCallback? onTap;
  final bool isMatch;

  const ModernJobCard({
    super.key,
    required this.job,
    this.matchScore,
    this.onApply,
    this.onSave,
    this.isSaved = false,
    this.hasApplied = false,
    this.onTap,
    this.isMatch = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.building, color: AppColors.primary, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job['title'] ?? 'Job Title',
                            style: theme.textTheme.h4.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job['company'] ?? 'Company Name',
                            style: theme.textTheme.muted.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isSaved ? LucideIcons.heart : LucideIcons.heart,
                        color: isSaved ? AppColors.error : AppColors.textPlaceholder,
                        fill: isSaved ? 1.0 : 0.0,
                        size: 20,
                      ),
                      onPressed: onSave,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildTag(LucideIcons.mapPin, job['location'] ?? 'Remote'),
                    const SizedBox(width: 12),
                    _buildTag(LucideIcons.briefcase, job['job_type'] ?? 'Full-time'),
                    const SizedBox(width: 12),
                    _buildTag(LucideIcons.banknote, job['salary'] ?? 'Competitive'),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (matchScore != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: AppColors.premiumGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.sparkles, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              '${matchScore!.toStringAsFixed(0)}% AI Match',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    const Spacer(),
                    ShadButton.outline(
                      size: ShadButtonSize.sm,
                      onPressed: onTap,
                      child: const Text('Details'),
                    ),
                    const SizedBox(width: 8),
                    ShadButton(
                      size: ShadButtonSize.sm,
                      onPressed: hasApplied ? null : onApply,
                      child: Text(hasApplied ? 'Applied' : 'Apply Now'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
