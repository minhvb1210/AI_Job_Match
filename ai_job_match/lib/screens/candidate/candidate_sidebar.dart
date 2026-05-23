import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class CandidateSidebar extends StatelessWidget {
  final String selectedTab;
  final Function(String) onTabChanged;
  final VoidCallback onLogout;

  const CandidateSidebar({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'AI Match',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          _SidebarItem(
            icon: LucideIcons.search,
            label: 'Discovery',
            isSelected: selectedTab == 'discover',
            onTap: () => onTabChanged('discover'),
          ),
          _SidebarItem(
            icon: LucideIcons.sparkles,
            label: 'AI Matches',
            isSelected: selectedTab == 'matches',
            onTap: () => onTabChanged('matches'),
          ),
          _SidebarItem(
            icon: LucideIcons.user,
            label: 'My Profile',
            isSelected: selectedTab == 'profile',
            onTap: () => onTabChanged('profile'),
          ),
          _SidebarItem(
            icon: LucideIcons.fileText,
            label: 'Online CV',
            isSelected: selectedTab == 'cv',
            onTap: () => onTabChanged('cv'),
          ),
          _SidebarItem(
            icon: LucideIcons.heart,
            label: 'Saved Jobs',
            isSelected: selectedTab == 'saved',
            onTap: () => onTabChanged('saved'),
          ),
          _SidebarItem(
            icon: LucideIcons.building,
            label: 'Companies',
            isSelected: selectedTab == 'companies',
            onTap: () => onTabChanged('companies'),
          ),
          _SidebarItem(
            icon: LucideIcons.briefcase,
            label: 'Applications',
            isSelected: selectedTab == 'applications',
            onTap: () => onTabChanged('applications'),
          ),
          const Spacer(),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 24),
          ListTile(
            onTap: onLogout,
            leading: const Icon(LucideIcons.logOut, color: AppColors.error, size: 20),
            title: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        selected: isSelected,
        selectedTileColor: AppColors.primary.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
