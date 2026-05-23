import 'package:flutter/foundation.dart';
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
import '../services/cv_service.dart';
import '../services/api_service.dart';
import '../services/application_service.dart';
import '../theme/app_colors.dart';
import '../widgets/responsive.dart';
import '../widgets/modern_job_card.dart';
import 'candidate/candidate_sidebar.dart';
import 'candidate/online_cv_tab.dart';
import 'candidate/candidate_dialogs.dart';
import 'candidate/top_companies_tab.dart';
import 'candidate/saved_jobs_screen.dart';
import 'candidate/companies_screen.dart';
import 'candidate/ai_matching_tab.dart';
import 'candidate/candidate_profile_screen.dart';
import 'my_applications_screen.dart';

class CandidateDashboard extends StatefulWidget {
  const CandidateDashboard({super.key});

  @override
  State<CandidateDashboard> createState() => _CandidateDashboardState();
}

class _CandidateDashboardState extends State<CandidateDashboard> {
  String _selectedTab = 'discover';
  List<dynamic> _jobs = [];
  List<dynamic> _matches = [];
  bool _isLoadingJobs = true;
  bool _isLoadingMatches = true;
  String? _cvText;

  final _jobService = JobService();
  final _cvService = CvService();
  final _discoverScrollController = ScrollController();
  final _matchesScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    debugPrint("DEBUG: CandidateDashboard initState");
    _fetchJobs();
    _fetchMatches();
    _checkCv();
  }

  @override
  void dispose() {
    _discoverScrollController.dispose();
    _matchesScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchJobs() async {
    try {
      final jobs = await _jobService.getAllJobs();
      setState(() {
        _jobs = jobs;
        _isLoadingJobs = false;
      });
    } catch (e) {
      setState(() => _isLoadingJobs = false);
    }
  }

  Future<void> _fetchMatches() async {
    try {
      final matches = await _jobService.getAiMatches();
      setState(() {
        _matches = matches;
        _isLoadingMatches = false;
      });
    } catch (e) {
      setState(() => _isLoadingMatches = false);
    }
  }

  Future<void> _checkCv() async {
    try {
      final dio = await ApiService.authenticated();
      final res = await dio.get('/cv/my-cv');
      if (res.data is Map && res.data['success'] == true) {
        setState(() => _cvText = res.data['data']['raw_text']);
      }
    } catch (_) {}
  }

  void _onLogout() {
    final auth = Provider.of<AuthService>(context, listen: false);
    auth.logout();
    context.go('/login');
  }

  Future<void> _applyForJob(int jobId, [double? score]) async {
    try {
      final appService = ApplicationService();
      await appService.applyForJob(jobId: jobId, matchScore: score ?? 0);
      ShadToaster.of(context).show(const ShadToast(title: Text("Application Sent"), description: Text("You have successfully applied for this role.")));
    } catch (e) {
      ShadToaster.of(context).show(ShadToast.destructive(title: Text("Error"), description: Text(ApiService.errorMessage(e))));
    }
  }

  Future<void> _toggleSaveJob(int jobId, bool currentlySaved) async {
    try {
      await _jobService.toggleSaveJob(jobId, currentlySaved);
      _fetchJobs(); // Refresh
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isDesktop = Responsive.isDesktop(context);

    // FIX: Wrap everything in a Material and SelectionArea to ensure Web hit-testing works correctly
    return SelectionArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        // FIX: Prevent invisible modal barrier from accidental drag gestures on Web
        drawerEnableOpenDragGesture: false,
        drawer: !isDesktop ? Drawer(
          child: Material(
            child: CandidateSidebar(
              selectedTab: _selectedTab,
              onTabChanged: (tab) {
                setState(() => _selectedTab = tab);
                Navigator.pop(context);
              },
              onLogout: _onLogout,
            ),
          ),
        ) : null,
        body: Material(
          color: Colors.transparent,
          child: Row(
            children: [
              if (isDesktop)
                CandidateSidebar(
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
        ),
      ),
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
            onPressed: () => _showNotifications(),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => setState(() => _selectedTab = 'profile'),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Text('Me', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedTab) {
      case 'discover': return 'Discover Opportunities';
      case 'matches': return 'AI Match Recommendations';
      case 'profile': return 'My Profile';
      case 'cv': return 'Online Professional Profile';
      case 'saved': return 'My Saved Jobs';
      case 'companies': return 'Top Companies';
      case 'applications': return 'My Applications';
      default: return 'Candidate Portal';
    }
  }

  Widget _buildTabContent(ShadThemeData theme) {
    switch (_selectedTab) {
      case 'discover': return _buildDiscoverTab(theme);
      case 'matches': return const AiMatchingTab();
      case 'profile': return const CandidateProfileScreen();
      case 'cv': return const OnlineCvTab();
      case 'saved': return const SavedJobsScreen();
      case 'companies': return const CompaniesScreen();
      case 'applications': return const MyApplicationsScreen();
      default: return _buildDiscoverTab(theme);
    }
  }

  Widget _buildDiscoverTab(ShadThemeData theme) {
    debugPrint("DEBUG: Rendering DiscoverTab (isLoading: $_isLoadingJobs)");
    final content = SingleChildScrollView(
        controller: _discoverScrollController,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchHero(),
            const SizedBox(height: 48),
            Row(
              children: [
                Text("Featured Opportunities", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(onPressed: () {}, child: const Text("View all")),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoadingJobs)
              Skeletonizer(
                enabled: true,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  itemBuilder: (context, index) => _buildSkeletonCard(),
                ),
              )
            else if (_jobs.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No jobs found matching your criteria.")))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _jobs.length,
                itemBuilder: (context, index) {
                  return ModernJobCard(
                    job: _jobs[index],
                    onApply: () => _applyForJob(_jobs[index]['id']),
                    onSave: () => _toggleSaveJob(_jobs[index]['id'], false),
                    onTap: () => context.push('/jobs/${_jobs[index]['id']}'),
                  )
                      .animate()
                      .fadeIn(delay: (index * 100).ms)
                      .slideX(begin: 0.1);
                },
              ),
            const SizedBox(height: 48),
            const TopCompaniesTab(),
          ],
        ),
      );

    if (kIsWeb) return content;
    
    return RefreshIndicator(
      onRefresh: _fetchJobs,
      child: content,
    );
  }

  Widget _buildAiMatchesTab(ShadThemeData theme) {
    return Column(
      children: [
        if (_cvText != null)
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.fromLTRB(32, 32, 32, 0),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.purple.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.sparkles, color: Colors.purpleAccent),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    "Your CV is active. Our AI has calculated match scores for all available roles.",
                    style: TextStyle(color: Colors.purple, fontWeight: FontWeight.w500),
                  ),
                ),
                ShadButton.outline(
                  onPressed: () => _showImproveCv(),
                  child: const Text("Optimize CV"),
                ),
              ],
            ),
          ),
        Expanded(
          child: _isLoadingMatches 
            ? Skeletonizer(
                enabled: true,
                child: ListView.builder(
                  padding: const EdgeInsets.all(32),
                  itemCount: 3,
                  itemBuilder: (context, index) => _buildSkeletonCard(),
                ),
              )
            : _matches.isEmpty
              ? const Center(child: Text("Upload your CV to see AI-matched jobs!"))
              : ListView.builder(
                  controller: _matchesScrollController,
                  padding: const EdgeInsets.all(32),
                  itemCount: _matches.length,
                  itemBuilder: (context, index) {
                    return ModernJobCard(
                      job: _matches[index], 
                      isMatch: true,
                      matchScore: double.tryParse(_matches[index]['score'].toString()),
                      onApply: () => _applyForJob(_matches[index]['id'], double.tryParse(_matches[index]['score'].toString())),
                      onSave: () => _toggleSaveJob(_matches[index]['id'], false),
                      onTap: () => context.push('/jobs/${_matches[index]['id']}'),
                    )
                        .animate()
                        .fadeIn(delay: (index * 100).ms)
                        .slideY(begin: 0.1);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchHero() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Find your dream role", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Search across thousands of high-quality AI-matched opportunities.", style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          const SizedBox(height: 32),
          Row(
            children: [
              const Expanded(
                child: ShadInput(
                  placeholder: Text("Job title, keywords, or company"),
                  leading: Padding(padding: EdgeInsets.only(right: 8), child: Icon(LucideIcons.search, size: 18, color: AppColors.textPlaceholder)),
                ),
              ),
              const SizedBox(width: 16),
              ShadButton(
                onPressed: () {},
                size: ShadButtonSize.lg,
                child: const Text("Search Jobs"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
    );
  }

  void _showNotifications() {
    // showDialog(
    //   context: context,
    //   builder: (context) => const NotificationDialog(),
    // );
  }

  void _showImproveCv() {
    if (_cvText == null) return;
    showDialog(
      context: context,
      builder: (context) => ImproveCvDialog(cvText: _cvText!),
    );
  }
}
