import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/job_service.dart';
import '../services/application_service.dart';
import '../services/company_service.dart';
import '../services/api_service.dart';
import '../services/dashboard_service.dart';

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
      final jobs = await _jobService.getAllJobs();
      setState(() {
        _jobs = jobs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showApplicantsDialog(int jobId, String jobTitle) {
    // Navigate to the dedicated full-screen applicants view (AI-sorted)
    context.push('/applicants/$jobId', extra: jobTitle);
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
    try {
      await _jobService.deleteJob(jobId);
      ShadToaster.of(context).show(const ShadToast(title: Text("Job Deleted"), description: Text("Successfully removed the job posting.")));
      _fetchJobs();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final theme = ShadTheme.of(context);
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text('Employer Command Center', style: theme.textTheme.h3.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
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
                  _buildTabButton("💼 Job Management", "jobs"),
                  _buildTabButton("📊 Command Center", "dashboard"),
                  _buildTabButton("🏢 Brand Profile", "profile"),
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
      floatingActionButton: ShadButton(
        onPressed: () => context.go('/create-job'),
        leading: const Icon(LucideIcons.plus, size: 18),
        child: const Text("Post a New Job"),
      ),
      ),
    );
  }

  Widget _buildTabButton(String label, String value) {
    bool isSelected = _selectedTab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = value),
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
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(ShadThemeData theme) {
    switch (_selectedTab) {
      case 'jobs': return _buildJobsTab(theme);
      case 'dashboard': return const DashboardTab();
      case 'profile': return const CompanyProfileTab();
      default: return _buildJobsTab(theme);
    }
  }

  Widget _buildJobsTab(ShadThemeData theme) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    if (_jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.fileText, size: 80, color: theme.colorScheme.primary.withOpacity(0.2)),
            const SizedBox(height: 24),
            Text("No active job postings found.", style: theme.textTheme.muted),
            const SizedBox(height: 16),
            ShadButton.outline(
              onPressed: () => context.go('/create-job'),
              child: const Text("Create your first listing"),
            )
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16),
      itemCount: _jobs.length,
      itemBuilder: (context, index) {
        final job = _jobs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ShadCard(
            padding: const EdgeInsets.all(24),
            radius: const BorderRadius.all(Radius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job['title'] ?? 'Untitled', style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(job['company'] ?? 'Unknown Company', style: theme.textTheme.muted),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.withOpacity(0.2))),
                      child: const Text('Live', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildIconLabel(LucideIcons.mapPin, job['location'] ?? 'Remote'),
                    const SizedBox(width: 24),
                    _buildIconLabel(LucideIcons.banknote, job['salary'] ?? 'Negotiable'),
                    const SizedBox(width: 24),
                    _buildIconLabel(LucideIcons.users, "Applicants: 0"), // TODO: count apps properly
                    const Spacer(),
                    ShadButton.ghost(
                      width: 36, height: 36, padding: EdgeInsets.zero,
                      leading: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18),
                      onPressed: () => _deleteJob(job['id']),
                    ),
                    const SizedBox(width: 8),
                    ShadButton.outline(
                      leading: const Icon(LucideIcons.sparkles, color: Colors.purpleAccent, size: 16),
                      onPressed: () => _showAiSuggestionsDialog(job['id'], job['title']),
                      child: const Text("AI Sourcing"),
                    ),
                    const SizedBox(width: 12),
                    ShadButton(
                      onPressed: () => _showApplicantsDialog(job['id'], job['title']),
                      leading: const Icon(LucideIcons.users, size: 16),
                      child: const Text("Review Applicants"),
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white30),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
      ],
    );
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
       backgroundColor: theme.colorScheme.card,
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
                 ShadButton.ghost(
                    width: 32, height: 32, padding: EdgeInsets.zero,
                    leading: const Icon(LucideIcons.x, size: 20), 
                    onPressed: () => Navigator.pop(context)
                 )
               ],
             ),
             const SizedBox(height: 8),
             Text("Our AI has scanned all candidate profiles to find the best matches for your role.", style: theme.textTheme.muted),
             const SizedBox(height: 24),
             const Divider(color: Colors.white10),
             const SizedBox(height: 16),
             Expanded(
               child: _isLoading 
                 ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                 : _suggestions.isEmpty 
                   ? const Center(child: Text("No candidates currently match this role strictly. Try expanding your requirements."))
                   : ListView.builder(
                       itemCount: _suggestions.length,
                       itemBuilder: (context, index) {
                         var sugg = _suggestions[index];
                         return Padding(
                           padding: const EdgeInsets.only(bottom: 16),
                           child: ShadCard(
                             backgroundColor: Colors.purple.withOpacity(0.05),
                             padding: const EdgeInsets.all(20),
                             border: ShadBorder.all(color: Colors.purple.withOpacity(0.2)),
                             radius: const BorderRadius.all(Radius.circular(16)),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Row(
                                   children: [
                                     Icon(LucideIcons.user, color: theme.colorScheme.primary),
                                     const SizedBox(width: 12),
                                     Text(sugg['candidate_email'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                     const Spacer(),
                                     Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.purpleAccent.withOpacity(0.3))),
                                        child: Text("${sugg['score'].toStringAsFixed(1)}% Match", style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                     )
                                   ],
                                 ),
                                 const SizedBox(height: 16),
                                 const Text("Match Intelligence Preview:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white54)),
                                 const SizedBox(height: 8),
                                 Container(
                                   width: double.infinity,
                                   padding: const EdgeInsets.all(12),
                                   decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                                   child: Text(sugg['matched_skills_text'], style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4)),
                                 ),
                                 const SizedBox(height: 16),
                                 Align(
                                    alignment: Alignment.centerRight,
                                    child: ShadButton(
                                       onPressed: () {
                                          ShadToaster.of(context).show(const ShadToast(title: Text("Invitation Sent"), description: Text("Invitation sent to candidate's inbox!")));
                                       },
                                       leading: const Icon(LucideIcons.mail, size: 16),
                                       child: const Text("Invite to Apply"),
                                    )
                                 )
                               ],
                             ),
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

class JobApplicantsDialog extends StatefulWidget {
  final int jobId;
  final String jobTitle;
  const JobApplicantsDialog({super.key, required this.jobId, required this.jobTitle});

  @override
  State<JobApplicantsDialog> createState() => _JobApplicantsDialogState();
}

class _JobApplicantsDialogState extends State<JobApplicantsDialog> {
  bool _isLoading = true;
  List<dynamic> _applicants = [];
  String _filterKeyword = '';
  final _appService = ApplicationService();

  @override
  void initState() {
    super.initState();
    _fetchApplicants();
  }

  Future<void> _fetchApplicants() async {
    try {
      final items = await _appService.getJobApplicants(jobId: widget.jobId);
      setState(() {
        _applicants = items.map((a) => {
          'id': a.id,
          'status': a.status,
          'match_score': a.matchScore,
          'candidate_email': a.candidateEmail,
          'candidate_skills': a.candidateSkills,
        }).toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int applicationId, String status) async {
    try {
      await _appService.updateStatus(applicationId: applicationId, status: status);
      _fetchApplicants();
      ShadToaster.of(context).show(ShadToast(title: Text("Status Updated"), description: Text("Applicant is now marked as $status.")));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Dialog(
       backgroundColor: theme.colorScheme.card,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
       child: Container(
         width: 750,
         height: 700,
         padding: const EdgeInsets.all(32),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Expanded(child: Text("Applications for ${widget.jobTitle}", style: theme.textTheme.h3.copyWith(fontWeight: FontWeight.bold))),
                 ShadButton.ghost(
                    width: 32, height: 32, padding: EdgeInsets.zero,
                    leading: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.pop(context)
                 )
               ],
             ),
             const SizedBox(height: 24),
             ShadInput(
               onChanged: (val) => setState(() => _filterKeyword = val.toLowerCase()),
               placeholder: const Text("Filter by keyword, skill or status..."),
               leading: const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(LucideIcons.search, size: 18, color: Colors.white30),
               ),
             ),
             const SizedBox(height: 24),
             Expanded(
               child: _isLoading 
                 ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                 : _applicants.isEmpty 
                   ? const Center(child: Text("No submissions for this position yet."))
                   : ListView.builder(
                       itemCount: _applicants.length,
                       itemBuilder: (context, index) {
                         var app = _applicants[index];
                         bool matchesSearch = app['candidate_skills'].toString().toLowerCase().contains(_filterKeyword) || app['status'].toString().toLowerCase().contains(_filterKeyword);
                         if (!matchesSearch) return const SizedBox.shrink();
                         
                         return Padding(
                           padding: const EdgeInsets.only(bottom: 16),
                           child: ShadCard(
                             backgroundColor: Colors.black.withOpacity(0.1),
                             padding: const EdgeInsets.all(20),
                             radius: const BorderRadius.all(Radius.circular(16)),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Row(
                                   children: [
                                     Icon(LucideIcons.user, color: theme.colorScheme.primary),
                                     const SizedBox(width: 8),
                                     Text(app['candidate_email'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                     const Spacer(),
                                     Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: (app['match_score'] > 15 ? Colors.green : Colors.orange).withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: (app['match_score'] > 15 ? Colors.green : Colors.orange).withOpacity(0.3))),
                                        child: Text("${app['match_score'].toStringAsFixed(1)}% Score", style: TextStyle(color: app['match_score'] > 15 ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                                     )
                                   ],
                                 ),
                                 const SizedBox(height: 12),
                                 Row(
                                   children: [
                                      const Text("Current Status: ", style: TextStyle(color: Colors.white30, fontSize: 12)),
                                      Text(app['status'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                   ],
                                 ),
                                 const SizedBox(height: 16),
                                 const Text("Candidate Profile Extraction:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white54)),
                                 const SizedBox(height: 6),
                                 Container(
                                   width: double.infinity,
                                   padding: const EdgeInsets.all(12),
                                   decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(12)),
                                   child: Text(app['candidate_skills'], style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.white70)),
                                 ),
                                 const SizedBox(height: 20),
                                 Row(
                                   mainAxisAlignment: MainAxisAlignment.end,
                                   children: [
                                     if (app['status'] == 'pending') ...[
                                       ShadButton.ghost(
                                         onPressed: () => _updateStatus(app['id'], 'rejected'),
                                         leading: const Icon(LucideIcons.userX, color: Colors.redAccent, size: 18),
                                         child: const Text("Decline", style: TextStyle(color: Colors.redAccent)),
                                       ),
                                       const SizedBox(width: 12),
                                       ShadButton(
                                         onPressed: () => _updateStatus(app['id'], 'accepted'),
                                         leading: const Icon(LucideIcons.userCheck, size: 18),
                                         child: const Text("Shortlist"),
                                       ),
                                     ] else ...[
                                        Text("Action Taken: ${app['status'].toUpperCase()}", style: theme.textTheme.small.copyWith(color: theme.colorScheme.primary)),
                                     ]
                                   ],
                                 )
                               ],
                             ),
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

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _titleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  
  String _selectedCategory = 'IT';
  String _selectedJobType = 'Full-time';
  String _selectedExperience = 'Middle';
  
  final List<String> _categories = ['IT', 'Marketing', 'Sales', 'Finance', 'Design', 'Other'];
  final List<String> _jobTypes = ['Full-time', 'Part-time', 'Remote', 'Internship'];
  final List<String> _experienceLevels = ['Intern', 'Fresher', 'Junior', 'Middle', 'Senior', 'Manager'];

  bool _isSubmitting = false;
  final _jobService = JobService();
  final _companyService = CompanyService();

  Future<void> _submitJob() async {
    if (_titleCtrl.text.isEmpty || _companyCtrl.text.isEmpty) {
       ShadToaster.of(context).show(const ShadToast.destructive(title: Text("Missing Data"), description: Text("Please fill in the job title and company name.")));
       return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      // 1. STRICT REAL CHECK: Ensure company exists
      final company = await _companyService.getMyCompany();
      if (company == null || company.isEmpty) {
        ShadToaster.of(context).show(const ShadToast.destructive(
          title: Text("Action Blocked"), 
          description: Text("Please create a company profile first.")
        ));
        setState(() => _isSubmitting = false);
        if (mounted) context.go('/recruiter'); // Redirect to dashboard where Brand Profile is
        return;
      }

      // 2. CREATE JOB
      await _jobService.createJob({
        'title': _titleCtrl.text,
        'company': _companyCtrl.text,
        'location': _locationCtrl.text,
        'salary': _salaryCtrl.text,
        'description': _descCtrl.text,
        'skills': _skillsCtrl.text,
        'category': _selectedCategory,
        'job_type': _selectedJobType,
        'experience_level': _selectedExperience,
      });

      ShadToaster.of(context).show(const ShadToast(title: Text("Position Published"), description: Text("Your job posting is now active on the platform.")));
      if (mounted) context.go('/recruiter');
    } catch (e) {
      ShadToaster.of(context).show(ShadToast.destructive(title: Text("Error"), description: Text(ApiService.errorMessage(e))));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text('Publish New Role', style: theme.textTheme.h3.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        leading: ShadButton.ghost(leading: const Icon(LucideIcons.arrowLeft, size: 20), onPressed: () => context.go('/recruiter')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Role Definition", style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Provide clear and concise details to reach the right candidates.", style: theme.textTheme.muted),
                const SizedBox(height: 32),
                
                ShadInput(
                  controller: _titleCtrl, 
                  placeholder: const Text("Job Title (e.g. Lead Product Designer)"),
                  leading: const Padding(padding: EdgeInsets.only(right: 8), child: Icon(LucideIcons.briefcase, size: 18)),
                ),
                const SizedBox(height: 20),
                
                ShadInput(
                  controller: _companyCtrl, 
                  placeholder: const Text("Hiring Entity / Company"),
                  leading: const Padding(padding: EdgeInsets.only(right: 8), child: Icon(LucideIcons.building, size: 18)),
                ),
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(child: ShadInput(
                      controller: _locationCtrl, 
                      placeholder: const Text("Location"),
                      leading: const Padding(padding: EdgeInsets.only(right: 8), child: Icon(LucideIcons.mapPin, size: 18)),
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: ShadInput(
                      controller: _salaryCtrl, 
                      placeholder: const Text("Salary Range"),
                      leading: const Padding(padding: EdgeInsets.only(right: 8), child: Icon(LucideIcons.banknote, size: 18)),
                    )),
                  ],
                ),
                const SizedBox(height: 20),
                
                ShadInput(
                  controller: _descCtrl, 
                  placeholder: const Text("Job Responsibilities & Detailed Requirements"),
                  maxLines: 5,
                ),
                const SizedBox(height: 20),
                
                ShadInput(
                  controller: _skillsCtrl, 
                  placeholder: const Text("Core Skills Required (e.g. Flutter, Dart, AI, Figma)"),
                  leading: const Padding(padding: EdgeInsets.only(right: 8), child: Icon(LucideIcons.asterisk, size: 18)),
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(child: _buildSelect('Category', _selectedCategory, _categories, (val) => setState(() => _selectedCategory = val!))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSelect('Job Type', _selectedJobType, _jobTypes, (val) => setState(() => _selectedJobType = val!))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSelect('Experience', _selectedExperience, _experienceLevels, (val) => setState(() => _selectedExperience = val!))),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                ShadButton(
                  width: double.infinity,
                  onPressed: _isSubmitting ? null : _submitJob,
                  child: _isSubmitting ? const CircularProgressIndicator(strokeWidth: 2) : const Text("Go Live with Position"),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelect(String label, String value, List<String> items, Function(String?) onChanged) {
    return ShadSelect<String>(
      placeholder: Text(label),
      initialValue: value,
      options: items.map((e) => ShadOption(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      selectedOptionBuilder: (context, value) => Text(value),
    );
  }
}

class CompanyProfileTab extends StatefulWidget {
  const CompanyProfileTab({super.key});

  @override
  State<CompanyProfileTab> createState() => _CompanyProfileTabState();
}

class _CompanyProfileTabState extends State<CompanyProfileTab> {
  final _nameCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _exists = false;
  final _companyService = CompanyService();

  @override
  void initState() {
    super.initState();
    _fetchCompanyProfile();
  }

  Future<void> _fetchCompanyProfile() async {
    try {
      final data = await _companyService.getMyCompany();
      if (data != null && data.isNotEmpty) {
        setState(() {
          _nameCtrl.text = data['name'] ?? '';
          _websiteCtrl.text = data['website'] ?? '';
          _locationCtrl.text = data['location'] ?? '';
          _sizeCtrl.text = data['size'] ?? '';
          _descCtrl.text = data['description'] ?? '';
          _exists = true;
        });
      } else {
        setState(() => _exists = false);
      }
    } catch (_) {
      setState(() => _exists = false);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveCompanyProfile() async {
    if (_nameCtrl.text.isEmpty) {
       ShadToaster.of(context).show(const ShadToast.destructive(title: Text("Incomplete Profile"), description: Text("Company name is required to build your brand.")));
       return;
    }
    
    setState(() => _isSaving = true);
    try {
      final payload = {
        'name': _nameCtrl.text,
        'website': _websiteCtrl.text,
        'location': _locationCtrl.text,
        'size': _sizeCtrl.text,
        'description': _descCtrl.text,
      };

      if (_exists) {
        await _companyService.updateMyCompany(payload);
        ShadToaster.of(context).show(const ShadToast(title: Text("Profile Updated"), description: Text("Your company profile has been updated successfully.")));
      } else {
        await _companyService.createMyCompany(payload);
        ShadToaster.of(context).show(const ShadToast(title: Text("Profile Created"), description: Text("Your brand profile is now live!")));
        setState(() => _exists = true);
      }
    } catch (e) {
      ShadToaster.of(context).show(ShadToast.destructive(title: Text("Error"), description: Text(ApiService.errorMessage(e))));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Widget _buildBrandingMeter(ShadThemeData theme) {
    int filled = 0;
    if (_nameCtrl.text.isNotEmpty) filled++;
    if (_websiteCtrl.text.isNotEmpty) filled++;
    if (_locationCtrl.text.isNotEmpty) filled++;
    if (_sizeCtrl.text.isNotEmpty) filled++;
    if (_descCtrl.text.isNotEmpty) filled++;
    
    double pct = filled / 5.0;
    Color meterColor = pct > 0.8 ? Colors.greenAccent : (pct > 0.4 ? Colors.orangeAccent : Colors.redAccent);
    String status = pct > 0.8 ? "Elite Brand" : (pct > 0.4 ? "Growing Presence" : "Incomplete Brand");

    return ShadCard(
      padding: const EdgeInsets.all(24),
      backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
      radius: const BorderRadius.all(Radius.circular(20)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: meterColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(LucideIcons.award, color: meterColor, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Branding Strength: $status", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("${(pct * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, color: meterColor)),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: pct,
                  backgroundColor: Colors.white10,
                  color: meterColor,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 8),
                Text("Complete your profile to increase trust with top-tier candidates.", style: theme.textTheme.small),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    final theme = ShadTheme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBrandingMeter(theme),
              const SizedBox(height: 32),
              Text("Company Profile Builder", style: theme.textTheme.h3.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Stand out to top talent by completing your employer profile and brand story.", style: theme.textTheme.muted),
              const SizedBox(height: 32),
              
              ShadInput(
                controller: _nameCtrl, 
                placeholder: const Text("Official Company Name"),
                leading: const Padding(padding: EdgeInsets.only(right: 8), child: Icon(LucideIcons.building, size: 18)),
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(child: ShadInput(
                    controller: _websiteCtrl, 
                    placeholder: const Text("Company Website (e.g. apple.com)"),
                    leading: const Padding(padding: EdgeInsets.only(right: 8), child: Icon(LucideIcons.globe, size: 18)),
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: ShadInput(
                    controller: _sizeCtrl, 
                    placeholder: const Text("Team Size (e.g. 100-500)"),
                    leading: const Padding(padding: EdgeInsets.only(right: 8), child: Icon(LucideIcons.users, size: 18)),
                  )),
                ],
              ),
              const SizedBox(height: 20),
              
              ShadInput(
                controller: _locationCtrl, 
                placeholder: const Text("Headquarters Address"),
                leading: const Padding(padding: EdgeInsets.only(right: 8), child: Icon(LucideIcons.mapPin, size: 18)),
              ),
              const SizedBox(height: 20),
              
              ShadInput(
                controller: _descCtrl, 
                placeholder: const Text("Tell us about your mission, culture, and team..."),
                maxLines: 8,
              ),
              
              const SizedBox(height: 36),
              Align(
                alignment: Alignment.centerRight,
                child: ShadButton(
                  onPressed: _isSaving ? null : _saveCompanyProfile, 
                  leading: _isSaving ? null : const Icon(LucideIcons.save, size: 18),
                  child: _isSaving ? const CircularProgressIndicator(strokeWidth: 2) : Text(_exists ? "Update Profile" : "Create Company Profile"),
                ),
              ),
              const SizedBox(height: 60),
            ]
          )
        )
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final provider = context.watch<DashboardProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (provider.errorMessage.isNotEmpty) {
      return Center(child: Text(provider.errorMessage, style: const TextStyle(color: Colors.redAccent)));
    }

    final stats = provider.stats;
    if (stats == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Recruitment Performance", style: theme.textTheme.h3.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          
          // Stats Grid
          GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(theme, "Active Jobs", stats['total_jobs'].toString(), LucideIcons.briefcase, Colors.blueAccent),
              _buildStatCard(theme, "Total Applicants", stats['total_applications'].toString(), LucideIcons.users, Colors.orangeAccent),
              _buildStatCard(theme, "Avg Match Score", "${stats['average_match_score']}%", LucideIcons.sparkles, Colors.purpleAccent),
              _buildStatCard(theme, "Placement Rate", "${stats['success_rate']}%", LucideIcons.circleCheck, Colors.greenAccent),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Strategic Insights
          Row(
            children: [
              const Icon(LucideIcons.lightbulb, color: Colors.amberAccent, size: 24),
              const SizedBox(width: 12),
              Text("Strategic Recruitment Insights", style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if (stats['top_candidate'] != null)
            ShadCard(
              padding: const EdgeInsets.all(24),
              backgroundColor: Colors.amberAccent.withOpacity(0.05),
              radius: const BorderRadius.all(Radius.circular(16)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.amberAccent.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(LucideIcons.trophy, color: Colors.amberAccent, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Top Match Found!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amberAccent)),
                        const SizedBox(height: 4),
                        Text("${stats['top_candidate']['email']} is a ${stats['top_candidate']['score']}% match for your ${stats['top_candidate']['job_title']} listing.", style: theme.textTheme.small),
                      ],
                    ),
                  ),
                  ShadButton.outline(
                    onPressed: () {
                       ShadToaster.of(context).show(const ShadToast(title: Text("Fast-Tracked"), description: Text("Opening top candidate profile...")));
                    },
                    child: const Text("View Profile"),
                  )
                ],
              ),
            )
          else
            ShadCard(
              padding: const EdgeInsets.all(20),
              child: Center(child: Text("Waiting for high-score candidates to apply...", style: theme.textTheme.muted)),
            ),
          
          const SizedBox(height: 32),
          
          // Industries Section
          Row(
            children: [
              const Icon(LucideIcons.chartPie, color: Colors.purpleAccent, size: 24),
              const SizedBox(width: 12),
              Text("Top Hiring Categories", style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ShadCard(
            padding: const EdgeInsets.all(24),
            radius: const BorderRadius.all(Radius.circular(16)),
            child: Column(
              children: (stats['top_industries'] as List).map((item) {
                final count = item['count'] as int;
                final total = stats['total_jobs'] as int;
                final pct = total > 0 ? count / total : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item['category'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("$count job${count > 1 ? 's' : ''}", style: theme.textTheme.muted),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.white10,
                        color: Colors.purpleAccent,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
          
          // Interviews Section
          Row(
            children: [
              const Icon(LucideIcons.calendar, color: Colors.blueAccent, size: 24),
              const SizedBox(width: 12),
              Text("Upcoming Interviews", style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if ((stats['upcoming_interviews'] as List).isEmpty)
             ShadCard(
               padding: const EdgeInsets.all(32),
               radius: const BorderRadius.all(Radius.circular(16)),
               child: Center(
                 child: Column(
                   children: [
                     Icon(LucideIcons.calendarX, size: 40, color: Colors.white10),
                     const SizedBox(height: 12),
                     Text("No interviews scheduled yet.", style: theme.textTheme.muted),
                   ],
                 ),
               ),
             )
          else
            Column(
              children: (stats['upcoming_interviews'] as List).map((iv) {
                final date = DateTime.tryParse(iv['scheduled_time'])?.toLocal() ?? DateTime.now();
                final dateStr = "${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ShadCard(
                    padding: const EdgeInsets.all(20),
                    radius: const BorderRadius.all(Radius.circular(16)),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(LucideIcons.video, color: Colors.blueAccent, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(iv['candidate_email'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text("Role: ${iv['job_title']}", style: theme.textTheme.muted.copyWith(fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(iv['location'], style: theme.textTheme.muted.copyWith(fontSize: 11)),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildStatCard(ShadThemeData theme, String label, String value, IconData icon, Color color) {
    return ShadCard(
      padding: const EdgeInsets.all(20),
      radius: const BorderRadius.all(Radius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: theme.textTheme.h2.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.muted),
        ],
      ),
    );
  }
}
