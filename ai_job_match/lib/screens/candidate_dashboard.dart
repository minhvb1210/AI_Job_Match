import 'dart:convert';
import 'dart:ui' as ui;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/job_service.dart';
import '../services/cv_service.dart';
import '../services/application_service.dart';
import '../services/company_service.dart';
import '../services/api_service.dart';

class CandidateDashboard extends StatefulWidget {
  const CandidateDashboard({super.key});
  @override
  State<CandidateDashboard> createState() => _CandidateDashboardState();
}

class _CandidateDashboardState extends State<CandidateDashboard> {
  bool _isLoading = false;
  bool _isAppsLoading = false;
  String _extractedText = "";
  List<dynamic> _matches = [];
  List<dynamic> _applications = [];
  List<dynamic> _savedJobs = [];
  List<dynamic> _searchResults = [];
  List<dynamic> _externalJobs = [];
  bool _isExternalLoading = false;
  String _errorMessage = "";
  String _searchQuery = "";
  String _searchCategory = "All";
  String _searchJobType = "All";
  String _searchExperience = "All";
  String _selectedTab = "matches";

  final _jobService = JobService();
  final _cvService = CvService();
  final _appService = ApplicationService();
  final _companyService = CompanyService();

  final List<String> _categories = ['All', 'IT', 'Marketing', 'Sales', 'Finance', 'Design', 'Other'];
  final List<String> _jobTypes = ['All', 'Full-time', 'Part-time', 'Remote', 'Internship'];
  final List<String> _experienceLevels = ['All', 'Intern', 'Fresher', 'Junior', 'Middle', 'Senior', 'Manager'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSavedMatches();
      _fetchApplications();
      _fetchSavedJobs();
      _fetchExternalJobs();
      _searchJobs(); // Load all jobs for discovery on init
    });
  }

  Future<void> _fetchExternalJobs() async {
    setState(() => _isExternalLoading = true);
    try {
      final jobs = await _jobService.getExternalJobs();
      setState(() => _externalJobs = jobs);
    } catch (_) {}
    setState(() => _isExternalLoading = false);
  }

  Future<void> _fetchSavedMatches() async {
    setState(() => _isLoading = true);
    try {
      final res = await _cvService.getSavedMatches();
      setState(() {
        _extractedText = res.extractedTextPreview;
        _matches = res.matches.map((m) => {
          'score': m.score,
          'missing_skills': m.missingSkills,
          'job': {
            'id': m.job.id,
            'title': m.job.title,
            'company': m.job.company,
            'location': m.job.location,
            'salary': m.job.salary,
            'skills': m.job.skills,
          }
        }).toList();
      });
    } catch (_) { }
    setState(() => _isLoading = false);
  }

  Future<void> _fetchApplications() async {
    setState(() => _isAppsLoading = true);
    try {
      final items = await _appService.getMyApplications();
      setState(() => _applications = items.map((a) => {
        'id': a.id,
        'job_id': a.jobId,
        'status': a.status,
        'match_score': a.matchScore,
        'job': {
          'id': a.jobId,
          'title': a.jobTitle,
          'company': a.company,
        }
      }).toList());
    } catch (_) { }
    setState(() => _isAppsLoading = false);
  }

  Future<void> _fetchSavedJobs() async {
    print("DEBUG: Fetching saved jobs...");
    try {
      final jobs = await _jobService.getSavedJobs();
      print("DEBUG: Received ${jobs.length} saved jobs");
      setState(() => _savedJobs = jobs);
    } catch (e) {
      print("DEBUG: Error fetching saved jobs: $e");
    }
  }

  Future<void> _searchJobs() async {
    print("DEBUG: Searching jobs (query: $_searchQuery)...");
    try {
      var results = await _jobService.searchJobs(
        query: _searchQuery,
        category: _searchCategory,
        jobType: _searchJobType,
        experienceLevel: _searchExperience,
      );
      print("PARSED JOBS: ${results.length}");
      print("UI JOB LENGTH: ${results.length}"); // REQUIRED LOG
      setState(() {
        _searchResults = results;
        _errorMessage = results.isEmpty ? "No jobs found matching your criteria." : "";
      });
    } catch (e) {
      print("DEBUG: Error searching jobs: $e");
      setState(() => _errorMessage = "Error connecting to job service.");
    }
  }

  Future<void> _toggleSaveJob(int jobId) async {
    bool isSaved = _savedJobs.any((j) => j['id'] == jobId);
    try {
       await _jobService.toggleSaveJob(jobId, isSaved);
       _fetchSavedJobs();
    } catch (_) {}
  }

  Future<void> _applyForJob(int jobId, [double? score]) async {
    try {
      await _appService.applyForJob(jobId: jobId, matchScore: score ?? 0);
      ShadToaster.of(context).show(
        const ShadToast(
          title: Text("Application Success"),
          description: Text("Successfully applied for this position!"),
        ),
      );
      _fetchApplications();
    } catch (e) {
       ShadToaster.of(context).show(
         ShadToast.destructive(
           title: const Text("Error Applying"),
           description: Text(ApiService.errorMessage(e)),
         ),
       );
    }
  }

  Future<void> _editProfileText() async {
    TextEditingController _ctrl = TextEditingController(text: _extractedText);
    bool? save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Extracted Profile"),
        content: TextField(
          controller: _ctrl,
          maxLines: 8,
          decoration: const InputDecoration(border: OutlineInputBorder())
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Save")),
        ],
      )
    );
    if (save == true) {
      setState(() => _isLoading = true);
      try {
        await _cvService.updateProfile(_ctrl.text);
        _fetchSavedMatches(); // Re-match based on new text
      } catch (_) {}
    }
  }

  Future<void> _pickAndUploadCV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'png', 'jpg', 'jpeg'],
        withData: true,
      );
 
      if (result != null) {
        setState(() {
          _isLoading = true;
          _errorMessage = "";
          _extractedText = "";
          _matches = [];
        });
 
        final fileBytes = result.files.first.bytes;
        final fileName = result.files.first.name;
 
        if (fileBytes == null) {
          setState(() {
            _isLoading = false;
            _errorMessage = "Could not read file data. Please try again.";
          });
          return;
        }
 
        // Use CvService for upload and match (byte-only)
        final res = await _cvService.uploadCV(fileBytes, fileName);
 
        setState(() {
          _extractedText = res.extractedTextPreview;
          _matches = res.matches.map((m) => {
            'score': m.score,
            'missing_skills': m.missingSkills,
            'job': {
              'id': m.job.id,
              'title': m.job.title,
              'company': m.job.company,
              'location': m.job.location,
              'salary': m.job.salary,
              'skills': m.job.skills,
            }
          }).toList();
        });
      }
    } catch (e) {
      setState(() => _errorMessage = ApiService.errorMessage(e));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showImproveCvDialog() async {
    showDialog(
      context: context,
      builder: (context) => _ImproveCvDialog(cvText: _extractedText),
    );
  }

  Widget _buildTabButton(String label, String value) {
    bool isSelected = _selectedTab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = value;
            if (value == 'find_jobs') {
               _searchJobs(); 
            }
          });
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? ShadTheme.of(context).colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(4),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(ShadThemeData theme) {
    switch (_selectedTab) {
      case 'find_jobs': return _buildFindJobsTab(theme);
      case 'external': return _buildExternalJobsTab(theme);
      case 'companies': return const TopCompaniesTab();
      case 'saved': return _buildSavedJobsTab(theme);
      case 'matches': return _buildAiMatchesTab(theme);
      case 'apps': return _buildApplicationsTab(theme);
      case 'cv': return const OnlineCvTab();
      default: return _buildFindJobsTab(theme);
    }
  }

  Widget _buildEmptyState(String title, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white10),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(fontSize: 14, color: Colors.white38), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildExternalJobsTab(ShadThemeData theme) {
    if (_isExternalLoading && _externalJobs.isEmpty) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => _buildSkeletonCard(),
      );
    }
    if (_externalJobs.isEmpty) {
      return _buildEmptyState(
        "No Remote Jobs", 
        "We couldn't find any external jobs at the moment. Please try again later.", 
        LucideIcons.globe
      );
    }
    return ListView.builder(
      itemCount: _externalJobs.length,
      itemBuilder: (context, index) => _buildExternalJobCard(_externalJobs[index], theme),
    );
  }

  Widget _buildSkeletonCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildExternalJobCard(dynamic job, ShadThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ShadCard(
        padding: const EdgeInsets.all(20),
        radius: const BorderRadius.all(Radius.circular(16)),
        child: Row(
          children: [
            if (job['logo_url'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(job['logo_url'], width: 50, height: 50, errorBuilder: (c, e, s) => const Icon(LucideIcons.building2, size: 40)),
              )
            else
              const Icon(LucideIcons.building2, size: 40, color: Colors.white24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(job['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: const Text("External", style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  Text(job['company'], style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, size: 12, color: Colors.white30),
                      const SizedBox(width: 4),
                      Text(job['location'], style: const TextStyle(color: Colors.white30, fontSize: 11)),
                      const SizedBox(width: 12),
                      const Icon(LucideIcons.calendar, size: 12, color: Colors.white30),
                      const SizedBox(width: 4),
                      Text(job['job_type'] ?? 'Remote', style: const TextStyle(color: Colors.white30, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            ShadButton.outline(
              onPressed: () {
                // Open external URL or show detail
              },
              child: const Text("View Details"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final theme = ShadTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text('Candidate Hub', style: theme.textTheme.h3.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          ShadButton.ghost(
            leading: const Icon(LucideIcons.bell, size: 20),
            onPressed: () {
               showDialog(context: context, builder: (_) => const NotificationDialog());
            },
          ),
          ShadButton.ghost(
            leading: const Icon(LucideIcons.logOut, size: 20),
            onPressed: () {
              auth.logout();
              context.go('/login');
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           // Left sidebar
           Expanded(
             flex: 3,
             child: Padding(
               padding: const EdgeInsets.all(16.0),
               child: ShadCard(
                 padding: const EdgeInsets.all(24),
                 backgroundColor: theme.colorScheme.card,
                 radius: const BorderRadius.all(Radius.circular(24)),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.stretch,
                   children: [
                     Icon(LucideIcons.userCheck, size: 48, color: theme.colorScheme.primary),
                     const SizedBox(height: 16),
                     Text(
                       "My AI Profile",
                       style: theme.textTheme.h3.copyWith(fontWeight: FontWeight.bold),
                       textAlign: TextAlign.center,
                     ),
                     const SizedBox(height: 8),
                     Text(
                       "Upload your CV to let AI extract your skills and find the best matches.", 
                       style: theme.textTheme.muted,
                       textAlign: TextAlign.center,
                     ),
                     const SizedBox(height: 24),
                     ShadButton(
                       onPressed: _isLoading ? null : _pickAndUploadCV,
                       leading: const Icon(LucideIcons.upload, size: 18),
                       child: const Text("Upload New CV"),
                     ),
                     const SizedBox(height: 12),
                     if (_extractedText.isNotEmpty)
                        ShadButton.outline(
                          onPressed: _isLoading ? null : _showImproveCvDialog,
                          leading: const Icon(LucideIcons.sparkles, size: 18, color: Colors.purpleAccent),
                          child: const Text("Improve my CV", style: TextStyle(color: Colors.purpleAccent)),
                        ),
                     const SizedBox(height: 16),
                     if (_isLoading) const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                     if (_errorMessage.isNotEmpty) 
                       Container(
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(color: theme.colorScheme.destructive.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                         child: Text(_errorMessage, style: TextStyle(color: theme.colorScheme.destructive, fontSize: 13)),
                       ),
                     if (_extractedText.isNotEmpty) ...[
                       const SizedBox(height: 24),
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                            Text("Extracted Profile:", style: theme.textTheme.small.copyWith(fontWeight: FontWeight.bold)),
                            ShadButton.ghost(
                              width: 32, height: 32, padding: EdgeInsets.zero,
                              leading: const Icon(LucideIcons.pencil, size: 14), 
                              onPressed: _editProfileText,
                            )
                         ],
                       ),
                       const SizedBox(height: 8),
                       Expanded(
                         child: ShadCard(
                           backgroundColor: Colors.black.withOpacity(0.2),
                           padding: const EdgeInsets.all(16),
                           radius: const BorderRadius.all(Radius.circular(12)),
                           child: SingleChildScrollView(
                             child: Text(
                               _extractedText, 
                               style: theme.textTheme.small.copyWith(color: Colors.white70, fontSize: 12),
                             ),
                           ),
                         ),
                       ),
                     ],
                   ],
                 ),
               ),
             ),
           ),
           // Right area
           Expanded(
             flex: 7,
             child: Padding(
               padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
               child: Column(
                 children: [
                   // Custom Tab Bar
                   Container(
                     height: 50,
                     decoration: BoxDecoration(
                       color: theme.colorScheme.card,
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: Row(
                       children: [
                         _buildTabButton("🔍 Internal", "find_jobs"),
                          _buildTabButton("🌐 External", "external"),
                         _buildTabButton("🏢 Companies", "companies"),
                         _buildTabButton("⭐ Saved", "saved"),
                         _buildTabButton("🔥 AI Matches", "matches"),
                         _buildTabButton("📝 Apps", "apps"),
                         _buildTabButton("📄 CV", "cv"),
                       ],
                     ),
                   ),
                   const SizedBox(height: 16),
                   Expanded(
                     child: _buildTabContent(theme),
                   ),
                 ],
               ),
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildFindJobsTab(ShadThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: ShadInput(
                placeholder: const Text("Search jobs by title, skill, company..."),
                leading: const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(LucideIcons.search, size: 18),
                ),
                onChanged: (val) {
                   _searchQuery = val;
                   _searchJobs();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildFilterSelect("Category", _searchCategory, _categories, (v) { setState(() => _searchCategory = v!); _searchJobs(); })),
            const SizedBox(width: 8),
            Expanded(child: _buildFilterSelect("Type", _searchJobType, _jobTypes, (v) { setState(() => _searchJobType = v!); _searchJobs(); })),
          ],
        ),
        const SizedBox(height: 24),
        // Temporary Debug Widget
        Container(
          width: double.infinity,
          color: Colors.blueAccent.withOpacity(0.1),
          padding: const EdgeInsets.all(8),
          child: Text("DEBUG: Visible Jobs in UI = ${_searchResults.length}", style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) => _buildJobCard(_searchResults[index], theme)
          ),
        ),
      ],
    );
  }

  Widget _buildSavedJobsTab(ShadThemeData theme) {
    if (_savedJobs.isEmpty) return const Center(child: Text("No saved jobs yet. Explore and save some!"));
    return ListView.builder(
      itemCount: _savedJobs.length,
      itemBuilder: (context, index) => _buildJobCard(_savedJobs[index], theme)
    );
  }

  Widget _buildAiMatchesTab(ShadThemeData theme) {
    if (_isLoading && _matches.isEmpty) {
      return ListView.builder(
        itemCount: 4,
        itemBuilder: (context, index) => _buildSkeletonCard(),
      );
    }
    if (_matches.isEmpty) {
      return _buildEmptyState(
        "No AI Matches Yet", 
        "Upload your CV to let our AI find the best positions tailored to your expertise.", 
        LucideIcons.sparkles
      );
    }
    return ListView.builder(
      itemCount: _matches.length,
      itemBuilder: (context, index) {
        var match = _matches[index];
        var job = match['job'];
        var score = double.parse(match['score'].toString());
        return _buildJobCard(job, theme, matchScore: score);
      },
    );
  }

  Widget _buildApplicationsTab(ShadThemeData theme) {
    if (_isAppsLoading && _applications.isEmpty) {
      return ListView.builder(
        itemCount: 4,
        itemBuilder: (context, index) => _buildSkeletonCard(),
      );
    }
    if (_applications.isEmpty) {
      return _buildEmptyState(
        "No Applications Found", 
        "You haven't applied to any jobs yet. Start matching to find your dream role!", 
        LucideIcons.fileText
      );
    }
    return ListView.builder(
      itemCount: _applications.length,
      itemBuilder: (context, index) {
        final app = _applications[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShadCard(
            padding: const EdgeInsets.all(20),
            radius: const BorderRadius.all(Radius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app['job']['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(app['job']['company'], style: theme.textTheme.muted),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Builder(builder: (context) {
                      Color statusColor = const Color(0xFFFFB347);
                      if (app['status'] == 'reviewing') statusColor = const Color(0xFFFF9800);
                      if (app['status'] == 'interviewing') statusColor = const Color(0xFF2196F3);
                      if (app['status'] == 'accepted') statusColor = const Color(0xFF4CAF50);
                      if (app['status'] == 'rejected') statusColor = const Color(0xFFF44336);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor.withOpacity(0.2)),
                        ),
                        child: Text(
                          app['status'].toString().toUpperCase(), 
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Text("${app['match_score'].toStringAsFixed(1)}% Match", style: theme.textTheme.small),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildJobCard(dynamic job, ShadThemeData theme, {double? matchScore, dynamic missingSkills}) {
    final hasApplied = _applications.any((a) => a['job_id'] == job['id']);
    bool isSaved = _savedJobs.any((j) => j['id'] == job['id']);
    Color scoreColor = Colors.grey;
    if (matchScore != null) {
       scoreColor = matchScore > 15 ? Colors.greenAccent : (matchScore > 8 ? Colors.orangeAccent : Colors.redAccent);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ShadCard(
        padding: const EdgeInsets.all(20),
        radius: const BorderRadius.all(Radius.circular(16)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                     children: [
                        Text(job['title'] ?? 'No Title', style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text("at ${job['company'] ?? 'Unknown'}", style: theme.textTheme.muted),
                        const Spacer(),
                        ShadButton.ghost(
                           width: 32, height: 32, padding: EdgeInsets.zero,
                           leading: Icon(LucideIcons.heart, color: isSaved ? Colors.redAccent : Colors.white30),
                           onPressed: () => _toggleSaveJob(job['id'] ?? 0)
                        )
                     ]
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildIconLabel(LucideIcons.mapPin, job['location'] ?? 'Remote', theme),
                    const SizedBox(width: 16),
                    _buildIconLabel(LucideIcons.banknote, job['salary'] ?? 'Competitive', theme),
                    const SizedBox(width: 16),
                    _buildIconLabel(LucideIcons.briefcase, job['job_type'] ?? 'Full-time', theme),
                  ],
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    List<String> skillList = [];
                    var rawSkills = job['skills'];
                    if (rawSkills is List) {
                      skillList = List<String>.from(rawSkills.map((e) => e.toString()));
                    } else if (rawSkills is String) {
                      skillList = rawSkills.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                    }

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: skillList.map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1), 
                          borderRadius: BorderRadius.circular(8), 
                          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2))
                        ),
                        child: Text(s, style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.w500)),
                      )).toList(),
                    );
                  }
                ),
                if (missingSkills != null) ...[
                  Builder(
                    builder: (context) {
                      List<String> missingList = [];
                      if (missingSkills is List) {
                        missingList = List<String>.from(missingSkills.map((e) => e.toString()));
                      } else if (missingSkills is String) {
                        missingList = missingSkills.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                      }
                      
                      if (missingList.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Text("💡 AI Recommendations:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: missingList.map((s) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.withOpacity(0.2))),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.sparkles, size: 12, color: Colors.orangeAccent),
                                  const SizedBox(width: 4),
                                  Text(s, style: const TextStyle(fontSize: 11, color: Colors.orangeAccent)),
                                ],
                              ),
                            )).toList(),
                          ),
                        ],
                      );
                    }
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(width: 24),
          Column(
            children: [
              if (matchScore != null) ...[
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60, height: 60,
                      child: CircularProgressIndicator(
                        value: (matchScore > 100 ? 100 : matchScore) / 100,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        color: scoreColor,
                        strokeWidth: 5,
                      ),
                    ),
                    Text("${matchScore.toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text("Match", style: TextStyle(fontSize: 10, color: Colors.white30)),
              ],
              const SizedBox(height: 20),
              if (job['is_external'] == true)
                ShadButton.outline(
                  onPressed: () async {
                    final url = job['url'] ?? '';
                    if (url.isNotEmpty) {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                    ShadToaster.of(context).show(const ShadToast(title: Text("Redirecting..."), description: Text("Opening external job source.")));
                  },
                  child: const Text("View Original"),
                )
              else ...[
                ShadButton(
                  onPressed: hasApplied ? null : () => _applyForJob(job['id'], matchScore),
                  backgroundColor: hasApplied ? Colors.white.withOpacity(0.05) : null,
                  child: Text(hasApplied ? "Applied" : "Apply Now"),
                ),
                const SizedBox(height: 8),
                if (matchScore != null)
                  ShadButton.ghost(
                    onPressed: () => context.push('/explain/${job['id']}', extra: job['title']),
                    child: const Text("Explain Score", style: TextStyle(fontSize: 12, color: Colors.white54)),
                  ),
              ]
            ],
          )
        ],
      ),
    ),
  );
}

  Widget _buildIconLabel(IconData icon, String label, ShadThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white30),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.small.copyWith(color: Colors.white60)),
      ],
    );
  }

  Widget _buildFilterSelect(String label, String value, List<String> items, Function(String?) onChanged) {
    return ShadSelect<String>(
      placeholder: Text(label),
      initialValue: value,
      options: items.map((e) => ShadOption(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      selectedOptionBuilder: (context, value) => Text(value),
    );
  }
}

class TopCompaniesTab extends StatefulWidget {
  const TopCompaniesTab({super.key});

  @override
  State<TopCompaniesTab> createState() => _TopCompaniesTabState();
}

class _TopCompaniesTabState extends State<TopCompaniesTab> {
  List<dynamic> _companies = [];
  bool _isLoading = true;
  final _companyService = CompanyService();

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    print("DEBUG: Fetching companies...");
    try {
      final res = await _companyService.getCompanies();
      print("DEBUG: Received ${res.length} companies from API");
      setState(() {
        _companies = res;
        _isLoading = false;
      });
    } catch (e) {
      print("DEBUG: Error fetching companies: $e");
      setState(() {
        _companies = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching companies: ${ApiService.errorMessage(e)}"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_companies.isEmpty) return const Center(child: Text("No companies listed yet."));

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _companies.length,
      itemBuilder: (context, index) {
        final comp = _companies[index];
        return ShadCard(
          backgroundColor: ShadTheme.of(context).colorScheme.card,
          radius: const BorderRadius.all(Radius.circular(16)),
          child: InkWell(
            onTap: () {
              showDialog(context: context, builder: (_) => CompanyDetailDialog(companyId: comp['id'], companyData: comp));
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(LucideIcons.building, size: 48, color: ShadTheme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(comp['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(comp['location'] ?? 'Multiple locations', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text("${comp['size'] ?? 'Varying'} employees", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class CompanyDetailDialog extends StatefulWidget {
  final int companyId;
  final dynamic companyData;
  const CompanyDetailDialog({super.key, required this.companyId, required this.companyData});

  @override
  State<CompanyDetailDialog> createState() => _CompanyDetailDialogState();
}

class _CompanyDetailDialogState extends State<CompanyDetailDialog> {
  List<dynamic> _companyJobs = [];
  bool _isFollowing = false;
  bool _isLoading = true;
  final _companyService = CompanyService();

  @override
  void initState() {
    super.initState();
    _fetchJobs();
    _fetchFollowStatus();
  }

  Future<void> _fetchFollowStatus() async {
    try {
      final isFollowing = await _companyService.getFollowStatus(widget.companyId);
      setState(() => _isFollowing = isFollowing);
    } catch (_) {}
  }

  Future<void> _toggleFollow() async {
    try {
      await _companyService.toggleFollow(widget.companyId);
      setState(() => _isFollowing = !_isFollowing);
    } catch (_) {}
  }

  Future<void> _fetchJobs() async {
    try {
      final jobs = await _companyService.getCompanyJobs(widget.companyId);
      setState(() {
        _companyJobs = jobs;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var comp = widget.companyData;
    final theme = ShadTheme.of(context);
    return Dialog(
      backgroundColor: theme.colorScheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 800,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.building2, size: 64, color: theme.colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(comp['name'], style: theme.textTheme.h2.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(LucideIcons.mapPin, size: 14, color: Colors.white54),
                          const SizedBox(width: 4),
                          Text(comp['location'] ?? '', style: const TextStyle(color: Colors.white54)),
                          const SizedBox(width: 16),
                           const Icon(LucideIcons.users, size: 14, color: Colors.white54),
                          const SizedBox(width: 4),
                          Text("${comp['size'] ?? ''} employees", style: const TextStyle(color: Colors.white54)),
                        ],
                      )
                    ],
                  ),
                ),
                ShadButton.outline(
                  onPressed: _toggleFollow, 
                  leading: Icon(_isFollowing ? LucideIcons.check : LucideIcons.plus, color: _isFollowing ? Colors.green : theme.colorScheme.primary),
                  child: Text(_isFollowing ? "Following" : "Follow"),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context))
              ],
            ),
            const SizedBox(height: 24),
            const Text("About Us", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ShadCard(
               backgroundColor: Colors.white.withOpacity(0.05),
               padding: const EdgeInsets.all(16),
               child: Text(comp['description'] ?? 'No description available.', style: const TextStyle(height: 1.5)),
            ),
            const SizedBox(height: 24),
            const Text("Open Positions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading 
                 ? const Center(child: CircularProgressIndicator())
                 : _companyJobs.isEmpty
                    ? const Center(child: Text("No open positions at the moment."))
                    : ListView.builder(
                        itemCount: _companyJobs.length,
                        itemBuilder: (context, index) {
                          var job = _companyJobs[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ShadCard(
                              child: ListTile(
                                title: Text(job['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text("${job['location']} • ${job['salary']}\n${job['experience_level']} • ${job['job_type']}"),
                                isThreeLine: true,
                                trailing: ShadButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Applied!")));
                                  },
                                  child: const Text("Apply"),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationDialog extends StatefulWidget {
  const NotificationDialog({super.key});

  @override
  State<NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<NotificationDialog> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final dio = await ApiService.authenticated();
      final response = await dio.get('/notifications/');
      final data = response.data as List<dynamic>;
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      final dio = await ApiService.authenticated();
      await dio.put('/notifications/$id/read');
      _fetchNotifications();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Notifications", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context))
              ],
            ),
            const Divider(),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                  ? const Center(child: Text("No notifications."))
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        var notif = _notifications[index];
                        return ListTile(
                          leading: Icon(LucideIcons.info, color: notif['is_read'] ? Colors.white24 : Colors.blueAccent),
                          title: Text(notif['message'], style: TextStyle(color: notif['is_read'] ? Colors.white54 : Colors.white)),
                          onTap: () {
                            if (!notif['is_read']) _markAsRead(notif['id']);
                          },
                        );
                      }
                    )
            )
          ],
        ),
      ),
    );
  }
}

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
    print("DEBUG: Fetching candidate profile for CV tab...");
    try {
      final dio = await ApiService.authenticated();
      final response = await dio.get('/cv/my-profile');
      print("DEBUG: Profile response received: ${response.data != null}");
      final data = response.data;
      setState(() {
        if (data is Map && data['success'] == true) {
          _profile = data['data'];
        } else {
          _profile = null;
        }
        _isLoading = false;
      });
      print("DEBUG: UI Updated with profile: ${_profile != null}");
    } catch (e) {
      print("DEBUG: Error fetching profile: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addSection(String type) async {
    final schoolCtrl = TextEditingController();
    final degreeCtrl = TextEditingController();
    final startYearCtrl = TextEditingController();
    final endYearCtrl = TextEditingController();

    bool? save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add $type"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: schoolCtrl, 
              decoration: InputDecoration(
                labelText: type == 'Education' ? "School" : (type == 'Experience' ? "Company" : "Project Name"),
                border: const OutlineInputBorder(),
              )
            ),
            const SizedBox(height: 12),
            TextField(
              controller: degreeCtrl, 
              decoration: InputDecoration(
                labelText: type == 'Education' ? "Degree" : (type == 'Experience' ? "Position" : "Link"),
                border: const OutlineInputBorder(),
              )
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(
                  controller: startYearCtrl, 
                  decoration: const InputDecoration(labelText: "Start Year", border: OutlineInputBorder())
                )),
                const SizedBox(width: 12),
                Expanded(child: TextField(
                  controller: endYearCtrl, 
                  decoration: const InputDecoration(labelText: "End Year", border: OutlineInputBorder())
                )),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              print("DEBUG: Submitting $type form");
              Navigator.pop(context, true);
            }, 
            child: const Text("Save")
          ),
        ],
      )
    );

    if (save == true) {
      final payload = {
        'school': schoolCtrl.text,
        'degree': degreeCtrl.text,
        'start_year': startYearCtrl.text,
        'end_year': endYearCtrl.text,
      };
      print("SENDING CV DATA: $payload");
      
      setState(() => _isLoading = true);
      try {
        final dio = await ApiService.authenticated();
        String path = type.toLowerCase();
        if (path == 'education') {
          await dio.post('/cv/education', data: payload);
        } else if (path == 'experience') {
          await dio.post('/cv/experience', data: {
            'company': schoolCtrl.text,
            'position': degreeCtrl.text,
            'start_year': startYearCtrl.text,
            'end_year': endYearCtrl.text,
          });
        } else {
           await dio.post('/cv/project', data: {
            'name': schoolCtrl.text,
            'link': degreeCtrl.text,
          });
        }
        print("CV DATA SAVED SUCCESSFULLY");
        await _fetchProfile(); // MUST refresh profile
      } catch (e) {
        print("ERROR SAVING CV DATA: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${ApiService.errorMessage(e)}")));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_profile == null) return const Center(child: Text("Profile not found. Please upload a CV first."));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Education", () => _addSection("Education")),
          // UI Verification: Displaying length of educations
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text("DEBUG: Educations count = ${(_profile['educations'] as List?)?.length ?? 0}", style: const TextStyle(fontSize: 10, color: Colors.blueAccent)),
          ),
          _buildList(_profile['educations'] ?? [], (item) => "${item['school'] ?? 'N/A'} - ${item['degree'] ?? 'N/A'}\n${item['start_year'] ?? ''} - ${item['end_year'] ?? ''}"),
          const SizedBox(height: 32),
          
          _buildSectionHeader("Experience", () => _addSection("Experience")),
          _buildList(_profile['experiences'] ?? [], (item) => "${item['position']} at ${item['company']}\n${item['start_year']} - ${item['end_year']}"),
          const SizedBox(height: 32),
          
          _buildSectionHeader("Projects", () => _addSection("Project")),
          _buildList(_profile['projects'] ?? [], (item) => "${item['name']}\n${item['description'] ?? 'No description'}"),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onAdd) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          ElevatedButton.icon(
             icon: const Icon(Icons.add, size: 18),
             label: const Text("Add"),
             style: ElevatedButton.styleFrom(
               backgroundColor: Colors.blueAccent.withOpacity(0.1),
               foregroundColor: Colors.blueAccent,
               padding: const EdgeInsets.symmetric(horizontal: 16),
             ),
             onPressed: () {
               print("DEBUG: Verified Click on Add $title");
               onAdd();
             },
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<dynamic> items, String Function(dynamic) formatter) {
    if (items.isEmpty) return const Text("No entries.", style: TextStyle(color: Colors.white24));
    return Column(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ShadCard(
          child: ListTile(
            title: Text(formatter(item)),
          ),
        ),
      )).toList(),
    );
  }
}

class _ImproveCvDialog extends StatefulWidget {
  final String cvText;
  const _ImproveCvDialog({required this.cvText});

  @override
  State<_ImproveCvDialog> createState() => _ImproveCvDialogState();
}

class _ImproveCvDialogState extends State<_ImproveCvDialog> {
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
    final theme = ShadTheme.of(context);
    return Dialog(
      backgroundColor: theme.colorScheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.sparkles, color: Colors.purpleAccent, size: 28),
                const SizedBox(width: 12),
                Text("AI CV Optimizer", style: theme.textTheme.h3.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                ShadButton.ghost(
                  width: 32, height: 32, padding: EdgeInsets.zero,
                  leading: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text("Actionable tips to increase your match score based on industry standards.", style: theme.textTheme.muted),
            const SizedBox(height: 24),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? _buildShimmer()
                  : _error.isNotEmpty
                      ? Center(child: Text(_error, style: const TextStyle(color: Colors.redAccent)))
                      : _suggestions.isEmpty
                          ? const Center(child: Text("Your CV looks excellent! No immediate improvements found."))
                          : ListView.builder(
                              itemCount: _suggestions.length,
                              itemBuilder: (context, i) => _buildSuggestionCard(_suggestions[i], theme),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(String text, ShadThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShadCard(
        backgroundColor: Colors.purple.withOpacity(0.05),
        padding: const EdgeInsets.all(16),
        radius: const BorderRadius.all(Radius.circular(16)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(LucideIcons.circleCheck, color: Colors.greenAccent, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      itemCount: 4,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
