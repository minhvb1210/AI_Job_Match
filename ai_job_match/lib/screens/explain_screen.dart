// lib/screens/explain_screen.dart
// AI score breakdown screen — shows cosine, keyword bonus, industry bonus, final score.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';

import '../models/job_match.dart';
import '../providers/explain_provider.dart';
import '../services/auth_service.dart';

class ExplainScreen extends StatefulWidget {
  final int jobId;
  final String jobTitle;

  const ExplainScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<ExplainScreen> createState() => _ExplainScreenState();
}

class _ExplainScreenState extends State<ExplainScreen> {
  @override
  void initState() {
    super.initState();
    // Kick off after first frame so Provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final provider = context.read<ExplainProvider>();
    final auth = context.read<AuthService>();
    provider.explain(
      jobId: widget.jobId,
      token: auth.isAuthenticated ? auth.token : null,
      // Falls back to public POST endpoint if not authenticated
      cvText: auth.isAuthenticated ? null : '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExplainProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F16),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score Breakdown',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Text(
              widget.jobTitle,
              style: GoogleFonts.outfit(
                color: const Color(0xFF6C63FF),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(ExplainProvider provider) {
    switch (provider.state) {
      case ExplainState.loading:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF6C63FF), strokeWidth: 3),
              SizedBox(height: 16),
              Text('Computing score breakdown…',
                  style: TextStyle(color: Colors.white54)),
            ],
          ),
        );

      case ExplainState.error:
        return _ErrorView(
          message: provider.errorMessage,
          onRetry: _load,
        );

      case ExplainState.success:
        if (provider.result == null) return const SizedBox();
        return _ExplainBody(result: provider.result!);

      default:
        return const SizedBox();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main explain body
// ─────────────────────────────────────────────────────────────────────────────
class _ExplainBody extends StatelessWidget {
  final ExplainResult result;
  const _ExplainBody({required this.result});

  @override
  Widget build(BuildContext context) {
    final scoreColor = result.finalScore >= 80
        ? const Color(0xFF4CAF50) // Green
        : result.finalScore >= 60
            ? const Color(0xFFFFC107) // Amber
            : const Color(0xFFF44336); // Red

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── AI Narrative ──────────────────────────────────────────────────
          _AiIntelligenceCard(narrative: result.narrative),
          const SizedBox(height: 20),

          // ── Hero score ring ──────────────────────────────────────────────
          _HeroScoreCard(result: result, scoreColor: scoreColor),
          const SizedBox(height: 24),

          // ── Score component bars ─────────────────────────────────────────
          _SectionTitle(title: 'Score Components', icon: Icons.bar_chart_rounded),
          const SizedBox(height: 12),
          _ScoreComponentCard(
            label: 'Text Similarity (TF-IDF Cosine)',
            value: result.cosinePct,
            maxValue: 100,
            color: const Color(0xFF6C63FF),
            subtitle: 'Raw cosine: ${(result.cosineRaw * 100).toStringAsFixed(2)}%',
            icon: Icons.compare_arrows_rounded,
          ),
          const SizedBox(height: 10),
          _ScoreComponentCard(
            label: 'Keyword Bonus',
            value: result.kwBonus.toDouble(),
            maxValue: 30,
            color: const Color(0xFF4CAF50),
            subtitle: '${result.matchedKeywords.length} keywords matched (max +30%)',
            icon: Icons.key_rounded,
          ),
          const SizedBox(height: 10),
          _ScoreComponentCard(
            label: 'Industry Alignment',
            value: result.industryAdjustment.abs().toDouble(),
            maxValue: 15,
            color: result.industryMatch ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
            subtitle: result.industryMatch
                ? 'CV industry matches job (+${result.industryAdjustment}%)'
                : 'Industry mismatch (${result.industryAdjustment}%)',
            icon: result.industryMatch
                ? Icons.check_circle_outline_rounded
                : Icons.cancel_outlined,
            isNegative: !result.industryMatch,
          ),
          const SizedBox(height: 20),

          // ── Industry detection ───────────────────────────────────────────
          _SectionTitle(title: 'Industry Detection', icon: Icons.business_center_outlined),
          const SizedBox(height: 12),
          _IndustryCard(result: result),
          const SizedBox(height: 20),

          // ── Matched keywords ─────────────────────────────────────────────
          if (result.matchedKeywords.isNotEmpty) ...[
            _SectionTitle(title: 'Matched Keywords', icon: Icons.verified_outlined),
            const SizedBox(height: 12),
            _ChipList(
              items: result.matchedKeywords,
              color: const Color(0xFF4CAF50),
            ),
            const SizedBox(height: 20),
          ],

          // ── Missing skills ───────────────────────────────────────────────
          if (result.missingSkills.isNotEmpty) ...[
            _SectionTitle(title: 'Missing Skills', icon: Icons.warning_amber_rounded),
            const SizedBox(height: 12),
            _ChipList(
              items: result.missingSkills,
              color: const Color(0xFFF44336),
            ),
            const SizedBox(height: 20),
          ],

          // ── AI Insights (The "Why") ──────────────────────────────────────
          _SectionTitle(title: 'AI Insights', icon: Icons.psychology_outlined),
          const SizedBox(height: 12),
          _InsightCard(result: result),
          const SizedBox(height: 20),

          // ── Success Suggestions ─────────────────────────────────────────
          if (result.missingSkills.isNotEmpty) ...[
            _SectionTitle(title: 'Improvement Roadmap', icon: Icons.auto_awesome_outlined),
            const SizedBox(height: 12),
            _SuggestionList(items: result.missingSkills),
            const SizedBox(height: 20),
          ],

          // ── Score formula ────────────────────────────────────────────────
          _SectionTitle(title: 'Score Formula', icon: Icons.functions_rounded),
          const SizedBox(height: 12),
          _FormulaCard(result: result),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Score Card
// ─────────────────────────────────────────────────────────────────────────────
class _HeroScoreCard extends StatelessWidget {
  final ExplainResult result;
  final Color scoreColor;
  const _HeroScoreCard({required this.result, required this.scoreColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scoreColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircularPercentIndicator(
            radius: 64,
            lineWidth: 10,
            percent: (result.finalScore / 100).clamp(0.0, 1.0),
            center: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${result.finalScore.toStringAsFixed(1)}%',
                      style: GoogleFonts.outfit(
                        color: scoreColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Match',
                      style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
                if (result.finalScore >= 85)
                   Positioned(
                     bottom: -10,
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                       decoration: BoxDecoration(
                         color: const Color(0xFFFFD700), // Gold
                         borderRadius: BorderRadius.circular(12),
                         boxShadow: [
                           BoxShadow(
                             color: const Color(0xFFFFD700).withOpacity(0.5),
                             blurRadius: 10,
                             spreadRadius: 2,
                           ),
                         ],
                       ),
                       child: const Text(
                         'BEST MATCH',
                         style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
                       ),
                     ),
                   ),
              ],
            ),
            progressColor: scoreColor,
            backgroundColor: Colors.white10,
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animationDuration: 800,
          ),
          const SizedBox(height: 16),
          Text(
            result.jobTitle,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.category_outlined, color: Colors.white38, size: 14),
              const SizedBox(width: 4),
              Text(
                result.jobCategory,
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Score Component Bar Card
// ─────────────────────────────────────────────────────────────────────────────
class _ScoreComponentCard extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;
  final String subtitle;
  final IconData icon;
  final bool isNegative;

  const _ScoreComponentCard({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.subtitle,
    required this.icon,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value / maxValue).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${isNegative ? "-" : "+"}${value.toStringAsFixed(0)}%',
                style: GoogleFonts.outfit(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearPercentIndicator(
            lineHeight: 6,
            percent: pct,
            backgroundColor: Colors.white10,
            progressColor: color,
            barRadius: const Radius.circular(4),
            padding: EdgeInsets.zero,
            animation: true,
            animationDuration: 700,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Industry Detection Card
// ─────────────────────────────────────────────────────────────────────────────
class _IndustryCard extends StatelessWidget {
  final ExplainResult result;
  const _IndustryCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _IndustryItem(
              label: 'CV Industry',
              value: result.cvIndustry,
              sub: 'Confidence: ${(result.industryConfidence * 100).toStringAsFixed(0)}%',
              icon: Icons.person_outline_rounded,
              color: const Color(0xFF6C63FF),
            ),
          ),
          Container(width: 1, height: 60, color: Colors.white10),
          Expanded(
            child: _IndustryItem(
              label: 'Job Category',
              value: result.jobCategory,
              sub: result.industryMatch ? 'Match ✓' : 'Mismatch ✗',
              icon: Icons.work_outline_rounded,
              color: result.industryMatch
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFF44336),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndustryItem extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;
  const _IndustryItem({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip row for keywords / missing skills
// ─────────────────────────────────────────────────────────────────────────────
class _ChipList extends StatelessWidget {
  final List<String> items;
  final Color color;
  const _ChipList({required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Text(
                item,
                style: GoogleFonts.outfit(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Score formula card
// ─────────────────────────────────────────────────────────────────────────────
class _FormulaCard extends StatelessWidget {
  final ExplainResult result;
  const _FormulaCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _FormulaRow(
            label: 'Cosine %',
            value: '${result.cosinePct.toStringAsFixed(1)}%',
            color: const Color(0xFF6C63FF),
          ),
          const _FormulaDivider(symbol: '+'),
          _FormulaRow(
            label: 'Keyword Bonus',
            value: '+${result.kwBonus}%',
            color: const Color(0xFF4CAF50),
          ),
          const _FormulaDivider(symbol: '+'),
          _FormulaRow(
            label: 'Industry Adj.',
            value: '${result.industryAdjustment > 0 ? '+' : ''}${result.industryAdjustment}%',
            color: result.industryMatch
                ? const Color(0xFF4CAF50)
                : const Color(0xFFF44336),
          ),
          const Divider(color: Colors.white12, height: 24),
          _FormulaRow(
            label: 'Final Score',
            value: '${result.finalScore.toStringAsFixed(1)}%',
            color: Colors.white,
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _FormulaRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isTotal;
  const _FormulaRow({
    required this.label,
    required this.value,
    required this.color,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: isTotal ? Colors.white : Colors.white60,
            fontSize: isTotal ? 14 : 13,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: color,
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FormulaDivider extends StatelessWidget {
  final String symbol;
  const _FormulaDivider({required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(symbol, style: const TextStyle(color: Colors.white24, fontSize: 18)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section title
// ─────────────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6C63FF), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error view
// ─────────────────────────────────────────────────────────────────────────────
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
              'Could not load breakdown',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message.isNotEmpty
                  ? message
                  : 'Please upload a CV first or sign in.',
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Insight Card (The "Why")
// ─────────────────────────────────────────────────────────────────────────────
class _InsightCard extends StatelessWidget {
  final ExplainResult result;
  const _InsightCard({required this.result});

  @override
  Widget build(BuildContext context) {
    String explanation = "";
    if (result.finalScore >= 80) {
      explanation = "Excellent match! Your profile shows a strong overlap in ${result.matchedKeywords.take(3).join(', ')} and your industry background aligns perfectly with the role's requirements.";
    } else if (result.finalScore >= 60) {
      explanation = "Good match. You have the core competencies, especially in ${result.matchedKeywords.take(2).join(' and ')}. Strengthening your profile with ${result.missingSkills.take(1).join('')} could push you to the top tier.";
    } else {
      explanation = "Match potential. While you share some common ground, the role requires more specific depth in ${result.missingSkills.take(2).join(' and ')}. Consider highlighting these skills more clearly in your CV.";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Analysis Summary",
            style: GoogleFonts.outfit(color: const Color(0xFF6C63FF), fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Suggestion List
// ─────────────────────────────────────────────────────────────────────────────
class _SuggestionList extends StatelessWidget {
  final List<String> items;
  const _SuggestionList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: Colors.orangeAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Upskill in $item to increase your relevance by up to 5%.",
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }
}
class _AiIntelligenceCard extends StatelessWidget {
  final String narrative;
  const _AiIntelligenceCard({required this.narrative});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF6C63FF).withOpacity(0.15), const Color(0xFF6C63FF).withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.psychology, color: Color(0xFF6C63FF), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Strategic Analysis',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  narrative,
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
