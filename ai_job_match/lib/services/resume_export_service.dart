import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import '../models/resume_data.dart';
import 'package:intl/intl.dart';

class ResumeExportService {
  static Future<void> exportToPdf(ResumeData data) async {
    final pdf = pw.Document();

    // Load fonts for Vietnamese support
    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final fontItalic = await PdfGoogleFonts.interItalic();

    final primaryColor = PdfColor.fromInt(int.parse(data.accentColor.replaceAll('#', '0xFF')));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          italic: fontItalic,
        ),
        build: (pw.Context context) {
          return [
            _buildHeader(data, primaryColor),
            pw.SizedBox(height: 25),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left Column (Skills, Languages, Contact)
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("CONTACT", primaryColor),
                      _buildContactItem(pw.IconData(0xe0b0), data.phone), // phone
                      _buildContactItem(pw.IconData(0xe0be), data.email), // email
                      _buildContactItem(pw.IconData(0xe88a), data.address), // home
                      if (data.website.isNotEmpty)
                        _buildContactItem(pw.IconData(0xe894), data.website), // web
                      
                      pw.SizedBox(height: 20),
                      _buildSectionTitle("SKILLS", primaryColor),
                      ...data.skills.map((s) => pw.Bullet(text: s, style: const pw.TextStyle(fontSize: 10))),
                      
                      pw.SizedBox(height: 20),
                      _buildSectionTitle("LANGUAGES", primaryColor),
                      ...data.languages.map((l) => pw.Bullet(text: l, style: const pw.TextStyle(fontSize: 10))),
                    ],
                  ),
                ),
                pw.SizedBox(width: 30),
                // Right Column (Objective, Experience, Education)
                pw.Expanded(
                  flex: 5,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("PROFILE", primaryColor),
                      pw.Text(data.objective, style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5)),
                      
                      pw.SizedBox(height: 20),
                      _buildSectionTitle("WORK EXPERIENCE", primaryColor),
                      ...data.experience.map((exp) => _buildExperienceItem(exp)),
                      
                      pw.SizedBox(height: 20),
                      _buildSectionTitle("EDUCATION", primaryColor),
                      ...data.education.map((edu) => _buildEducationItem(edu)),
                      
                      if (data.projects.isNotEmpty) ...[
                        pw.SizedBox(height: 20),
                        _buildSectionTitle("PROJECTS", primaryColor),
                        ...data.projects.map((proj) => _buildProjectItem(proj)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    final fileName = "resume_${data.fullName.replaceAll(' ', '_').toLowerCase()}.pdf";
    await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);
  }

  static pw.Widget _buildHeader(ResumeData data, PdfColor primaryColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: primaryColor, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(data.fullName.toUpperCase(), style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: primaryColor)),
              pw.SizedBox(height: 4),
              pw.Text(data.jobTitle, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: color)),
          pw.Divider(thickness: 1, color: color, indent: 0, endIndent: 0),
        ],
      ),
    );
  }

  static pw.Widget _buildContactItem(pw.IconData icon, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          // pw.Icon(icon, size: 12, color: PdfColors.grey700), // Icons sometimes bug out on web printing
          // pw.SizedBox(width: 8),
          pw.Text(text, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
        ],
      ),
    );
  }

  static pw.Widget _buildExperienceItem(ResumeExperience exp) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(exp.position, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.Text("${exp.startYear} - ${exp.endYear}", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Text(exp.company, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
          pw.SizedBox(height: 4),
          pw.Text(exp.description, style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.2)),
        ],
      ),
    );
  }

  static pw.Widget _buildEducationItem(ResumeEducation edu) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(edu.school, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.Text("${edu.degree}${edu.gpa.isNotEmpty ? ' • GPA: ${edu.gpa}' : ''}", style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.Text("${edu.startYear} - ${edu.endYear}", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  static pw.Widget _buildProjectItem(ResumeProject proj) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(proj.name, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text(proj.description, style: const pw.TextStyle(fontSize: 9)),
          if (proj.link.isNotEmpty)
            pw.Text(proj.link, style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue700)),
        ],
      ),
    );
  }
}
