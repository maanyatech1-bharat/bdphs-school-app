// lib/screens/shared/study_material_screen.dart
// Teachers upload study material via Google Drive links
// Students browse and download by class and subject
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../services/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class StudyMaterialScreen extends StatefulWidget {
  final int initialTab; // 0 = All Material, 1 = Upload
  const StudyMaterialScreen({super.key, this.initialTab = 0});
  @override
  State<StudyMaterialScreen> createState() => _StudyMaterialScreenState();
}

class _StudyMaterialScreenState extends State<StudyMaterialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser;
    final canUpload =
        user?.role == UserRole.teacher || user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Study Material',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        bottom: canUpload
            ? TabBar(
                controller: _tabs,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: const [
                  Tab(text: '📚 All Material'),
                  Tab(text: '➕ Upload'),
                ],
              )
            : null,
      ),
      body: canUpload
          ? TabBarView(
              controller: _tabs,
              children: [
                _MaterialListTab(user: user, canDelete: true),
                _UploadTab(user: user),
              ],
            )
          : _MaterialListTab(user: user, canDelete: false),
    );
  }
}

// ─── Material List Tab ────────────────────────────────────────────────────────
class _MaterialListTab extends StatefulWidget {
  final dynamic user;
  final bool canDelete;
  const _MaterialListTab({required this.user, required this.canDelete});
  @override
  State<_MaterialListTab> createState() => _MaterialListTabState();
}

class _MaterialListTabState extends State<_MaterialListTab> {
  String _selectedClass = 'All';
  String _selectedSubject = 'All';
  String _selectedCategory = 'All';
  String _search = '';

  final _classes = ['All', 'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10'];
  final _subjects = ['All', 'Mathematics', 'Science', 'English', 'Hindi',
    'Social Studies', 'Sanskrit', 'Computer', 'General Knowledge'];
  final _categories = ['All', 'Notes', 'Question Paper', 'Sample Paper',
    'Reference Book', 'Worksheet', 'Mind Map', 'Formula Sheet', 'Other'];

  Color _catColor(String c) {
    const map = {
      'Notes': Color(0xFF2563EB), 'Question Paper': Color(0xFFDC2626),
      'Sample Paper': Color(0xFF7C3AED), 'Reference Book': Color(0xFF059669),
      'Worksheet': Color(0xFFD97706), 'Mind Map': Color(0xFF0891B2),
      'Formula Sheet': Color(0xFFEC4899),
    };
    return map[c] ?? AppColors.primary;
  }

  IconData _catIcon(String c) {
    const map = {
      'Notes': Icons.note_rounded, 'Question Paper': Icons.quiz_rounded,
      'Sample Paper': Icons.assignment_rounded,
      'Reference Book': Icons.auto_stories_rounded,
      'Worksheet': Icons.grid_on_rounded, 'Mind Map': Icons.account_tree_rounded,
      'Formula Sheet': Icons.functions_rounded,
    };
    return map[c] ?? Icons.description_rounded;
  }

  @override
  void initState() {
    super.initState();
    if (widget.user is StudentModel) {
      _selectedClass = (widget.user as StudentModel).className;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.user?.role == UserRole.student;

    return Column(children: [
      // Search
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: TextField(
          onChanged: (v) => setState(() => _search = v.toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search material...',
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textHint),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint),
            filled: true, fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ),
      // Filters
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(children: [
          // Row 1: Class + Subject
          Row(children: [
            Expanded(child: _drop('Class', _selectedClass, _classes,
                (v) => setState(() => _selectedClass = v!),
                enabled: !isStudent)),
            const SizedBox(width: 8),
            Expanded(child: _drop('Subject', _selectedSubject, _subjects,
                (v) => setState(() => _selectedSubject = v!))),
          ]),
          const SizedBox(height: 8),
          // Row 2: Type (full width)
          _drop('Material Type', _selectedCategory, _categories,
              (v) => setState(() => _selectedCategory = v!)),
        ]),
      ),
      const Divider(height: 1),

      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: _buildQuery(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
                color: Color(0xFF059669)));
          }
          var docs = snap.data?.docs ?? [];
          if (_selectedSubject != 'All') {
            docs = docs.where((d) =>
                (d.data() as Map)['subject'] == _selectedSubject).toList();
          }
          if (_selectedCategory != 'All') {
            docs = docs.where((d) =>
                (d.data() as Map)['category'] == _selectedCategory).toList();
          }
          if (_search.isNotEmpty) {
            docs = docs.where((d) {
              final data = d.data() as Map;
              return (data['title'] ?? '').toLowerCase().contains(_search) ||
                  (data['subject'] ?? '').toLowerCase().contains(_search);
            }).toList();
          }

          if (docs.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open_rounded, size: 64,
                    color: AppColors.primary.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('No Material Found',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Study material uploaded by teachers\nappears here',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
              ],
            ));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final docId = docs[i].id;
              final cat = d['category'] as String? ?? 'Other';
              final color = _catColor(cat);
              final icon = _catIcon(cat);
              final createdAt = (d['createdAt'] as Timestamp?)?.toDate();

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border(left: BorderSide(color: color, width: 4)),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8)],
                ),
                child: Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['title'] ?? 'Material',
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Wrap(spacing: 6, children: [
                        _badge(cat, color),
                        _badge(d['className'] ?? 'All', const Color(0xFF2563EB)),
                        if ((d['subject'] as String? ?? '').isNotEmpty)
                          _badge(d['subject'], const Color(0xFF7C3AED)),
                      ]),
                      if (createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text('${d['uploadedBy'] ?? 'Teacher'} • '
                            '${DateFormat('dd MMM yyyy').format(createdAt)}',
                            style: GoogleFonts.poppins(
                                fontSize: 10, color: AppColors.textHint)),
                      ],
                    ],
                  )),
                  Column(children: [
                    if ((d['fileUrl'] as String? ?? '').isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.open_in_new_rounded,
                            color: color, size: 22),
                        tooltip: 'Open',
                        onPressed: () => _open(context, d['fileUrl']),
                      ),
                    if (widget.canDelete) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_rounded,
                            color: Color(0xFF2563EB), size: 20),
                        tooltip: 'Edit',
                        onPressed: () => _showEditSheet(context, docId, d),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.error, size: 20),
                        tooltip: 'Delete',
                        onPressed: () => _confirmDelete(context, docId),
                      ),
                    ],
                  ]),
                ]),
              );
            },
          );
        },
      )),
    ]);
  }

  // ── Delete with confirmation ───────────────────────────────────────────────
  Future<void> _confirmDelete(BuildContext context, String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Material',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete this material?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.poppins())),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error),
              child: Text('Delete',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('study_materials').doc(docId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Material deleted'),
            backgroundColor: AppColors.error));
      }
    }
  }

  // ── Edit material bottom sheet ─────────────────────────────────────────────
  void _showEditSheet(BuildContext context, String docId,
      Map<String, dynamic> data) {
    final titleCtrl = TextEditingController(text: data['title'] ?? '');
    final urlCtrl   = TextEditingController(text: data['fileUrl'] ?? '');
    final descCtrl  = TextEditingController(text: data['description'] ?? '');

    final categories = ['Notes', 'Question Paper', 'Sample Paper',
      'Reference Book', 'Worksheet', 'Mind Map', 'Formula Sheet', 'Other'];
    final subjects = ['Mathematics', 'Science', 'English', 'Hindi',
      'Social Studies', 'Sanskrit', 'Computer', 'General Knowledge'];
    final classes = ['All Classes', 'Nursery', 'LKG', 'UKG',
      'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
      'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10'];

    // ✅ Safe fallbacks — use stored value only if it exists in list
    String category = categories.contains(data['category'])
        ? data['category'] : categories.first;
    String subject  = subjects.contains(data['subject'])
        ? data['subject'] : subjects.first;
    String className = classes.contains(data['className'])
        ? data['className'] : classes.first;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),

              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.edit_rounded,
                      color: Color(0xFF059669), size: 20),
                ),
                const SizedBox(width: 12),
                Text('Edit Study Material',
                    style: GoogleFonts.poppins(
                        fontSize: 17, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 20),

              _editField('Title *', titleCtrl, 'Material title'),
              const SizedBox(height: 12),
              _editField('File Link *', urlCtrl,
                  'Paste Google Drive / PDF link'),
              const SizedBox(height: 12),
              _editField('Description', descCtrl,
                  'Optional description', maxLines: 2),
              const SizedBox(height: 12),

              _editDrop('Category', category, categories,
                  (v) => setModal(() => category = v!)),
              const SizedBox(height: 12),
              _editDrop('Subject', subject, subjects,
                  (v) => setModal(() => subject = v!)),
              const SizedBox(height: 12),
              _editDrop('For Class', className, classes,
                  (v) => setModal(() => className = v!)),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : () async {
                    if (titleCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Title is required'),
                              backgroundColor: AppColors.error));
                      return;
                    }
                    setModal(() => saving = true);
                    try {
                      await FirebaseFirestore.instance
                          .collection('study_materials')
                          .doc(docId)
                          .update({
                        'title':       titleCtrl.text.trim(),
                        'fileUrl':     urlCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'category':    category,
                        'subject':     subject,
                        'className':   className,
                      });
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('✅ Material updated!'),
                                backgroundColor: AppColors.success));
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: AppColors.error));
                      }
                    } finally {
                      if (ctx.mounted) setModal(() => saving = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: saving
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Text('Update Material',
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _editField(String label, TextEditingController ctrl, String hint,
      {int maxLines = 1}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textHint),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: Color(0xFF059669), width: 2)),
          ),
        ),
      ]);

  Widget _editDrop(String label, String value, List<String> items,
      void Function(String?) fn) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          style: GoogleFonts.poppins(
              fontSize: 13, color: AppColors.textPrimary),
          items: items.map((i) => DropdownMenuItem(
              value: i,
              child: Text(i,
                  style: GoogleFonts.poppins(fontSize: 13)))).toList(),
          onChanged: fn,
        ),
      ]);

  Stream<QuerySnapshot> _buildQuery() {
    Query q = FirebaseFirestore.instance.collection('study_materials');
    if (widget.user is StudentModel) {
      q = q.where('className', isEqualTo: (widget.user as StudentModel).className);
    } else if (_selectedClass != 'All') {
      q = q.where('className', isEqualTo: _selectedClass);
    }
    return q.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> _open(BuildContext context, String url) async {
    if (url.trim().isEmpty) return;
    String fullUrl = url.trim();
    if (!fullUrl.startsWith('http://') && !fullUrl.startsWith('https://')) {
      fullUrl = 'https://$fullUrl';
    }
    final uri = Uri.tryParse(fullUrl);
    if (uri != null && uri.host.isNotEmpty && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Invalid link. Please paste a valid Google Drive or PDF URL.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3)));
      }
    }
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: GoogleFonts.poppins(
            fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      );

  Widget _drop(String label, String value, List<String> items,
      void Function(String?) onChange, {bool enabled = true}) =>
      DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label, isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textPrimary),
        items: items.map((i) => DropdownMenuItem(
            value: i, child: Text(i, style: GoogleFonts.poppins(fontSize: 12)))).toList(),
        onChanged: enabled ? onChange : null,
      );
}

// ─── Upload Tab ───────────────────────────────────────────────────────────────
class _UploadTab extends StatefulWidget {
  final dynamic user;
  const _UploadTab({required this.user});
  @override
  State<_UploadTab> createState() => _UploadTabState();
}

class _UploadTabState extends State<_UploadTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _selectedClass = 'All Classes';
  String _selectedSubject = 'Mathematics';
  String _selectedCategory = 'Notes';
  bool _saving = false;

  final _classes = ['All Classes', 'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10'];
  final _subjects = ['Mathematics', 'Science', 'English', 'Hindi',
    'Social Studies', 'Sanskrit', 'Computer', 'General Knowledge'];
  final _categories = ['Notes', 'Question Paper', 'Sample Paper',
    'Reference Book', 'Worksheet', 'Mind Map', 'Formula Sheet', 'Other'];

  @override
  void dispose() {
    _titleCtrl.dispose(); _urlCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('study_materials').add({
        'title': _titleCtrl.text.trim(),
        'fileUrl': _urlCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'subject': _selectedSubject,
        'className': _selectedClass,
        'category': _selectedCategory,
        'uploadedBy': widget.user?.fullName ?? 'Teacher',
        'uploadedById': widget.user?.uid ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _titleCtrl.clear(); _urlCtrl.clear(); _descCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Material uploaded!'),
            backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF059669).withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  color: Color(0xFF059669), size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Upload to Google Drive → Share → Copy link → Paste below',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              )),
            ]),
          ),
          const SizedBox(height: 16),

          _f('Title *', 'e.g. Class 10 - Algebra Notes', _titleCtrl,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
          const SizedBox(height: 14),

          _f('File Link *', 'Paste Google Drive / PDF link here', _urlCtrl,
              icon: Icons.link_rounded,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
          const SizedBox(height: 14),

          _f('Description', 'Optional description', _descCtrl, maxLines: 2),
          const SizedBox(height: 14),

          // Category (full width)
          _lw('Category',
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _dec('Type'),
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary),
                items: _categories.map((c) => DropdownMenuItem(
                    value: c, child: Text(c, style: GoogleFonts.poppins(fontSize: 13)))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              )),
          const SizedBox(height: 14),

          // Subject (full width)
          _lw('Subject',
              DropdownButtonFormField<String>(
                value: _selectedSubject,
                decoration: _dec('Subject'),
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary),
                items: _subjects.map((s) => DropdownMenuItem(
                    value: s, child: Text(s, style: GoogleFonts.poppins(fontSize: 13)))).toList(),
                onChanged: (v) => setState(() => _selectedSubject = v!),
              )),
          const SizedBox(height: 14),

          _lw('For Class',
              DropdownButtonFormField<String>(
                value: _selectedClass,
                decoration: _dec('Class'),
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary),
                items: _classes.map((c) => DropdownMenuItem(
                    value: c, child: Text(c, style: GoogleFonts.poppins(fontSize: 13)))).toList(),
                onChanged: (v) => setState(() => _selectedClass = v!),
              )),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text('Upload Material',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: Colors.white)),
            ),
          ),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _f(String label, String hint, TextEditingController ctrl,
      {int maxLines = 1, IconData? icon, String? Function(String?)? validator}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl, maxLines: maxLines, validator: validator,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: _dec(hint).copyWith(
            prefixIcon: icon != null
                ? Icon(icon, size: 18, color: AppColors.textHint) : null),
        ),
      ]);

  Widget _lw(String label, Widget child) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        child,
      ]);

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.textHint),
    filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.divider)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF059669), width: 2)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error)),
  );
}