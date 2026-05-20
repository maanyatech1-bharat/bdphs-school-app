// lib/screens/teacher/teacher_features_screen.dart
// Contains: Enter Marks, Monthly Assessment, Homework, Leave Approvals
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/school_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

// ═════════════════════════════════════════════════════════════════════════════
//  ENTER MARKS SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class EnterMarksScreen extends StatefulWidget {
  const EnterMarksScreen({super.key});
  @override State<EnterMarksScreen> createState() => _EnterMarksScreenState();
}

class _EnterMarksScreenState extends State<EnterMarksScreen> {
  final _service = SchoolService();
  final _authService = AuthService();

  String _selectedClass = 'Class 1';
  String _selectedExam = 'F1';
  String _selectedSubject = 'Hindi';
  List<StudentModel> _students = [];
  bool _loading = false;
  bool _saving = false;

  final Map<String, TextEditingController> _marksCtrl = {};
  final _maxMarksCtrl = TextEditingController(text: '100');

  final List<String> _classes = [
    'Nursery','LKG','UKG','Class 1','Class 2','Class 3','Class 4','Class 5',
    'Class 6','Class 7','Class 8','Class 9','Class 10',
  ];
  final List<String> _exams = [
    'F1','F2','F3','F4','F5','F6','Class Test','Monthly Test','Half Yearly','Annual',
  ];
  final List<String> _subjects = [
    'Hindi','English','Mathematics','Science','Social Science',
    'Sanskrit','Computer','Drawing','Physical Education','General Knowledge',
  ];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    _authService.getStudentsByClass(_selectedClass).listen((students) {
      if (mounted) {
        setState(() {
          _students = students;
          _loading = false;
          for (final s in students) {
            _marksCtrl[s.uid] ??= TextEditingController();
          }
        });
      }
    });
  }

  Future<void> _saveMarks() async {
    final teacher = context.read<AppAuthProvider>().currentUser;
    if (teacher == null) return;
    final max = double.tryParse(_maxMarksCtrl.text) ?? 100;
    setState(() => _saving = true);

    int saved = 0;
    for (final student in _students) {
      final obtained = double.tryParse(_marksCtrl[student.uid]?.text ?? '') ?? 0;
      if (obtained > 0) {
        final result = ResultModel(
          id: '', studentId: student.uid, studentName: student.fullName,
          className: _selectedClass, subject: _selectedSubject,
          examType: _selectedExam, maxMarks: max, obtainedMarks: obtained,
          grade: SchoolService.calculateGrade(obtained, max),
          month: DateFormat('MMMM').format(DateTime.now()),
          year: DateTime.now().year,
          enteredBy: teacher.uid, enteredByName: teacher.fullName,
          createdAt: DateTime.now(),
        );
        final ok = await _service.saveResult(result);
        if (ok) saved++;
      }
    }
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ $saved marks saved successfully!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      for (final c in _marksCtrl.values) c.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Enter Marks', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.teacherColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filters
          Container(
            color: AppColors.teacherColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _DropField(
                      label: 'Class', value: _selectedClass, items: _classes,
                      onChanged: (v) { setState(() => _selectedClass = v!); _loadStudents(); },
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _DropField(
                      label: 'Exam', value: _selectedExam, items: _exams,
                      onChanged: (v) => setState(() => _selectedExam = v!),
                    )),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _DropField(
                      label: 'Subject', value: _selectedSubject, items: _subjects,
                      onChanged: (v) => setState(() => _selectedSubject = v!),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Max Marks', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
                          TextField(
                            controller: _maxMarksCtrl,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              border: InputBorder.none, isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ],
            ),
          ),
          // Students list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? const EmptyState(icon: Icons.people_outline, title: 'No Students', subtitle: 'No approved students in this class')
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _students.length,
                        itemBuilder: (_, i) {
                          final s = _students[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white, borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                            ),
                            child: Row(
                              children: [
                                UserAvatar(photoUrl: s.photoUrl, name: s.fullName, size: 40),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.fullName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                                      Text('Roll: ${s.rollNumber}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textHint)),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: _marksCtrl[s.uid],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      hintStyle: GoogleFonts.poppins(color: AppColors.textHint),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: AppColors.teacherColor, width: 2),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('/ ${_maxMarksCtrl.text}',
                                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textHint)),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: ElevatedButton.icon(
          onPressed: _saving ? null : _saveMarks,
          icon: _saving
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_rounded, color: Colors.white),
          label: Text(_saving ? 'Saving...' : 'Save All Marks',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teacherColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  MONTHLY ASSESSMENT SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class MonthlyAssessmentScreen extends StatefulWidget {
  const MonthlyAssessmentScreen({super.key});
  @override State<MonthlyAssessmentScreen> createState() => _MonthlyAssessmentScreenState();
}

class _MonthlyAssessmentScreenState extends State<MonthlyAssessmentScreen> {
  final _service = SchoolService();
  final _authService = AuthService();
  String _selectedClass = 'Class 1';
  String _selectedMonth = DateFormat('MMMM').format(DateTime.now());
  List<StudentModel> _students = [];
  bool _loading = false;
  bool _saving = false;

  final Map<String, String> _disciplineGrade = {};
  final Map<String, String> _uniformGrade = {};
  final Map<String, String> _punctualityGrade = {};
  final Map<String, TextEditingController> _remarksCtrl = {};
  final Map<String, TextEditingController> _daysCtrl = {};
  final _totalDaysCtrl = TextEditingController(text: '26');

  final List<String> _classes = [
    'Nursery','LKG','UKG','Class 1','Class 2','Class 3','Class 4','Class 5',
    'Class 6','Class 7','Class 8','Class 9','Class 10',
  ];
  final List<String> _months = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];
  final List<String> _grades = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  void _loadStudents() {
    setState(() => _loading = true);
    _authService.getStudentsByClass(_selectedClass).listen((students) {
      if (mounted) {
        setState(() {
          _students = students;
          _loading = false;
          for (final s in students) {
            _disciplineGrade[s.uid] ??= 'A';
            _uniformGrade[s.uid] ??= 'A';
            _punctualityGrade[s.uid] ??= 'A';
            _remarksCtrl[s.uid] ??= TextEditingController();
            _daysCtrl[s.uid] ??= TextEditingController(text: _totalDaysCtrl.text);
          }
        });
      }
    });
  }

  Future<void> _saveAssessments() async {
    final teacher = context.read<AppAuthProvider>().currentUser;
    if (teacher == null) return;
    setState(() => _saving = true);
    int saved = 0;
    for (final student in _students) {
      final assessment = MonthlyAssessment(
        id: '', studentId: student.uid, studentName: student.fullName,
        className: _selectedClass, month: _selectedMonth,
        year: DateTime.now().year,
        daysPresent: int.tryParse(_daysCtrl[student.uid]?.text ?? '') ?? 0,
        totalDays: int.tryParse(_totalDaysCtrl.text) ?? 26,
        disciplineGrade: _disciplineGrade[student.uid] ?? 'A',
        uniformGrade: _uniformGrade[student.uid] ?? 'A',
        punctualityGrade: _punctualityGrade[student.uid] ?? 'A',
        remarks: _remarksCtrl[student.uid]?.text ?? '',
        assessedBy: teacher.uid, assessedByName: teacher.fullName,
        createdAt: DateTime.now(),
      );
      final ok = await _service.saveAssessment(assessment);
      if (ok) saved++;
    }
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ $saved assessments saved!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Monthly Assessment', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.teacherColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.teacherColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(child: _DropField(
                  label: 'Class', value: _selectedClass, items: _classes,
                  onChanged: (v) { setState(() => _selectedClass = v!); _loadStudents(); },
                )),
                const SizedBox(width: 8),
                Expanded(child: _DropField(
                  label: 'Month', value: _selectedMonth, items: _months,
                  onChanged: (v) => setState(() => _selectedMonth = v!),
                )),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Days', style: GoogleFonts.poppins(fontSize: 9, color: Colors.white70)),
                        TextField(
                          controller: _totalDaysCtrl,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                          decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? const EmptyState(icon: Icons.people_outline, title: 'No Students', subtitle: 'No students in this class')
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _students.length,
                        itemBuilder: (_, i) {
                          final s = _students[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white, borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Student header
                                Row(
                                  children: [
                                    UserAvatar(photoUrl: s.photoUrl, name: s.fullName, size: 38),
                                    const SizedBox(width: 10),
                                    Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s.fullName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
                                        Text('Roll: ${s.rollNumber}', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
                                      ],
                                    )),
                                    // Days present
                                    Column(
                                      children: [
                                        Text('Days Present', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textHint)),
                                        SizedBox(
                                          width: 50,
                                          child: TextField(
                                            controller: _daysCtrl[s.uid],
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                                            decoration: InputDecoration(
                                              isDense: true,
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              contentPadding: const EdgeInsets.symmetric(vertical: 6),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                // Grades row
                                Row(
                                  children: [
                                    Expanded(child: _GradeSelector(
                                      label: 'Discipline',
                                      value: _disciplineGrade[s.uid] ?? 'A',
                                      grades: _grades,
                                      onChanged: (v) => setState(() => _disciplineGrade[s.uid] = v),
                                    )),
                                    const SizedBox(width: 8),
                                    Expanded(child: _GradeSelector(
                                      label: 'Uniform',
                                      value: _uniformGrade[s.uid] ?? 'A',
                                      grades: _grades,
                                      onChanged: (v) => setState(() => _uniformGrade[s.uid] = v),
                                    )),
                                    const SizedBox(width: 8),
                                    Expanded(child: _GradeSelector(
                                      label: 'Punctuality',
                                      value: _punctualityGrade[s.uid] ?? 'A',
                                      grades: _grades,
                                      onChanged: (v) => setState(() => _punctualityGrade[s.uid] = v),
                                    )),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _remarksCtrl[s.uid],
                                  decoration: InputDecoration(
                                    hintText: 'Remarks (optional)',
                                    hintStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.textHint),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    isDense: true,
                                  ),
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        color: Colors.white,
        child: ElevatedButton.icon(
          onPressed: _saving ? null : _saveAssessments,
          icon: _saving
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.assessment_rounded, color: Colors.white),
          label: Text(_saving ? 'Saving...' : 'Save Assessments',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teacherColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  HOMEWORK SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class HomeworkScreen extends StatefulWidget {
  final String? className;
  final bool isTeacher;
  const HomeworkScreen({super.key, this.className, this.isTeacher = true});
  @override State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  final _service = SchoolService();
  late String _selectedClass;

  final List<String> _classes = [
    'Nursery','LKG','UKG','Class 1','Class 2','Class 3','Class 4','Class 5',
    'Class 6','Class 7','Class 8','Class 9','Class 10',
  ];

  @override
  void initState() {
    super.initState();
    _selectedClass = widget.className ?? 'Class 1';
  }

  void _showPostSheet(BuildContext context, String teacherUid, String teacherName) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String subject = 'Hindi';
    DateTime dueDate = DateTime.now().add(const Duration(days: 1));
    bool isPosting = false;

    final subjects = ['Hindi','English','Mathematics','Science','Social Science',
      'Sanskrit','Computer','Drawing','Physical Education','General Knowledge'];

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) => Container(
        height: MediaQuery.of(ctx).size.height * 0.80,
        decoration: const BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(margin: const EdgeInsets.only(top: 12), width: 48, height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(children: [
                Text('Post Homework', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
              ]),
            ),
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  AppTextField(label: 'Title', hint: 'Homework title', controller: titleCtrl, prefixIcon: Icons.title_rounded),
                  const SizedBox(height: 12),
                  Text('Subject', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: subject,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                    items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.poppins()))).toList(),
                    onChanged: (v) => setModal(() => subject = v!),
                  ),
                  const SizedBox(height: 12),
                  Text('Description', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: descCtrl, maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Describe the homework...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx, initialDate: dueDate,
                        firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) setModal(() => dueDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.divider),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_rounded, color: AppColors.textSecondary, size: 18),
                        const SizedBox(width: 10),
                        Text('Due: ${DateFormat('dd MMM, yyyy').format(dueDate)}',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                        const Spacer(),
                        const Icon(Icons.edit_rounded, color: AppColors.textHint, size: 16),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isPosting ? null : () async {
                        if (titleCtrl.text.trim().isEmpty) return;
                        setModal(() => isPosting = true);
                        final hw = HomeworkModel(
                          id: '', className: _selectedClass, subject: subject,
                          title: titleCtrl.text.trim(), description: descCtrl.text.trim(),
                          dueDate: dueDate, postedBy: teacherUid,
                          postedByName: teacherName, createdAt: DateTime.now(),
                        );
                        await _service.postHomework(hw);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teacherColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isPosting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Post Homework', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Homework', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.teacherColor,
        foregroundColor: Colors.white,
        bottom: widget.isTeacher ? PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: DropdownButtonFormField<String>(
              value: _selectedClass,
              decoration: InputDecoration(
                filled: true, fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              dropdownColor: AppColors.primary,
              style: GoogleFonts.poppins(color: Colors.white),
              items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedClass = v!),
            ),
          ),
        ) : null,
      ),
      body: StreamBuilder<List<HomeworkModel>>(
        stream: _service.getHomework(_selectedClass),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(padding: const EdgeInsets.all(16), itemCount: 4, itemBuilder: (_, __) => const ShimmerCard());
          }
          final homeworks = snapshot.data ?? [];
          if (homeworks.isEmpty) {
            return const EmptyState(icon: Icons.assignment_outlined, title: 'No Homework', subtitle: 'No homework assigned yet');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: homeworks.length,
            itemBuilder: (_, i) {
              final hw = homeworks[i];
              final isOverdue = hw.dueDate.isBefore(DateTime.now());
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isOverdue ? AppColors.error.withValues(alpha: 0.3) : AppColors.divider),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                    decoration: BoxDecoration(
                      color: AppColors.teacherColor.withValues(alpha: 0.06),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.teacherColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(hw.subject, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.teacherColor)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(hw.title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700))),
                      if (widget.isTeacher) IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                        onPressed: () => _service.deleteHomework(hw.id),
                      ),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (hw.description.isNotEmpty)
                        Text(hw.description, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary, height: 1.5)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.calendar_today_rounded, size: 14,
                          color: isOverdue ? AppColors.error : AppColors.textHint),
                        const SizedBox(width: 4),
                        Text('Due: ${DateFormat('dd MMM, yyyy').format(hw.dueDate)}',
                          style: GoogleFonts.poppins(fontSize: 12, color: isOverdue ? AppColors.error : AppColors.textHint,
                            fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400)),
                        const SizedBox(width: 8),
                        if (isOverdue) Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text('Overdue', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.error)),
                        ),
                        const Spacer(),
                        Text('By ${hw.postedByName}', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
                      ]),
                    ]),
                  ),
                ]),
              );
            },
          );
        },
      ),
      floatingActionButton: widget.isTeacher && user != null
          ? FloatingActionButton.extended(
              onPressed: () => _showPostSheet(context, user.uid, user.fullName),
              backgroundColor: AppColors.teacherColor,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text('Add Homework', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  LEAVE APPROVALS SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class LeaveApprovalsScreen extends StatefulWidget {
  const LeaveApprovalsScreen({super.key});
  @override State<LeaveApprovalsScreen> createState() => _LeaveApprovalsScreenState();
}

class _LeaveApprovalsScreenState extends State<LeaveApprovalsScreen> {
  final _service = SchoolService();
  String _selectedClass = 'Class 1';
  final List<String> _classes = [
    'Nursery','LKG','UKG','Class 1','Class 2','Class 3','Class 4','Class 5',
    'Class 6','Class 7','Class 8','Class 9','Class 10',
  ];

  @override
  Widget build(BuildContext context) {
    final teacher = context.read<AppAuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Leave Approvals', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.teacherColor,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: DropdownButtonFormField<String>(
              value: _selectedClass,
              decoration: InputDecoration(
                filled: true, fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              dropdownColor: AppColors.primary,
              style: GoogleFonts.poppins(color: Colors.white),
              items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedClass = v!),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<LeaveModel>>(
        stream: _service.getPendingLeaves(_selectedClass),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(padding: const EdgeInsets.all(16), itemCount: 4, itemBuilder: (_, __) => const ShimmerCard());
          }
          final leaves = snapshot.data ?? [];
          if (leaves.isEmpty) {
            return const EmptyState(icon: Icons.event_available_rounded, title: 'No Pending Leaves', subtitle: 'All leave requests are reviewed');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: leaves.length,
            itemBuilder: (_, i) {
              final leave = leaves[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const CircleAvatar(radius: 18, backgroundColor: AppColors.warning, child: Icon(Icons.person_rounded, color: Colors.white, size: 18)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(leave.studentName, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
                      Text('${leave.className} • ${leave.days} day(s)',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textHint)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Pending', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Text('Reason:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  Text(leave.reason, style: GoogleFonts.poppins(fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.date_range_rounded, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text('${DateFormat('dd MMM').format(leave.fromDate)} — ${DateFormat('dd MMM yyyy').format(leave.toDate)}',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textHint)),
                    const SizedBox(width: 4),
                    Text('(${leave.days} days)', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(
                      onPressed: () async {
                        await _service.reviewLeave(leave.id, 'rejected', teacher?.uid ?? '', teacher?.fullName ?? '');
                      },
                      icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                      label: Text('Reject', style: GoogleFonts.poppins(color: AppColors.error, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: ElevatedButton.icon(
                      onPressed: () async {
                        await _service.reviewLeave(leave.id, 'approved', teacher?.uid ?? '', teacher?.fullName ?? '');
                      },
                      icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                      label: Text('Approve', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    )),
                  ]),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── HELPERS ──────────────────────────────────────────────────────────────────
class _DropField extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final void Function(String?) onChanged;
  const _DropField({required this.label, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
      DropdownButton<String>(
        value: value, isExpanded: true, underline: const SizedBox(),
        dropdownColor: AppColors.primary,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white),
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        onChanged: onChanged,
      ),
    ]),
  );
}

class _GradeSelector extends StatelessWidget {
  final String label, value;
  final List<String> grades;
  final void Function(String) onChanged;
  const _GradeSelector({required this.label, required this.value, required this.grades, required this.onChanged});

  Color _gradeColor(String g) {
    switch (g) {
      case 'A': return AppColors.success;
      case 'B': return AppColors.info;
      case 'C': return AppColors.warning;
      case 'D': return AppColors.error;
      default: return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
    const SizedBox(height: 4),
    Row(
      children: grades.map((g) => GestureDetector(
        onTap: () => onChanged(g),
        child: Container(
          margin: const EdgeInsets.only(right: 4),
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: value == g ? _gradeColor(g) : _gradeColor(g).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _gradeColor(g), width: value == g ? 0 : 1),
          ),
          child: Center(child: Text(g,
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700,
              color: value == g ? Colors.white : _gradeColor(g)))),
        ),
      )).toList(),
    ),
  ]);
}