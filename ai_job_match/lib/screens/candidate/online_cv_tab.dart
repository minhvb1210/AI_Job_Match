import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

class OnlineCvTab extends StatefulWidget {
  const OnlineCvTab({super.key});

  @override
  State<OnlineCvTab> createState() => _OnlineCvTabState();
}

class _OnlineCvTabState extends State<OnlineCvTab> {
  dynamic _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final dio = await ApiService.authenticated();
      final response = await dio.get('/cv/my-profile');
      final data = response.data;
      setState(() {
        if (data is Map && data['success'] == true) {
          _profile = data['data'];
        }
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_profile == null) return _buildEmptyState();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 48),
          _buildSection("Education", _profile['educations'] ?? [], LucideIcons.graduationCap),
          const SizedBox(height: 32),
          _buildSection("Work Experience", _profile['experiences'] ?? [], LucideIcons.briefcase),
          const SizedBox(height: 32),
          _buildSection("Key Projects", _profile['projects'] ?? [], LucideIcons.code),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: AppColors.premiumGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white24,
            child: Icon(LucideIcons.user, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "My Online Profile",
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  "Last updated: Just now",
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                ),
                const SizedBox(height: 12),
                ShadButton.outline(
                  onPressed: () => context.push('/cv-builder'),
                  backgroundColor: Colors.white,
                  child: const Text("Build Professional Resume", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          ShadButton.outline(
            onPressed: () {},
            backgroundColor: Colors.white24,
            child: const Text("Edit Bio", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<dynamic> items, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const Spacer(),
            ShadButton.ghost(
              width: 32, height: 32, padding: EdgeInsets.zero,
              leading: const Icon(LucideIcons.plus, size: 18, color: AppColors.primary),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          const Text("No entries added yet.", style: TextStyle(color: AppColors.textPlaceholder, fontSize: 13))
        else
          ...items.map((item) => _buildItemCard(item, title)),
      ],
    );
  }

  Widget _buildItemCard(dynamic item, String type) {
    String title = "";
    String subtitle = "";
    String date = "";

    if (type == "Education") {
      title = item['school'] ?? 'N/A';
      subtitle = item['degree'] ?? 'N/A';
      date = "${item['start_year']} - ${item['end_year']}";
    } else if (type == "Work Experience") {
      title = item['position'] ?? 'N/A';
      subtitle = item['company'] ?? 'N/A';
      date = "${item['start_year']} - ${item['end_year']}";
    } else {
      title = item['name'] ?? 'N/A';
      subtitle = item['description'] ?? 'No description';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          if (date.isNotEmpty)
            Text(date, style: const TextStyle(color: AppColors.textPlaceholder, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.fileText, size: 64, color: AppColors.textPlaceholder.withOpacity(0.3)),
          const SizedBox(height: 24),
          const Text("Profile not found", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Please upload your CV in the Discover tab first.", style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
