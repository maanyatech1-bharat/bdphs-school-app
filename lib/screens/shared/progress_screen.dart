// lib/screens/shared/progress_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/school_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class StudentProgressScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String className;
  const StudentProgressScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    this.className = "",
  });
  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _service = SchoolService();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Color _gradeColor(String g) {
    switch (g) {
      case "A+": case "A": return AppColors.success;
      case "B+": case "B": return AppColors.info;
      case "C": return AppColors.warning;
      default: return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.studentName,
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          tabs: const [
            Tab(text: "Overview"),
            Tab(text: "Results"),
            Tab(text: "Assessment"),
            Tab(text: "Leaderboard"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          StreamBuilder<List<ResultModel>>(
            stream: _service.getStudentResults(widget.studentId),
            builder: (ctx, snap) => _OverviewTab(results: snap.data ?? [], gradeColor: _gradeColor),
          ),
          StreamBuilder<List<ResultModel>>(
            stream: _service.getStudentResults(widget.studentId),
            builder: (ctx, snap) => _ResultsTab(results: snap.data ?? [], gradeColor: _gradeColor),
          ),
          StreamBuilder<List<MonthlyAssessment>>(
            stream: _service.getStudentAssessments(widget.studentId),
            builder: (ctx, snap) => _AssessmentTab(assessments: snap.data ?? []),
          ),
          _LeaderboardTab(className: widget.className, studentId: widget.studentId),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final List<ResultModel> results;
  final Color Function(String) gradeColor;
  const _OverviewTab({required this.results, required this.gradeColor});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const EmptyState(icon: Icons.bar_chart_outlined, title: "No Results Yet", subtitle: "Results will appear here once entered by teacher");
    }
    final bySubject = <String, List<ResultModel>>{};
    for (final r in results) { bySubject.putIfAbsent(r.subject, () => []).add(r); }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Performance by Subject", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...bySubject.entries.map((e) {
          final avg = e.value.map((r) => (r.maxMarks > 0 ? r.obtainedMarks / r.maxMarks * 100 : 0.0)).reduce((a, b) => a + b) / e.value.length;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(e.key, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
                Text("${avg.toStringAsFixed(1)}%", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700,
                  color: avg >= 75 ? AppColors.success : avg >= 50 ? AppColors.warning : AppColors.error)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: avg / 100, minHeight: 8,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation(avg >= 75 ? AppColors.success : avg >= 50 ? AppColors.warning : AppColors.error))),
            ]),
          );
        }),
      ],
    );
  }
}

class _ResultsTab extends StatelessWidget {
  final List<ResultModel> results;
  final Color Function(String) gradeColor;
  const _ResultsTab({required this.results, required this.gradeColor});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const EmptyState(icon: Icons.assignment_outlined, title: "No Results", subtitle: "Results will appear here");
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (_, i) {
        final r = results[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.subject, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
              Text("${r.examType} - ${r.month.contains(r.year.toString()) ? r.month : '${r.month} ${r.year}'}", style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
              if (r.enteredByName.isNotEmpty)
                Text("By ${r.enteredByName}", style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text("${r.obtainedMarks}/${r.maxMarks}", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: gradeColor(r.grade).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text("${r.grade} ${(r.maxMarks > 0 ? r.obtainedMarks / r.maxMarks * 100 : 0.0).toStringAsFixed(1)}%",
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: gradeColor(r.grade))),
              ),
            ]),
          ]),
        );
      },
    );
  }
}

class _AssessmentTab extends StatefulWidget {
  final List<MonthlyAssessment> assessments;
  const _AssessmentTab({required this.assessments});
  @override
  State<_AssessmentTab> createState() => _AssessmentTabState();
}

class _AssessmentTabState extends State<_AssessmentTab> {
  String _selectedMonth = "All";

  Color _gradeC(String g) {
    switch (g) {
      case "A": return AppColors.success;
      case "B": return AppColors.info;
      case "C": return AppColors.warning;
      default: return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.assessments.isEmpty) {
      return const EmptyState(icon: Icons.assessment_outlined, title: "No Assessments", subtitle: "Monthly assessments will appear here");
    }
    final months = ["All", ...widget.assessments.map((a) =>
      a.month.contains(a.year.toString()) ? a.month : "${a.month} ${a.year}").toSet().toList()];
    final filtered = _selectedMonth == "All"
        ? widget.assessments
        : widget.assessments.where((a) {
            final m = a.month.contains(a.year.toString()) ? a.month : "${a.month} ${a.year}";
            return m == _selectedMonth;
          }).toList();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: DropdownButtonFormField<String>(
          value: _selectedMonth,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: "Select Month",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            prefixIcon: const Icon(Icons.calendar_month_rounded),
          ),
          items: months.map((m) => DropdownMenuItem(value: m, child: Text(m, style: GoogleFonts.poppins(fontSize: 13)))).toList(),
          onChanged: (v) => setState(() => _selectedMonth = v!),
        ),
      ),
      Expanded(
        child: filtered.isEmpty
          ? const EmptyState(icon: Icons.assessment_outlined, title: "No Assessment", subtitle: "No assessment for selected month")
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final a = filtered[i];
                final attPct = a.totalDays > 0 ? (a.daysPresent / a.totalDays * 100) : 0.0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(a.month.contains(a.year.toString()) ? a.month : "${a.month} ${a.year}",
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                      const Spacer(),
                      if (a.assessedByName.isNotEmpty)
                        Text("By ${a.assessedByName}", style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
                    ]),
                    const SizedBox(height: 12),
                    if (a.totalDays > 0) ...[
                      Row(children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 6),
                        Text("Attendance: ${a.daysPresent}/${a.totalDays} days (${attPct.toStringAsFixed(0)}%)",
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(value: attPct / 100, minHeight: 8,
                          backgroundColor: AppColors.divider,
                          valueColor: AlwaysStoppedAnimation(attPct >= 75 ? AppColors.success : attPct >= 50 ? AppColors.warning : AppColors.error))),
                      const SizedBox(height: 12),
                    ] else ...[
                      Text("Attendance not recorded yet",
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textHint, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 12),
                    ],
                    Row(children: [
                      Expanded(child: _GradeBadge("Discipline", a.disciplineGrade, _gradeC(a.disciplineGrade))),
                      Expanded(child: _GradeBadge("Uniform", a.uniformGrade, _gradeC(a.uniformGrade))),
                      Expanded(child: _GradeBadge("Punctuality", a.punctualityGrade, _gradeC(a.punctualityGrade))),
                    ]),
                    if (a.remarks.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                        child: Text("📝 ${a.remarks}", style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                      ),
                    ],
                  ]),
                );
              }),
      ),
    ]);
  }
}

class _GradeBadge extends StatelessWidget {
  final String label, grade;
  final Color color;
  const _GradeBadge(this.label, this.grade, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
    CircleAvatar(radius: 22, backgroundColor: color.withValues(alpha: 0.15),
      child: Text(grade, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: color))),
    const SizedBox(height: 4),
    Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
  ]);
}

class _LeaderboardTab extends StatelessWidget {
  final String className;
  final String studentId;
  const _LeaderboardTab({required this.className, required this.studentId});

  @override
  Widget build(BuildContext context) {
    if (className.isEmpty) {
      return const EmptyState(icon: Icons.leaderboard_outlined, title: "Class not found", subtitle: "Unable to load leaderboard");
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("monthly_assessments").where("className", isEqualTo: className).snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const EmptyState(icon: Icons.leaderboard_outlined, title: "No Data", subtitle: "No assessment data available yet");

        final Map<String, Map<String, dynamic>> studentData = {};
        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final sid = d["studentId"] ?? "";
          final name = d["studentName"] ?? "";
          final pct = (d["percentage"] as num?)?.toDouble() ?? 0.0;
          final present = (d["daysPresent"] as num?)?.toInt() ?? 0;
          final total = (d["totalDays"] as num?)?.toInt() ?? 0;
          if (!studentData.containsKey(sid)) {
            studentData[sid] = {"name": name, "totalPct": 0.0, "count": 0, "present": 0, "total": 0};
          }
          studentData[sid]!["totalPct"] = (studentData[sid]!["totalPct"] as double) + pct;
          studentData[sid]!["count"] = (studentData[sid]!["count"] as int) + 1;
          studentData[sid]!["present"] = (studentData[sid]!["present"] as int) + present;
          studentData[sid]!["total"] = (studentData[sid]!["total"] as int) + total;
        }

        final students = studentData.entries.map((e) {
          final avgMarks = (e.value["count"] as int) > 0 ? (e.value["totalPct"] as double) / (e.value["count"] as int) : 0.0;
          final attPct = (e.value["total"] as int) > 0 ? ((e.value["present"] as int) / (e.value["total"] as int) * 100) : 0.0;
          final overall = (avgMarks * 0.7) + (attPct * 0.3);
          return {"id": e.key, "name": e.value["name"], "marks": avgMarks, "attendance": attPct, "overall": overall};
        }).toList()..sort((a, b) => (b["overall"] as double).compareTo(a["overall"] as double));

        return Column(children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary.withValues(alpha: 0.05),
            child: Row(children: [
              const Icon(Icons.leaderboard_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text("Class $className Leaderboard", style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const Spacer(),
              Text("${students.length} students", style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              itemBuilder: (_, i) {
                final s = students[i];
                final isMe = s["id"] == studentId;
                final rank = i + 1;
                final medal = rank == 1 ? "🥇" : rank == 2 ? "🥈" : rank == 3 ? "🥉" : "#$rank";
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: isMe ? Border.all(color: AppColors.primary, width: 2) : null,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
                  ),
                  child: Row(children: [
                    SizedBox(width: 40, child: Text(medal, style: const TextStyle(fontSize: 20), textAlign: TextAlign.center)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Flexible(child: Text(s["name"] as String,
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700,
                            color: isMe ? AppColors.primary : AppColors.textPrimary))),
                        if (isMe) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                            child: Text("You", style: GoogleFonts.poppins(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        Text("📚 ${(s["marks"] as double).toStringAsFixed(1)}%", style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(width: 10),
                        Text("📅 ${(s["attendance"] as double).toStringAsFixed(1)}%", style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                      ]),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text("${(s["overall"] as double).toStringAsFixed(1)}%",
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800,
                          color: rank <= 3 ? const Color(0xFFD97706) : AppColors.primary)),
                      Text("Overall", style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textHint)),
                    ]),
                  ]),
                );
              },
            ),
          ),
        ]);
      },
    );
  }
}
