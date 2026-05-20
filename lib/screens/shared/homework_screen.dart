// lib/screens/shared/homework_screen.dart
// Teacher: post homework per class | Student: see only their class homework
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});
  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser;
    final canPost = user?.role == UserRole.teacher || user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Homework',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        bottom: canPost ? TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: '📋 Homework List'),
            Tab(text: '➕ Post Homework'),
          ],
        ) : null,
      ),
      body: canPost
          ? TabBarView(
              controller: _tabs,
              children: [
                _HomeworkListTab(user: user, canDelete: true),
                _PostHomeworkTab(user: user),
              ],
            )
          : _HomeworkListTab(user: user, canDelete: false),
    );
  }
}

// ─── Homework List Tab ────────────────────────────────────────────────────────
class _HomeworkListTab extends StatefulWidget {
  final dynamic user;
  final bool canDelete;
  const _HomeworkListTab({required this.user, required this.canDelete});
  @override
  State<_HomeworkListTab> createState() => _HomeworkListTabState();
}

class _HomeworkListTabState extends State<_HomeworkListTab> {
  String _selectedClass = 'All';
  String _selectedSubject = 'All';

  final _classes = ['All', 'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10'];
  final _subjects = ['All', 'Mathematics', 'Science', 'English', 'Hindi',
    'Social Studies', 'Sanskrit', 'Computer', 'General Knowledge'];

  Color _subjectColor(String s) {
    const map = {
      'Mathematics': Color(0xFF2563EB), 'Science': Color(0xFF059669),
      'English': Color(0xFF7C3AED), 'Hindi': Color(0xFFDC2626),
      'Social Studies': Color(0xFFD97706), 'Sanskrit': Color(0xFF0891B2),
      'Computer': Color(0xFF374151),
    };
    return map[s] ?? AppColors.primary;
  }

  @override
  void initState() {
    super.initState();
    // ✅ FIX: use role check, not 'is StudentModel' (user is dynamic)
    final user = widget.user;
    if (user?.role == UserRole.student) {
      _selectedClass = user?.className ?? 'All';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.user?.role == UserRole.student;

    return Column(children: [
      // Filters
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          _drop('Class', _selectedClass, _classes,
              (v) => setState(() => _selectedClass = v!),
              enabled: !isStudent),
          const SizedBox(height: 8),
          _drop('Subject', _selectedSubject, _subjects,
              (v) => setState(() => _selectedSubject = v!)),
        ]),
      ),
      const Divider(height: 1),

      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: _buildQuery(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
                color: Color(0xFF7C3AED)));
          }
          var docs = snap.data?.docs ?? [];

          // ✅ Sort client-side by dueDate ascending
          docs = List.from(docs)..sort((a, b) {
            final aDate = (a.data() as Map)['dueDate'] as Timestamp?;
            final bDate = (b.data() as Map)['dueDate'] as Timestamp?;
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return aDate.compareTo(bDate);
          });

          if (_selectedSubject != 'All') {
            docs = docs.where((d) =>
                (d.data() as Map)['subject'] == _selectedSubject).toList();
          }

          if (docs.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64,
                    color: AppColors.primary.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('No Homework',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                Text(isStudent
                    ? 'No homework assigned for your class yet'
                    : 'No homework posted yet',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final docId = docs[i].id;
              final subject = d['subject'] as String? ?? 'General';
              final color = _subjectColor(subject);
              final dueDate = (d['dueDate'] as Timestamp?)?.toDate();
              final isOverdue = dueDate != null &&
                  dueDate.isBefore(DateTime.now());
              final daysLeft = dueDate != null
                  ? dueDate.difference(DateTime.now()).inDays
                  : null;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border(left: BorderSide(color: color, width: 4)),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8)],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(d['title'] ?? 'Homework',
                            style: GoogleFonts.poppins(
                                fontSize: 15, fontWeight: FontWeight.w800))),
                        if (widget.canDelete)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.error, size: 20),
                            onPressed: () => FirebaseFirestore.instance
                                .collection('homework').doc(docId).delete(),
                          ),
                      ]),
                      const SizedBox(height: 6),
                      Wrap(spacing: 8, children: [
                        _tag(subject, color),
                        _tag(d['className'] ?? 'All',
                            const Color(0xFF2563EB)),
                        if (isOverdue)
                          _tag('Overdue', AppColors.error)
                        else if (daysLeft != null && daysLeft <= 1)
                          _tag('Due Today!', const Color(0xFFD97706)),
                      ]),
                      if ((d['description'] as String? ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(d['description'],
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: AppColors.textSecondary,
                                height: 1.5)),
                      ],
                      const SizedBox(height: 10),
                      Row(children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 14, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          dueDate != null
                              ? 'Due: ${DateFormat('dd MMM yyyy').format(dueDate)}'
                              : 'No due date',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isOverdue
                                  ? AppColors.error
                                  : AppColors.textHint,
                              fontWeight: isOverdue
                                  ? FontWeight.w700 : FontWeight.w400),
                        ),
                        const Spacer(),
                        Text('By: ${d['postedByName'] ?? 'Teacher'}',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: AppColors.textHint)),
                      ]),
                    ],
                  ),
                ),
              );
            },
          );
        },
      )),
    ]);
  }

  Stream<QuerySnapshot> _buildQuery() {
    final user = widget.user;
    Query q = FirebaseFirestore.instance.collection('homework');

    // ✅ FIX: use role check not 'is StudentModel'
    if (user?.role == UserRole.student) {
      final cls = user?.className ?? '';
      if (cls.isNotEmpty) {
        q = q.where('className', isEqualTo: cls);
      }
    } else if (_selectedClass != 'All') {
      q = q.where('className', isEqualTo: _selectedClass);
    }

    // ✅ FIX: removed orderBy — avoids composite index requirement
    // Sorting done client-side below
    return q.snapshots();
  }

  Widget _tag(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.divider)),
        ),
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary),
        items: items.map((i) => DropdownMenuItem(
            value: i, child: Text(i, style: GoogleFonts.poppins(fontSize: 13)))).toList(),
        onChanged: enabled ? onChange : null,
      );
}

// ─── Post Homework Tab ────────────────────────────────────────────────────────
class _PostHomeworkTab extends StatefulWidget {
  final dynamic user;
  const _PostHomeworkTab({required this.user});
  @override
  State<_PostHomeworkTab> createState() => _PostHomeworkTabState();
}

class _PostHomeworkTabState extends State<_PostHomeworkTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _selectedClass = 'Class 1';
  String _selectedSubject = 'Mathematics';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  bool _saving = false;

  final _classes = ['All Classes', 'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10'];
  final _subjects = ['Mathematics', 'Science', 'English', 'Hindi',
    'Social Studies', 'Sanskrit', 'Computer', 'General Knowledge',
    'Drawing', 'Physical Education'];

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('homework').add({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'subject': _selectedSubject,
        'className': _selectedClass,
        'dueDate': Timestamp.fromDate(_dueDate),
        'postedBy': widget.user?.uid ?? '',
        'postedByName': widget.user?.fullName ?? 'Teacher',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _titleCtrl.clear(); _descCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Homework posted successfully!'),
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
          // For Class — full width
          _labelWrap('For Class *',
              DropdownButtonFormField<String>(
                value: _selectedClass,
                decoration: _dec('Class'),
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary),
                items: _classes.map((c) => DropdownMenuItem(
                    value: c, child: Text(c, style: GoogleFonts.poppins(fontSize: 13)))).toList(),
                onChanged: (v) => setState(() => _selectedClass = v!),
              )),
          const SizedBox(height: 14),

          // Subject — full width
          _labelWrap('Subject *',
              DropdownButtonFormField<String>(
                value: _selectedSubject,
                decoration: _dec('Subject'),
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary),
                items: _subjects.map((s) => DropdownMenuItem(
                    value: s, child: Text(s, style: GoogleFonts.poppins(fontSize: 13)))).toList(),
                onChanged: (v) => setState(() => _selectedSubject = v!),
              )),
          const SizedBox(height: 14),

          // Title
          _labelWrap('Homework Title *',
              TextFormField(
                controller: _titleCtrl,
                style: GoogleFonts.poppins(fontSize: 14),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                decoration: _dec('e.g. Chapter 3 Exercise 2 — Q1 to Q10'),
              )),
          const SizedBox(height: 14),

          // Description
          _labelWrap('Description / Instructions',
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _dec('Describe what students need to do...'),
              )),
          const SizedBox(height: 14),

          // Due date
          _labelWrap('Due Date *',
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: Color(0xFF7C3AED))),
                      child: child!,
                    ),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 18, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 10),
                    Text(DateFormat('dd MMMM yyyy').format(_dueDate),
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: const Color(0xFF7C3AED))),
                    const Spacer(),
                    const Icon(Icons.edit_rounded,
                        size: 16, color: AppColors.textHint),
                  ]),
                ),
              )),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text('Post Homework',
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ]),
            ),
          ),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _labelWrap(String label, Widget child) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary)),
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
        borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error)),
  );
}