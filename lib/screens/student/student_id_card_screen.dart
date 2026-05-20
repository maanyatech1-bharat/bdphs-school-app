// lib/screens/student/student_id_card_screen.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';

class StudentIdCardScreen extends StatefulWidget {
  const StudentIdCardScreen({super.key});
  @override
  State<StudentIdCardScreen> createState() => _StudentIdCardScreenState();
}

class _StudentIdCardScreenState extends State<StudentIdCardScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser;
    final student = user is StudentModel ? user as StudentModel : null;

    if (student == null) {
      return const Scaffold(
        body: Center(child: Text('Student data not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Student ID Card',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Print / Save PDF',
            onPressed: _generating ? null : () => _printCard(student),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ─── ID Card ────────────────────────────────────────────────
            RepaintBoundary(
              key: _cardKey,
              child: _IDCard(student: student),
            ),

            const SizedBox(height: 24),

            // ─── QR Code section ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      // ✅ FIX: withOpacity → withValues(alpha:)
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  Text('Scan QR Code',
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text('Scan to verify student identity',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  QrImageView(
                    data: _buildQrData(student),
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.primary,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'UID: ${student.uid.substring(0, 16).toUpperCase()}',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textHint,
                        letterSpacing: 1),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─── Actions ────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _generating ? null : () => _printCard(student),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _generating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.picture_as_pdf_rounded,
                            color: Colors.white),
                    label: Text(
                      _generating ? 'Generating...' : 'Download PDF',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareCard(student),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.share_rounded,
                        color: AppColors.primary),
                    label: Text('Share',
                        style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ─── Info note ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                // ✅ FIX: withOpacity → withValues(alpha:)
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.info, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This digital ID card is valid only while your account is active. Carry your physical school ID for official purposes.',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildQrData(StudentModel student) {
    final classCode = student.className
        .replaceAll('Class ', '')
        .replaceAll('Nursery', 'N')
        .replaceAll('LKG', 'LKG')
        .replaceAll('UKG', 'UKG');
    final sid = 'BDPHS${classCode}${student.rollNumber}';
    return [
      'BLOOMING DALE PUBLIC HIGH SCHOOL',
      '━━━━━━━━━━━━━━━━━━━━━━━━━━',
      'STUDENT IDENTITY CARD',
      '━━━━━━━━━━━━━━━━━━━━━━━━━━',
      'Name     : ${student.fullName}',
      'Class    : ${student.className}',
      'Roll No  : ${student.rollNumber}',
      'Student ID: $sid',
      'Father   : ${student.fatherName}',
      'Phone    : ${student.phone}',
      '━━━━━━━━━━━━━━━━━━━━━━━━━━',
      'Academic Year: 2026-27',
      'Issued by: BDPHS Administration',
      '━━━━━━━━━━━━━━━━━━━━━━━━━━',
      'UID: ${student.uid}',
    ].join('\n');
  }

  Future<void> _printCard(StudentModel student) async {
    setState(() => _generating = true);
    try {
      final pdf = pw.Document();
      final qrImage = await _generateQrImage(student);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a6,
          margin: const pw.EdgeInsets.all(16),
          build: (pw.Context ctx) {
            return pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                    color: const PdfColor(0.1, 0.22, 0.36), width: 2),
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Column(
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: const pw.BoxDecoration(
                      color: PdfColor(0.1, 0.22, 0.36),
                      borderRadius: pw.BorderRadius.vertical(
                          top: pw.Radius.circular(10)),
                    ),
                    child: pw.Column(children: [
                      pw.Text('BDPHS',
                          style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white)),
                      pw.Text('Student Identity Card',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.white)),
                    ]),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(12),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(student.fullName,
                                  style: pw.TextStyle(
                                      fontSize: 14,
                                      fontWeight: pw.FontWeight.bold)),
                              pw.SizedBox(height: 6),
                              _pdfRow('Class', student.className),
                              _pdfRow('Roll No.', student.rollNumber),
                              _pdfRow('Father', student.fatherName),
                              _pdfRow('Phone', student.phone),
                              if (student.dateOfBirth != null)
                                _pdfRow('DOB',
                                    DateFormat('dd/MM/yyyy').format(student.dateOfBirth)),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Column(children: [
                          pw.Image(pw.MemoryImage(qrImage),
                              width: 80, height: 80),
                          pw.SizedBox(height: 4),
                          pw.Text('Scan to verify',
                              style: const pw.TextStyle(
                                  fontSize: 7, color: PdfColors.grey)),
                        ]),
                      ],
                    ),
                  ),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: const pw.BoxDecoration(
                      color: PdfColor(0.91, 0.63, 0.13),
                      borderRadius: pw.BorderRadius.vertical(
                          bottom: pw.Radius.circular(10)),
                    ),
                    child: pw.Text(
                      'Valid for Academic Year 2026-27 • BDPHS School',
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.white),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (_) async => pdf.save());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 52,
            child: pw.Text('$label:',
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey700)),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _generateQrImage(StudentModel student) async {
    final qrPainter = QrPainter(
      data: _buildQrData(student),
      version: QrVersions.auto,
      gapless: true,
    );
    // ✅ FIX: 300 → 300.0 (toImageData expects double, not int)
    final imageData = await qrPainter.toImageData(
      300.0,
      format: ui.ImageByteFormat.png,
    );
    return imageData!.buffer.asUint8List();
  }

  Future<void> _shareCard(StudentModel student) async {
    final pdf = pw.Document();
    final qrImage = await _generateQrImage(student);
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        build: (ctx) => pw.Center(
          child: pw.Column(children: [
            pw.Text(student.fullName,
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Image(pw.MemoryImage(qrImage), width: 120, height: 120),
            pw.SizedBox(height: 8),
            pw.Text(
                '${student.className} | Roll: ${student.rollNumber}',
                style: const pw.TextStyle(fontSize: 11)),
          ]),
        ),
      ),
    );
    await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'BDPHS_ID_${student.rollNumber}.pdf');
  }
}

// ─── ID CARD WIDGET ───────────────────────────────────────────────────────────
class _IDCard extends StatelessWidget {
  final StudentModel student;
  const _IDCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            // ✅ FIX: withOpacity → withValues(alpha:)
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(children: [
          // ─── Card Header ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration:
                const BoxDecoration(gradient: AppColors.primaryGradient),
            child: Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  // ✅ FIX: withOpacity → withValues(alpha:)
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BDPHS',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 2)),
                  Text('Student Identity Card',
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white70,
                          letterSpacing: 1.5)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('2026-27',
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ]),
          ),

          // ─── Card Body ────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(children: [
                  Container(
                    width: 80,
                    height: 90,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.primary, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.surface,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: student.photoUrl != null &&
                              student.photoUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: student.photoUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Icon(
                                  Icons.person_rounded,
                                  size: 44,
                                  color: AppColors.textHint),
                              errorWidget: (_, __, ___) => const Icon(
                                  Icons.person_rounded,
                                  size: 44,
                                  color: AppColors.textHint),
                            )
                          : const Icon(Icons.person_rounded,
                              size: 44, color: AppColors.textHint),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      // ✅ FIX: withOpacity → withValues(alpha:)
                      color: AppColors.studentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.studentColor
                              .withValues(alpha: 0.3)),
                    ),
                    child: Text('STUDENT',
                        style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.studentColor,
                            letterSpacing: 1)),
                  ),
                ]),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.fullName,
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 10),
                      _CardRow(
                          icon: Icons.class_rounded,
                          label: 'Class',
                          value: student.className),
                      _CardRow(
                          icon: Icons.numbers_rounded,
                          label: 'Roll',
                          value: student.rollNumber),
                      _CardRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Father',
                          value: student.fatherName),
                      _CardRow(
                          icon: Icons.phone_rounded,
                          label: 'Phone',
                          value: student.phone),
                      _CardRow(
                          icon: Icons.cake_rounded,
                          label: 'DOB',
                          value: DateFormat('dd/MM/yyyy')
                              .format(student.dateOfBirth)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Card Footer ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
            decoration:
                const BoxDecoration(gradient: AppColors.accentGradient),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Valid for Academic Year 2026-27',
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w500)),
                const Icon(Icons.verified_rounded,
                    size: 16, color: Colors.white),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _CardRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: AppColors.textHint),
          const SizedBox(width: 5),
          SizedBox(
            width: 40,
            child: Text('$label:',
                style: GoogleFonts.poppins(
                    fontSize: 10, color: AppColors.textHint)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}