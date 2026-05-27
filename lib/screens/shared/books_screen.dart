// lib/screens/shared/books_screen.dart
// Teacher/Admin: upload PDFs & images per class+subject
// Student: browse class → subject → materials, read in-app
// No external links | No downloads | No screenshots

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
class BookMaterial {
  final String id;
  final String title;
  final String description;
  final String fileUrl;
  final String fileType; // 'pdf' | 'image'
  final String className;
  final String subject;
  final String uploadedBy;
  final String uploadedByName;
  final DateTime uploadedAt;
  final int fileSizeKb;

  BookMaterial({
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
    required this.fileSizeKb,
  });

  factory BookMaterial.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BookMaterial(
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
      fileSizeKb: d['fileSizeKb'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'fileUrl': fileUrl,
        'fileType': fileType,
        'className': className,
        'subject': subject,
        'uploadedBy': uploadedBy,
        'uploadedByName': uploadedByName,
        'uploadedAt': Timestamp.fromDate(uploadedAt),
        'fileSizeKb': fileSizeKb,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const List<String> _kClasses = [
  'Nursery', 'LKG', 'UKG',
  'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
  'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
];

const List<String> _kSubjects = [
  'Mathematics', 'Science', 'English', 'Hindi', 'Social Studies',
  'Computer Science', 'Sanskrit', 'Urdu', 'Physical Education',
  'Art & Craft', 'Moral Science', 'General Knowledge',
];

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  String? _selectedClass;
  String? _selectedSubject;

  @override
  Widget build(BuildContext context) {
    final user = context.read<AppAuthProvider>().currentUser;
    final isTeacher = user?.role == UserRole.teacher;
    final isAdmin = user?.role == UserRole.admin;
    final canUpload = isTeacher || isAdmin;

    // Student: lock class to their own class
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
                  ? '$_selectedClass — Select Subject'
                  : 'Library',
          style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: _selectedSubject != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => setState(() => _selectedSubject = null))
            : _selectedClass != null && user?.role != UserRole.student
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () =>
                        setState(() => _selectedClass = null))
                : null,
        actions: [
          if (canUpload && _selectedSubject != null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'Upload Material',
              onPressed: () => _showUploadDialog(context, user!),
            ),
        ],
      ),
      body: _selectedSubject != null
          ? _MaterialsList(
              className: _selectedClass!,
              subject: _selectedSubject!,
              canUpload: canUpload,
              user: user!,
            )
          : _selectedClass != null
              ? _SubjectGrid(
                  onSubjectTap: (s) => setState(() => _selectedSubject = s),
                )
              : _ClassGrid(
                  onClassTap: (c) => setState(() => _selectedClass = c),
                ),
    );
  }

  void _showUploadDialog(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UploadSheet(
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
  final ValueChanged<String> onClassTap;
  const _ClassGrid({required this.onClassTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('School Library',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      Text('Select your class to begin',
                          style: GoogleFonts.poppins(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
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
              return _ClassCard(label: cls, onTap: () => onClassTap(cls));
            },
          ),
        ),
      ],
    );
  }
}

class _ClassCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ClassCard({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.class_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUBJECT GRID
// ─────────────────────────────────────────────────────────────────────────────
class _SubjectGrid extends StatelessWidget {
  final ValueChanged<String> onSubjectTap;
  const _SubjectGrid({required this.onSubjectTap});

  static const Map<String, IconData> _icons = {
    'Mathematics': Icons.calculate_rounded,
    'Science': Icons.science_rounded,
    'English': Icons.translate_rounded,
    'Hindi': Icons.language_rounded,
    'Social Studies': Icons.public_rounded,
    'Computer Science': Icons.computer_rounded,
    'Sanskrit': Icons.auto_stories_rounded,
    'Urdu': Icons.text_fields_rounded,
    'Physical Education': Icons.sports_soccer_rounded,
    'Art & Craft': Icons.palette_rounded,
    'Moral Science': Icons.psychology_rounded,
    'General Knowledge': Icons.lightbulb_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
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
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icons[sub] ?? Icons.book_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(sub,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textHint),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MATERIALS LIST
// ─────────────────────────────────────────────────────────────────────────────
class _MaterialsList extends StatelessWidget {
  final String className;
  final String subject;
  final bool canUpload;
  final UserModel user;

  const _MaterialsList({
    required this.className,
    required this.subject,
    required this.canUpload,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('books')
          .where('className', isEqualTo: className)
          .where('subject', isEqualTo: subject)
          .orderBy('uploadedAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open_rounded,
                    size: 80, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('No materials uploaded yet',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary)),
                if (canUpload) ...[
                  const SizedBox(height: 8),
                  Text('Tap + to upload PDFs or images',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.textHint)),
                ],
              ],
            ),
          );
        }

        final materials =
            docs.map((d) => BookMaterial.fromFirestore(d)).toList();

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: materials.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _MaterialCard(
            material: materials[i],
            canDelete: canUpload,
          ),
        );
      },
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final BookMaterial material;
  final bool canDelete;
  const _MaterialCard({required this.material, required this.canDelete});

  @override
  Widget build(BuildContext context) {
    final isPdf = material.fileType == 'pdf';
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => isPdf
              ? _PdfReaderScreen(material: material)
              : _ImageReaderScreen(material: material),
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
                color: isPdf
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                color: isPdf ? AppColors.error : AppColors.info,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(material.title,
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  if (material.description.isNotEmpty)
                    Text(material.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 12, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(material.uploadedByName,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: AppColors.textHint)),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time_rounded,
                          size: 12, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(material.uploadedAt),
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppColors.textHint),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPdf ? 'PDF' : 'IMG',
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                ),
                if (canDelete) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _confirmDelete(context),
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 20, color: AppColors.error),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Material',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Delete "${material.title}"? This cannot be undone.',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance
                    .collection('books')
                    .doc(material.id)
                    .delete();
                // Also delete from Storage
                try {
                  await FirebaseStorage.instance
                      .refFromURL(material.fileUrl)
                      .delete();
                } catch (_) {}
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Deleted "${material.title}"'),
                    backgroundColor: AppColors.error,
                  ));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to delete')));
                }
              }
            },
            child:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UPLOAD SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _UploadSheet extends StatefulWidget {
  final String className;
  final String subject;
  final UserModel user;

  const _UploadSheet({
    required this.className,
    required this.subject,
    required this.user,
  });

  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  File? _selectedFile;
  String? _fileType;
  String? _fileName;
  bool _uploading = false;
  double _uploadProgress = 0;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileType = 'pdf';
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (img != null) {
      setState(() {
        _selectedFile = File(img.path);
        _fileType = 'image';
        _fileName = img.name;
      });
    }
  }

  Future<void> _upload() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a file')));
      return;
    }

    setState(() => _uploading = true);

    try {
      final ext = _fileType == 'pdf' ? 'pdf' : 'jpg';
      final storageRef = FirebaseStorage.instance.ref().child(
          'books/${widget.className}/${widget.subject}/${DateTime.now().millisecondsSinceEpoch}.$ext');

      final uploadTask = storageRef.putFile(_selectedFile!);
      uploadTask.snapshotEvents.listen((snap) {
        setState(() {
          _uploadProgress =
              snap.bytesTransferred / (snap.totalBytes == 0 ? 1 : snap.totalBytes);
        });
      });

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      final sizeKb = (await _selectedFile!.length()) ~/ 1024;

      await FirebaseFirestore.instance.collection('books').add({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'fileUrl': url,
        'fileType': _fileType,
        'className': widget.className,
        'subject': widget.subject,
        'uploadedBy': widget.user.uid,
        'uploadedByName': widget.user.fullName,
        'uploadedAt': FieldValue.serverTimestamp(),
        'fileSizeKb': sizeKb,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ "${_titleCtrl.text.trim()}" uploaded successfully!'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
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

            // Title
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'e.g. Chapter 3 - Photosynthesis',
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Brief description of this material',
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 20),

            // File selection
            if (_selectedFile == null) ...[
              Text('Select File',
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _FileTypeBtn(
                      icon: Icons.picture_as_pdf_rounded,
                      label: 'Upload PDF',
                      color: AppColors.error,
                      onTap: _pickPdf,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FileTypeBtn(
                      icon: Icons.image_rounded,
                      label: 'Upload Image',
                      color: AppColors.info,
                      onTap: _pickImage,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _fileType == 'pdf'
                          ? Icons.picture_as_pdf_rounded
                          : Icons.image_rounded,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_fileName ?? '',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.success)),
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
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            if (_uploading) ...[
              Text(
                  'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(fontSize: 13)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: AppColors.divider,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 16),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _upload,
                  icon: const Icon(Icons.cloud_upload_rounded),
                  label: const Text('Upload Material'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FileTypeBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FileTypeBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PDF READER SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class _PdfReaderScreen extends StatefulWidget {
  final BookMaterial material;
  const _PdfReaderScreen({required this.material});

  @override
  State<_PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<_PdfReaderScreen> {
  PDFViewController? _pdfController;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _loading = true;
  String? _localPath;
  String? _error;

  @override
  void initState() {
    super.initState();
    _blockScreenshots();
    _downloadPdf();
  }

  Future<void> _blockScreenshots() async {
    try {
      // flutter_windowmanager — block screenshots
      await const MethodChannel('flutter_windowmanager')
          .invokeMethod('addFlags', {'flags': 0x00002000}); // FLAG_SECURE
    } catch (_) {}
  }

  @override
  void dispose() {
    _unblockScreenshots();
    super.dispose();
  }

  Future<void> _unblockScreenshots() async {
    try {
      await const MethodChannel('flutter_windowmanager')
          .invokeMethod('clearFlags', {'flags': 0x00002000});
    } catch (_) {}
  }

  Future<void> _downloadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.material.fileUrl));
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/temp_${widget.material.id}.pdf');
      await file.writeAsBytes(response.bodyBytes);
      if (mounted) setState(() => _localPath = file.path);
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.material.title,
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            if (_totalPages > 0)
              Text('Page ${_currentPage + 1} of $_totalPages',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.white60)),
          ],
        ),
      ),
      body: _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.error, size: 48),
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center),
                ],
              ),
            )
          : _localPath == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.accent)),
                    const SizedBox(height: 16),
                    Text('Loading PDF...',
                        style: GoogleFonts.poppins(color: Colors.white54)),
                  ],
                )
              : Stack(
                  children: [
                    PDFView(
                      filePath: _localPath!,
                      enableSwipe: true,
                      swipeHorizontal: true,
                      autoSpacing: false,
                      pageFling: true,
                      fitEachPage: true,
                      onRender: (pages) =>
                          setState(() {
                            _totalPages = pages ?? 0;
                            _loading = false;
                          }),
                      onViewCreated: (c) => _pdfController = c,
                      onPageChanged: (page, _) =>
                          setState(() => _currentPage = page ?? 0),
                    ),
                    if (_loading)
                      const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accent)),
                  ],
                ),
      bottomNavigationBar: _localPath != null && !_loading
          ? _PdfNavBar(
              current: _currentPage,
              total: _totalPages,
              onPrev: _currentPage > 0
                  ? () => _pdfController?.setPage(_currentPage - 1)
                  : null,
              onNext: _currentPage < _totalPages - 1
                  ? () => _pdfController?.setPage(_currentPage + 1)
                  : null,
              onDashboard: () => Navigator.pop(context),
            )
          : null,
    );
  }
}

class _PdfNavBar extends StatelessWidget {
  final int current;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onDashboard;

  const _PdfNavBar({
    required this.current,
    required this.total,
    required this.onPrev,
    required this.onNext,
    required this.onDashboard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onDashboard,
            icon: const Icon(Icons.home_rounded, color: Colors.white),
            tooltip: 'Back',
          ),
          const Spacer(),
          IconButton(
            onPressed: onPrev,
            icon: Icon(Icons.arrow_back_ios_rounded,
                color: onPrev != null ? Colors.white : Colors.white30),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${current + 1} / $total',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: Icon(Icons.arrow_forward_ios_rounded,
                color: onNext != null ? Colors.white : Colors.white30),
          ),
          const Spacer(),
          const SizedBox(width: 48), // balance the home button
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IMAGE READER SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class _ImageReaderScreen extends StatefulWidget {
  final BookMaterial material;
  const _ImageReaderScreen({required this.material});

  @override
  State<_ImageReaderScreen> createState() => _ImageReaderScreenState();
}

class _ImageReaderScreenState extends State<_ImageReaderScreen> {
  @override
  void initState() {
    super.initState();
    _blockScreenshots();
  }

  Future<void> _blockScreenshots() async {
    try {
      await const MethodChannel('flutter_windowmanager')
          .invokeMethod('addFlags', {'flags': 0x00002000});
    } catch (_) {}
  }

  @override
  void dispose() {
    _unblockScreenshots();
    super.dispose();
  }

  Future<void> _unblockScreenshots() async {
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
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: Text(widget.material.title,
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w600)),
      ),
      body: PhotoView(
        imageProvider: NetworkImage(widget.material.fileUrl),
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
        color: AppColors.primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.home_rounded, color: Colors.white),
              tooltip: 'Back',
            ),
            const Spacer(),
            Text('Pinch to zoom',
                style: GoogleFonts.poppins(
                    color: Colors.white54, fontSize: 12)),
            const Spacer(),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}