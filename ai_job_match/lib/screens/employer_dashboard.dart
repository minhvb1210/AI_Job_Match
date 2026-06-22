import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/auth_service.dart';
import '../services/job_service.dart';
import '../services/application_service.dart';
import '../services/company_service.dart';
import '../services/api_service.dart';
import '../services/dashboard_service.dart';
import '../theme/app_colors.dart';
import '../widgets/responsive.dart';
import 'employer/employer_sidebar.dart';
import 'employer/dashboard_tab.dart';
import 'employer/company_profile_tab.dart';
import 'employer/ai_sourcing_dialog.dart';
import 'employer/recruiter_profile_screen.dart';
import 'shared/notifications_screen.dart';

class EmployerDashboard extends StatefulWidget {
  const EmployerDashboard({super.key});

  @override
  State<EmployerDashboard> createState() => _EmployerDashboardState();
}

class _EmployerDashboardState extends State<EmployerDashboard> {
  List<dynamic> _jobs = [];
  bool _isLoading = true;
  String _selectedTab = 'jobs';
  
  final _jobService = JobService();
  final _appService = ApplicationService();
  final _companyService = CompanyService();

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  Future<void> _fetchJobs() async {
    try {
      final jobs = await _jobService.getMyJobs();
      setState(() {
        _jobs = jobs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onLogout() {
    final auth = Provider.of<AuthService>(context, listen: false);
    auth.logout();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isDesktop = Responsive.isDesktop(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: !isDesktop ? Drawer(child: EmployerSidebar(
        selectedTab: _selectedTab,
        onTabChanged: (tab) {
          setState(() => _selectedTab = tab);
          Navigator.pop(context);
        },
        onLogout: _onLogout,
      )) : null,
      body: Row(
        children: [
          if (isDesktop)
            EmployerSidebar(
              selectedTab: _selectedTab,
              onTabChanged: (tab) => setState(() => _selectedTab = tab),
              onLogout: _onLogout,
            ),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(theme),
                Expanded(
                  child: _buildTabContent(theme),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedTab == 'jobs' ? FloatingActionButton.extended(
        onPressed: () => context.go('/create-job'),
        backgroundColor: AppColors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text("Post Job", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
    );
  }

  Widget _buildTopBar(ShadThemeData theme) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (!Responsive.isDesktop(context))
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(LucideIcons.menu, color: AppColors.textPrimary),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          Text(
            _getPageTitle(),
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(LucideIcons.bell, color: AppColors.textSecondary, size: 20),
            onPressed: () => setState(() => _selectedTab = 'notifications'),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => setState(() => _selectedTab = 'my-profile'),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Text('Me', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedTab) {
      case 'jobs': return 'Job Management';
      case 'dashboard': return 'Analytics & Insights';
      case 'my-profile': return 'My Profile';
      case 'profile': return 'Company Profile';
      case 'talent': return 'Talent Pool';
      case 'notifications': return 'Notifications';
      default: return 'Recruiter Portal';
    }
  }

  Widget _buildTabContent(ShadThemeData theme) {
    switch (_selectedTab) {
      case 'jobs': return _buildJobsTab(theme);
      case 'dashboard': return const DashboardTab();
      case 'my-profile': return const RecruiterProfileScreen();
      case 'profile': return const CompanyProfileTab();
      case 'talent': return const Center(child: Text("Talent Pool coming soon..."));
      case 'notifications': return const NotificationsScreen();
      default: return _buildJobsTab(theme);
    }
  }

  Widget _buildJobsTab(ShadThemeData theme) {
    return Skeletonizer(
      enabled: _isLoading,
      child: ListView.builder(
        padding: const EdgeInsets.all(32),
        itemCount: _isLoading ? 5 : _jobs.length,
        itemBuilder: (context, index) {
          if (_isLoading) return _buildSkeletonJobCard();
          final job = _jobs[index];
          return _buildEmployerJobCard(job, theme)
              .animate()
              .fadeIn(delay: (index * 100).ms)
              .slideX(begin: 0.1);
        },
      ),
    );
  }

  Widget _buildEmployerJobCard(dynamic job, ShadThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(LucideIcons.briefcase, color: AppColors.primary),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job['title'] ?? 'Untitled Role',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job['company'] ?? 'Hiring Entity',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge('active'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildIconInfo(LucideIcons.mapPin, job['location'] ?? 'Remote'),
              const SizedBox(width: 24),
              _buildIconInfo(LucideIcons.users, "12 Applicants"), // Static for now
              const SizedBox(width: 24),
              _buildIconInfo(LucideIcons.calendar, "Posted 2 days ago"),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              ShadButton.outline(
                onPressed: () => _deleteJob(job['id']),
                leading: const Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                child: const Text("Remove", style: TextStyle(color: AppColors.error)),
              ),
              const Spacer(),
              ShadButton.outline(
                onPressed: () => _showAiSuggestionsDialog(job['id'], job['title']),
                leading: const Icon(LucideIcons.sparkles, size: 16, color: Colors.purpleAccent),
                child: const Text("AI Match"),
              ),
              const SizedBox(width: 12),
              ShadButton(
                onPressed: () => context.push('/applicants/${job['id']}', extra: job['title']),
                leading: const Icon(LucideIcons.users, size: 16),
                child: const Text("Review"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textPlaceholder),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withOpacity(0.2)),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _buildSkeletonJobCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
    );
  }

  Future<void> _deleteJob(int jobId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Job Posting?"),
        content: const Text("This will permanently remove the job listing and all received applications."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.redAccent))),
        ]
      )
    );
    if (confirm != true) return;
    
    // Store backup for rollback if needed
    final originalJobs = List.from(_jobs);

    try {
      // Optimistic UI update: remove instantly from list
      setState(() {
        _jobs.removeWhere((job) => job['id'] == jobId);
      });

      await _jobService.deleteJob(jobId);
      
      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            title: Text("Job Deleted"),
            description: Text("Successfully removed the job posting.")
          )
        );
      }
    } catch (e) {
      // Rollback on failure
      setState(() {
        _jobs = originalJobs;
      });
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text("Delete Failed"),
            description: Text("Failed to delete the job post. Please try again."),
          )
        );
      }
    }
  }

  void _showAiSuggestionsDialog(int jobId, String jobTitle) {
    showDialog(
      context: context,
      builder: (context) {
        return JobAiSourcingDialog(jobId: jobId, jobTitle: jobTitle);
      }
    );
  }
}
