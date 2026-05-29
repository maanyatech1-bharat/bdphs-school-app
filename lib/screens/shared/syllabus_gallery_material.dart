// lib/screens/shared/syllabus_gallery_material.dart
// Contains: SyllabusScreen, GalleryScreen, StudyMaterialScreen
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/auth_provider.dart';
import '../../services/extended_service.dart';
import '../../services/school_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

// ════════════════════════════════════
//  SYLLABUS TRACKER
// ════════════════════════════════════
class SyllabusScreen extends StatefulWidget {
  final String? className;
  const SyllabusScreen({super.key, this.className});
  @override State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> {
  final _service = ExtendedService();
  late String _selectedClass;
  String _selectedSubject = 'Hindi';
  final _classes = ['Nursery','LKG','UKG','Class 1','Class 2','Class 3','Class 4','Class 5','Class 6','Class 7','Class 8','Class 9','Class 10'];
  final _subjects = ['Hindi','English','Mathematics','Science','Social Science','Sanskrit','Computer','Drawing','Physical Education','General Knowledge'];

  @override
  void initState() {
    super.initState();
    _selectedClass = widget.className ?? 'Class 1';
  }

  void _showAddTopic(BuildContext context, UserModel user) {
    final chapterCtrl = TextEditingController();
    final topicCtrl = TextEditingController();
    final chNoCtrl = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) => Container(
        height: MediaQuery.of(ctx).size.height * 0.60,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 48, height: 4,
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 16, 12, 0), child: Row(children: [
            Text('Add Syllabus Topic', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
          ])),
          const Divider(height: 20),
          Expanded(child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(children: [
              Row(children: [
                Expanded(child: AppTextField(label: 'Chapter No.', hint: '1', controller: chNoCtrl, prefixIcon: Icons.tag_rounded)),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: AppTextField(label: 'Chapter Name', hint: 'Chapter name', controller: chapterCtrl, prefixIcon: Icons.book_rounded)),
              ]),
              const SizedBox(height: 12),
              AppTextField(label: 'Topic / Description', hint: 'Topics covered in this chapter', controller: topicCtrl, prefixIcon: Icons.subject_rounded),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: isSaving ? null : () async {
                  if (chapterCtrl.text.trim().isEmpty) return;
                  setModal(() => isSaving = true);
                  await _service.addSyllabusItem(SyllabusItem(
                    id: '', className: _selectedClass, subject: _selectedSubject,
                    chapter: chapterCtrl.text.trim(), topic: topicCtrl.text.trim(),
                    status: 'pending', teacherId: user.uid, teacherName: user.fullName,
                    chapterNo: int.tryParse(chNoCtrl.text), createdAt: DateTime.now(),
                  ));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.teacherColor, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Add Topic', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
              )),
            ]),
          )),
        ]),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser;
    final isTeacher = user?.role == UserRole.teacher || user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Syllabus Tracker', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.teacherColor, foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: DropdownButtonFormField<String>(
                value: _selectedClass,
                decoration: InputDecoration(filled: true, fillColor: Colors.white.withValues(alpha: 0.15), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                dropdownColor: AppColors.teacherColor, style: GoogleFonts.poppins(color: Colors.white),
                items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedClass = v!),
              )),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(children: _subjects.map((s) => GestureDetector(
                onTap: () => setState(() => _selectedSubject = s),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedSubject == s ? Colors.white : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(s, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _selectedSubject == s ? AppColors.teacherColor : Colors.white)),
                ),
              )).toList()),
            ),
          ]),
        ),
      ),
      body: StreamBuilder<List<SyllabusItem>>(
        stream: _service.getClassSyllabus(_selectedClass, _selectedSubject),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) return ListView.builder(padding: const EdgeInsets.all(16), itemCount: 4, itemBuilder: (_, __) => const ShimmerCard());
          final items = snap.data ?? [];
          final completed = items.where((i) => i.status == 'completed').length;
          final total = items.length;
          return Column(children: [
            if (total > 0) Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Progress: $completed/$total chapters', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('${total > 0 ? (completed / total * 100).toInt() : 0}%', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.teacherColor)),
                ]),
                const SizedBox(height: 8),
                ClipRRect(borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: total > 0 ? completed / total : 0, minHeight: 10, backgroundColor: AppColors.divider, valueColor: const AlwaysStoppedAnimation(AppColors.teacherColor))),
              ]),
            ),
            Expanded(child: items.isEmpty
                ? EmptyState(icon: Icons.menu_book_rounded, title: 'No Syllabus Added', subtitle: isTeacher ? 'Add chapters and topics' : 'Syllabus not added yet')
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      final isCompleted = item.status == 'completed';
                      final isInProgress = item.status == 'in_progress';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(12),
                          border: Border(left: BorderSide(
                            color: isCompleted ? AppColors.success : isInProgress ? AppColors.warning : AppColors.divider,
                            width: 4,
                          )),
                        ),
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              if (item.chapterNo != null) Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(color: AppColors.teacherColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: Center(child: Text('${item.chapterNo}', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.teacherColor))),
                              ),
                              if (item.chapterNo != null) const SizedBox(width: 8),
                              Expanded(child: Text(item.chapter, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, decoration: isCompleted ? TextDecoration.lineThrough : null))),
                            ]),
                            if (item.topic.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(item.topic, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                            if (item.completedAt != null) Text('Completed: ${DateFormat('dd MMM yyyy').format(item.completedAt!)}',
                              style: GoogleFonts.poppins(fontSize: 10, color: AppColors.success)),
                          ])),
                          if (isTeacher) PopupMenuButton<String>(
                            onSelected: (val) => _service.updateSyllabusStatus(item.id, val),
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'pending', child: Text('Pending', style: GoogleFonts.poppins())),
                              PopupMenuItem(value: 'in_progress', child: Text('In Progress', style: GoogleFonts.poppins())),
                              PopupMenuItem(value: 'completed', child: Text('Completed ✓', style: GoogleFonts.poppins())),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCompleted ? AppColors.success.withValues(alpha: 0.1) : isInProgress ? AppColors.warning.withValues(alpha: 0.1) : AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(isCompleted ? '✓ Done' : isInProgress ? '⏳ Active' : '○ Pending',
                                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600,
                                  color: isCompleted ? AppColors.success : isInProgress ? AppColors.warning : AppColors.textHint)),
                            ),
                          ) else Icon(isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: isCompleted ? AppColors.success : AppColors.divider, size: 20),
                        ]),
                      );
                    },
                  )),
          ]);
        },
      ),
      floatingActionButton: isTeacher && user != null
          ? FloatingActionButton.extended(
              onPressed: () => _showAddTopic(context, user),
              backgroundColor: AppColors.teacherColor,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text('Add Topic', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }
}

// ════════════════════════════════════
//  PHOTO GALLERY
// ════════════════════════════════════
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});
  @override State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _service = ExtendedService();
  String _selectedAlbum = 'All';

  void _showAddPhoto(BuildContext context, UserModel user) {
    final titleCtrl = TextEditingController();
    final albumCtrl = TextEditingController();
    String? pickedFilePath;
    String? pickedFileName;
    double uploadProgress = 0;
    bool isSaving = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) => Container(
        height: MediaQuery.of(ctx).size.height * 0.72,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 48, height: 4,
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 16, 12, 0), child: Row(children: [
            const Icon(Icons.add_photo_alternate_rounded, color: AppColors.accent),
            const SizedBox(width: 10),
            Text('Add Photo', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
          ])),
          const Divider(height: 20),
          if (isSaving) LinearProgressIndicator(value: uploadProgress, backgroundColor: Colors.grey[200], color: AppColors.accent),
          Expanded(child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(children: [
              const SizedBox(height: 8),
              AppTextField(label: 'Photo Title *', hint: 'e.g. Annual Day 2024', controller: titleCtrl, prefixIcon: Icons.title_rounded),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: isSaving ? null : () async {
                  final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
                  if (result != null && result.files.isNotEmpty) {
                    setModal(() {
                      pickedFilePath = result.files.first.path;
                      pickedFileName = result.files.first.name;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: pickedFilePath != null ? 180 : 120,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: pickedFilePath != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(pickedFilePath!), fit: BoxFit.cover))
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.add_photo_alternate_rounded, color: AppColors.accent, size: 40),
                        const SizedBox(height: 8),
                        Text('Tap to select photo', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w600)),
                        Text('JPG, PNG supported', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
                      ]),
                ),
              ),
              if (pickedFileName != null) ...[
                const SizedBox(height: 6),
                Text('✅ $pickedFileName', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.success)),
              ],
              const SizedBox(height: 12),
              AppTextField(label: 'Album Name', hint: 'e.g. Sports Day, Annual Day 2024', controller: albumCtrl, prefixIcon: Icons.photo_album_rounded),
              const SizedBox(height: 20),
              isSaving
                ? Column(children: [
                    Text('Uploading... \${(uploadProgress * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.accent)),
                    const SizedBox(height: 8),
                  ])
                : SizedBox(width: double.infinity, child: ElevatedButton.icon(
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty || pickedFilePath == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please add a title and select a photo.')));
                        return;
                      }
                      setModal(() => isSaving = true);
                      try {
                        final album = albumCtrl.text.trim().isEmpty ? 'General' : albumCtrl.text.trim();
                        final fileName = '\${DateTime.now().millisecondsSinceEpoch}_\$pickedFileName';
                        final storagePath = 'gallery/\$album/\$fileName';
                        final ref = FirebaseStorage.instance.ref(storagePath);
                        final task = ref.putFile(File(pickedFilePath!));
                        task.snapshotEvents.listen((s) {
                          setModal(() => uploadProgress = s.bytesTransferred / s.totalBytes);
                        });
                        final snap = await task;
                        final url = await snap.ref.getDownloadURL();
                        await _service.addPhoto(GalleryPhoto(
                          id: '', title: titleCtrl.text.trim(), description: '',
                          imageUrl: url, storagePath: storagePath,
                          albumName: album,
                          addedBy: user.uid, addedByName: user.fullName,
                          createdAt: DateTime.now(),
                        ));
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setModal(() => isSaving = false);
                        if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Upload failed: \$e')));
                      }
                    },
                    icon: const Icon(Icons.upload_rounded, color: Colors.white),
                    label: Text('Upload Photo', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  )),
            ]),
          )),
        ]),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser;
    final canAdd = user?.role == UserRole.teacher || user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Photo Gallery 📸', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.accent, foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<String>>(
        stream: _service.getAlbums(),
        builder: (_, snapAlbums) {
          final albums = ['All', ...snapAlbums.data ?? []];
          if (!albums.contains(_selectedAlbum)) _selectedAlbum = 'All';
          return Column(children: [
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: albums.length,
                itemBuilder: (_, i) {
                  final a = albums[i];
                  final sel = _selectedAlbum == a;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAlbum = a),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.accent : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? AppColors.accent : AppColors.divider),
                      ),
                      child: Text(a, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.textSecondary)),
                    ),
                  );
                },
              ),
            ),
            Expanded(child: StreamBuilder<List<GalleryPhoto>>(
              stream: _service.getGalleryByAlbum(_selectedAlbum == 'All' ? '' : _selectedAlbum),
              builder: (_, snap) {
                List<GalleryPhoto> photos = snap.data ?? [];
                if (_selectedAlbum == 'All') {
                  // load all
                }
                if (photos.isEmpty) return const EmptyState(icon: Icons.photo_library_outlined, title: 'No Photos', subtitle: 'School event photos will appear here');
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.85),
                  itemCount: photos.length,
                  itemBuilder: (_, i) {
                    final p = photos[i];
                    return GestureDetector(
                      onTap: () => _showPhotoDetail(context, p, canAdd),
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)]),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                            child: Image.network(p.imageUrl, fit: BoxFit.cover, width: double.infinity,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.surface,
                                child: const Center(child: Icon(Icons.broken_image_rounded, color: AppColors.textHint, size: 40)),
                              ),
                              loadingBuilder: (_, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                          )),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(p.title, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(p.albumName, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ]),
                      ),
                    );
                  },
                );
              },
            )),
          ]);
        },
      ),
      floatingActionButton: canAdd && user != null
          ? FloatingActionButton(
              onPressed: () => _showAddPhoto(context, user),
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.add_photo_alternate_rounded, color: Colors.white),
            )
          : null,
    );
  }

  void _showPhotoDetail(BuildContext context, GalleryPhoto p, bool canDelete) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.network(p.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 200, child: Icon(Icons.broken_image_rounded, size: 60, color: AppColors.textHint))),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
              Text(p.albumName, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
              Text('Added by ${p.addedByName}', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
              if (canDelete) ...[
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: OutlinedButton.icon(
                  onPressed: () { Navigator.pop(context); _service.deletePhoto(p.id); },
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  label: Text('Delete', style: GoogleFonts.poppins(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                )),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════
//  STUDY MATERIAL SCREEN
// ════════════════════════════════════
class StudyMaterialScreen extends StatefulWidget {
  final String? className;
  const StudyMaterialScreen({super.key, this.className});
  @override State<StudyMaterialScreen> createState() => _StudyMaterialScreenState();
}

class _StudyMaterialScreenState extends State<StudyMaterialScreen> {
  final _service = SchoolService();
  late String _selectedClass;
  final _classes = ['Nursery','LKG','UKG','Class 1','Class 2','Class 3','Class 4','Class 5','Class 6','Class 7','Class 8','Class 9','Class 10'];
  final _subjects = ['Hindi','English','Mathematics','Science','Social Science','Sanskrit','Computer','Drawing','Physical Education','General Knowledge'];

  @override
  void initState() {
    super.initState();
    _selectedClass = widget.className ?? 'Class 1';
  }

  void _showAddMaterial(BuildContext context, UserModel user) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String subject = 'Hindi';
    String fileType = 'note';
    bool isSaving = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 48, height: 4,
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 16, 12, 0), child: Row(children: [
            const Icon(Icons.note_add_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Text('Add Study Material', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
          ])),
          const Divider(height: 20),
          Expanded(child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Type selector
              Row(children: [
                _TypeBtn(label: '📝 Notes', value: 'note', selected: fileType, onTap: () => setModal(() => fileType = 'note'), color: AppColors.primary),
                const SizedBox(width: 8),
                _TypeBtn(label: '🔗 Link', value: 'link', selected: fileType, onTap: () => setModal(() => fileType = 'link'), color: AppColors.info),
                const SizedBox(width: 8),
                _TypeBtn(label: '📄 PDF', value: 'pdf', selected: fileType, onTap: () => setModal(() => fileType = 'pdf'), color: AppColors.error),
              ]),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: subject,
                decoration: InputDecoration(labelText: 'Subject', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.subject_rounded), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.poppins()))).toList(),
                onChanged: (v) => setModal(() => subject = v!),
              ),
              const SizedBox(height: 12),
              AppTextField(label: 'Title', hint: 'e.g. Chapter 3 Notes — Plants', controller: titleCtrl, prefixIcon: Icons.title_rounded),
              const SizedBox(height: 12),
              Text('Content / Notes', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: descCtrl, maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Write notes or description here...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(14),
                ),
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              if (fileType != 'note') ...[
                const SizedBox(height: 12),
                AppTextField(label: fileType == 'link' ? 'URL Link' : 'PDF Link (Google Drive)', hint: 'Paste link here', controller: urlCtrl, prefixIcon: Icons.link_rounded),
              ],
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(
                onPressed: isSaving ? null : () async {
                  if (titleCtrl.text.trim().isEmpty) return;
                  setModal(() => isSaving = true);
                  await _service.addMaterial(StudyMaterial(
                    id: '', className: _selectedClass, subject: subject,
                    title: titleCtrl.text.trim(), description: descCtrl.text.trim(),
                    fileUrl: urlCtrl.text.trim(), fileType: fileType,
                    addedBy: user.uid, addedByName: user.fullName, createdAt: DateTime.now(),
                  ));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                icon: const Icon(Icons.save_rounded, color: Colors.white),
                label: Text('Save Material', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              )),
            ]),
          )),
        ]),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser;
    final canAdd = user?.role == UserRole.teacher || user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Study Material 📖', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: DropdownButtonFormField<String>(
              value: _selectedClass,
              decoration: InputDecoration(filled: true, fillColor: Colors.white.withValues(alpha: 0.15), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
              dropdownColor: AppColors.primary, style: GoogleFonts.poppins(color: Colors.white),
              items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedClass = v!),
            )),
        ),
      ),
      body: StreamBuilder<List<StudyMaterial>>(
        stream: _service.getMaterials(_selectedClass),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) return ListView.builder(padding: const EdgeInsets.all(16), itemCount: 4, itemBuilder: (_, __) => const ShimmerCard());
          final materials = snap.data ?? [];
          if (materials.isEmpty) return EmptyState(
            icon: Icons.note_outlined, title: 'No Study Material',
            subtitle: canAdd ? 'Add notes and materials for students' : 'If you missed class, check here for notes from your teacher',
          );
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: materials.length,
            itemBuilder: (_, i) {
              final m = materials[i];
              final typeColor = m.fileType == 'note' ? AppColors.primary : m.fileType == 'link' ? AppColors.info : AppColors.error;
              final typeIcon = m.fileType == 'note' ? Icons.notes_rounded : m.fileType == 'link' ? Icons.link_rounded : Icons.picture_as_pdf_rounded;
              final typeLabel = m.fileType == 'note' ? 'Notes' : m.fileType == 'link' ? 'Link' : 'PDF';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(typeIcon, color: typeColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: Text(typeLabel, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: typeColor)),
                        ),
                        const SizedBox(width: 6),
                        Text(m.subject, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
                      ]),
                    ])),
                    if (canAdd) IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 16), onPressed: () => _service.deleteMaterial(m.id)),
                  ]),
                  if (m.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Text(m.description, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary, height: 1.6)),
                  ],
                  const SizedBox(height: 8),
                  Text('By ${m.addedByName} • ${DateFormat('dd MMM yyyy').format(m.createdAt)}',
                    style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
                ]),
              );
            },
          );
        },
      ),
      floatingActionButton: canAdd && user != null
          ? FloatingActionButton.extended(
              onPressed: () => _showAddMaterial(context, user),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.note_add_rounded, color: Colors.white),
              label: Text('Add Material', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label, value, selected;
  final VoidCallback onTap;
  final Color color;
  const _TypeBtn({required this.label, required this.value, required this.selected, required this.onTap, required this.color});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected == value ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: selected == value ? Colors.white : color)),
    ),
  );
}