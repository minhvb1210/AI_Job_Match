import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../services/company_service.dart';
import '../../theme/app_colors.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  final _companyService = CompanyService();
  List<dynamic> _companies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    setState(() => _isLoading = true);
    try {
      final companies = await _companyService.getCompanies();
      if (mounted) {
        setState(() {
          _companies = companies;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Discover Companies",
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Learn more about the best places to work and their open roles.",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Skeletonizer(
                    enabled: true,
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: 6,
                      itemBuilder: (context, index) => _buildSkeletonCard(),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 2,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _companies.length,
                    itemBuilder: (context, index) {
                      final company = _companies[index];
                      return _buildCompanyCard(company);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(dynamic company) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(LucideIcons.building, color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            company['name'] ?? 'Company Name',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            company['industry'] ?? 'Technology',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Text(
            company['description'] ?? 'No description available.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.briefcase, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                "${company['jobs_count'] ?? 0} open jobs",
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ShadButton.outline(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Container(
                    width: 500,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(LucideIcons.building, color: AppColors.primary, size: 50),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          company['name'] ?? 'Company Name',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            company['industry'] ?? 'Technology',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text("About Company", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          company['description'] ?? 'No description available.',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.6),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(LucideIcons.briefcase, color: AppColors.textSecondary, size: 18),
                                const SizedBox(width: 8),
                                Text("${company['jobs_count'] ?? 0} open jobs", style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            ShadButton(
                              onPressed: () {
                                Navigator.pop(context);
                                context.read<JobProvider>().updateFilters(query: company['name']);
                                context.go('/jobs');
                              },
                              child: const Text("View Jobs"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            width: double.infinity,
            child: const Text("View Profile"),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
    );
  }
}
