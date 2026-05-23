import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../providers/resume_provider.dart';
import '../../../models/resume_data.dart';
import '../../../theme/app_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CvPreview extends StatelessWidget {
  const CvPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final resumeProvider = context.watch<ResumeProvider>();
    final data = resumeProvider.data;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1 / 1.414,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _buildSelectedTemplate(data),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTemplate(ResumeData data) {
    final TextStyle Function({TextStyle? textStyle, Color? color, double? fontSize, FontWeight? fontWeight, double? letterSpacing, double? height}) fontMethod;
    
    switch (data.fontFamily) {
      case 'Roboto': fontMethod = GoogleFonts.roboto; break;
      case 'Montserrat': fontMethod = GoogleFonts.montserrat; break;
      case 'Inter':
      default: fontMethod = GoogleFonts.inter; break;
    }

    switch (data.templateId) {
      case 'professional':
        return _ProfessionalTemplate(data: data, fontMethod: fontMethod);
      case 'creative':
        return _CreativeTemplate(data: data, fontMethod: fontMethod);
      case 'modern':
      default:
        return _ModernTemplate(data: data, fontMethod: fontMethod);
    }
  }
}

class _ModernTemplate extends StatelessWidget {
  final ResumeData data;
  final TextStyle Function({TextStyle? textStyle, Color? color, double? fontSize, FontWeight? fontWeight, double? letterSpacing, double? height}) fontMethod;
  const _ModernTemplate({required this.data, required this.fontMethod});

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(int.parse(data.accentColor.replaceAll('#', '0xff')));
    
    return Column(
      children: [
        Container(
          height: 160,
          color: accentColor,
          padding: const EdgeInsets.all(32),
          child: Row(
            children: [
              if (data.avatarUrl.isNotEmpty)
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(image: NetworkImage(data.avatarUrl), fit: BoxFit.cover),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(data.fullName, style: fontMethod(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(data.jobTitle, style: fontMethod(fontSize: 16, color: Colors.white.withOpacity(0.9))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _headerInfoItem(LucideIcons.mail, data.email),
                  _headerInfoItem(LucideIcons.phone, data.phone),
                  _headerInfoItem(LucideIcons.mapPin, data.address),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle("PROFILE", accentColor, fontMethod),
                      Text(data.objective, style: fontMethod(fontSize: 10, height: 1.5)),
                      const SizedBox(height: 24),
                      _sectionTitle("WORK EXPERIENCE", accentColor, fontMethod),
                      ...data.experience.map((exp) => _ExperienceItem(exp: exp, fontMethod: fontMethod)),
                      const SizedBox(height: 24),
                      _sectionTitle("PROJECTS", accentColor, fontMethod),
                      ...data.projects.map((proj) => _ProjectItem(proj: proj, fontMethod: fontMethod)),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle("SKILLS", accentColor, fontMethod),
                      Wrap(spacing: 6, runSpacing: 6, children: data.skills.map((s) => _SkillBadge(label: s, color: accentColor, fontMethod: fontMethod)).toList()),
                      const SizedBox(height: 24),
                      _sectionTitle("EDUCATION", accentColor, fontMethod),
                      ...data.education.map((edu) => _EducationItem(edu: edu, fontMethod: fontMethod)),
                      const SizedBox(height: 24),
                      _sectionTitle("CERTIFICATES", accentColor, fontMethod),
                      ...data.certificates.map((c) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text("• $c", style: fontMethod(fontSize: 9)))),
                      const SizedBox(height: 24),
                      _sectionTitle("LANGUAGES", accentColor, fontMethod),
                      ...data.languages.map((l) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text("• $l", style: fontMethod(fontSize: 9, fontWeight: FontWeight.bold)))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 10)),
          const SizedBox(width: 8),
          Icon(icon, size: 12, color: Colors.white),
        ],
      ),
    );
  }
}

class _ProfessionalTemplate extends StatelessWidget {
  final ResumeData data;
  final TextStyle Function({TextStyle? textStyle, Color? color, double? fontSize, FontWeight? fontWeight, double? letterSpacing, double? height}) fontMethod;
  const _ProfessionalTemplate({required this.data, required this.fontMethod});

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(int.parse(data.accentColor.replaceAll('#', '0xff')));
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Text(data.fullName.toUpperCase(), style: fontMethod(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.textPrimary)),
                Text(data.jobTitle.toUpperCase(), style: fontMethod(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 3, color: accentColor)),
                const SizedBox(height: 12),
                Text("${data.email} • ${data.phone} • ${data.address}", style: fontMethod(fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(thickness: 1, color: Colors.black12),
          const SizedBox(height: 24),
          _sectionTitle("PROFILE", accentColor, fontMethod, centered: true),
          Text(data.objective, textAlign: TextAlign.center, style: fontMethod(fontSize: 10, height: 1.6)),
          const SizedBox(height: 32),
          _sectionTitle("EXPERIENCE", accentColor, fontMethod, centered: true),
          ...data.experience.map((exp) => _ExperienceItem(exp: exp, fontMethod: fontMethod, isProfessional: true)),
          const SizedBox(height: 24),
          _sectionTitle("SKILLS & LANGUAGES", accentColor, fontMethod, centered: true),
          Center(child: Text("${data.skills.join(' • ')}", textAlign: TextAlign.center, style: fontMethod(fontSize: 10, fontWeight: FontWeight.bold))),
          const SizedBox(height: 24),
          _sectionTitle("EDUCATION", accentColor, fontMethod, centered: true),
          ...data.education.map((edu) => _EducationItem(edu: edu, fontMethod: fontMethod, isProfessional: true)),
        ],
      ),
    );
  }
}

class _CreativeTemplate extends StatelessWidget {
  final ResumeData data;
  final TextStyle Function({TextStyle? textStyle, Color? color, double? fontSize, FontWeight? fontWeight, double? letterSpacing, double? height}) fontMethod;
  const _CreativeTemplate({required this.data, required this.fontMethod});

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(int.parse(data.accentColor.replaceAll('#', '0xff')));
    return Row(
      children: [
        Container(
          width: 200,
          color: const Color(0xFF1E293B),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.avatarUrl.isNotEmpty)
                Container(
                  width: 140,
                  height: 140,
                  margin: const EdgeInsets.only(bottom: 32),
                  decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: NetworkImage(data.avatarUrl), fit: BoxFit.cover), border: Border.all(color: accentColor, width: 3)),
                )
              else
                const CircleAvatar(radius: 40, backgroundColor: Colors.white10, child: Icon(LucideIcons.user, size: 40, color: Colors.white)),
              const SizedBox(height: 24),
              _sidebarSection("CONTACT", accentColor, fontMethod),
              _sidebarItem(LucideIcons.mail, data.email, fontMethod),
              _sidebarItem(LucideIcons.phone, data.phone, fontMethod),
              _sidebarItem(LucideIcons.mapPin, data.address, fontMethod),
              const SizedBox(height: 32),
              _sidebarSection("SKILLS", accentColor, fontMethod),
              ...data.skills.map((s) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(s, style: fontMethod(color: Colors.white, fontSize: 9)))),
              const SizedBox(height: 32),
              _sidebarSection("LANGUAGES", accentColor, fontMethod),
              ...data.languages.map((l) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(l, style: fontMethod(color: Colors.white70, fontSize: 9)))),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.fullName, style: fontMethod(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text(data.jobTitle, style: fontMethod(fontSize: 18, color: accentColor, fontWeight: FontWeight.w600)),
                const SizedBox(height: 32),
                _sectionTitle("SUMMARY", accentColor, fontMethod),
                Text(data.objective, style: fontMethod(fontSize: 10, height: 1.5)),
                const SizedBox(height: 32),
                _sectionTitle("EXPERIENCE", accentColor, fontMethod),
                ...data.experience.map((exp) => _ExperienceItem(exp: exp, fontMethod: fontMethod)),
                const SizedBox(height: 32),
                _sectionTitle("PROJECTS", accentColor, fontMethod),
                ...data.projects.map((p) => _ProjectItem(proj: p, fontMethod: fontMethod)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sidebarSection(String title, Color accent, TextStyle Function({TextStyle? textStyle, Color? color, double? fontSize, FontWeight? fontWeight, double? letterSpacing, double? height}) font) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: font(color: accent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)), const SizedBox(height: 12)]);
  }

  Widget _sidebarItem(IconData icon, String text, TextStyle Function({TextStyle? textStyle, Color? color, double? fontSize, FontWeight? fontWeight, double? letterSpacing, double? height}) font) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Icon(icon, size: 10, color: Colors.white70), const SizedBox(width: 8), Expanded(child: Text(text, style: font(color: Colors.white70, fontSize: 9)))]));
  }
}

// Helpers
Widget _sectionTitle(String title, Color accent, TextStyle Function({TextStyle? textStyle, Color? color, double? fontSize, FontWeight? fontWeight, double? letterSpacing, double? height}) font, {bool centered = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(title, style: font(color: accent, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 4),
        Container(width: centered ? 40 : 20, height: 2, color: accent),
      ],
    ),
  );
}

class _ExperienceItem extends StatelessWidget {
  final ResumeExperience exp;
  final bool isProfessional;
  final TextStyle Function({TextStyle? textStyle, Color? color, double? fontSize, FontWeight? fontWeight, double? letterSpacing, double? height}) fontMethod;
  const _ExperienceItem({required this.exp, required this.fontMethod, this.isProfessional = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isProfessional ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isProfessional ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
            children: [
              Text(exp.position, style: fontMethod(fontSize: 11, fontWeight: FontWeight.bold)),
              if (!isProfessional) Text("${exp.startYear} - ${exp.endYear}", style: fontMethod(fontSize: 9, color: Colors.grey)),
            ],
          ),
          Text(exp.company, style: fontMethod(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
          if (isProfessional) Text("${exp.startYear} - ${exp.endYear}", style: fontMethod(fontSize: 9, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(exp.description, textAlign: isProfessional ? TextAlign.center : TextAlign.start, style: fontMethod(fontSize: 9, height: 1.4)),
        ],
      ),
    );
  }
}

class _ProjectItem extends StatelessWidget {
  final ResumeProject proj;
  final TextStyle Function({TextStyle? textStyle, Color? color, double? fontSize, FontWeight? fontWeight, double? letterSpacing, double? height}) fontMethod;
  const _ProjectItem({required this.proj, required this.fontMethod});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(proj.name, style: fontMethod(fontSize: 11, fontWeight: FontWeight.bold)),
          Text(proj.description, style: fontMethod(fontSize: 9, height: 1.3)),
          if (proj.link.isNotEmpty) Text(proj.link, style: fontMethod(fontSize: 8, color: Colors.blue)),
        ],
      ),
    );
  }
}

class _EducationItem extends StatelessWidget {
  final ResumeEducation edu;
  final bool isProfessional;
  final TextStyle Function({TextStyle? textStyle, Color? color, double? fontSize, FontWeight? fontWeight, double? letterSpacing, double? height}) fontMethod;
  const _EducationItem({required this.edu, required this.fontMethod, this.isProfessional = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: isProfessional ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isProfessional ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
            children: [
              Text(edu.school, style: fontMethod(fontSize: 11, fontWeight: FontWeight.bold)),
              if (!isProfessional) Text("${edu.startYear} - ${edu.endYear}", style: fontMethod(fontSize: 9, color: Colors.grey)),
            ],
          ),
          Text("${edu.degree}${edu.gpa.isNotEmpty ? ' • GPA: ${edu.gpa}' : ''}", style: fontMethod(fontSize: 9)),
          if (isProfessional) Text("${edu.startYear} - ${edu.endYear}", style: fontMethod(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _SkillBadge extends StatelessWidget {
  final String label;
  final Color color;
  final TextStyle Function({TextStyle? textStyle, Color? color, double? fontSize, FontWeight? fontWeight, double? letterSpacing, double? height}) fontMethod;
  const _SkillBadge({required this.label, required this.color, required this.fontMethod});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.2))),
      child: Text(label, style: fontMethod(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }
}
