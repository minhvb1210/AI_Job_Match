import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/company_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

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
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.isEmpty) {
      ShadToaster.of(context).show(const ShadToast.destructive(title: Text("Error"), description: Text("Company name is required.")));
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
      } else {
        await _companyService.createMyCompany(payload);
      }

      ShadToaster.of(context).show(const ShadToast(title: Text("Success"), description: Text("Profile updated successfully.")));
      setState(() => _exists = true);
    } catch (e) {
      ShadToaster.of(context).show(ShadToast.destructive(title: Text("Error"), description: Text(ApiService.errorMessage(e))));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Company Profile",
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text("Manage your brand appearance on the platform.", style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildField("Company Name", _nameCtrl, LucideIcons.building),
                    const SizedBox(height: 24),
                    _buildField("Website", _websiteCtrl, LucideIcons.globe),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _buildField("Location", _locationCtrl, LucideIcons.mapPin)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildField("Company Size", _sizeCtrl, LucideIcons.users)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildField("About the Company", _descCtrl, LucideIcons.fileText, maxLines: 5),
                    const SizedBox(height: 40),
                    ShadButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      size: ShadButtonSize.lg,
                      child: _isSaving 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("Save Profile Settings"),
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

  Widget _buildField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        ShadInput(
          controller: controller,
          maxLines: maxLines,
          leading: maxLines == 1 ? Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(icon, size: 18, color: AppColors.textPlaceholder),
          ) : null,
        ),
      ],
    );
  }
}
