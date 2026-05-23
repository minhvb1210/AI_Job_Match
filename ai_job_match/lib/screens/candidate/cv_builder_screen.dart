import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../providers/resume_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/responsive.dart';
import 'cv_builder/cv_form.dart';
import 'cv_builder/cv_preview.dart';
import '../../../services/resume_export_service.dart';

class CvBuilderScreen extends StatefulWidget {
  const CvBuilderScreen({super.key});

  @override
  State<CvBuilderScreen> createState() => _CvBuilderScreenState();
}

class _CvBuilderScreenState extends State<CvBuilderScreen> {
  @override
  Widget build(BuildContext context) {
    final resumeProvider = context.watch<ResumeProvider>();
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Resume Builder",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          _buildActionButtons(resumeProvider),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Left side: Editor
          Expanded(
            flex: isDesktop ? 5 : 10,
            child: const CvForm(),
          ),
          
          // Right side: Preview (Only on Desktop/Wide screens)
          if (isDesktop)
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  border: Border(left: BorderSide(color: Color(0xFFCBD5E1))),
                ),
                child: const CvPreview(),
              ),
            ),
        ],
      ),
      // Mobile Preview FAB
      floatingActionButton: !isDesktop 
          ? FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const FractionallySizedBox(
                    heightFactor: 0.9,
                    child: CvPreview(),
                  ),
                );
              },
              label: const Text("Preview"),
              icon: const Icon(LucideIcons.eye),
            )
          : null,
    );
  }

  Widget _buildActionButtons(ResumeProvider provider) {
    return Row(
      children: [
        ShadButton.outline(
          onPressed: () {
            // Save logic would go here
          },
          child: const Text("Save Draft"),
        ),
        const SizedBox(width: 8),
        ShadButton(
          onPressed: () async {
            await ResumeExportService.exportToPdf(provider.data);
          },
          leading: const Icon(LucideIcons.download, size: 16),
          child: const Text("Export PDF"),
        ),
      ],
    );
  }
}
