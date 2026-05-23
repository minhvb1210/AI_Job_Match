import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/job_service.dart';
import '../../theme/app_colors.dart';

class JobAiSourcingDialog extends StatefulWidget {
  final int jobId;
  final String jobTitle;
  const JobAiSourcingDialog({super.key, required this.jobId, required this.jobTitle});

  @override
  State<JobAiSourcingDialog> createState() => _JobAiSourcingDialogState();
}

class _JobAiSourcingDialogState extends State<JobAiSourcingDialog> {
  List<dynamic> _suggestions = [];
  bool _isLoading = true;
  final _jobService = JobService();

  @override
  void initState() {
    super.initState();
    _fetchSuggestions();
  }

  Future<void> _fetchSuggestions() async {
    try {
      final res = await _jobService.getAiSourcingCandidates(widget.jobId);
      setState(() {
        _suggestions = res;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Dialog(
       backgroundColor: Colors.white,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
       child: Container(
         width: 700,
         height: 650,
         padding: const EdgeInsets.all(32),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Row(
               children: [
                 const Icon(LucideIcons.sparkles, color: Colors.purpleAccent, size: 28),
                 const SizedBox(width: 12),
                 Expanded(child: Text("AI Talent Sourcing: ${widget.jobTitle}", style: theme.textTheme.h3.copyWith(fontWeight: FontWeight.bold))),
                 IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
               ],
             ),
             const SizedBox(height: 8),
             Text("Our AI has scanned all candidate profiles to find the best matches for your role.", style: theme.textTheme.muted),
             const SizedBox(height: 24),
             const Divider(color: Color(0xFFE2E8F0)),
             const SizedBox(height: 16),
             Expanded(
               child: _isLoading 
                 ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                 : _suggestions.isEmpty 
                   ? const Center(child: Text("No candidates currently match this role strictly."))
                   : ListView.builder(
                       itemCount: _suggestions.length,
                       itemBuilder: (context, index) {
                         var sugg = _suggestions[index];
                         return Container(
                           margin: const EdgeInsets.only(bottom: 16),
                           padding: const EdgeInsets.all(20),
                           decoration: BoxDecoration(
                             color: Colors.purple.withOpacity(0.05),
                             borderRadius: BorderRadius.circular(16),
                             border: Border.all(color: Colors.purple.withOpacity(0.1)),
                           ),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Row(
                                 children: [
                                   const Icon(LucideIcons.user, color: AppColors.primary),
                                   const SizedBox(width: 12),
                                   Text(sugg['candidate_email'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                   const Spacer(),
                                   Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                                      child: Text("${sugg['score'].toStringAsFixed(1)}% Match", style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                   )
                                 ],
                               ),
                               const SizedBox(height: 16),
                               Text(sugg['matched_skills_text'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                               const SizedBox(height: 16),
                               Align(
                                  alignment: Alignment.centerRight,
                                  child: ShadButton(
                                     onPressed: () {},
                                     leading: const Icon(LucideIcons.mail, size: 16),
                                     child: const Text("Invite to Apply"),
                                  )
                               )
                             ],
                           ),
                         );
                       }
                     )
             )
           ],
         ),
       )
    );
  }
}
