import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _adminService = AdminService();
  int _selectedTab = 0;

  // Stats
  Map<String, dynamic> _stats = {};
  bool _loadingStats = true;

  // Users
  List<dynamic> _users = [];
  bool _loadingUsers = true;
  String _userRoleFilter = 'all';
  String _userSearch = '';
  int _userPage = 1;
  int _userTotal = 0;

  // Jobs
  List<dynamic> _jobs = [];
  bool _loadingJobs = true;
  String _jobSearch = '';
  int _jobPage = 1;
  int _jobTotal = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchUsers();
    _fetchJobs();
  }

  Future<void> _fetchStats() async {
    try {
      final data = await _adminService.getStats();
      if (mounted) setState(() { _stats = data; _loadingStats = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _fetchUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final data = await _adminService.getUsers(
        page: _userPage,
        role: _userRoleFilter,
        query: _userSearch.isNotEmpty ? _userSearch : null,
      );
      if (mounted) {
        setState(() {
          _users = data['items'] as List<dynamic>? ?? [];
          _userTotal = data['total'] as int? ?? 0;
          _loadingUsers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _fetchJobs() async {
    setState(() => _loadingJobs = true);
    try {
      final data = await _adminService.getJobs(
        page: _jobPage,
        query: _jobSearch.isNotEmpty ? _jobSearch : null,
      );
      if (mounted) {
        setState(() {
          _jobs = data['items'] as List<dynamic>? ?? [];
          _jobTotal = data['total'] as int? ?? 0;
          _loadingJobs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingJobs = false);
    }
  }

  Future<void> _deleteUser(int userId, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Delete'),
        content: Text('Delete user "$email"?\nThis action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _adminService.deleteUser(userId);
        _fetchStats();
        _fetchUsers();
        if (mounted) {
          ShadToaster.of(context).show(ShadToast(
            title: const Text('User Deleted'),
            description: Text('$email has been removed.'),
          ));
        }
      } catch (e) {
        if (mounted) {
          ShadToaster.of(context).show(ShadToast.destructive(
            title: const Text('Error'),
            description: Text(e.toString()),
          ));
        }
      }
    }
  }

  Future<void> _deleteJob(int jobId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Delete'),
        content: Text('Delete job "$title"?\nAll applications will also be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _adminService.deleteJob(jobId);
        _fetchStats();
        _fetchJobs();
        if (mounted) {
          ShadToaster.of(context).show(ShadToast(
            title: const Text('Job Deleted'),
            description: Text('"$title" has been removed.'),
          ));
        }
      } catch (e) {
        if (mounted) {
          ShadToaster.of(context).show(ShadToast.destructive(
            title: const Text('Error'),
            description: Text(e.toString()),
          ));
        }
      }
    }
  }

  void _onLogout() {
    final auth = Provider.of<AuthService>(context, listen: false);
    auth.logout();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: IndexedStack(
                    index: _selectedTab,
                    children: [
                      _buildOverviewTab(),
                      _buildUsersTab(),
                      _buildJobsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sidebar ──────────────────────────────────────────────────────────────
  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.shield, color: Colors.amber, size: 28),
              const SizedBox(width: 10),
              Text(
                'Admin Panel',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          _sidebarItem(0, LucideIcons.layoutDashboard, 'Dashboard'),
          _sidebarItem(1, LucideIcons.users, 'Users'),
          _sidebarItem(2, LucideIcons.briefcase, 'Jobs'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _onLogout,
                icon: const Icon(LucideIcons.logOut, color: Colors.redAccent, size: 18),
                label: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, String label) {
    final selected = _selectedTab == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: selected ? Colors.white.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedTab = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: selected ? Colors.amber : Colors.white54, size: 20),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white60,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    final titles = ['Dashboard Overview', 'User Management', 'Job Management'];
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Text(
            titles[_selectedTab],
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.shield, size: 16, color: Colors.amber),
                const SizedBox(width: 6),
                Text('Administrator', style: TextStyle(color: Colors.amber[800], fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Overview Tab ─────────────────────────────────────────────────────────
  Widget _buildOverviewTab() {
    if (_loadingStats) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Platform Statistics', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _statCard('Total Users', _stats['total_users'] ?? 0, LucideIcons.users, const Color(0xFF6366F1)),
              _statCard('Candidates', _stats['total_candidates'] ?? 0, LucideIcons.userCheck, const Color(0xFF06B6D4)),
              _statCard('Recruiters', _stats['total_recruiters'] ?? 0, LucideIcons.building, const Color(0xFFF59E0B)),
              _statCard('Jobs', _stats['total_jobs'] ?? 0, LucideIcons.briefcase, const Color(0xFF10B981)),
              _statCard('Applications', _stats['total_applications'] ?? 0, LucideIcons.fileText, const Color(0xFFEF4444)),
              _statCard('Companies', _stats['total_companies'] ?? 0, LucideIcons.building2, const Color(0xFF8B5CF6)),
            ],
          ),
          const SizedBox(height: 48),
          Text('Quick Actions', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              _quickAction('Manage Users', LucideIcons.users, () => setState(() => _selectedTab = 1)),
              const SizedBox(width: 16),
              _quickAction('Manage Jobs', LucideIcons.briefcase, () => setState(() => _selectedTab = 2)),
              const SizedBox(width: 16),
              _quickAction('Refresh Data', LucideIcons.refreshCcw, () {
                _fetchStats();
                _fetchUsers();
                _fetchJobs();
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, int value, IconData icon, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text('$value', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _quickAction(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ── Users Tab ────────────────────────────────────────────────────────────
  Widget _buildUsersTab() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Filters
          Row(
            children: [
              // Search
              SizedBox(
                width: 320,
                child: ShadInput(
                  placeholder: const Text('Search by email or name...'),
                  leading: const Padding(padding: EdgeInsets.only(right: 8), child: Icon(LucideIcons.search, size: 16, color: AppColors.textPlaceholder)),
                  onChanged: (v) {
                    _userSearch = v;
                    _userPage = 1;
                    _fetchUsers();
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Role Filter
              ...['all', 'candidate', 'recruiter', 'admin'].map((role) {
                final selected = _userRoleFilter == role;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(role == 'all' ? 'All' : role[0].toUpperCase() + role.substring(1)),
                    selected: selected,
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    onSelected: (_) {
                      setState(() { _userRoleFilter = role; _userPage = 1; });
                      _fetchUsers();
                    },
                  ),
                );
              }),
              const Spacer(),
              Text('$_userTotal users', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 20),
          // Table
          Expanded(
            child: _loadingUsers
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                ? const Center(child: Text('No users found.'))
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('CV', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _users.map<DataRow>((u) {
                            return DataRow(cells: [
                              DataCell(Text('#${u['id']}')),
                              DataCell(Text(u['full_name'] ?? 'N/A')),
                              DataCell(Text(u['email'] ?? '')),
                              DataCell(_roleBadge(u['role'] ?? '')),
                              DataCell(Icon(
                                u['has_cv'] == true ? LucideIcons.circleCheck : LucideIcons.circleX,
                                size: 18,
                                color: u['has_cv'] == true ? Colors.green : Colors.grey,
                              )),
                              DataCell(
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent),
                                  tooltip: 'Delete user',
                                  onPressed: () => _deleteUser(u['id'], u['email']),
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _roleBadge(String role) {
    Color color;
    switch (role) {
      case 'admin':
        color = Colors.amber;
        break;
      case 'recruiter':
      case 'employer':
        color = Colors.blue;
        break;
      default:
        color = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.5),
      ),
    );
  }

  // ── Jobs Tab ─────────────────────────────────────────────────────────────
  Widget _buildJobsTab() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 320,
                child: ShadInput(
                  placeholder: const Text('Search jobs by title or company...'),
                  leading: const Padding(padding: EdgeInsets.only(right: 8), child: Icon(LucideIcons.search, size: 16, color: AppColors.textPlaceholder)),
                  onChanged: (v) {
                    _jobSearch = v;
                    _jobPage = 1;
                    _fetchJobs();
                  },
                ),
              ),
              const Spacer(),
              Text('$_jobTotal jobs', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _loadingJobs
              ? const Center(child: CircularProgressIndicator())
              : _jobs.isEmpty
                ? const Center(child: Text('No jobs found.'))
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SingleChildScrollView(
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                          columnSpacing: 20,
                          columns: const [
                            DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Company', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Location', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Applicants', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Posted by', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _jobs.map<DataRow>((j) {
                            return DataRow(cells: [
                              DataCell(Text('#${j['id']}')),
                              DataCell(SizedBox(width: 180, child: Text(j['title'] ?? '', overflow: TextOverflow.ellipsis))),
                              DataCell(Text(j['company'] ?? '')),
                              DataCell(Text(j['location'] ?? '')),
                              DataCell(_jobTypeBadge(j['job_type'] ?? '')),
                              DataCell(Text('${j['applicants'] ?? 0}')),
                              DataCell(SizedBox(width: 140, child: Text(j['employer_email'] ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))),
                              DataCell(
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent),
                                  tooltip: 'Delete job',
                                  onPressed: () => _deleteJob(j['id'], j['title']),
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _jobTypeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(type, style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
