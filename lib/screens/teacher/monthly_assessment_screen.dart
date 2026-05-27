// lib/screens/teacher/monthly_assessment_screen.dart
// Comprehensive Monthly Assessment — 9 parameters, max 75 marks
// Components: Written Test | Oral | Assignment | Project |
//             Behavior | Homework | Punctuality | Dress Code | Personal Hygiene
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import 'enter_marks_screen.dart' show gradeFromPct, gradeColor;

class MonthlyAssessmentScreen extends StatefulWidget {
  const MonthlyAssessmentScreen({super.key});
  @override
  State<MonthlyAssessmentScreen> createState() =>
      _MonthlyAssessmentScreenState();
}

class _MonthlyAssessmentScreenState extends State<MonthlyAssessmentScreen>
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
    final canAdd =
        user?.role == UserRole.teacher || user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0891B2),
        foregroundColor: Colors.white,
        title: Text('Monthly Assessment',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            if (canAdd) const Tab(text: '✏️ Add Assessment'),
            const Tab(text: '📋 Report Cards'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          if (canAdd) _AddAssessmentTab(user: user),
          _ReportCardsTab(user: user),
        ],
      ),
    );
  }
}

// ─── Assessment data model ────────────────────────────────────────────────────
class _StudentAssessment {
  // Academic
  int writtenTest;   // out of 20
  int oral;          // out of 10
  int assignment;    // out of 10
  int project;       // out of 10

  // Behavioral & Personal
  String behavior;   // Excellent/Good/Satisfactory/Needs Improvement/Poor
  int homeworkPct;   // 0-100% → score out of 6

  // ✅ NEW: Personal Development Parameters
  String punctuality;   // Excellent/Good/Satisfactory/Needs Improvement/Poor → out of 5
  String dressCode;     // Excellent/Good/Satisfactory/Needs Improvement/Poor → out of 5
  String personalHygiene; // Excellent/Good/Satisfactory/Needs Improvement/Poor → out of 5

  String remarks;

  _StudentAssessment({
    required this.writtenTest,
    required this.oral,
    required this.assignment,
    required this.project,
    required this.behavior,
    required this.homeworkPct,
    required this.punctuality,
    required this.dressCode,
    required this.personalHygiene,
    required this.remarks,
  });

  // Behavior score (out of 4)
  int get behaviorScore => _ratingScore(behavior, 4);
  // Homework score (out of 6)
  int get homeworkScore => (homeworkPct / 100 * 6).round();
  // Punctuality score (out of 5)
  int get punctualityScore => _ratingScore(punctuality, 5);
  // Dress Code score (out of 5)
  int get dressCodeScore => _ratingScore(dressCode, 5);
  // Personal Hygiene score (out of 5)
  int get personalHygieneScore => _ratingScore(personalHygiene, 5);

  int _ratingScore(String rating, int max) {
    switch (rating) {
      case 'Excellent':          return max;
      case 'Good':               return (max * 0.8).round();
      case 'Satisfactory':       return (max * 0.6).round();
      case 'Needs Improvement':  return (max * 0.4).round();
      case 'Poor':               return (max * 0.2).round();
      default:                   return (max * 0.6).round();
    }
  }

  // Total out of 75
  int get totalScore =>
      writtenTest + oral + assignment + project +
      behaviorScore + homeworkScore +
      punctualityScore + dressCodeScore + personalHygieneScore;

  int get maxScore => 20 + 10 + 10 + 10 + 4 + 6 + 5 + 5 + 5; // = 75
}

// ─── Add Assessment Tab ────────────────────────────────────────────────────────
class _AddAssessmentTab extends StatefulWidget {
  final dynamic user;
  const _AddAssessmentTab({required this.user});
  @override
  State<_AddAssessmentTab> createState() => _AddAssessmentTabState();
}

class _AddAssessmentTabState extends State<_AddAssessmentTab> {
  String _selectedClass = 'Class 1';
  String _selectedMonth = 'May 2026';
  String _selectedSubject = 'Mathematics';
  List<Map<String, dynamic>> _students = [];
  bool _loading = false;
  int _selectedStudentIndex = 0;
  bool _saving = false;
  final Map<String, _StudentAssessment> _assessments = {};

  final _classes = [
    'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
  ];
  final _subjects = [
    'Mathematics', 'Science', 'English', 'Hindi',
    'Social Studies', 'Sanskrit', 'Computer', 'General Knowledge',
    'Drawing', 'Physical Education',
  ];
  final _months = [
    'April 2026', 'May 2026', 'June 2026', 'July 2026',
    'August 2026', 'September 2026', 'October 2026',
    'November 2026', 'December 2026',
    'January 2027', 'February 2027', 'March 2027',
  ];

  static const _ratingOptions = [
    'Excellent', 'Good', 'Satisfactory', 'Needs Improvement', 'Poor'
  ];

  Color _ratingColor(String r) {
    switch (r) {
      case 'Excellent':         return const Color(0xFF059669);
      case 'Good':              return const Color(0xFF2563EB);
      case 'Satisfactory':      return const Color(0xFFD97706);
      case 'Needs Improvement': return const Color(0xFFEF4444);
      case 'Poor':              return AppColors.error;
      default:                  return AppColors.primary;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() { _loading = true; _students = []; _assessments.clear(); });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('students')
          .where('className', isEqualTo: _selectedClass)
          .where('approvalStatus', isEqualTo: 'approved')
          .get();

      final students = snap.docs.map((d) => {
        'uid': d.id,
        'name': d.data()['fullName'] ?? '',
        'roll': d.data()['rollNumber'] ?? '',
      }).toList()
        ..sort((a, b) =>
            (a['roll'] as String).compareTo(b['roll'] as String));

      // Load existing assessments
      final existing = await FirebaseFirestore.instance
          .collection('monthly_assessments')
          .where('className', isEqualTo: _selectedClass)
          .where('month', isEqualTo: _selectedMonth)
          .where('subject', isEqualTo: _selectedSubject)
          .get();

      final existingMap = <String, Map>{};
      for (final d in existing.docs) {
        existingMap[d.data()['studentId'] as String] = d.data();
      }

      for (final s in students) {
        final uid = s['uid'] as String;
        final ex = existingMap[uid];
        _assessments[uid] = _StudentAssessment(
          writtenTest: (ex?['writtenTest'] as num?)?.toInt() ?? 0,
          oral: (ex?['oral'] as num?)?.toInt() ?? 0,
          assignment: (ex?['assignment'] as num?)?.toInt() ?? 0,
          project: (ex?['project'] as num?)?.toInt() ?? 0,
          behavior: ex?['behavior'] as String? ?? 'Good',
          homeworkPct: (ex?['homeworkPct'] as num?)?.toInt() ?? 80,
          punctuality: ex?['punctuality'] as String? ?? 'Good',
          dressCode: ex?['dressCode'] as String? ?? 'Good',
          personalHygiene: ex?['personalHygiene'] as String? ?? 'Good',
          remarks: ex?['remarks'] as String? ?? '',
        );
      }

      setState(() {
        _students = students;
        _loading = false;
        _selectedStudentIndex = 0;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final s in _students) {
        final uid = s['uid'] as String;
        final a = _assessments[uid]!;
        final pct = a.maxScore > 0
            ? (a.totalScore / a.maxScore * 100) : 0.0;
        final grade = gradeFromPct(pct.toDouble());

        final docId =
            '${uid}_${_selectedClass}_${_selectedSubject}_${_selectedMonth}'
            .replaceAll(' ', '_');
        final ref = FirebaseFirestore.instance
            .collection('monthly_assessments').doc(docId);
        batch.set(ref, {
          'studentId': uid,
          'studentName': s['name'],
          'rollNumber': s['roll'],
          'className': _selectedClass,
          'subject': _selectedSubject,
          'month': _selectedMonth,
          // Academic
          'writtenTest': a.writtenTest, 'writtenTestMax': 20,
          'oral': a.oral, 'oralMax': 10,
          'assignment': a.assignment, 'assignmentMax': 10,
          'project': a.project, 'projectMax': 10,
          // Behavioral
          'behavior': a.behavior,
          'behaviorScore': a.behaviorScore, 'behaviorMax': 4,
          'homeworkPct': a.homeworkPct,
          'homeworkScore': a.homeworkScore, 'homeworkMax': 6,
          // ✅ NEW: Personal Development
          'punctuality': a.punctuality,
          'punctualityScore': a.punctualityScore, 'punctualityMax': 5,
          'dressCode': a.dressCode,
          'dressCodeScore': a.dressCodeScore, 'dressCodeMax': 5,
          'personalHygiene': a.personalHygiene,
          'personalHygieneScore': a.personalHygieneScore, 'personalHygieneMax': 5,
          // Summary
          'remarks': a.remarks,
          'totalScore': a.totalScore,
          'maxScore': a.maxScore,
          'percentage': double.parse(pct.toStringAsFixed(1)),
          'grade': grade,
          'addedBy': widget.user?.uid ?? '',
          'addedByName': widget.user?.fullName ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Assessments saved for all students!'),
            backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(
          color: Color(0xFF0891B2)));
    }

    return Column(children: [
      // ── Filters ─────────────────────────────────────────────────────
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Row(children: [
            Expanded(child: _drop('Class', _selectedClass, _classes,
                (v) {
              setState(() {
                _selectedClass = v!;
                _selectedStudentIndex = 0;
              });
              _fetchStudents();
            })),
            const SizedBox(width: 10),
            Expanded(child: _drop('Subject', _selectedSubject, _subjects,
                (v) {
              setState(() {
                _selectedSubject = v!;
                _selectedStudentIndex = 0;
              });
              _fetchStudents();
            })),
          ]),
          const SizedBox(height: 10),
          _drop('Month', _selectedMonth, _months, (v) {
            setState(() {
              _selectedMonth = v!;
              _selectedStudentIndex = 0;
            });
            _fetchStudents();
          }),
        ]),
      ),
      const Divider(height: 1),

      if (_students.isEmpty)
        Expanded(child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.people_outline, size: 64,
                color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No students in $_selectedClass',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ]),
        ))
      else
        Expanded(child: Column(children: [
          // Student selector chips
          Container(
            color: AppColors.surface,
            height: 54,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _students.length,
              itemBuilder: (_, i) {
                final sel = i == _selectedStudentIndex;
                final s = _students[i];
                final a = _assessments[s['uid'] as String]!;
                final isDone = a.writtenTest > 0;
                return GestureDetector(
                  onTap: () => setState(() => _selectedStudentIndex = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFF0891B2) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel
                              ? const Color(0xFF0891B2)
                              : AppColors.divider),
                    ),
                    child: Row(children: [
                      if (isDone) ...[
                        const Icon(Icons.check_circle_rounded,
                            size: 12, color: AppColors.success),
                        const SizedBox(width: 4),
                      ],
                      Text(s['name'] as String,
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : AppColors.textPrimary)),
                    ]),
                  ),
                );
              },
            ),
          ),

          // Assessment form
          Expanded(child: _buildForm()),

          // Save all button
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0891B2),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(width: 24, height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text('Save All Assessments',
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: Colors.white)),
              ),
            ),
          ),
        ])),
    ]);
  }

  Widget _buildForm() {
    if (_students.isEmpty) return const SizedBox();
    final s = _students[_selectedStudentIndex];
    final uid = s['uid'] as String;
    final a = _assessments[uid]!;
    final pct = a.maxScore > 0 ? (a.totalScore / a.maxScore * 100) : 0.0;
    final grade = gradeFromPct(pct.toDouble());
    final gColor = gradeColor(grade);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(children: [

        // ── Student score header ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF0891B2), Color(0xFF0E7490)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text((s['name'] as String)[0],
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['name'] as String, style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w800,
                    color: Colors.white)),
                Text('Roll: ${s['roll']}  •  $_selectedClass',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.white70)),
              ],
            )),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${a.totalScore}/${a.maxScore}',
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.w900,
                      color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: gColor, borderRadius: BorderRadius.circular(12)),
                child: Text('$grade  ${pct.toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                        fontSize: 11, fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 14),

        // ════════════════════════════════════
        //  SECTION 1: ACADEMIC PERFORMANCE
        // ════════════════════════════════════
        _sectionTitle('📚 Academic Performance', const Color(0xFF7C3AED)),
        const SizedBox(height: 10),

        // Written Test (20)
        _academicCard('📝 Written Test', 20, a.writtenTest,
            const Color(0xFF7C3AED), (v) {
          setState(() => _assessments[uid]!.writtenTest = v);
        }),
        const SizedBox(height: 10),

        // Oral / Viva (10)
        _academicCard('🎤 Oral / Viva', 10, a.oral,
            const Color(0xFF2563EB), (v) {
          setState(() => _assessments[uid]!.oral = v);
        }),
        const SizedBox(height: 10),

        // Assignment (10)
        _academicCard('📂 Assignment', 10, a.assignment,
            const Color(0xFF059669), (v) {
          setState(() => _assessments[uid]!.assignment = v);
        }),
        const SizedBox(height: 10),

        // Project Work (10)
        _academicCard('🔬 Project Work', 10, a.project,
            const Color(0xFFD97706), (v) {
          setState(() => _assessments[uid]!.project = v);
        }),
        const SizedBox(height: 16),

        // ════════════════════════════════════
        //  SECTION 2: BEHAVIOR & HABITS
        // ════════════════════════════════════
        _sectionTitle('⭐ Behavior & Habits', const Color(0xFFEC4899)),
        const SizedBox(height: 10),

        // Behavior & Discipline (4)
        _ratingCard(
          '🧑‍🏫 Behavior & Discipline',
          'Score: ${a.behaviorScore}/4',
          a.behavior,
          const Color(0xFFEC4899),
          (v) => setState(() => _assessments[uid]!.behavior = v),
        ),
        const SizedBox(height: 10),

        // Homework Completion (6)
        _homeworkCard(a.homeworkPct, uid),
        const SizedBox(height: 16),

        // ════════════════════════════════════
        //  SECTION 3: PERSONAL DEVELOPMENT
        // ════════════════════════════════════
        _sectionTitle('👔 Personal Development', const Color(0xFF0891B2)),
        const SizedBox(height: 10),

        // ✅ Punctuality (5)
        _ratingCard(
          '⏰ Punctuality',
          'Timeliness — Score: ${a.punctualityScore}/5\n'
          'Arriving to school & class on time',
          a.punctuality,
          const Color(0xFF0891B2),
          (v) => setState(() => _assessments[uid]!.punctuality = v),
        ),
        const SizedBox(height: 10),

        // ✅ Dress Code & Uniform (5)
        _ratingCard(
          '👕 Dress Code & Uniform',
          'Proper uniform, neat & tidy — Score: ${a.dressCodeScore}/5\n'
          'Correct uniform, shoes, ID card, tie/belt',
          a.dressCode,
          const Color(0xFF6366F1),
          (v) => setState(() => _assessments[uid]!.dressCode = v),
        ),
        const SizedBox(height: 10),

        // ✅ Personal Hygiene (5)
        _ratingCard(
          '🧼 Personal Hygiene',
          'Grooming standards — Score: ${a.personalHygieneScore}/5\n'
          'Clean nails, tidy hair, neat appearance',
          a.personalHygiene,
          const Color(0xFF14B8A6),
          (v) => setState(() => _assessments[uid]!.personalHygiene = v),
        ),
        const SizedBox(height: 16),

        // ════════════════════════════════════
        //  REMARKS
        // ════════════════════════════════════
        _sectionTitle('💬 Teacher Remarks', AppColors.textSecondary),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: a.remarks,
          maxLines: 3,
          onChanged: (v) => _assessments[uid]!.remarks = v,
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Write remarks, feedback, or suggestions for this student...',
            hintStyle: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textHint),
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _sectionTitle(String title, Color color) => Row(children: [
        Container(width: 4, height: 20,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      ]);

  Widget _academicCard(String title, int max, int value, Color color,
      void Function(int) onChanged) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(title, style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w700))),
            Text('$value / $max', style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          ]),
          Slider(
            value: value.toDouble(),
            min: 0, max: max.toDouble(), divisions: max,
            activeColor: color,
            inactiveColor: color.withValues(alpha: 0.15),
            onChanged: (v) => onChanged(v.toInt()),
          ),
        ]),
      );

  Widget _ratingCard(String title, String subtitle, String value,
      Color color, void Function(String) onChanged) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w700)),
          Text(subtitle, style: GoogleFonts.poppins(
              fontSize: 11, color: AppColors.textHint, height: 1.4)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: _ratingOptions.map((r) {
              final sel = value == r;
              final rColor = _ratingColor(r);
              return GestureDetector(
                onTap: () => onChanged(r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? rColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: rColor, width: sel ? 2 : 1),
                    boxShadow: sel ? [BoxShadow(
                        color: rColor.withValues(alpha: 0.3),
                        blurRadius: 6)] : [],
                  ),
                  child: Text(r, style: GoogleFonts.poppins(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : rColor)),
                ),
              );
            }).toList(),
          ),
        ]),
      );

  Widget _homeworkCard(int homeworkPct, String uid) {
    final a = _assessments[uid]!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(
            color: Color(0xFF0891B2), width: 4)),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('📋 Homework Completion',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w700))),
          Text('${a.homeworkScore}/6', style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w900,
              color: const Color(0xFF0891B2))),
        ]),
        Text('Percentage of homework submitted on time',
            style: GoogleFonts.poppins(
                fontSize: 11, color: AppColors.textHint)),
        const SizedBox(height: 6),
        Row(children: [
          Text('$homeworkPct%', style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w900,
              color: const Color(0xFF0891B2))),
          Expanded(child: Slider(
            value: homeworkPct.toDouble(),
            min: 0, max: 100, divisions: 20,
            activeColor: const Color(0xFF0891B2),
            inactiveColor: const Color(0xFF0891B2).withValues(alpha: 0.15),
            onChanged: (v) => setState(
                () => _assessments[uid]!.homeworkPct = v.toInt()),
          )),
        ]),
      ]),
    );
  }

  Widget _drop(String label, String value, List<String> items,
      void Function(String?) onChange) =>
      DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label, isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textPrimary),
        items: items.map((i) => DropdownMenuItem(
            value: i, child: Text(i, style: GoogleFonts.poppins(fontSize: 12)))).toList(),
        onChanged: onChange,
      );
}

// ─── Report Cards Tab ─────────────────────────────────────────────────────────
class _ReportCardsTab extends StatefulWidget {
  final dynamic user;
  const _ReportCardsTab({required this.user});
  @override
  State<_ReportCardsTab> createState() => _ReportCardsTabState();
}

class _ReportCardsTabState extends State<_ReportCardsTab> {
  String _filterClass = 'All';
  String _filterMonth = 'All';

  final _classes = ['All', 'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10'];
  final _months = ['All', 'April 2026', 'May 2026', 'June 2026',
    'July 2026', 'August 2026', 'September 2026', 'October 2026',
    'November 2026', 'December 2026', 'January 2027',
    'February 2027', 'March 2027'];

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final isStudent = user?.role == UserRole.student;

    return Column(children: [
      if (!isStudent) ...[
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: _drop('Class', _filterClass, _classes,
                (v) => setState(() => _filterClass = v!))),
            const SizedBox(width: 10),
            Expanded(child: _drop('Month', _filterMonth, _months,
                (v) => setState(() => _filterMonth = v!))),
          ]),
        ),
        const Divider(height: 1),
      ],

      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: _buildQuery(user),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          var docs = snap.data?.docs ?? [];
          if (_filterMonth != 'All' && !isStudent) {
            docs = docs.where((d) =>
                (d.data() as Map)['month'] == _filterMonth).toList();
          }
          if (docs.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_late_outlined, size: 64,
                    color: AppColors.primary.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text('No assessments found',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final grade = d['grade'] as String? ?? 'C';
              final gColor = gradeColor(grade);
              final pct = (d['percentage'] as num?)?.toDouble() ?? 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8)],
                ),
                child: Column(children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: gColor.withValues(alpha: 0.07),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                    ),
                    child: Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isStudent)
                            Text(d['studentName'] as String? ?? '—',
                                style: GoogleFonts.poppins(
                                    fontSize: 15, fontWeight: FontWeight.w800)),
                          Text('${d['subject']} • ${d['month']}',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                          Text(d['className'] as String? ?? '',
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: AppColors.textHint)),
                        ],
                      )),
                      Column(children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                              color: gColor, shape: BoxShape.circle),
                          child: Center(child: Text(grade,
                              style: GoogleFonts.poppins(
                                  fontSize: 18, fontWeight: FontWeight.w900,
                                  color: Colors.white))),
                        ),
                        Text('${pct.toStringAsFixed(0)}%',
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: gColor)),
                      ]),
                    ]),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(children: [
                      // Academic section
                      _sectionLabel('📚 Academic', const Color(0xFF7C3AED)),
                      _bar('Written Test', d['writtenTest'] ?? 0,
                          d['writtenTestMax'] ?? 20, const Color(0xFF7C3AED)),
                      _bar('Oral / Viva', d['oral'] ?? 0,
                          d['oralMax'] ?? 10, const Color(0xFF2563EB)),
                      _bar('Assignment', d['assignment'] ?? 0,
                          d['assignmentMax'] ?? 10, const Color(0xFF059669)),
                      _bar('Project Work', d['project'] ?? 0,
                          d['projectMax'] ?? 10, const Color(0xFFD97706)),
                      const SizedBox(height: 10),

                      // Behavior section
                      _sectionLabel('⭐ Behavior & Habits', const Color(0xFFEC4899)),
                      _ratingRow('Behavior & Discipline',
                          d['behavior'] ?? 'Good',
                          d['behaviorScore'] ?? 3, 4),
                      _ratingRow('Homework Completion',
                          '${d['homeworkPct'] ?? 80}%',
                          d['homeworkScore'] ?? 5, 6),
                      const SizedBox(height: 10),

                      // Personal Development section
                      _sectionLabel('👔 Personal Development',
                          const Color(0xFF0891B2)),
                      _ratingRow('Punctuality',
                          d['punctuality'] ?? 'Good',
                          d['punctualityScore'] ?? 4, 5),
                      _ratingRow('Dress Code & Uniform',
                          d['dressCode'] ?? 'Good',
                          d['dressCodeScore'] ?? 4, 5),
                      _ratingRow('Personal Hygiene',
                          d['personalHygiene'] ?? 'Good',
                          d['personalHygieneScore'] ?? 4, 5),
                      const Divider(height: 20),

                      // Total
                      Row(children: [
                        Text('Total Score', style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Text(
                          '${d['totalScore'] ?? 0}/${d['maxScore'] ?? 75}  '
                          '(${pct.toStringAsFixed(0)}%)',
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w900,
                              color: gColor),
                        ),
                      ]),

                      // Remarks
                      if ((d['remarks'] as String? ?? '').isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('💬 ',
                                  style: TextStyle(fontSize: 14)),
                              Expanded(child: Text(d['remarks'] as String,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      height: 1.5))),
                            ],
                          ),
                        ),
                      ],
                    ]),
                  ),
                ]),
              );
            },
          );
        },
      )),
    ]);
  }

  Widget _sectionLabel(String text, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Container(width: 3, height: 14,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          Text(text, style: GoogleFonts.poppins(
              fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ]),
      );

  Widget _bar(String label, dynamic obtained, dynamic max, Color color) {
    final o = (obtained as num?)?.toDouble() ?? 0;
    final m = (max as num?)?.toDouble() ?? 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(children: [
        Row(children: [
          Expanded(child: Text(label, style: GoogleFonts.poppins(
              fontSize: 11, color: AppColors.textSecondary))),
          Text('${o.toInt()}/${m.toInt()}', style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ]),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: m > 0 ? (o / m).clamp(0.0, 1.0) : 0,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 5,
          ),
        ),
      ]),
    );
  }

  Widget _ratingRow(String label, String rating, int score, int max) {
    Color rColor;
    switch (rating) {
      case 'Excellent':         rColor = const Color(0xFF059669); break;
      case 'Good':              rColor = const Color(0xFF2563EB); break;
      case 'Satisfactory':      rColor = const Color(0xFFD97706); break;
      case 'Needs Improvement': rColor = const Color(0xFFEF4444); break;
      default:                  rColor = AppColors.error;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(child: Text(label, style: GoogleFonts.poppins(
            fontSize: 11, color: AppColors.textSecondary))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: rColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(rating, style: GoogleFonts.poppins(
              fontSize: 10, fontWeight: FontWeight.w700, color: rColor)),
        ),
        const SizedBox(width: 8),
        Text('$score/$max', style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w700, color: rColor)),
      ]),
    );
  }

  Stream<QuerySnapshot> _buildQuery(dynamic user) {
    Query q = FirebaseFirestore.instance.collection('monthly_assessments');
    if (user?.role == UserRole.student) {
      q = q.where('studentId', isEqualTo: user?.uid ?? '');
    } else if (_filterClass != 'All') {
      q = q.where('className', isEqualTo: _filterClass);
    }
    return q.snapshots();
  }

  Widget _drop(String label, String value, List<String> items,
      void Function(String?) onChange) =>
      DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label, isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary),
        items: items.map((i) => DropdownMenuItem(
            value: i, child: Text(i, style: GoogleFonts.poppins(fontSize: 13)))).toList(),
        onChanged: onChange,
      );
}