import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../services/profile_service.dart';
import '../../../theme/app_colors.dart';
import '../shared/edit_profile_dialog.dart';

class RecruiterProfileScreen extends StatefulWidget {
  const RecruiterProfileScreen({super.key});

  @override
  State<RecruiterProfileScreen> createState() => _RecruiterProfileScreenState();
}

class _RecruiterProfileScreenState extends State<RecruiterProfileScreen> {
  final _profileService = ProfileService();
  bool _isLoading = true;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final data = await _profileService.getMyProfile();
    setState(() {
      _profile = data;
      _isLoading = false;
    });
  }

  void _showEditDialog() {
    if (_profile == null) return;
    showDialog(
      context: context,
      builder: (context) => EditProfileDialog(
        initialData: _profile!,
        isRecruiter: true,
        onSaved: _loadProfile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_profile == null) {
      return const Center(child: Text('Failed to load profile.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildAboutCard(),
                    const SizedBox(height: 24),
                    _buildCompanyCard(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildContactCard(),
                    const SizedBox(height: 24),
                    _buildStatsCard(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.05),
    );
  }

  Widget _buildHeader() {
    final avatarUrl = _profile!['avatar_url'] as String?;
    final name = _profile!['full_name'] ?? 'Recruiter Name';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 120,
            decoration: const BoxDecoration(gradient: AppColors.accentGradient),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.background,
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty 
                          ? NetworkImage(avatarUrl) 
                          : null,
                      child: avatarUrl == null || avatarUrl.isEmpty
                          ? const Icon(LucideIcons.briefcase, size: 40, color: AppColors.textPlaceholder)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _profile!['email'] ?? '',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Verified Recruiter',
                            style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ShadButton.outline(
                    leading: const Icon(Icons.edit, size: 16),
                    onPressed: _showEditDialog,
                    child: const Text('Edit Profile'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return _buildCard(
      title: 'About',
      icon: LucideIcons.user,
      child: Text(
        _profile!['bio'] ?? 'No bio provided yet. Add details about your role and hiring focus.',
        style: const TextStyle(color: AppColors.textSecondary, height: 1.5, fontSize: 15),
      ),
    );
  }

  Widget _buildContactCard() {
    return _buildCard(
      title: 'Contact Details',
      icon: LucideIcons.mail,
      child: Column(
        children: [
          _buildContactRow(LucideIcons.phone, 'Phone', _profile!['phone_number']),
          _buildContactRow(LucideIcons.mapPin, 'Location', _profile!['address']),
          _buildContactRow(LucideIcons.globe, 'Website', _profile!['website']),
          _buildContactRow(LucideIcons.building, 'Industry', _profile!['industry']),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textPlaceholder)),
                Text(
                  value != null && value.isNotEmpty ? value : 'Not provided',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: value != null && value.isNotEmpty ? AppColors.textPrimary : AppColors.textPlaceholder,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return _buildCard(
      title: 'Hiring Activity',
      icon: LucideIcons.activity,
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              label: 'Jobs Posted',
              value: _profile!['jobs_posted_count'].toString(),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatItem(
              label: 'Applicants',
              value: _profile!['total_applicants_count'].toString(),
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard() {
    final company = _profile!['company'];
    if (company == null) {
      return _buildCard(
        title: 'Company Information',
        icon: LucideIcons.building,
        child: const Text('No company profile linked.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    
    return _buildCard(
      title: 'Company Information',
      icon: LucideIcons.building,
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              image: company['logo_url'] != null && company['logo_url'].isNotEmpty
                  ? DecorationImage(image: NetworkImage(company['logo_url']), fit: BoxFit.contain)
                  : null,
            ),
            child: company['logo_url'] == null || company['logo_url'].isEmpty
                ? const Icon(LucideIcons.building, size: 32, color: AppColors.textPlaceholder)
                : null,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(company['name'] ?? 'Company Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text(company['description'] ?? 'No description.', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  children: [
                    if (company['location'] != null && company['location'].isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.mapPin, size: 14, color: AppColors.textPlaceholder),
                          const SizedBox(width: 4),
                          Text(company['location'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    if (company['size'] != null && company['size'].isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.users, size: 14, color: AppColors.textPlaceholder),
                          const SizedBox(width: 4),
                          Text(company['size'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
