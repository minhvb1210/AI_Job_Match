import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../services/company_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

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
    try {
      final res = await _companyService.getCompanies();
      setState(() {
        _companies = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _companies = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_companies.isEmpty) return const Center(child: Text("No companies listed yet."));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        childAspectRatio: 1.5,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: _companies.length,
      itemBuilder: (context, index) {
        final comp = _companies[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () {
                // showDialog(context: context, builder: (_) => CompanyDetailDialog(companyId: comp['id'], companyData: comp));
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.building, size: 40, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      comp['name'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      comp['location'] ?? 'Multiple locations',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
