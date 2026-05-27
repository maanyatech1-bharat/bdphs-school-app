// lib/screens/shared/homework_screen.dart
// Teacher: post homework — type text + optional photo of board/diary
// Student: see only their class homework, read image in-app
// No downloads | No screenshots on image view

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────
class HomeworkEntry {
  final String id;
  final String subject;
  final String description;
  final String? imageUrl;
  final String className;
  final DateTime dueDate;
  final String postedBy;
  final String postedByName;
  final DateTime postedAt;
  final bool isUrgent;

  HomeworkEntry({
    required this.id,
    required this.subject,
    required this.description,
    this.imageUrl,
    required this.className,
    required this.dueDate,
    required this.postedBy,
    required this.postedByName,
    required this.postedAt,
    required this.isUrgent,
  });

  factory HomeworkEntry.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return HomeworkEntry(
      id: doc.id,
      subject: d['subject'] ?? '',
      description: d['description'] ?? '',
      imageUrl: d['imageUrl'],
      className: d['className'] ?? '',
      dueDate: (d['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      postedBy: d['postedBy'] ?? '',
      postedByName: d['postedByName'] ?? '',
      postedAt: (d['postedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isUrgent: d['isUrgent'] ?? false,
    );
  }
}

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
class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  String? _selectedClass;

  @override
  Widget build(BuildContext context) {
    final user = context.read<AppAuthProvider>().currentUser;
    final isStudent = user?.role == UserRole.student;
    final canPost =
        user?.role == UserRole.teacher || user?.role == UserRole.admin;

    // Students always see their own class
    if (isStudent && _selectedClass == null) {
      _selectedClass = (user as dynamic)?.className;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _selectedClass != null ? 'Homework — $_selectedClass' : 'Homework',
          style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        leading: _selectedClass != null && !isStudent
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => setState(() => _selectedClass = null))
            : null,
      ),
      body: _selectedClass != null
          ? _HomeworkList(
              className: _selectedClass!,
              canPost: canPost,
              user: user!,
            )
          : _ClassGrid(
              onClassTap: (c) => setState(() => _selectedClass = c)),
      floatingActionButton: canPost && _selectedClass != null
          ? FloatingActionButton.extended(
              onPressed: () => _showPostDialog(context, user!),
              backgroundColor: AppColors.accent,
              icon: const Icon(Icons.add_task_rounded),
              label: Text('Post Homework',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  void _showPostDialog(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _PostHomeworkSheet(className: _selectedClass!, user: user),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLASS GRID (teacher picks class)
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
          color: AppColors.accent,
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.assignment_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Homework',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              Text('Select class to view or post',
                  style: GoogleFonts.poppins(
                      color: Colors.white70, fontSize: 13)),
            ]),
          ]),
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
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.group_rounded,
                            color: AppColors.accent, size: 22),
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
// HOMEWORK LIST
// ─────────────────────────────────────────────────────────────────────────────
class _HomeworkList extends StatelessWidget {
  final String className;
  final bool canPost;
  final UserModel user;

  const _HomeworkList({
    required this.className,
    required this.canPost,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('homework')
          .where('className', isEqualTo: className)
          .orderBy('postedAt', descending: true)
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
                Icon(Icons.assignment_outlined,
                    size: 80, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('No homework posted yet',
                    style: GoogleFonts.poppins(
                        fontSize: 16, color: AppColors.textSecondary)),
                if (canPost)
                  Text('Tap the button below to post homework',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.textHint)),
              ],
            ),
          );
        }

        final entries =
            docs.map((d) => HomeworkEntry.fromFirestore(d)).toList();

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _HomeworkCard(
            entry: entries[i],
            canDelete: canPost,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOMEWORK CARD
// ─────────────────────────────────────────────────────────────────────────────
class _HomeworkCard extends StatelessWidget {
  final HomeworkEntry entry;
  final bool canDelete;
  const _HomeworkCard({required this.entry, required this.canDelete});

  bool get _isOverdue => entry.dueDate.isBefore(DateTime.now());
  bool get _isDueToday {
    final now = DateTime.now();
    return entry.dueDate.year == now.year &&
        entry.dueDate.month == now.month &&
        entry.dueDate.day == now.day;
  }

  Color get _statusColor {
    if (_isOverdue) return AppColors.error;
    if (_isDueToday) return AppColors.warning;
    return AppColors.success;
  }

  String get _statusLabel {
    if (_isOverdue) return 'Overdue';
    if (_isDueToday) return 'Due Today';
    return 'Upcoming';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: entry.isUrgent
            ? Border.all(color: AppColors.error.withValues(alpha: 0.5), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.assignment_rounded,
                      color: AppColors.accent, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.subject,
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      Text(entry.className,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (entry.isUrgent)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('URGENT',
                        style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_statusLabel,
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _statusColor)),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                if (entry.description.isNotEmpty) ...[
                  Text(entry.description,
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: AppColors.textPrimary,
                          height: 1.5)),
                  const SizedBox(height: 12),
                ],

                // Image thumbnail
                if (entry.imageUrl != null) ...[
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => _HomeworkImageViewer(
                              imageUrl: entry.imageUrl!,
                              subject: entry.subject)),
                    ),
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.background,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            entry.imageUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) =>
                                progress == null
                                    ? child
                                    : const Center(
                                        child: CircularProgressIndicator()),
                          ),
                          // View overlay
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(children: [
                                const Icon(Icons.zoom_in_rounded,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text('View',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Footer
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${DateFormat('dd MMM yyyy').format(entry.dueDate)}',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _statusColor),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.person_outline_rounded,
                        size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(entry.postedByName,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.textHint)),
                    const Spacer(),
                    if (canDelete)
                      GestureDetector(
                        onTap: () => _confirmDelete(context),
                        child: const Icon(Icons.delete_outline_rounded,
                            size: 20, color: AppColors.error),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Homework',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Delete ${entry.subject} homework?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('homework')
                  .doc(entry.id)
                  .delete();
              if (entry.imageUrl != null) {
                try {
                  await FirebaseStorage.instance
                      .refFromURL(entry.imageUrl!)
                      .delete();
                } catch (_) {}
              }
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
// POST HOMEWORK SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _PostHomeworkSheet extends StatefulWidget {
  final String className;
  final UserModel user;

  const _PostHomeworkSheet({required this.className, required this.user});

  @override
  State<_PostHomeworkSheet> createState() => _PostHomeworkSheetState();
}

class _PostHomeworkSheetState extends State<_PostHomeworkSheet> {
  final _descCtrl = TextEditingController();
  String _subject = _kSubjects.first;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  File? _image;
  bool _isUrgent = false;
  bool _posting = false;
  double _uploadProgress = 0;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImageCamera() async {
    final img = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 80);
    if (img != null) setState(() => _image = File(img.path));
  }

  Future<void> _pickImageGallery() async {
    final img = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) setState(() => _image = File(img.path));
  }

  Future<void> _post() async {
    if (_descCtrl.text.trim().isEmpty && _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Add a description or a photo to post homework')));
      return;
    }
    setState(() => _posting = true);
    try {
      String? imageUrl;

      if (_image != null) {
        final ref = FirebaseStorage.instance.ref().child(
            'homework/${widget.className}/$_subject/${DateTime.now().millisecondsSinceEpoch}.jpg');
        final task = ref.putFile(_image!);
        task.snapshotEvents.listen((s) {
          setState(() => _uploadProgress =
              s.bytesTransferred / (s.totalBytes == 0 ? 1 : s.totalBytes));
        });
        final snap = await task;
        imageUrl = await snap.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('homework').add({
        'subject': _subject,
        'description': _descCtrl.text.trim(),
        'imageUrl': imageUrl,
        'className': widget.className,
        'dueDate': Timestamp.fromDate(_dueDate),
        'postedBy': widget.user.uid,
        'postedByName': widget.user.fullName,
        'postedAt': FieldValue.serverTimestamp(),
        'isUrgent': _isUrgent,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('✅ Homework posted for ${widget.className}!'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _posting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Post Homework',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          Text(widget.className,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),

          // Subject
          Text('Subject',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _subject,
                isExpanded: true,
                items: _kSubjects
                    .map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.poppins(fontSize: 14))))
                    .toList(),
                onChanged: (v) => setState(() => _subject = v!),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Description (text)
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Homework Instructions',
              hintText:
                  'Type homework details here (or attach a photo below)',
              prefixIcon: Icon(Icons.edit_note_rounded),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),

          // Image attachment
          Text('Attach Photo (optional)',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'Take a photo of the board or diary page',
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textHint),
          ),
          const SizedBox(height: 10),

          if (_image == null)
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickImageCamera,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Column(children: [
                      const Icon(Icons.camera_alt_rounded,
                          color: AppColors.accent, size: 28),
                      const SizedBox(height: 6),
                      Text('Camera',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _pickImageGallery,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.3)),
                    ),
                    child: Column(children: [
                      const Icon(Icons.photo_library_rounded,
                          color: AppColors.info, size: 28),
                      const SizedBox(height: 6),
                      Text('Gallery',
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
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(_image!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _image = null),
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 14),

          // Due date
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dueDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) setState(() => _dueDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(children: [
                const Icon(Icons.event_rounded,
                    color: AppColors.accent),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Due Date',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary)),
                  Text(
                    DateFormat('EEEE, dd MMMM yyyy').format(_dueDate),
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                ]),
                const Spacer(),
                const Icon(Icons.edit_calendar_rounded,
                    color: AppColors.textHint, size: 18),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // Urgent toggle
          GestureDetector(
            onTap: () => setState(() => _isUrgent = !_isUrgent),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isUrgent
                    ? AppColors.error.withValues(alpha: 0.06)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _isUrgent
                        ? AppColors.error.withValues(alpha: 0.4)
                        : AppColors.divider),
              ),
              child: Row(children: [
                Icon(Icons.warning_rounded,
                    color:
                        _isUrgent ? AppColors.error : AppColors.textHint),
                const SizedBox(width: 12),
                Text('Mark as Urgent',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _isUrgent
                            ? AppColors.error
                            : AppColors.textPrimary)),
                const Spacer(),
                Switch(
                  value: _isUrgent,
                  onChanged: (v) => setState(() => _isUrgent = v),
                  activeColor: AppColors.error,
                ),
              ]),
            ),
          ),

          const SizedBox(height: 24),
          if (_posting) ...[
            Text(
              _image != null
                  ? 'Uploading image... ${(_uploadProgress * 100).toStringAsFixed(0)}%'
                  : 'Posting...',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _image != null ? _uploadProgress : null,
              backgroundColor: AppColors.divider,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _post,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent),
                icon: const Icon(Icons.send_rounded),
                label: const Text('Post Homework'),
              ),
            ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOMEWORK IMAGE VIEWER (no screenshots)
// ─────────────────────────────────────────────────────────────────────────────
class _HomeworkImageViewer extends StatefulWidget {
  final String imageUrl;
  final String subject;

  const _HomeworkImageViewer(
      {required this.imageUrl, required this.subject});

  @override
  State<_HomeworkImageViewer> createState() => _HomeworkImageViewerState();
}

class _HomeworkImageViewerState extends State<_HomeworkImageViewer> {
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
        backgroundColor: AppColors.accentDark,
        foregroundColor: Colors.white,
        title: Text('${widget.subject} — Homework',
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w600)),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 6.0,
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.accent)),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: AppColors.accentDark,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const Spacer(),
          Text('Pinch to zoom',
              style: GoogleFonts.poppins(
                  color: Colors.white54, fontSize: 12)),
          const Spacer(),
          const SizedBox(width: 48),
        ]),
      ),
    );
  }
}