import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../providers/resume_provider.dart';
import '../../../models/resume_data.dart';
import '../../../theme/app_colors.dart';

class CvForm extends StatelessWidget {
  const CvForm({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Template & Style", LucideIcons.palette),
          const _StyleSettings(),
          const SizedBox(height: 40),
          
          _buildSectionHeader("Personal Information", LucideIcons.user),
          const _PersonalInformationForm(),
          const SizedBox(height: 40),
          
          _buildSectionHeader("Career Objective", LucideIcons.target),
          const _ObjectiveForm(),
          const SizedBox(height: 40),
          
          _buildSectionHeader("Work Experience", LucideIcons.briefcase),
          const _ExperienceForm(),
          const SizedBox(height: 40),
          
          _buildSectionHeader("Education", LucideIcons.graduationCap),
          const _EducationForm(),
          const SizedBox(height: 40),
          
          _buildSectionHeader("Skills", LucideIcons.star),
          const _SkillsForm(),
          const SizedBox(height: 40),

          _buildSectionHeader("Projects", LucideIcons.folder),
          const _ProjectsForm(),
          const SizedBox(height: 40),

          _buildSectionHeader("Certificates", LucideIcons.award),
          const _CertificatesForm(),
          const SizedBox(height: 40),

          _buildSectionHeader("Languages", LucideIcons.languages),
          const _LanguagesForm(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StyleSettings extends StatelessWidget {
  const _StyleSettings();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResumeProvider>();
    return Column(
      children: [
        _buildField("Template", ShadSelect<String>(
          initialValue: provider.data.templateId,
          options: const [
            ShadOption(value: 'modern', child: Text('Modern')),
            ShadOption(value: 'professional', child: Text('Professional')),
            ShadOption(value: 'creative', child: Text('Creative')),
          ],
          selectedOptionBuilder: (context, value) => Text(value),
          onChanged: (v) => provider.setTemplate(v!),
        )),
        const SizedBox(height: 16),
        _buildField("Font Family", ShadSelect<String>(
          initialValue: provider.data.fontFamily,
          options: const [
            ShadOption(value: 'Inter', child: Text('Inter (Modern)')),
            ShadOption(value: 'Roboto', child: Text('Roboto (Professional)')),
            ShadOption(value: 'Montserrat', child: Text('Montserrat (Creative)')),
          ],
          selectedOptionBuilder: (context, value) => Text(value),
          onChanged: (v) => provider.setFont(v!),
        )),
        const SizedBox(height: 16),
        _buildField("Accent Color", Row(
          children: [
            _colorDot(provider, "#3B82F6"),
            _colorDot(provider, "#10B981"),
            _colorDot(provider, "#F59E0B"),
            _colorDot(provider, "#EF4444"),
            _colorDot(provider, "#8B5CF6"),
            _colorDot(provider, "#000000"),
          ],
        )),
      ],
    );
  }

  Widget _colorDot(ResumeProvider provider, String hex) {
    bool isSelected = provider.data.accentColor == hex;
    return GestureDetector(
      onTap: () => provider.setAccentColor(hex),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Color(int.parse(hex.replaceAll('#', '0xff'))),
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: isSelected ? [BoxShadow(color: Colors.black26, blurRadius: 4)] : null,
        ),
      ),
    );
  }
}

class _PersonalInformationForm extends StatelessWidget {
  const _PersonalInformationForm();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResumeProvider>();
    final data = provider.data;

    return Column(
      children: [
        _buildField("Full Name", ShadInput(
          initialValue: data.fullName,
          onChanged: (v) => provider.updatePersonalInfo(fullName: v),
        )),
        const SizedBox(height: 16),
        _buildField("Job Title", ShadInput(
          initialValue: data.jobTitle,
          onChanged: (v) => provider.updatePersonalInfo(jobTitle: v),
        )),
        const SizedBox(height: 16),
        _buildField("Avatar URL", ShadInput(
          initialValue: data.avatarUrl,
          onChanged: (v) => provider.updatePersonalInfo(avatarUrl: v),
          placeholder: const Text("https://example.com/avatar.jpg"),
        )),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildField("Email", ShadInput(
              initialValue: data.email,
              onChanged: (v) => provider.updatePersonalInfo(email: v),
            ))),
            const SizedBox(width: 16),
            Expanded(child: _buildField("Phone", ShadInput(
              initialValue: data.phone,
              onChanged: (v) => provider.updatePersonalInfo(phone: v),
            ))),
          ],
        ),
        const SizedBox(height: 16),
        _buildField("Address", ShadInput(
          initialValue: data.address,
          onChanged: (v) => provider.updatePersonalInfo(address: v),
        )),
      ],
    );
  }
}

class _ObjectiveForm extends StatelessWidget {
  const _ObjectiveForm();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResumeProvider>();
    return ShadInput(
      initialValue: provider.data.objective,
      maxLines: 4,
      onChanged: (v) => provider.updatePersonalInfo(objective: v),
    );
  }
}

class _ExperienceForm extends StatelessWidget {
  const _ExperienceForm();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResumeProvider>();
    return Column(
      children: [
        ...List.generate(provider.data.experience.length, (index) {
          final exp = provider.data.experience[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Role ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, color: AppColors.error, size: 18),
                      onPressed: () => provider.removeExperience(index),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField("Company", ShadInput(
                  initialValue: exp.company,
                  onChanged: (v) => provider.updateExperience(index, exp..company = v),
                )),
                const SizedBox(height: 16),
                _buildField("Position", ShadInput(
                  initialValue: exp.position,
                  onChanged: (v) => provider.updateExperience(index, exp..position = v),
                )),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildField("Start Year", ShadInput(
                      initialValue: exp.startYear,
                      onChanged: (v) => provider.updateExperience(index, exp..startYear = v),
                    ))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildField("End Year", ShadInput(
                      initialValue: exp.endYear,
                      onChanged: (v) => provider.updateExperience(index, exp..endYear = v),
                    ))),
                  ],
                ),
              ],
            ),
          );
        }),
        ShadButton.outline(
          onPressed: () => provider.addExperience(ResumeExperience()),
          leading: const Icon(LucideIcons.plus, size: 16),
          child: const Text("Add Experience"),
        ),
      ],
    );
  }
}

class _EducationForm extends StatelessWidget {
  const _EducationForm();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResumeProvider>();
    return Column(
      children: [
        ...List.generate(provider.data.education.length, (index) {
          final edu = provider.data.education[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Education ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, color: AppColors.error, size: 18),
                      onPressed: () => provider.removeEducation(index),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField("School", ShadInput(
                  initialValue: edu.school,
                  onChanged: (v) => provider.updateEducation(index, edu..school = v),
                )),
                const SizedBox(height: 16),
                _buildField("Degree", ShadInput(
                  initialValue: edu.degree,
                  onChanged: (v) => provider.updateEducation(index, edu..degree = v),
                )),
              ],
            ),
          );
        }),
        ShadButton.outline(
          onPressed: () => provider.addEducation(ResumeEducation()),
          leading: const Icon(LucideIcons.plus, size: 16),
          child: const Text("Add Education"),
        ),
      ],
    );
  }
}

class _SkillsForm extends StatelessWidget {
  const _SkillsForm();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResumeProvider>();
    return ShadInput(
      initialValue: provider.data.skills.join(", "),
      placeholder: const Text("e.g. Flutter, Dart, Python (separated by comma)"),
      onChanged: (v) => provider.updateSkills(v.split(",").map((e) => e.trim()).where((e) => e.isNotEmpty).toList()),
    );
  }
}

class _ProjectsForm extends StatelessWidget {
  const _ProjectsForm();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResumeProvider>();
    return Column(
      children: [
        ...List.generate(provider.data.projects.length, (index) {
          final proj = provider.data.projects[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Project ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, color: AppColors.error, size: 18),
                      onPressed: () => provider.removeProject(index),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField("Project Name", ShadInput(
                  initialValue: proj.name,
                  onChanged: (v) => provider.updateProject(index, proj..name = v),
                )),
                const SizedBox(height: 16),
                _buildField("Description", ShadInput(
                  initialValue: proj.description,
                  onChanged: (v) => provider.updateProject(index, proj..description = v),
                )),
              ],
            ),
          );
        }),
        ShadButton.outline(
          onPressed: () => provider.addProject(ResumeProject()),
          leading: const Icon(LucideIcons.plus, size: 16),
          child: const Text("Add Project"),
        ),
      ],
    );
  }
}

class _CertificatesForm extends StatelessWidget {
  const _CertificatesForm();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResumeProvider>();
    return ShadInput(
      initialValue: provider.data.certificates.join(", "),
      placeholder: const Text("e.g. AWS Solutions Architect, Google Cloud Professional (comma separated)"),
      onChanged: (v) => provider.updateCertificates(v.split(",").map((e) => e.trim()).where((e) => e.isNotEmpty).toList()),
    );
  }
}

class _LanguagesForm extends StatelessWidget {
  const _LanguagesForm();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResumeProvider>();
    return ShadInput(
      initialValue: provider.data.languages.join(", "),
      placeholder: const Text("e.g. English (Fluent), Vietnamese (Native)"),
      onChanged: (v) => provider.updateLanguages(v.split(",").map((e) => e.trim()).where((e) => e.isNotEmpty).toList()),
    );
  }
}

Widget _buildField(String label, Widget child) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
      const SizedBox(height: 8),
      child,
    ],
  );
}
