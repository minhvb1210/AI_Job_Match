import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../services/profile_service.dart';
import '../../../theme/app_colors.dart';
import '../shared/edit_profile_dialog.dart';

class CandidateProfileScreen extends StatefulWidget {
  const CandidateProfileScreen({super.key});

  @override
  State<CandidateProfileScreen> createState() => _CandidateProfileScreenState();
}

class _CandidateProfileScreenState extends State<CandidateProfileScreen> {
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
        isRecruiter: false,
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
                    _buildExperienceCard(),
                    const SizedBox(height: 24),
                    _buildEducationCard(),
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
    final name = _profile!['full_name'] ?? 'Candidate Name';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Banner
          Container(
            height: 120,
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar overlapping banner
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
                          ? const Icon(LucideIcons.user, size: 40, color: AppColors.textPlaceholder)
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
      title: 'About Me',
      icon: LucideIcons.user,
      child: Text(
        _profile!['bio'] ?? 'No bio provided yet. Add a short bio to introduce yourself to recruiters.',
        style: const TextStyle(color: AppColors.textSecondary, height: 1.5, fontSize: 15),
      ),
    );
  }

  Widget _buildContactCard() {
    return _buildCard(
      title: 'Contact Information',
      icon: LucideIcons.mail,
      child: Column(
        children: [
          _buildContactRow(LucideIcons.phone, 'Phone', _profile!['phone_number']),
          _buildContactRow(LucideIcons.mapPin, 'Address', _profile!['address']),
          _buildContactRow(LucideIcons.calendar, 'Date of Birth', _profile!['date_of_birth']),
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
      title: 'Skills & Expertise',
      icon: Icons.bar_chart,
      child: Wrap(
        children: [
          Expanded(
            child: _buildStatItem(
              label: 'Saved Jobs',
              value: _profile!['saved_jobs_count'].toString(),
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatItem(
              label: 'Applied',
              value: _profile!['applied_jobs_count'].toString(),
              color: AppColors.success,
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
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceCard() {
    final experiences = _profile!['experiences'] as List<dynamic>? ?? [];
    return _buildCard(
      title: 'Experience',
      icon: LucideIcons.briefcase,
      child: experiences.isEmpty
          ? const Text('No experience details added yet.', style: TextStyle(color: AppColors.textSecondary))
          : Column(
              children: experiences.map((exp) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF1F5F9),
                    child: Icon(LucideIcons.building, color: AppColors.textSecondary, size: 18),
                  ),
                  title: Text(exp['position'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${exp['company']} • ${exp['start_year']} - ${exp['end_year']}'),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildEducationCard() {
    final educations = _profile!['educations'] as List<dynamic>? ?? [];
    return _buildCard(
      title: 'Education',
      icon: LucideIcons.graduationCap,
      child: educations.isEmpty
          ? const Text('No education details added yet.', style: TextStyle(color: AppColors.textSecondary))
          : Column(
              children: educations.map((edu) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF1F5F9),
                    child: Icon(LucideIcons.book, color: AppColors.textSecondary, size: 18),
                  ),
                  title: Text(edu['degree'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${edu['school']} • ${edu['start_year']} - ${edu['end_year']}'),
                );
              }).toList(),
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
