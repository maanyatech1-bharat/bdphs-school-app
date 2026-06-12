// lib/screens/teacher/teacher_id_card_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';

class TeacherIdCardScreen extends StatefulWidget {
  const TeacherIdCardScreen({super.key});
  @override
  State<TeacherIdCardScreen> createState() => _TeacherIdCardScreenState();
}

class _TeacherIdCardScreenState extends State<TeacherIdCardScreen> {
  bool _generating = false;

  String _buildQrData(TeacherModel t) =>
      [
      'BLOOMING DALE PUBLIC HIGH SCHOOL',
      'TEACHER IDENTITY CARD',
      'Name     : ${t.fullName}',
      'Emp ID   : ${t.employeeId.isEmpty ? "N/A" : t.employeeId}',
      'Subject  : ${t.subject}',
      'Academic Year: 2026-27',
      'Issued by: BDPHS Administration',
    ].join('\n');

  Future<void> _printCard(TeacherModel t) async {
    setState(() => _generating = true);
    try {
      final doc = pw.Document();
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a6.landscape,
        build: (ctx) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.blueGrey800, width: 2),
            borderRadius: pw.BorderRadius.circular(12),
          ),
          padding: const pw.EdgeInsets.all(16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(children: [
                pw.Expanded(child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('BLOOMING DALE PUBLIC HIGH SCHOOL',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Jammu & Kashmir, India',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blueGrey800,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text('STAFF ID CARD',
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                )),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: _buildQrData(t),
                  width: 60, height: 60,
                ),
              ]),
              pw.Divider(color: PdfColors.blueGrey300),
              pw.SizedBox(height: 4),
              pw.Text(t.fullName,
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Subject: ${t.subject}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey700)),
              pw.Text('Employee ID: ${t.employeeId}',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Qualification: ${t.qualification}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              pw.Text('Joined: ${DateFormat('dd MMM yyyy').format(t.joiningDate)}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            ],
          ),
        ),
      ));
      await Printing.layoutPdf(onLayout: (_) async => doc.save());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    }
    if (mounted) setState(() => _generating = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser;
    final teacher = user is TeacherModel ? user as TeacherModel : null;

    if (teacher == null) {
      return const Scaffold(body: Center(child: Text('Teacher data not found')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Staff ID Card',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.teacherColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // ── ID Card ────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A3A5C), Color(0xFF2E5E8E)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                color: const Color(0xFF1A3A5C).withValues(alpha: 0.4),
                blurRadius: 20, offset: const Offset(0, 8),
              )],
            ),
            child: Column(children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('BLOOMING DALE PUBLIC HIGH SCHOOL',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 9,
                            fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    Text('Jammu & Kashmir, India',
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 8)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('STAFF ID', style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                  ),
                ]),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  // Photo
                  Container(
                    width: 80, height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white30, width: 2),
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: teacher.photoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(teacher.photoUrl!, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _photoPlaceholder(teacher)))
                        : _photoPlaceholder(teacher),
                  ),
                  const SizedBox(width: 16),

                  // Info
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(teacher.fullName,
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    _infoRow(Icons.book_rounded, teacher.subject),
                    _infoRow(Icons.badge_rounded, 'EMP: ${teacher.employeeId}'),
                    _infoRow(Icons.school_rounded, teacher.qualification),
                    _infoRow(Icons.calendar_today_rounded,
                        'Joined: ${DateFormat('MMM yyyy').format(teacher.joiningDate)}'),
                  ])),
                ]),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Valid for Academic Year 2026-27',
                        style: GoogleFonts.poppins(color: Colors.white60, fontSize: 9)),
                    Text('bdphschool1@gmail.com',
                        style: GoogleFonts.poppins(color: Colors.white60, fontSize: 9)),
                  ])),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: QrImageView(
                      data: _buildQrData(teacher),
                      version: QrVersions.auto,
                      size: 44,
                    ),
                  ),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // QR details
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(children: [
              Text('Scan QR Code', style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Scan to verify staff identity', style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              QrImageView(
                data: _buildQrData(teacher),
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square, color: AppColors.primary),
                dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square, color: AppColors.primaryDark),
              ),
              const SizedBox(height: 12),
              Text('EMP ID: ${teacher.employeeId}',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textHint, letterSpacing: 1)),
            ]),
          ),

          const SizedBox(height: 16),

          // Download button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generating ? null : () => _printCard(teacher),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teacherColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _generating
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
              label: Text(
                _generating ? 'Generating...' : 'Download PDF',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _photoPlaceholder(TeacherModel t) => Center(
    child: Text(t.fullName.isNotEmpty ? t.fullName[0].toUpperCase() : 'T',
        style: GoogleFonts.poppins(
            color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
  );

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      Icon(icon, color: Colors.white60, size: 13),
      const SizedBox(width: 5),
      Expanded(child: Text(text,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
          overflow: TextOverflow.ellipsis)),
    ]),
  );
}