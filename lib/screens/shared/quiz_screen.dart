// lib/screens/shared/quiz_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/auth_provider.dart';
import '../../services/school_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

// ════════════════════════════════════════════════════
//  QUIZ LIST SCREEN
// ════════════════════════════════════════════════════
class QuizListScreen extends StatefulWidget {
  final String? className;
  const QuizListScreen({super.key, this.className});
  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  final _service = SchoolService();

  final List<String> _classes = [
    'All', 'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
  ];

  final List<String> _subjects = [
    'All', 'Hindi', 'English', 'Mathematics', 'Science',
    'Social Science', 'Sanskrit', 'Computer', 'Drawing',
  ];

  late String _selectedClass;
  String _selectedSubject = 'All';

  @override
  void initState() {
    super.initState();
    _selectedClass = widget.className ?? 'All';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser;
    final isTeacherOrAdmin =
        user?.role == UserRole.teacher || user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Quizzes',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Filter bar — FIXED overflow ─────────────────────────
          Container(
            color: const Color(0xFFD97706),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: _FilterDropdown(
                    label: 'Subject',
                    value: _selectedSubject,
                    items: _subjects,
                    onChanged: (v) => setState(() => _selectedSubject = v!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterDropdown(
                    label: 'Class',
                    value: _selectedClass,
                    items: _classes,
                    onChanged: (v) => setState(() => _selectedClass = v!),
                  ),
                ),
              ],
            ),
          ),

          // ── Quiz list ───────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<QuizModel>>(
              stream: _selectedClass == 'All'
                  ? _service.getAllQuizzes()
                  : _service.getQuizzes(_selectedClass),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 4,
                    itemBuilder: (_, __) => const ShimmerCard(),
                  );
                }

                var quizzes = snap.data ?? [];
                if (_selectedSubject != 'All') {
                  quizzes = quizzes
                      .where((q) => q.subject == _selectedSubject)
                      .toList();
                }

                if (quizzes.isEmpty) {
                  return EmptyState(
                    icon: Icons.quiz_outlined,
                    title: 'No Quizzes Yet',
                    subtitle: isTeacherOrAdmin
                        ? 'Tap + to create a quiz for your students'
                        : 'No quizzes available right now',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: quizzes.length,
                  itemBuilder: (_, i) => _QuizCard(
                    quiz: quizzes[i],
                    user: user,
                    isTeacherOrAdmin: isTeacherOrAdmin,
                    onDelete: () => _service.deleteQuiz(quizzes[i].id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isTeacherOrAdmin && user != null
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateQuizScreen(
                    className: _selectedClass == 'All' ? 'Class 1' : _selectedClass,
                    teacher: user,
                  ),
                ),
              ),
              backgroundColor: const Color(0xFFD97706),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text('Create Quiz',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }
}

// ── Filter Dropdown — compact, no overflow ────────────────────────────────────
class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFFB45309),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white, size: 18),
          style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          selectedItemBuilder: (ctx) => items
              .map((item) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.length > 10 ? item.substring(0, 10) : item,
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item,
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 13)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
//  QUIZ CARD — fully fixed
// ════════════════════════════════════════════════════
class _QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final UserModel? user;
  final bool isTeacherOrAdmin;
  final VoidCallback onDelete;

  const _QuizCard({
    required this.quiz,
    required this.user,
    required this.isTeacherOrAdmin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.quiz_rounded,
                      color: Color(0xFFD97706), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.title,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${quiz.subject}  •  ${quiz.chapter.isNotEmpty ? quiz.chapter : quiz.className}',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isTeacherOrAdmin)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error, size: 20),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        title: Text('Delete Quiz?',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700)),
                        content: Text(
                            'This will also delete all student attempts.',
                            style: GoogleFonts.poppins()),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel',
                                  style: GoogleFonts.poppins())),
                          ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                onDelete();
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error),
                              child: Text('Delete',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Info chips ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _InfoChip(Icons.help_outline_rounded,
                    '${quiz.questions.length} Qs', const Color(0xFFD97706)),
                _InfoChip(Icons.timer_outlined,
                    '${quiz.timeLimitMinutes} min', const Color(0xFF2563EB)),
                _InfoChip(Icons.class_rounded, quiz.className,
                    const Color(0xFF059669)),
                _InfoChip(Icons.person_outline_rounded, quiz.createdByName,
                    AppColors.primary),
              ],
            ),
          ),

          // ── Date + Action button ─────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 11, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd MMM yyyy').format(quiz.createdAt),
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textHint),
                ),
                const Spacer(),
                if (isTeacherOrAdmin)
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => QuizAttemptsScreen(quiz: quiz)),
                    ),
                    icon: const Icon(Icons.bar_chart_rounded,
                        color: Colors.white, size: 14),
                    label: Text('Results',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  )
                else
                  _StudentQuizButton(quiz: quiz, user: user),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Student Start Quiz Button ─────────────────────────────────────────────────
class _StudentQuizButton extends StatelessWidget {
  final QuizModel quiz;
  final UserModel? user;
  const _StudentQuizButton({required this.quiz, required this.user});

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();
    return FutureBuilder<bool>(
      future: SchoolService().hasAttempted(quiz.id, user!.uid),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFFD97706)));
        }
        final attempted = snap.data ?? false;
        return ElevatedButton.icon(
          onPressed: attempted
              ? null
              : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TakeQuizScreen(quiz: quiz, student: user!),
                    ),
                  ),
          icon: Icon(
              attempted
                  ? Icons.check_circle_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 14),
          label: Text(
              attempted ? 'Done' : 'Start →',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                attempted ? AppColors.textHint : const Color(0xFFD97706),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        );
      },
    );
  }
}

// ── Info Chip ─────────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.25))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ]),
      );
}

// ════════════════════════════════════════════════════
//  CREATE QUIZ SCREEN
// ════════════════════════════════════════════════════
class CreateQuizScreen extends StatefulWidget {
  final String className;
  final UserModel teacher;
  const CreateQuizScreen(
      {super.key, required this.className, required this.teacher});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _titleCtrl = TextEditingController();
  final _chapterCtrl = TextEditingController();
  String _subject = 'Hindi';
  late String _selectedClass;
  int _timeLimit = 10;
  final List<_QuestionEntry> _questions = [];
  bool _saving = false;

  final List<String> _subjects = [
    'Hindi', 'English', 'Mathematics', 'Science',
    'Social Science', 'Sanskrit', 'Computer', 'Drawing',
  ];
  final List<String> _classes = [
    'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
  ];

  @override
  void initState() {
    super.initState();
    _selectedClass = widget.className;
    if (!_classes.contains(_selectedClass)) _selectedClass = 'Class 1';
  }

  void _addQuestion() => setState(() => _questions.add(_QuestionEntry()));

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a quiz title')));
      return;
    }
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one question')));
      return;
    }
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.questionCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Question ${i + 1} is empty')));
        return;
      }
      for (int j = 0; j < 4; j++) {
        if (q.optionCtrls[j].text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Q${i + 1}: Option ${String.fromCharCode(65 + j)} is empty')));
          return;
        }
      }
    }

    setState(() => _saving = true);
    final questions = _questions
        .map((q) => QuizQuestion(
              question: q.questionCtrl.text.trim(),
              options: q.optionCtrls.map((c) => c.text.trim()).toList(),
              correctIndex: q.correctIndex,
            ))
        .toList();

    await SchoolService().createQuiz(QuizModel(
      id: '',
      className: _selectedClass,
      subject: _subject,
      chapter: _chapterCtrl.text.trim(),
      title: _titleCtrl.text.trim(),
      createdBy: widget.teacher.uid,
      createdByName: widget.teacher.fullName,
      questions: questions,
      timeLimitMinutes: _timeLimit,
      createdAt: DateTime.now(),
    ));

    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Quiz published successfully!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _chapterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Create Quiz',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Publish',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quiz Details',
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFD97706))),
                const SizedBox(height: 14),
                AppTextField(
                    label: 'Quiz Title *',
                    hint: 'e.g. Chapter 3 – Plants Quiz',
                    controller: _titleCtrl,
                    prefixIcon: Icons.quiz_rounded),
                const SizedBox(height: 12),
                AppTextField(
                    label: 'Chapter / Topic',
                    hint: 'e.g. Chapter 3 – Plants',
                    controller: _chapterCtrl,
                    prefixIcon: Icons.book_outlined),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _subject,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Subject',
                        labelStyle: GoogleFonts.poppins(fontSize: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.subject_rounded, size: 18),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 14),
                      ),
                      items: _subjects
                          .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(fontSize: 12))))
                          .toList(),
                      onChanged: (v) => setState(() => _subject = v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedClass,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Class',
                        labelStyle: GoogleFonts.poppins(fontSize: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon:
                            const Icon(Icons.class_rounded, size: 18),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 14),
                      ),
                      items: _classes
                          .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(fontSize: 12))))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedClass = v!),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.timer_rounded,
                        color: Color(0xFFD97706), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text('Time Limit',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  Expanded(
                    child: Slider(
                      value: _timeLimit.toDouble(),
                      min: 5,
                      max: 60,
                      divisions: 11,
                      label: '$_timeLimit min',
                      activeColor: const Color(0xFFD97706),
                      onChanged: (v) =>
                          setState(() => _timeLimit = v.toInt()),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$_timeLimit min',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFD97706))),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_questions.isNotEmpty) ...[
            Row(children: [
              Text('Questions',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${_questions.length}',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFD97706))),
              ),
            ]),
            const SizedBox(height: 12),
          ],
          ..._questions.asMap().entries.map((e) => _QuestionCard(
                index: e.key,
                entry: e.value,
                onRemove: () => setState(() => _questions.removeAt(e.key)),
              )),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addQuestion,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
            label: Text('Add Question',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFD97706), width: 1.5),
              foregroundColor: const Color(0xFFD97706),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          if (_questions.isNotEmpty)
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.publish_rounded, color: Colors.white),
              label: Text(_saving ? 'Publishing...' : 'Publish Quiz',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Question Entry ────────────────────────────────────────────────────────────
class _QuestionEntry {
  final questionCtrl = TextEditingController();
  final optionCtrls = List.generate(4, (_) => TextEditingController());
  int correctIndex = 0;
}

// ── Question Card ─────────────────────────────────────────────────────────────
class _QuestionCard extends StatefulWidget {
  final int index;
  final _QuestionEntry entry;
  final VoidCallback onRemove;
  const _QuestionCard(
      {required this.index, required this.entry, required this.onRemove});

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                  color: Color(0xFFD97706), shape: BoxShape.circle),
              child: Center(
                child: Text('${widget.index + 1}',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
            ),
            const SizedBox(width: 8),
            Text('Question ${widget.index + 1}',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD97706))),
            const Spacer(),
            IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.error, size: 20),
                onPressed: widget.onRemove),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: widget.entry.questionCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Type your question here...',
              hintStyle:
                  GoogleFonts.poppins(color: AppColors.textHint, fontSize: 13),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFFD97706), width: 2)),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.touch_app_rounded,
                size: 13, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text('Tap circle to mark correct answer',
                style:
                    GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
          ]),
          const SizedBox(height: 8),
          ...List.generate(
              4,
              (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      GestureDetector(
                        onTap: () =>
                            setState(() => widget.entry.correctIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: widget.entry.correctIndex == i
                                ? AppColors.success
                                : AppColors.background,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: widget.entry.correctIndex == i
                                    ? AppColors.success
                                    : AppColors.divider,
                                width: 2),
                          ),
                          child: Center(
                            child: widget.entry.correctIndex == i
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 16)
                                : Text(String.fromCharCode(65 + i),
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textSecondary)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: widget.entry.optionCtrls[i],
                          decoration: InputDecoration(
                            hintText: 'Option ${String.fromCharCode(65 + i)}',
                            hintStyle: GoogleFonts.poppins(
                                color: AppColors.textHint, fontSize: 13),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                    color: widget.entry.correctIndex == i
                                        ? AppColors.success
                                        : AppColors.divider)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                    color: widget.entry.correctIndex == i
                                        ? AppColors.success
                                        : AppColors.divider,
                                    width:
                                        widget.entry.correctIndex == i ? 2 : 1)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFFD97706), width: 2)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            isDense: true,
                            filled: widget.entry.correctIndex == i,
                            fillColor:
                                AppColors.success.withValues(alpha: 0.05),
                          ),
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                      ),
                    ]),
                  )),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════
//  TAKE QUIZ SCREEN
// ════════════════════════════════════════════════════
class TakeQuizScreen extends StatefulWidget {
  final QuizModel quiz;
  final UserModel student;
  const TakeQuizScreen(
      {super.key, required this.quiz, required this.student});

  @override
  State<TakeQuizScreen> createState() => _TakeQuizScreenState();
}

class _TakeQuizScreenState extends State<TakeQuizScreen> {
  int _current = 0;
  late List<int?> _answers;
  bool _submitted = false;
  int _score = 0;
  late Timer _timer;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    _answers = List.filled(widget.quiz.questions.length, null);
    _seconds = widget.quiz.timeLimitMinutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        _submit();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _timeStr {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get _isLowTime => _seconds < 60;
  int get _answeredCount => _answers.where((a) => a != null).length;

  Future<void> _submit() async {
    _timer.cancel();
    int score = 0;
    for (int i = 0; i < widget.quiz.questions.length; i++) {
      if (_answers[i] == widget.quiz.questions[i].correctIndex) score++;
    }
    await SchoolService().submitAttempt(QuizAttempt(
      id: '',
      quizId: widget.quiz.id,
      studentId: widget.student.uid,
      studentName: widget.student.fullName,
      className: (widget.student is StudentModel)
          ? (widget.student as StudentModel).className
          : '',
      answers: _answers.map((a) => a ?? -1).toList(),
      score: score,
      totalQuestions: widget.quiz.questions.length,
      attemptedAt: DateTime.now(),
    ));
    if (mounted) setState(() { _score = score; _submitted = true; });
  }

  Future<bool> _onWillPop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Leave Quiz?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Your progress will be lost. Quit?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Continue',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFFD97706),
                      fontWeight: FontWeight.w700))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Quit',
                  style: GoogleFonts.poppins(color: AppColors.error))),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _ResultScreen(
          score: _score,
          total: widget.quiz.questions.length,
          quiz: widget.quiz,
          answers: _answers);
    }

    final q = widget.quiz.questions[_current];
    final progress = (_current + 1) / widget.quiz.questions.length;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (await _onWillPop()) {
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(widget.quiz.title,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14),
              overflow: TextOverflow.ellipsis),
          backgroundColor: const Color(0xFFD97706),
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              if (await _onWillPop()) {
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isLowTime
                    ? AppColors.error
                    : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                Icon(Icons.timer_rounded,
                    size: 14,
                    color: _isLowTime ? Colors.white : Colors.white70),
                const SizedBox(width: 4),
                Text(_timeStr,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
              ]),
            ),
          ],
        ),
        body: Column(children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.divider,
            color: const Color(0xFFD97706),
            minHeight: 4,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        'Q ${_current + 1} of ${widget.quiz.questions.length}',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFD97706)),
                      ),
                    ),
                    const Spacer(),
                    Text('$_answeredCount/${widget.quiz.questions.length} answered',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.textHint)),
                  ]),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFD97706), Color(0xFFB45309)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFFD97706).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Text(q.question,
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.5)),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(q.options.length, (i) {
                    final isSelected = _answers[_current] == i;
                    return GestureDetector(
                      onTap: () => setState(() => _answers[_current] = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFD97706).withValues(alpha: 0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFD97706)
                                  : AppColors.divider,
                              width: isSelected ? 2 : 1),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 5)
                          ],
                        ),
                        child: Row(children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFD97706)
                                  : AppColors.background,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFD97706)
                                      : AppColors.divider),
                            ),
                            child: Center(
                              child: isSelected
                                  ? const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 16)
                                  : Text(String.fromCharCode(65 + i),
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: AppColors.textSecondary)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(q.options[i],
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? const Color(0xFFD97706)
                                        : AppColors.textPrimary)),
                          ),
                        ]),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  Text('Jump to:',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textHint)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(
                      widget.quiz.questions.length,
                      (i) => GestureDetector(
                        onTap: () => setState(() => _current = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: i == _current
                                ? const Color(0xFFD97706)
                                : _answers[i] != null
                                    ? AppColors.success
                                    : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: i == _current
                                    ? const Color(0xFFD97706)
                                    : _answers[i] != null
                                        ? AppColors.success
                                        : AppColors.divider,
                                width: 2),
                          ),
                          child: Center(
                            child: Text('${i + 1}',
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: i == _current || _answers[i] != null
                                        ? Colors.white
                                        : AppColors.textSecondary)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -3))
              ],
            ),
            child: Row(children: [
              if (_current > 0) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _current--),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: Text('Prev',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: Color(0xFFD97706)),
                      foregroundColor: const Color(0xFFD97706),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_current < widget.quiz.questions.length - 1) {
                      setState(() => _current++);
                    } else {
                      final unanswered =
                          _answers.where((a) => a == null).length;
                      if (unanswered > 0) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            title: Text('Submit Quiz?',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700)),
                            content: Text(
                                '$unanswered question${unanswered > 1 ? 's' : ''} unanswered. Submit anyway?',
                                style: GoogleFonts.poppins()),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Review',
                                      style: GoogleFonts.poppins(
                                          color: const Color(0xFFD97706),
                                          fontWeight: FontWeight.w700))),
                              ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _submit();
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success),
                                  child: Text('Submit',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700))),
                            ],
                          ),
                        );
                      } else {
                        _submit();
                      }
                    }
                  },
                  icon: Icon(
                      _current == widget.quiz.questions.length - 1
                          ? Icons.check_circle_rounded
                          : Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 16),
                  label: Text(
                      _current == widget.quiz.questions.length - 1
                          ? 'Submit Quiz'
                          : 'Next',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _current == widget.quiz.questions.length - 1
                            ? AppColors.success
                            : const Color(0xFFD97706),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
//  RESULT SCREEN
// ════════════════════════════════════════════════════
class _ResultScreen extends StatelessWidget {
  final int score, total;
  final QuizModel quiz;
  final List<int?> answers;
  const _ResultScreen(
      {required this.score,
      required this.total,
      required this.quiz,
      required this.answers});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (score / total * 100) : 0.0;
    final color = pct >= 75
        ? AppColors.success
        : pct >= 50
            ? AppColors.warning
            : AppColors.error;
    final emoji = pct >= 75 ? '🎉' : pct >= 50 ? '👍' : '📚';
    final message =
        pct >= 75 ? 'Excellent Work!' : pct >= 50 ? 'Good Effort!' : 'Keep Practicing!';
    final grade = SchoolService.calculateGrade(score.toDouble(), total.toDouble());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Quiz Result',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.04)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(children: [
              Text('$emoji $message',
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 110,
                    height: 110,
                    child: CircularProgressIndicator(
                      value: total > 0 ? score / total : 0,
                      backgroundColor: color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(color),
                      strokeWidth: 10,
                    ),
                  ),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('$score/$total',
                        style: GoogleFonts.poppins(
                            fontSize: 26, fontWeight: FontWeight.w800, color: color)),
                    Text('Score',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppColors.textHint)),
                  ]),
                ],
              ),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _ResultBadge('Grade', grade, color),
                const SizedBox(width: 10),
                _ResultBadge('Score', '${pct.toStringAsFixed(0)}%', color),
                const SizedBox(width: 10),
                _ResultBadge('Wrong', '${total - score}', AppColors.error),
              ]),
            ]),
          ),
          const SizedBox(height: 24),
          Row(children: [
            const Icon(Icons.fact_check_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text('Answer Review',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          ...List.generate(quiz.questions.length, (i) {
            final q = quiz.questions[i];
            final isCorrect = answers[i] == q.correctIndex;
            final userAnswer = answers[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: isCorrect
                        ? AppColors.success.withValues(alpha: 0.4)
                        : AppColors.error.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
                ],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                        color: isCorrect ? AppColors.success : AppColors.error,
                        shape: BoxShape.circle),
                    child: Center(
                      child: Icon(
                          isCorrect ? Icons.check_rounded : Icons.close_rounded,
                          color: Colors.white,
                          size: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Q${i + 1}. ${q.question}',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: isCorrect
                          ? AppColors.success.withValues(alpha: 0.06)
                          : AppColors.error.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.person_rounded,
                          size: 12,
                          color: isCorrect ? AppColors.success : AppColors.error),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Your answer: ${userAnswer != null && userAnswer < q.options.length ? q.options[userAnswer] : 'Not answered'}',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isCorrect ? AppColors.success : AppColors.error),
                        ),
                      ),
                    ]),
                    if (!isCorrect) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 12, color: AppColors.success),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Correct: ${q.options[q.correctIndex]}',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success),
                          ),
                        ),
                      ]),
                    ],
                  ]),
                ),
              ]),
            );
          }),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              icon: const Icon(Icons.home_rounded, color: Colors.white),
              label: Text('Back to Home',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  final String label, value;
  final Color color;
  const _ResultBadge(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Column(children: [
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: AppColors.textSecondary)),
        ]),
      );
}

// ════════════════════════════════════════════════════
//  QUIZ ATTEMPTS SCREEN  (teacher views results)
// ════════════════════════════════════════════════════
class QuizAttemptsScreen extends StatelessWidget {
  final QuizModel quiz;
  const QuizAttemptsScreen({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Results: ${quiz.title}',
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14),
            overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<QuizAttempt>>(
        stream: SchoolService().getQuizAttempts(quiz.id),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFD97706)));
          }
          final attempts = snap.data ?? [];
          if (attempts.isEmpty) {
            return const EmptyState(
                icon: Icons.assignment_outlined,
                title: 'No Attempts Yet',
                subtitle: 'Students have not taken this quiz yet');
          }

          final avg = attempts
                  .map((a) => a.score / a.totalQuestions * 100)
                  .reduce((a, b) => a + b) /
              attempts.length;
          final highest = attempts
              .map((a) => a.score / a.totalQuestions * 100)
              .reduce((a, b) => a > b ? a : b);

          return Column(children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFFD97706).withValues(alpha: 0.25)),
              ),
              child: Row(children: [
                Expanded(child: _StatBox('${attempts.length}', 'Attempts', AppColors.primary)),
                Container(width: 1, height: 40, color: AppColors.divider),
                Expanded(child: _StatBox('${avg.toStringAsFixed(0)}%', 'Avg Score', const Color(0xFFD97706))),
                Container(width: 1, height: 40, color: AppColors.divider),
                Expanded(child: _StatBox('${highest.toStringAsFixed(0)}%', 'Highest', AppColors.success)),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: attempts.length,
                itemBuilder: (_, i) {
                  final a = attempts[i];
                  final pct = a.totalQuestions > 0
                      ? (a.score / a.totalQuestions * 100)
                      : 0.0;
                  final color = pct >= 75
                      ? AppColors.success
                      : pct >= 50
                          ? AppColors.warning
                          : AppColors.error;
                  final grade = SchoolService.calculateGrade(
                      a.score.toDouble(), a.totalQuestions.toDouble());
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6)
                      ],
                    ),
                    child: Row(children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                              a.studentName.isNotEmpty
                                  ? a.studentName[0].toUpperCase()
                                  : 'S',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                  fontSize: 14)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(a.studentName,
                              style: GoogleFonts.poppins(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                          Text(
                              '${a.className}  •  ${DateFormat('dd MMM, hh:mm a').format(a.attemptedAt)}',
                              style: GoogleFonts.poppins(
                                  fontSize: 10, color: AppColors.textHint)),
                        ]),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('${a.score}/${a.totalQuestions}',
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: color)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(grade,
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: color)),
                        ),
                      ]),
                    ]),
                  );
                },
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatBox(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      );
}