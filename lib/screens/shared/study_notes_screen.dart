// lib/screens/shared/study_notes_screen.dart
// Teacher/Admin: upload notes (PDF or image) per class+subject
// Student: browse class → subject → notes, read in-app
// No external links | No downloads | No screenshots

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────
class StudyNote {
  final String id;
  final String title;
  final String description;
  final String fileUrl;
  final String fileType;
  final String className;
  final String subject;
  final String uploadedBy;
  final String uploadedByName;
  final DateTime uploadedAt;
  final String noteType; // 'notes' | 'assignment' | 'revision' | 'question_paper'

  StudyNote({
    required this.id,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.fileType,
    required this.className,
    required this.subject,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.uploadedAt,
    required this.noteType,
  });

  factory StudyNote.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return StudyNote(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      fileUrl: d['fileUrl'] ?? '',
      fileType: d['fileType'] ?? 'pdf',
      className: d['className'] ?? '',
      subject: d['subject'] ?? '',
      uploadedBy: d['uploadedBy'] ?? '',
      uploadedByName: d['uploadedByName'] ?? '',
      uploadedAt: (d['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      noteType: d['noteType'] ?? 'notes',
    );
  }
}

const List<String> _kClasses = [
  'Nursery', 'LKG', 'UKG',
  'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
  'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
];

const List<String> _kSubjects = [
  'Maths', 'Science', 'English', 'Hindi', 'S.ST',
  'Comp. Sci', 'Sanskrit', 'Urdu', 'Phy. Edu',
  'Art & Craft', 'Moral Sci', 'G.K',
];

const List<String> _kNoteTypes = [
  'notes', 'assignment', 'revision', 'question_paper',
];

const Map<String, String> _kNoteTypeLabels = {
  'notes': '📝 Notes',
  'assignment': '📋 Assignment',
  'revision': '🔁 Revision',
  'question_paper': '📄 Question Paper',
};

const Map<String, Color> _kNoteTypeColors = {
  'notes': AppColors.primary,
  'assignment': AppColors.warning,
  'revision': AppColors.success,
  'question_paper': AppColors.error,
};

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class StudyNotesScreen extends StatefulWidget {
  const StudyNotesScreen({super.key});

  @override
  State<StudyNotesScreen> createState() => _StudyNotesScreenState();
}

class _StudyNotesScreenState extends State<StudyNotesScreen> {
  String? _selectedClass;
  String? _selectedSubject;

  @override
  Widget build(BuildContext context) {
    final user = context.read<AppAuthProvider>().currentUser;
    final canUpload =
        user?.role == UserRole.teacher || user?.role == UserRole.admin;

    if (user?.role == UserRole.student && _selectedClass == null) {
      _selectedClass = (user as dynamic)?.className;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _selectedSubject != null
              ? _selectedSubject!
              : _selectedClass != null
                  ? '$_selectedClass — Subject'
                  : 'Study Material',
          style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppColors.teacherColor,
        foregroundColor: Colors.white,
        leading: _selectedSubject != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => setState(() => _selectedSubject = null))
            : _selectedClass != null && user?.role != UserRole.student
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => setState(() => _selectedClass = null))
                : null,
        actions: [
          if (canUpload && _selectedSubject != null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'Upload Notes',
              onPressed: () => _showUploadDialog(context, user!),
            ),
        ],
      ),
      body: _selectedSubject != null
          ? _NotesList(
              className: _selectedClass!,
              subject: _selectedSubject!,
              canUpload: canUpload,
              user: user!,
            )
          : _selectedClass != null
              ? _SubjectGrid(
                  color: AppColors.teacherColor,
                  onSubjectTap: (s) => setState(() => _selectedSubject = s),
                )
              : _ClassGrid(
                  color: AppColors.teacherColor,
                  onClassTap: (c) => setState(() => _selectedClass = c),
                ),
    );
  }

  void _showUploadDialog(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UploadNotesSheet(
        className: _selectedClass!,
        subject: _selectedSubject!,
        user: user,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLASS GRID
// ─────────────────────────────────────────────────────────────────────────────
class _ClassGrid extends StatelessWidget {
  final Color color;
  final ValueChanged<String> onClassTap;
  const _ClassGrid({required this.color, required this.onClassTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: color,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.article_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Study Material',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  Text('Notes, Assignments & Papers',
                      style: GoogleFonts.poppins(
                          color: Colors.white70, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: _kClasses.length,
            itemBuilder: (_, i) {
              final cls = _kClasses[i];
              return GestureDetector(
                onTap: () => onClassTap(cls),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            Icon(Icons.class_rounded, color: color, size: 22),
                      ),
                      const SizedBox(height: 8),
                      Text(cls,
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUBJECT GRID
// ─────────────────────────────────────────────────────────────────────────────
class _SubjectGrid extends StatelessWidget {
  final Color color;
  final ValueChanged<String> onSubjectTap;
  const _SubjectGrid({required this.color, required this.onSubjectTap});

  static const Map<String, IconData> _icons = {
    'Maths': Icons.calculate_rounded,
    'Science': Icons.science_rounded,
    'English': Icons.translate_rounded,
    'Hindi': Icons.language_rounded,
    'S.ST': Icons.public_rounded,
    'Comp. Sci': Icons.computer_rounded,
    'Sanskrit': Icons.auto_stories_rounded,
    'Urdu': Icons.text_fields_rounded,
    'Phy. Edu': Icons.sports_soccer_rounded,
    'Art & Craft': Icons.palette_rounded,
    'Moral Sci': Icons.psychology_rounded,
    'G.K': Icons.lightbulb_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        
      ),
      itemCount: _kSubjects.length,
      itemBuilder: (_, i) {
        final sub = _kSubjects[i];
        return GestureDetector(
          onTap: () => onSubjectTap(sub),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icons[sub] ?? Icons.book_rounded,
                      color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(sub,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ),
                Icon(Icons.chevron_right_rounded, color: color),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTES LIST
// ─────────────────────────────────────────────────────────────────────────────
class _NotesList extends StatefulWidget {
  final String className;
  final String subject;
  final bool canUpload;
  final UserModel user;

  const _NotesList({
    required this.className,
    required this.subject,
    required this.canUpload,
    required this.user,
  });

  @override
  State<_NotesList> createState() => _NotesListState();
}

class _NotesListState extends State<_NotesList> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        Container(
          color: AppColors.cardBg,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filter == 'all',
                  color: AppColors.teacherColor,
                  onTap: () => setState(() => _filter = 'all'),
                ),
                ..._kNoteTypes.map((t) => _FilterChip(
                      label: _kNoteTypeLabels[t]!,
                      selected: _filter == t,
                      color: _kNoteTypeColors[t]!,
                      onTap: () => setState(() => _filter = t),
                    )),
              ],
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('study_notes')
                .where('className', isEqualTo: widget.className)
                .where('subject', isEqualTo: widget.subject)
                .orderBy('uploadedAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              var docs = snap.data?.docs ?? [];
              if (_filter != 'all') {
                docs = docs
                    .where((d) =>
                        (d.data() as Map)['noteType'] == _filter)
                    .toList();
              }

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article_outlined,
                          size: 80, color: AppColors.textHint),
                      const SizedBox(height: 16),
                      Text('No materials here yet',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: AppColors.textSecondary)),
                      if (widget.canUpload)
                        Text('Tap + to upload notes or papers',
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: AppColors.textHint)),
                    ],
                  ),
                );
              }

              final notes =
                  docs.map((d) => StudyNote.fromFirestore(d)).toList();
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _NoteCard(
                  note: notes[i],
                  canDelete: widget.canUpload,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : color)),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final StudyNote note;
  final bool canDelete;
  const _NoteCard({required this.note, required this.canDelete});

  @override
  Widget build(BuildContext context) {
    final isPdf = note.fileType == 'pdf';
    final typeColor = _kNoteTypeColors[note.noteType] ?? AppColors.primary;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => isPdf
              ? _NotesPdfReader(note: note)
              : _NotesImageReader(note: note),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                color: typeColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _kNoteTypeLabels[note.noteType] ?? note.noteType,
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: typeColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(note.title,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  if (note.description.isNotEmpty)
                    Text(note.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    '${note.uploadedByName} • ${note.uploadedAt.day}/${note.uploadedAt.month}/${note.uploadedAt.year}',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
            if (canDelete)
              GestureDetector(
                onTap: () => _confirmDelete(context),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 20, color: AppColors.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Delete "${note.title}"?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('study_notes')
                  .doc(note.id)
                  .delete();
              try {
                await FirebaseStorage.instance
                    .refFromURL(note.fileUrl)
                    .delete();
              } catch (_) {}
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UPLOAD SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _UploadNotesSheet extends StatefulWidget {
  final String className;
  final String subject;
  final UserModel user;

  const _UploadNotesSheet({
    required this.className,
    required this.subject,
    required this.user,
  });

  @override
  State<_UploadNotesSheet> createState() => _UploadNotesSheetState();
}

class _UploadNotesSheetState extends State<_UploadNotesSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  File? _selectedFile;
  String? _fileType;
  String? _fileName;
  String _noteType = 'notes';
  bool _uploading = false;
  double _progress = 0;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result?.files.single.path != null) {
      setState(() {
        _selectedFile = File(result!.files.single.path!);
        _fileType = 'pdf';
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _pickImage() async {
    final img = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) {
      setState(() {
        _selectedFile = File(img.path);
        _fileType = 'image';
        _fileName = img.name;
      });
    }
  }

  Future<void> _upload() async {
    if (_titleCtrl.text.trim().isEmpty || _selectedFile == null) return;
    setState(() => _uploading = true);
    try {
      final ext = _fileType == 'pdf' ? 'pdf' : 'jpg';
      final ref = FirebaseStorage.instance.ref().child(
          'study_notes/${widget.className}/${widget.subject}/${DateTime.now().millisecondsSinceEpoch}.$ext');

      final task = ref.putFile(_selectedFile!);
      task.snapshotEvents.listen((s) {
        setState(() => _progress = s.bytesTransferred / (s.totalBytes == 0 ? 1 : s.totalBytes));
      });

      final snap = await task;
      final url = await snap.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('study_notes').add({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'fileUrl': url,
        'fileType': _fileType,
        'className': widget.className,
        'subject': widget.subject,
        'uploadedBy': widget.user.uid,
        'uploadedByName': widget.user.fullName,
        'uploadedAt': FieldValue.serverTimestamp(),
        'noteType': _noteType,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ "${_titleCtrl.text.trim()}" uploaded!'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Upload Study Material',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          Text('${widget.className} • ${widget.subject}',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),

          // Type selector
          Text('Type',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _kNoteTypes.map((t) {
                final selected = _noteType == t;
                final color = _kNoteTypeColors[t]!;
                return GestureDetector(
                  onTap: () => setState(() => _noteType = t),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? color
                          : color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: color.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      _kNoteTypeLabels[t] ?? t,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : color),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Title *',
              prefixIcon: Icon(Icons.title_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              prefixIcon: Icon(Icons.description_outlined),
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedFile == null)
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickPdf,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Column(children: [
                      const Icon(Icons.picture_as_pdf_rounded,
                          color: AppColors.error, size: 32),
                      const SizedBox(height: 8),
                      Text('Upload PDF',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.3)),
                    ),
                    child: Column(children: [
                      const Icon(Icons.image_rounded,
                          color: AppColors.info, size: 32),
                      const SizedBox(height: 8),
                      Text('Upload Image',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.info)),
                    ]),
                  ),
                ),
              ),
            ])
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Icon(
                    _fileType == 'pdf'
                        ? Icons.picture_as_pdf_rounded
                        : Icons.image_rounded,
                    color: AppColors.success),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_fileName ?? '',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.success)),
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedFile = null;
                    _fileType = null;
                    _fileName = null;
                  }),
                  child: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary, size: 20),
                ),
              ]),
            ),
          const SizedBox(height: 20),
          if (_uploading) ...[
            Text('Uploading... ${(_progress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(fontSize: 13)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.teacherColor),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _upload,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teacherColor),
                icon: const Icon(Icons.cloud_upload_rounded),
                label: const Text('Upload'),
              ),
            ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PDF READER
// ─────────────────────────────────────────────────────────────────────────────
class _NotesPdfReader extends StatefulWidget {
  final StudyNote note;
  const _NotesPdfReader({required this.note});

  @override
  State<_NotesPdfReader> createState() => _NotesPdfReaderState();
}

class _NotesPdfReaderState extends State<_NotesPdfReader> {
  PDFViewController? _ctrl;
  int _page = 0, _total = 0;
  bool _loading = true;
  String? _path, _error;

  @override
  void initState() {
    super.initState();
    _block();
    _load();
  }

  Future<void> _block() async {
    try {
      await const MethodChannel('flutter_windowmanager')
          .invokeMethod('addFlags', {'flags': 0x00002000});
    } catch (_) {}
  }

  @override
  void dispose() {
    _unblock();
    super.dispose();
  }

  Future<void> _unblock() async {
    try {
      await const MethodChannel('flutter_windowmanager')
          .invokeMethod('clearFlags', {'flags': 0x00002000});
    } catch (_) {}
  }

  Future<void> _load() async {
    try {
      final res = await http.get(Uri.parse(widget.note.fileUrl));
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/note_${widget.note.id}.pdf');
      await file.writeAsBytes(res.bodyBytes);
      if (mounted) setState(() => _path = file.path);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF047857),
        foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.note.title,
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600)),
          if (_total > 0)
            Text('${_page + 1} / $_total',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.white60)),
        ]),
      ),
      body: _error != null
          ? Center(
              child: Text(_error!,
                  style: const TextStyle(color: Colors.white)))
          : _path == null
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
              : Stack(
                  children: [
                    PDFView(
                      filePath: _path!,
                      enableSwipe: true,
                      swipeHorizontal: true,
                      pageFling: true,
                      fitEachPage: true,
                      onRender: (p) =>
                          setState(() {
                            _total = p ?? 0;
                            _loading = false;
                          }),
                      onViewCreated: (c) => _ctrl = c,
                      onPageChanged: (p, _) =>
                          setState(() => _page = p ?? 0),
                    ),
                    if (_loading)
                      const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accent)),
                  ],
                ),
      bottomNavigationBar: _path != null && !_loading
          ? Container(
              color: const Color(0xFF047857),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.home_rounded,
                        color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _page > 0
                        ? () => _ctrl?.setPage(_page - 1)
                        : null,
                    icon: Icon(Icons.arrow_back_ios_rounded,
                        color:
                            _page > 0 ? Colors.white : Colors.white30),
                  ),
                  Text('${_page + 1} / $_total',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  IconButton(
                    onPressed: _page < _total - 1
                        ? () => _ctrl?.setPage(_page + 1)
                        : null,
                    icon: Icon(Icons.arrow_forward_ios_rounded,
                        color: _page < _total - 1
                            ? Colors.white
                            : Colors.white30),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IMAGE READER
// ─────────────────────────────────────────────────────────────────────────────
class _NotesImageReader extends StatefulWidget {
  final StudyNote note;
  const _NotesImageReader({required this.note});

  @override
  State<_NotesImageReader> createState() => _NotesImageReaderState();
}

class _NotesImageReaderState extends State<_NotesImageReader> {
  @override
  void initState() {
    super.initState();
    _block();
  }

  Future<void> _block() async {
    try {
      await const MethodChannel('flutter_windowmanager')
          .invokeMethod('addFlags', {'flags': 0x00002000});
    } catch (_) {}
  }

  @override
  void dispose() {
    _unblock();
    super.dispose();
  }

  Future<void> _unblock() async {
    try {
      await const MethodChannel('flutter_windowmanager')
          .invokeMethod('clearFlags', {'flags': 0x00002000});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF047857),
        foregroundColor: Colors.white,
        title: Text(widget.note.title,
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w600)),
      ),
      body: PhotoView(
        imageProvider: NetworkImage(widget.note.fileUrl),
        minScale: PhotoViewComputedScale.contained * 0.8,
        maxScale: PhotoViewComputedScale.covered * 4.0,
        initialScale: PhotoViewComputedScale.contained,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (_, __) => const Center(
            child: CircularProgressIndicator(color: AppColors.accent)),
        errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image, color: Colors.white54, size: 80)),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF047857),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.home_rounded, color: Colors.white),
          ),
          const Spacer(),
          Text('Pinch to zoom',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
          const Spacer(),
          const SizedBox(width: 48),
        ]),
      ),
    );
  }
}