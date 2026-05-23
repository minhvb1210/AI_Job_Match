import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/cv_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

class ImproveCvDialog extends StatefulWidget {
  final String cvText;
  const ImproveCvDialog({super.key, required this.cvText});

  @override
  State<ImproveCvDialog> createState() => _ImproveCvDialogState();
}

class _ImproveCvDialogState extends State<ImproveCvDialog> {
  bool _isLoading = true;
  List<String> _suggestions = [];
  String _error = "";

  @override
  void initState() {
    super.initState();
    _fetchSuggestions();
  }

  Future<void> _fetchSuggestions() async {
    try {
      final service = CvService();
      final res = await service.getSuggestions();
      setState(() {
        _suggestions = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = ApiService.errorMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.sparkles, color: Colors.purpleAccent, size: 28),
                const SizedBox(width: 12),
                Text(
                  "AI Optimizer",
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const Spacer(),
                IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Actionable tips to improve your match score based on industry standards.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                      ? Center(child: Text(_error, style: const TextStyle(color: AppColors.error)))
                      : ListView.builder(
                          itemCount: _suggestions.length,
                          itemBuilder: (context, i) => _buildSuggestionCard(_suggestions[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.circleCheck, color: Colors.purpleAccent, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
