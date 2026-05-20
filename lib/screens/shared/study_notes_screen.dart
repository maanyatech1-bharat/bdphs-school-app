// lib/screens/shared/study_notes_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../services/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class StudyNotesScreen extends StatefulWidget {
  const StudyNotesScreen({super.key});
  @override
  State<StudyNotesScreen> createState() => _StudyNotesScreenState();
}

class _StudyNotesScreenState extends State<StudyNotesScreen> {
  String _selectedSubject = 'All';
  String _selectedClass = 'All';

  final _subjects = [
    'All', 'Mathematics', 'Science', 'English', 'Hindi',
    'Social Studies', 'Sanskrit', 'Computer', 'General'
  ];
  final _classes = [
    'All', 'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10'
  ];

  Color _subjectColor(String subject) {
    const colors = {
      'Mathematics': Color(0xFF2563EB),
      'Science': Color(0xFF059669),
      'English': Color(0xFF7C3AED),
      'Hindi': Color(0xFFDC2626),
      'Social Studies': Color(0xFFD97706),
      'Sanskrit': Color(0xFF0891B2),
      'Computer': Color(0xFF374151),
      'General': Color(0xFF6B7280),
    };
    return colors[subject] ?? AppColors.primary;
  }

  IconData _subjectIcon(String subject) {
    const icons = {
      'Mathematics': Icons.calculate_rounded,
      'Science': Icons.science_rounded,
      'English': Icons.menu_book_rounded,
      'Hindi': Icons.translate_rounded,
      'Social Studies': Icons.public_rounded,
      'Sanskrit': Icons.auto_stories_rounded,
      'Computer': Icons.computer_rounded,
      'General': Icons.folder_rounded,
    };
    return icons[subject] ?? Icons.description_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser;
    final canUpload =
        user?.role == UserRole.teacher || user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Study Notes',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF0891B2),
        foregroundColor: Colors.white,
        actions: [
          if (canUpload)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _showAddNoteSheet(context, user),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSubject,
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    items: _subjects
                        .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s,
                                style: GoogleFonts.poppins(fontSize: 13))))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedSubject = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedClass,
                    decoration: InputDecoration(
                      labelText: 'Class',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    items: _classes
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c,
                                style: GoogleFonts.poppins(fontSize: 13))))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedClass = v!),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('study_notes')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var docs = snap.data?.docs ?? [];
                if (_selectedSubject != 'All') {
                  docs = docs
                      .where((d) =>
                          (d.data()
                              as Map<String, dynamic>)['subject'] ==
                          _selectedSubject)
                      .toList();
                }
                if (_selectedClass != 'All') {
                  docs = docs
                      .where((d) =>
                          (d.data()
                              as Map<String, dynamic>)['className'] ==
                          _selectedClass)
                      .toList();
                }
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.folder_open_rounded,
                            size: 64, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        Text('No notes found',
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                        Text('Notes uploaded by teachers will appear here',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textHint)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final noteId = docs[i].id;
                    final subject = d['subject'] ?? 'General';
                    final color = _subjectColor(subject);
                    final icon = _subjectIcon(subject);
                    final createdAt = d['createdAt'] != null
                        ? (d['createdAt'] as dynamic).toDate()
                        : null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border(left: BorderSide(color: color, width: 4)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8)
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12)),
                            child: Icon(icon, color: color, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d['title'] ?? 'Note',
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Text(subject,
                                          style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: color)),
                                    ),
                                    const SizedBox(width: 6),
                                    Text('• ${d['className'] ?? 'All'}',
                                        style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: AppColors.textHint)),
                                  ],
                                ),
                                if (createdAt != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                      DateFormat('dd MMM yyyy')
                                          .format(createdAt),
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: AppColors.textHint)),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              if ((d['fileUrl'] ?? '').isNotEmpty)
                                IconButton(
                                  icon: const Icon(
                                      Icons.download_rounded,
                                      color: Color(0xFF0891B2)),
                                  onPressed: () =>
                                      _openUrl(context, d['fileUrl']),
                                ),
                              if (canUpload)
                                IconButton(
                                  icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.error,
                                      size: 18),
                                  onPressed: () => FirebaseFirestore
                                      .instance
                                      .collection('study_notes')
                                      .doc(noteId)
                                      .delete(),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: canUpload
          ? FloatingActionButton.extended(
              onPressed: () => _showAddNoteSheet(context, user),
              backgroundColor: const Color(0xFF0891B2),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text('Add Note',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file')),
        );
      }
    }
  }

  void _showAddNoteSheet(BuildContext context, dynamic user) {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String subject = 'Mathematics';
    String cls = 'Class 6';
    bool saving = false;

    final subjects = [
      'Mathematics', 'Science', 'English', 'Hindi',
      'Social Studies', 'Sanskrit', 'Computer', 'General'
    ];
    final classes = [
      'All Classes', 'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
      'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          height: MediaQuery.of(ctx).size.height * 0.65,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 16, 12, 0),
                child: Row(
                  children: [
                    Text('Add Study Note',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded)),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      MediaQuery.of(ctx).viewInsets.bottom + 20),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: titleCtrl,
                        decoration: InputDecoration(
                          labelText: 'Note Title',
                          hintText: 'e.g. Chapter 3 - Algebra Notes',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          prefixIcon:
                              const Icon(Icons.title_rounded),
                        ),
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: urlCtrl,
                        decoration: InputDecoration(
                          labelText: 'File URL (Google Drive / PDF link)',
                          hintText: 'https://drive.google.com/...',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          prefixIcon:
                              const Icon(Icons.link_rounded),
                        ),
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: subject,
                        decoration: InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          prefixIcon:
                              const Icon(Icons.subject_rounded),
                        ),
                        items: subjects
                            .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s,
                                    style: GoogleFonts.poppins(
                                        fontSize: 13))))
                            .toList(),
                        onChanged: (v) =>
                            setModal(() => subject = v!),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: cls,
                        decoration: InputDecoration(
                          labelText: 'For Class',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          prefixIcon:
                              const Icon(Icons.class_rounded),
                        ),
                        items: classes
                            .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c,
                                    style: GoogleFonts.poppins(
                                        fontSize: 13))))
                            .toList(),
                        onChanged: (v) =>
                            setModal(() => cls = v!),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  if (titleCtrl.text.trim().isEmpty)
                                    return;
                                  setModal(() => saving = true);
                                  await FirebaseFirestore.instance
                                      .collection('study_notes')
                                      .add({
                                    'title': titleCtrl.text.trim(),
                                    'fileUrl': urlCtrl.text.trim(),
                                    'subject': subject,
                                    'className': cls,
                                    'uploadedBy':
                                        user?.fullName ?? 'Teacher',
                                    'uploadedById': user?.uid ?? '',
                                    'createdAt':
                                        FieldValue.serverTimestamp(),
                                  });
                                  if (ctx.mounted) Navigator.pop(ctx);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF0891B2),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                          ),
                          child: saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : Text('Upload Note',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}