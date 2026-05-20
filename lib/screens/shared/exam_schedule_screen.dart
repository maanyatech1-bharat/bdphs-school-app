// lib/screens/shared/exam_schedule_screen.dart
// Admin/Teacher: post exam schedule per class
// Student: view exam timetable for their class
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class ExamScheduleScreen extends StatefulWidget {
  const ExamScheduleScreen({super.key});
  @override
  State<ExamScheduleScreen> createState() => _ExamScheduleScreenState();
}

class _ExamScheduleScreenState extends State<ExamScheduleScreen>
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
    final user    = context.watch<AppAuthProvider>().currentUser;
    final canPost = user?.role == UserRole.admin ||
                    user?.role == UserRole.teacher;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        title: Text('Exam Schedule',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700)),
        bottom: canPost
            ? TabBar(
                controller: _tabs,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: const [
                  Tab(text: '📋 View Schedule'),
                  Tab(text: '➕ Add Exam'),
                ],
              )
            : null,
      ),
      body: canPost
          ? TabBarView(
              controller: _tabs,
              children: [
                _ViewTab(user: user),
                _AddTab(user: user),
              ],
            )
          : _ViewTab(user: user),
    );
  }
}

// ─── View Tab ─────────────────────────────────────────────────────────────────
class _ViewTab extends StatefulWidget {
  final dynamic user;
  const _ViewTab({required this.user});
  @override
  State<_ViewTab> createState() => _ViewTabState();
}

class _ViewTabState extends State<_ViewTab> {
  String _selectedClass = 'All';

  static const _classes = ['All', 'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10'];

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    if (user?.role == UserRole.student) {
      _selectedClass = user?.className ?? 'All';
    }
  }

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
  Widget build(BuildContext context) {
    final isStudent = widget.user?.role == UserRole.student;

    return Column(children: [
      // Class filter (disabled for student — auto-set to their class)
      if (!isStudent)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<String>(
            value: _selectedClass,
            decoration: InputDecoration(
              labelText: 'Filter by Class',
              isDense: true,
              prefixIcon: const Icon(Icons.filter_list_rounded, size: 18),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textPrimary),
            items: _classes.map((c) => DropdownMenuItem(
                value: c,
                child: Text(c,
                    style: GoogleFonts.poppins(fontSize: 13)))).toList(),
            onChanged: (v) => setState(() => _selectedClass = v!),
          ),
        ),

      // Exam list
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: _buildQuery(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
                color: Color(0xFFDC2626)));
          }

          var docs = snap.data?.docs ?? [];

          // Sort by exam date ascending (client-side — no index needed)
          docs = List.from(docs)..sort((a, b) {
            final aDate = (a.data() as Map)['examDate'] as Timestamp?;
            final bDate = (b.data() as Map)['examDate'] as Timestamp?;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return aDate.compareTo(bDate);
          });

          if (docs.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_note_outlined, size: 72,
                    color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('No Exam Schedule',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  isStudent
                      ? 'Exam schedule will appear here when posted'
                      : 'Add exams from the "Add Exam" tab',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ));
          }

          // Group by exam type
          final Map<String, List<QueryDocumentSnapshot>> grouped = {};
          for (final d in docs) {
            final type = (d.data() as Map)['examType'] as String? ?? 'Exam';
            grouped.putIfAbsent(type, () => []).add(d);
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exam type header
                  Container(
                    margin: const EdgeInsets.only(bottom: 10, top: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('📝 ${entry.key}',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w800,
                            color: const Color(0xFFDC2626))),
                  ),

                  ...entry.value.map((doc) {
                    final d       = doc.data() as Map<String, dynamic>;
                    final subject = d['subject'] as String? ?? '—';
                    final color   = _subjectColor(subject);
                    final date    = (d['examDate'] as Timestamp?)?.toDate();
                    final cls     = d['className'] as String? ?? '';
                    final time    = d['examTime'] as String? ?? '';
                    final duration = d['duration'] as String? ?? '';
                    final canDelete = widget.user?.role == UserRole.admin ||
                        widget.user?.role == UserRole.teacher;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border(
                            left: BorderSide(color: color, width: 4)),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8)],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          // Date column
                          Container(
                            width: 52,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626)
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(children: [
                              Text(
                                date != null
                                    ? DateFormat('dd').format(date) : '--',
                                style: GoogleFonts.poppins(
                                    fontSize: 20, fontWeight: FontWeight.w900,
                                    color: const Color(0xFFDC2626)),
                              ),
                              Text(
                                date != null
                                    ? DateFormat('MMM').format(date) : '--',
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: const Color(0xFFDC2626),
                                    fontWeight: FontWeight.w700),
                              ),
                              Text(
                                date != null
                                    ? DateFormat('EEE').format(date) : '--',
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: AppColors.textHint),
                              ),
                            ]),
                          ),
                          const SizedBox(width: 12),

                          // Info
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(subject, style: GoogleFonts.poppins(
                                  fontSize: 15, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Wrap(spacing: 6, children: [
                                if (cls.isNotEmpty) _badge(cls, AppColors.primary),
                                if (time.isNotEmpty)
                                  _badge('🕐 $time', const Color(0xFF059669)),
                                if (duration.isNotEmpty)
                                  _badge('⏱ $duration', const Color(0xFFD97706)),
                              ]),
                            ],
                          )),

                          if (canDelete)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: AppColors.error, size: 18),
                              onPressed: () => FirebaseFirestore.instance
                                  .collection('exam_schedule')
                                  .doc(doc.id)
                                  .delete(),
                            ),
                        ]),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              );
            }).toList(),
          );
        },
      )),
    ]);
  }

  Stream<QuerySnapshot> _buildQuery() {
    Query q = FirebaseFirestore.instance.collection('exam_schedule');
    final user = widget.user;
    if (user?.role == UserRole.student) {
      q = q.where('className', isEqualTo: user?.className ?? '');
    } else if (_selectedClass != 'All') {
      q = q.where('className', isEqualTo: _selectedClass);
    }
    return q.snapshots();
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: GoogleFonts.poppins(
            fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      );
}

// ─── Add Exam Tab ─────────────────────────────────────────────────────────────
class _AddTab extends StatefulWidget {
  final dynamic user;
  const _AddTab({required this.user});
  @override
  State<_AddTab> createState() => _AddTabState();
}

class _AddTabState extends State<_AddTab> {
  final _timeCtrl     = TextEditingController();
  final _durationCtrl = TextEditingController();

  String _selectedClass   = 'Class 10';
  String _selectedSubject = 'Mathematics';
  String _selectedExamType = 'Half Yearly';
  DateTime _examDate = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;

  static const _classes = ['All Classes', 'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10'];
  static const _subjects = ['Mathematics', 'Science', 'English', 'Hindi',
    'Social Studies', 'Sanskrit', 'Computer', 'General Knowledge',
    'Drawing', 'Physical Education'];
  static const _examTypes = ['Class Test', 'Half Yearly', 'Annual Exam',
    'Pre-Board', 'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'Practical'];

  @override
  void dispose() {
    _timeCtrl.dispose(); _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
                primary: Color(0xFFDC2626))),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _examDate = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('exam_schedule').add({
        'className':   _selectedClass,
        'subject':     _selectedSubject,
        'examType':    _selectedExamType,
        'examDate':    Timestamp.fromDate(_examDate),
        'examTime':    _timeCtrl.text.trim(),
        'duration':    _durationCtrl.text.trim(),
        'addedBy':     widget.user?.fullName ?? '',
        'createdAt':   FieldValue.serverTimestamp(),
      });
      _timeCtrl.clear(); _durationCtrl.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Exam added!'),
              backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Class
        _lbl('For Class *'),
        _dd('Class', _selectedClass, _classes,
            (v) => setState(() => _selectedClass = v!)),
        const SizedBox(height: 14),

        // Subject
        _lbl('Subject *'),
        _dd('Subject', _selectedSubject, _subjects,
            (v) => setState(() => _selectedSubject = v!)),
        const SizedBox(height: 14),

        // Exam Type
        _lbl('Exam Type *'),
        _dd('Exam Type', _selectedExamType, _examTypes,
            (v) => setState(() => _selectedExamType = v!)),
        const SizedBox(height: 14),

        // Exam Date
        _lbl('Exam Date *'),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFDC2626)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 18, color: Color(0xFFDC2626)),
              const SizedBox(width: 10),
              Text(DateFormat('EEEE, dd MMMM yyyy').format(_examDate),
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: const Color(0xFFDC2626))),
            ]),
          ),
        ),
        const SizedBox(height: 14),

        // Time + Duration row
        Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _lbl('Exam Time'),
              TextField(
                controller: _timeCtrl,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _dec('e.g. 10:00 AM'),
              ),
            ],
          )),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _lbl('Duration'),
              TextField(
                controller: _durationCtrl,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _dec('e.g. 3 Hours'),
              ),
            ],
          )),
        ]),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : const Icon(Icons.add_rounded,
                    color: Colors.white, size: 20),
            label: Text('Add Exam',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ]),
    );
  }

  Widget _lbl(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w700)),
      );

  Widget _dd(String hint, String value, List<String> items,
      void Function(String?) fn) =>
      DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          hintText: hint, isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        ),
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary),
        items: items.map((i) => DropdownMenuItem(
            value: i,
            child: Text(i, style: GoogleFonts.poppins(fontSize: 13)))).toList(),
        onChanged: fn,
      );

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.textHint),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.divider)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2)),
  );
}