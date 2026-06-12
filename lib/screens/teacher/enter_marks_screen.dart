// lib/screens/teacher/enter_marks_screen.dart
// Teacher: enter, view AND edit marks | Student: view own results
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/fcm_service.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

// ── Grade helpers ──────────────────────────────────────────────────────────────
String gradeFromPct(double pct) {
  if (pct >= 90) return 'A+';
  if (pct >= 80) return 'A';
  if (pct >= 70) return 'B+';
  if (pct >= 60) return 'B';
  if (pct >= 50) return 'C';
  if (pct >= 40) return 'D';
  return 'F';
}

Color gradeColor(String g) {
  switch (g) {
    case 'A+': return const Color(0xFF059669);
    case 'A':  return const Color(0xFF10B981);
    case 'B+': return const Color(0xFF2563EB);
    case 'B':  return const Color(0xFF3B82F6);
    case 'C':  return const Color(0xFFD97706);
    case 'D':  return const Color(0xFFF59E0B);
    default:   return AppColors.error;
  }
}

// ── Shared constants ──────────────────────────────────────────────────────────
const _kClasses = [
  'Nursery', 'LKG', 'UKG',
  'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
  'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
];
const _kSubjects = [
  'Mathematics', 'Science', 'English', 'Hindi', 'Social Studies',
  'Sanskrit', 'Computer', 'General Knowledge', 'Drawing', 'Physical Education',
];
// ✅ Class Tests 1–10
const _kClassTestExams = [
  'Class Test 1', 'Class Test 2', 'Class Test 3', 'Class Test 4',
  'Class Test 5', 'Class Test 6', 'Class Test 7', 'Class Test 8',
  'Class Test 9', 'Class Test 10',
];
// ✅ Formal Exams
const _kFormalExams = [
  'F1', 'F2', 'F3', 'Half Yearly',
  'F4', 'F5', 'F6',
  'Pre-Board 1', 'Pre-Board 2', 'Pre-Board 3',
  'Pre-Board 4', 'Pre-Board 5', 'Pre-Board 6',
  'Annual Exam / Final', 'Practical',
];
const _kMonths = [
  'April 2026', 'May 2026', 'June 2026', 'July 2026',
  'August 2026', 'September 2026', 'October 2026',
  'November 2026', 'December 2026',
  'January 2027', 'February 2027', 'March 2027',
];
// ✅ Set used for fast lookup — ALL 10 class tests
final _kClassTestSet = Set<String>.from(_kClassTestExams);

// ─── Screen ────────────────────────────────────────────────────────────────────
class EnterMarksScreen extends StatefulWidget {
  final int initialTab;      // 0 = Enter Marks, 1 = View Results
  final String examCategory; // 'classTests' | 'formal'
  const EnterMarksScreen({
    super.key,
    this.initialTab = 0,
    this.examCategory = 'classTests',
  });
  @override
  State<EnterMarksScreen> createState() => _EnterMarksScreenState();
}

class _EnterMarksScreenState extends State<EnterMarksScreen>
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
    final user     = context.watch<AppAuthProvider>().currentUser;
    final canEnter =
        user?.role == UserRole.teacher || user?.role == UserRole.admin;
    final isStudent  = user?.role == UserRole.student;
    final isClassTest = widget.examCategory == 'classTests';

    // ✅ Student sees "My Results", teacher sees category name
    final title = isStudent
        ? 'My Results'
        : (isClassTest ? 'Class / Unit Tests' : 'Formal Exams');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        title: Text(title,
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            if (canEnter) const Tab(text: '✏️ Enter Marks'),
            // ✅ Student sees "My Results", teacher sees "View & Edit"
            Tab(text: isStudent ? '📊 My Results' : '📊 View & Edit Results'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          if (canEnter)
            _EnterMarksTab(user: user, examCategory: widget.examCategory),
          _ViewResultsTab(
              user: user, canEdit: canEnter, examCategory: widget.examCategory),
        ],
      ),
    );
  }
}

// ─── Enter Marks Tab ──────────────────────────────────────────────────────────
class _EnterMarksTab extends StatefulWidget {
  final dynamic user;
  final String examCategory;
  const _EnterMarksTab({required this.user, required this.examCategory});
  @override
  State<_EnterMarksTab> createState() => _EnterMarksTabState();
}

class _EnterMarksTabState extends State<_EnterMarksTab> {
  String _selectedClass   = 'Class 1';
  String _selectedSubject = 'Mathematics';
  late String _selectedExam;
  String _selectedMonth   = 'April 2026';
  int    _maxMarks        = 20;

  List<Map<String, dynamic>> _students = [];
  Map<String, TextEditingController> _ctrl = {};
  bool _loading = false;
  bool _saving  = false;

  static const _maxOptions = [5, 10, 15, 20, 25, 30, 40, 50, 75, 80, 100];

  List<String> get _examTypes =>
      widget.examCategory == 'classTests' ? _kClassTestExams : _kFormalExams;

  bool get _isClassTest => widget.examCategory == 'classTests';

  @override
  void initState() {
    super.initState();
    _selectedExam = _examTypes.first;
    _fetch();
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) c.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _students = []; });
    for (final c in _ctrl.values) c.dispose();
    _ctrl = {};
    try {
      final snap = await FirebaseFirestore.instance
          .collection('students')
          .where('className', isEqualTo: _selectedClass)
          .where('approvalStatus', isEqualTo: 'approved')
          .get();

      final existing = await FirebaseFirestore.instance
          .collection('results')
          .where('className', isEqualTo: _selectedClass)
          .where('subject', isEqualTo: _selectedSubject)
          .where('examType', isEqualTo: _selectedExam)
          .get();

      final savedMap = <String, double>{};
      int savedMax = _maxMarks;
      for (final d in existing.docs) {
        final data = d.data();
        savedMap[data['studentId'] as String] =
            (data['marksObtained'] as num?)?.toDouble() ?? 0;
        savedMax = (data['totalMarks'] as num?)?.toInt() ?? _maxMarks;
      }
      if (existing.docs.isNotEmpty) setState(() => _maxMarks = savedMax);

      final students = snap.docs.map((d) => {
        'uid': d.id,
        'name': d.data()['fullName'] ?? '',
        'roll': d.data()['rollNumber'] ?? '',
      }).toList()
        ..sort((a, b) =>
            (a['roll'] as String).compareTo(b['roll'] as String));

      for (final s in students) {
        final uid = s['uid'] as String;
        final prev = savedMap[uid];
        _ctrl[uid] = TextEditingController(
            text: prev != null ? prev.toInt().toString() : '');
      }
      setState(() { _students = students; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final s in _students) {
        final uid = s['uid'] as String;
        final raw = _ctrl[uid]?.text.trim() ?? '';
        if (raw.isEmpty) continue;
        final marks = double.tryParse(raw) ?? 0;
        final pct   = _maxMarks > 0 ? (marks / _maxMarks * 100) : 0.0;
        final grade = gradeFromPct(pct);
        // Unique doc ID includes month for class tests
        final docId =
            '${uid}_${_selectedClass}_${_selectedSubject}_$_selectedExam'
            '${_isClassTest ? '_$_selectedMonth' : ''}'
            .replaceAll(' ', '_');
        final ref = FirebaseFirestore.instance
            .collection('results').doc(docId);
        batch.set(ref, {
          'studentId':   uid,
          'studentName': s['name'],
          'rollNumber':  s['roll'],
          'className':   _selectedClass,
          'subject':     _selectedSubject,
          'examType':    _selectedExam,
          'month':       _isClassTest ? _selectedMonth : '',
          'examCategory': widget.examCategory,
          'marksObtained': marks,
          'totalMarks':  _maxMarks,
          'percentage':  double.parse(pct.toStringAsFixed(1)),
          'grade':       grade,
          'addedBy':     widget.user?.uid ?? '',
          'addedByName': widget.user?.fullName ?? '',
          'createdAt':   FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      // Notify each student
      for (final s in _students) {
        final uid = s['uid'] as String;
        final raw = _ctrl[uid]?.text.trim() ?? '';
        if (raw.isEmpty) continue;
        await NotificationSender.notifyUser(
          userId: uid,
          title: '📊 Marks Updated - $_selectedSubject',
          body: "${s['name']}, your $_selectedExam marks for $_selectedSubject have been uploaded.",
          type: 'marks',
        );
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Marks saved successfully!'),
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
    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(children: [

          // ✅ MONTH — shown at TOP prominently (class tests only)
          if (_isClassTest) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_month_rounded,
                    size: 16, color: Color(0xFF7C3AED)),
                const SizedBox(width: 8),
                Text('$_selectedExam  •  $_selectedMonth',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: const Color(0xFF7C3AED))),
              ]),
            ),
            const SizedBox(height: 10),
            // Month dropdown full width
            _dd('📅 Month *', _selectedMonth, _kMonths,
                (v) { setState(() => _selectedMonth = v!); _fetch(); }),
            const SizedBox(height: 10),
          ],

          // Class + Subject
          Row(children: [
            Expanded(child: _dd('Class', _selectedClass, _kClasses,
                (v) { setState(() => _selectedClass = v!); _fetch(); })),
            const SizedBox(width: 10),
            Expanded(child: _dd('Subject', _selectedSubject, _kSubjects,
                (v) { setState(() => _selectedSubject = v!); _fetch(); })),
          ]),
          const SizedBox(height: 10),

          // Exam Type + Max Marks
          Row(children: [
            Expanded(child: _dd('Exam Type', _selectedExam, _examTypes,
                (v) { setState(() => _selectedExam = v!); _fetch(); })),
            const SizedBox(width: 10),
            Expanded(child: DropdownButtonFormField<int>(
              value: _maxMarks,
              decoration: InputDecoration(
                labelText: 'Max Marks', isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textPrimary),
              items: _maxOptions.map((m) => DropdownMenuItem(
                  value: m,
                  child: Text('$m', style: GoogleFonts.poppins()))).toList(),
              onChanged: (v) => setState(() => _maxMarks = v!),
            )),
          ]),
        ]),
      ),
      const Divider(height: 1),

      // Student list
      if (_loading)
        const Expanded(child: Center(child: CircularProgressIndicator(
            color: Color(0xFF7C3AED))))
      else if (_students.isEmpty)
        Expanded(child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64,
                color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No students in $_selectedClass',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        )))
      else
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _students.length,
          itemBuilder: (_, i) {
            final s      = _students[i];
            final uid    = s['uid'] as String;
            final ctrl   = _ctrl[uid]!;
            final raw    = ctrl.text.trim();
            final marks  = double.tryParse(raw) ?? -1;
            final pct    = marks >= 0 ? (marks / _maxMarks * 100) : -1.0;
            final grade  = pct >= 0 ? gradeFromPct(pct) : '—';
            final gColor = pct >= 0 ? gradeColor(grade) : AppColors.textHint;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6)],
              ),
              child: Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child: Center(child: Text(
                      (s['roll'] as String).isNotEmpty ? s['roll'] as String
                          : '${i + 1}',
                      style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w800,
                          color: const Color(0xFF7C3AED)))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(s['name'] as String,
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600))),
                SizedBox(
                  width: 68,
                  child: TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w800),
                    decoration: InputDecoration(
                      hintText: '—', isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: Color(0xFF7C3AED), width: 2)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('/$_maxMarks',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textHint)),
                ),
                Container(
                  width: 40,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: gColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: gColor.withValues(alpha: 0.4)),
                  ),
                  child: Center(child: Text(grade,
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w900,
                          color: gColor))),
                ),
              ]),
            );
          },
        )),

      // Save button
      if (_students.isNotEmpty)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text('Save All Marks',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: Colors.white)),
            ),
          ),
        ),
    ]);
  }

  Widget _dd(String label, String value, List<String> items,
      void Function(String?) fn) =>
      DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label, isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textPrimary),
        items: items.map((i) => DropdownMenuItem(
            value: i,
            child: Text(i, style: GoogleFonts.poppins(fontSize: 12)))).toList(),
        onChanged: fn,
      );
}

// ─── View & Edit Results Tab ──────────────────────────────────────────────────
class _ViewResultsTab extends StatefulWidget {
  final dynamic user;
  final bool canEdit;
  final String examCategory;
  const _ViewResultsTab({
    required this.user,
    required this.canEdit,
    required this.examCategory,
  });
  @override
  State<_ViewResultsTab> createState() => _ViewResultsTabState();
}

class _ViewResultsTabState extends State<_ViewResultsTab> {
  String _filterClass = 'All';
  String _filterExam  = 'All';
  String _filterMonth = 'All';

  bool get _isClassTest => widget.examCategory == 'classTests';

  // ✅ All 10 class tests in filter dropdown
  static const _filterClassTestExams = [
    'All',
    'Class Test 1', 'Class Test 2', 'Class Test 3', 'Class Test 4',
    'Class Test 5', 'Class Test 6', 'Class Test 7', 'Class Test 8',
    'Class Test 9', 'Class Test 10',
  ];
  static const _filterFormalExams = [
    'All', 'F1', 'F2', 'F3', 'Half Yearly',
    'F4', 'F5', 'F6',
    'Pre-Board 1', 'Pre-Board 2', 'Pre-Board 3',
    'Pre-Board 4', 'Pre-Board 5', 'Pre-Board 6',
    'Annual Exam / Final', 'Practical',
  ];
  static const _filterClasses = ['All', 'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10'];
  static const _filterMonths = [
    'All',
    'April 2026', 'May 2026', 'June 2026', 'July 2026',
    'August 2026', 'September 2026', 'October 2026',
    'November 2026', 'December 2026',
    'January 2027', 'February 2027', 'March 2027',
  ];

  List<String> get _exams =>
      _isClassTest ? _filterClassTestExams : _filterFormalExams;

  // ✅ Students see ALL results; teachers see only their category
  List<QueryDocumentSnapshot> _filterByCategory(
      List<QueryDocumentSnapshot> docs) {
    // Students see everything — no category filter
    if (widget.user?.role == UserRole.student) return docs;

    if (_isClassTest) {
      return docs.where((d) => _kClassTestSet
          .contains((d.data() as Map)['examType'])).toList();
    } else {
      return docs.where((d) => !_kClassTestSet
          .contains((d.data() as Map)['examType'])).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.user?.role == UserRole.student;

    return Column(children: [
      // ✅ Hide filters for students — they just see their own results
      if (!isStudent) ...[
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            // Month filter at top for class tests
            if (_isClassTest) ...[
              _dd('📅 Month', _filterMonth, _filterMonths,
                  (v) => setState(() => _filterMonth = v!)),
              const SizedBox(height: 8),
            ],
            Row(children: [
              Expanded(child: _dd('Class', _filterClass, _filterClasses,
                  (v) => setState(() => _filterClass = v!))),
              const SizedBox(width: 10),
              Expanded(child: _dd('Exam', _filterExam, _exams,
                  (v) => setState(() => _filterExam = v!))),
            ]),
          ]),
        ),
        const Divider(height: 1),
      ],

      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: _buildQuery(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          var docs = snap.data?.docs ?? [];
          // ✅ Sort client-side — no composite index needed
          docs = List.from(docs)..sort((a, b) {
            final at = (a.data() as Map)['createdAt'] as Timestamp?;
            final bt = (b.data() as Map)['createdAt'] as Timestamp?;
            if (at == null) return 1;
            if (bt == null) return -1;
            return bt.compareTo(at);
          });
          docs = _filterByCategory(docs);
          if (_filterExam != 'All') {
            docs = docs.where((d) =>
                (d.data() as Map)['examType'] == _filterExam).toList();
          }
          if (_filterMonth != 'All' && _isClassTest) {
            docs = docs.where((d) =>
                (d.data() as Map)['month'] == _filterMonth).toList();
          }

          if (docs.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64,
                    color: AppColors.primary.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text('No results found',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('Enter marks from the Enter Marks tab',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ));
          }

          // Group by Class → Subject
          final byClass = <String, Map<String, List<QueryDocumentSnapshot>>>{};
          for (final d in docs) {
            final data = d.data() as Map;
            final cls  = data['className'] as String? ?? 'Unknown';
            final subj = data['subject']   as String? ?? 'General';
            byClass.putIfAbsent(cls, () => {});
            byClass[cls]!.putIfAbsent(subj, () => []).add(d);
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: byClass.entries.map((clsEntry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Class header
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('📚 ${clsEntry.key}',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w800,
                            color: const Color(0xFF7C3AED))),
                  ),

                  ...clsEntry.value.entries.map((subjEntry) {
                    final subject = subjEntry.key;
                    final results = subjEntry.value;
                    final valid   = results.where((d) =>
                        ((d.data() as Map)['totalMarks'] as num? ?? 0) > 0).toList();
                    final avg     = valid.isEmpty ? 0.0
                        : valid.fold<double>(0, (s, d) =>
                            s + ((d.data() as Map)['percentage'] as num? ?? 0)
                                .toDouble()) / valid.length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(children: [
                            Text(subject, style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                            const Spacer(),
                            Text('Avg: ${avg.toStringAsFixed(0)}%',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ),
                        ...results.map((doc) {
                          final d      = doc.data() as Map<String, dynamic>;
                          final pct    = (d['percentage'] as num?)?.toDouble() ?? 0;
                          final grade  = d['grade'] as String? ?? '—';
                          final gColor = gradeColor(grade);
                          final totalM = (d['totalMarks'] as num?)?.toInt() ?? 0;
                          final month  = d['month'] as String? ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border(left: BorderSide(
                                  color: totalM == 0 ? AppColors.error : gColor,
                                  width: 4)),
                              boxShadow: [BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6)],
                            ),
                            child: Row(children: [
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isStudent)
                                    Text(d['studentName'] as String? ?? '—',
                                        style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700)),
                                  Text(d['examType'] as String? ?? '—',
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                  // ✅ Month badge for class tests
                                  if (month.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(top: 3),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7C3AED)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text('📅 $month',
                                          style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF7C3AED))),
                                    ),
                                  if (totalM == 0)
                                    Text('⚠️ Max marks not set — tap ✏️',
                                        style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: AppColors.error,
                                            fontWeight: FontWeight.w600)),
                                ],
                              )),
                              Text('${(d['marksObtained'] as num?)?.toInt() ?? 0}/$totalM',
                                  style: GoogleFonts.poppins(
                                      fontSize: 16, fontWeight: FontWeight.w900,
                                      color: totalM == 0
                                          ? AppColors.error
                                          : AppColors.textPrimary)),
                              const SizedBox(width: 8),
                              if (totalM > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: gColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: gColor),
                                  ),
                                  child: Text('$grade  ${pct.toStringAsFixed(0)}%',
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: gColor)),
                                ),
                              if (widget.canEdit) ...[
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => _showEditSheet(context, doc.id, d),
                                  child: Container(
                                    width: 34, height: 34,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7C3AED)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: const Color(0xFF7C3AED)
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: const Icon(Icons.edit_rounded,
                                        size: 16, color: Color(0xFF7C3AED)),
                                  ),
                                ),
                              ],
                            ]),
                          );
                        }),
                        const Divider(height: 16),
                      ],
                    );
                  }),
                ],
              );
            }).toList(),
          );
        },
      )),
    ]);
  }

  void _showEditSheet(
      BuildContext context, String docId, Map<String, dynamic> data) {
    final obtained  = (data['marksObtained'] as num?)?.toDouble() ?? 0;
    final total     = (data['totalMarks'] as num?)?.toInt() ?? 0;
    final marksCtrl = TextEditingController(text: obtained.toInt().toString());
    final maxCtrl   = TextEditingController(
        text: total > 0 ? total.toString() : '');
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final maxVal = int.tryParse(maxCtrl.text.trim()) ?? 0;
          final m      = double.tryParse(marksCtrl.text.trim()) ?? 0;
          final pct    = maxVal > 0 ? (m / maxVal * 100) : 0.0;
          final g      = gradeFromPct(pct);
          final gc     = gradeColor(g);

          return Container(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
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
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.edit_rounded,
                      color: Color(0xFF7C3AED), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edit Marks', style: GoogleFonts.poppins(
                        fontSize: 17, fontWeight: FontWeight.w800)),
                    Text(
                      '${data['studentName'] ?? ''}  •  '
                      '${data['subject'] ?? ''}  •  '
                      '${data['examType'] ?? ''}'
                      '${(data['month'] as String? ?? '').isNotEmpty ? '  •  ${data['month']}' : ''}',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                )),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(flex: 3, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Marks Obtained', style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textHint)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: marksCtrl,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      onChanged: (_) => setModal(() {}),
                      style: GoogleFonts.poppins(
                          fontSize: 26, fontWeight: FontWeight.w900),
                      decoration: InputDecoration(
                        hintText: '0', isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFF7C3AED), width: 2)),
                      ),
                    ),
                  ],
                )),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('/', style: GoogleFonts.poppins(
                      fontSize: 28, color: AppColors.textHint,
                      fontWeight: FontWeight.w300)),
                ),
                Expanded(flex: 2, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Max Marks', style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textHint)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: maxCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      onChanged: (_) => setModal(() {}),
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary),
                      decoration: InputDecoration(
                        hintText: '100', isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFF7C3AED), width: 2)),
                      ),
                    ),
                  ],
                )),
                const SizedBox(width: 10),
                Column(children: [
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: gc.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: gc),
                    ),
                    child: Column(children: [
                      Text(g, style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.w900,
                          color: gc)),
                      Text('${pct.toStringAsFixed(0)}%',
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: gc,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ]),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : () async {
                    final rawM = marksCtrl.text.trim();
                    final rawX = maxCtrl.text.trim();
                    if (rawM.isEmpty || rawX.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Enter both marks and max marks'),
                          backgroundColor: AppColors.error));
                      return;
                    }
                    setModal(() => saving = true);
                    try {
                      final marks = double.parse(rawM);
                      final mx    = int.parse(rawX);
                      final p     = mx > 0 ? (marks / mx * 100) : 0.0;
                      await FirebaseFirestore.instance
                          .collection('results').doc(docId).update({
                        'marksObtained': marks,
                        'totalMarks': mx,
                        'percentage': double.parse(p.toStringAsFixed(1)),
                        'grade': gradeFromPct(p),
                        'editedAt': FieldValue.serverTimestamp(),
                      });
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Marks updated!'),
                                backgroundColor: AppColors.success));
                      }
                    } catch (e) {
                      if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'),
                              backgroundColor: AppColors.error));
                    } finally {
                      if (ctx.mounted) setModal(() => saving = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: saving
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Text('Update Marks',
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  Stream<QuerySnapshot> _buildQuery() {
    Query q = FirebaseFirestore.instance.collection('results');
    if (widget.user?.role == UserRole.student) {
      q = q.where('studentId', isEqualTo: widget.user?.uid ?? '');
    } else if (_filterClass != 'All') {
      q = q.where('className', isEqualTo: _filterClass);
    }
    // ✅ No orderBy — avoids composite index requirement; sorted client-side
    return q.snapshots();
  }

  Widget _dd(String label, String value, List<String> items,
      void Function(String?) fn) =>
      DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label, isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        ),
        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textPrimary),
        items: items.map((i) => DropdownMenuItem(
            value: i,
            child: Text(i,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 12)))).toList(),
        onChanged: fn,
      );
}