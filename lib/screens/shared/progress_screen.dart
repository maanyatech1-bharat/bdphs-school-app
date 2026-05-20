// lib/screens/shared/progress_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/school_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class StudentProgressScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  const StudentProgressScreen({super.key, required this.studentId, required this.studentName});
  @override State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _service = SchoolService();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Color _gradeColor(String g) {
    switch (g) {
      case 'A+': case 'A': return AppColors.success;
      case 'B+': case 'B': return AppColors.info;
      case 'C': return AppColors.warning;
      default: return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.studentName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [Tab(text: 'Overview'), Tab(text: 'Results'), Tab(text: 'Assessment')],
        ),
      ),
      body: StreamBuilder<List<ResultModel>>(
        stream: _service.getStudentResults(widget.studentId),
        builder: (_, snap) {
          final results = snap.data ?? [];
          return StreamBuilder<List<MonthlyAssessment>>(
            stream: _service.getStudentAssessments(widget.studentId),
            builder: (_, snapA) {
              final assessments = snapA.data ?? [];
              return TabBarView(
                controller: _tabs,
                children: [
                  _OverviewTab(results: results, assessments: assessments),
                  _ResultsTab(results: results, gradeColor: _gradeColor),
                  _AssessmentTab(assessments: assessments),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ─── OVERVIEW TAB ─────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final List<ResultModel> results;
  final List<MonthlyAssessment> assessments;
  const _OverviewTab({required this.results, required this.assessments});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const EmptyState(icon: Icons.bar_chart_rounded, title: 'No Results Yet', subtitle: 'Results will appear after exams');

    // Group by exam type
    final Map<String, List<double>> byExam = {};
    for (final r in results) {
      byExam.putIfAbsent(r.examType, () => []).add(r.percentage);
    }
    final avgByExam = byExam.map((k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length));

    // Subject averages
    final Map<String, List<double>> bySubject = {};
    for (final r in results) {
      bySubject.putIfAbsent(r.subject, () => []).add(r.percentage);
    }
    final avgBySubject = bySubject.map((k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length));
    final overall = results.isEmpty ? 0.0 : results.map((r) => r.percentage).reduce((a, b) => a + b) / results.length;
    final grade = SchoolService.calculateGrade(overall, 100);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overall score card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: overall >= 75 ? [AppColors.success, const Color(0xFF047857)] : overall >= 50 ? [AppColors.warning, const Color(0xFFB45309)] : [AppColors.error, const Color(0xFFB91C1C)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Overall Performance', style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
              const SizedBox(height: 4),
              Text('${overall.toStringAsFixed(1)}%', style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white)),
              Text('Grade: $grade  •  ${results.length} exams', style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
            ]),
            const Spacer(),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Center(child: Text(grade, style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white))),
            ),
          ]),
        ),
        const SizedBox(height: 20),

        // Bar chart by exam type
        if (avgByExam.isNotEmpty) ...[
          Text('Performance by Exam', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final key = avgByExam.keys.elementAt(groupIndex);
                    return BarTooltipItem('$key\n${rod.toY.toStringAsFixed(0)}%', GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600));
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textHint)))),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
                  getTitlesWidget: (v, _) {
                    final keys = avgByExam.keys.toList();
                    if (v.toInt() >= keys.length) return const SizedBox();
                    return Text(keys[v.toInt()], style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textHint));
                  })),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true, horizontalInterval: 25, drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.divider, strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              barGroups: avgByExam.entries.toList().asMap().entries.map((e) {
                final pct = e.value.value;
                final color = pct >= 75 ? AppColors.success : pct >= 50 ? AppColors.warning : AppColors.error;
                return BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: pct, color: color, width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))]);
              }).toList(),
            )),
          ),
          const SizedBox(height: 20),
        ],

        // Subject breakdown
        Text('Subject Breakdown', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...avgBySubject.entries.map((e) {
          final pct = e.value;
          final color = pct >= 75 ? AppColors.success : pct >= 50 ? AppColors.warning : AppColors.error;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(e.key, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${pct.toStringAsFixed(1)}%', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: pct / 100, backgroundColor: color.withValues(alpha: 0.1), valueColor: AlwaysStoppedAnimation(color), minHeight: 8),
              ),
            ]),
          );
        }),
      ],
    );
  }
}

// ─── RESULTS TAB ──────────────────────────────────────────────────────────────
class _ResultsTab extends StatelessWidget {
  final List<ResultModel> results;
  final Color Function(String) gradeColor;
  const _ResultsTab({required this.results, required this.gradeColor});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const EmptyState(icon: Icons.assignment_outlined, title: 'No Results', subtitle: 'No exam results available');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (_, i) {
        final r = results[i];
        final color = gradeColor(r.grade);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(r.grade, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: color))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.subject, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
              Text('${r.examType} • ${r.month} ${r.year}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
              Text('By ${r.enteredByName}', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${r.obtainedMarks.toInt()}/${r.maxMarks.toInt()}', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
              Text('${r.percentage.toStringAsFixed(1)}%', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
            ]),
          ]),
        );
      },
    );
  }
}

// ─── ASSESSMENT TAB ───────────────────────────────────────────────────────────
class _AssessmentTab extends StatelessWidget {
  final List<MonthlyAssessment> assessments;
  const _AssessmentTab({required this.assessments});

  Color _gradeC(String g) {
    switch (g) {
      case 'A': return AppColors.success;
      case 'B': return AppColors.info;
      case 'C': return AppColors.warning;
      default: return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (assessments.isEmpty) return const EmptyState(icon: Icons.assessment_outlined, title: 'No Assessments', subtitle: 'Monthly assessments will appear here');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assessments.length,
      itemBuilder: (_, i) {
        final a = assessments[i];
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
                child: Text('${a.month} ${a.year}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              const Spacer(),
              Text('By ${a.assessedByName}', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
            ]),
            const SizedBox(height: 12),
            // Attendance bar
            Row(children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textHint),
              const SizedBox(width: 6),
              Text('Attendance: ${a.daysPresent}/${a.totalDays} days (${attPct.toStringAsFixed(0)}%)',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: attPct / 100, minHeight: 8,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation(attPct >= 75 ? AppColors.success : attPct >= 50 ? AppColors.warning : AppColors.error))),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _GradeBadge('Discipline', a.disciplineGrade, _gradeC(a.disciplineGrade))),
              Expanded(child: _GradeBadge('Uniform', a.uniformGrade, _gradeC(a.uniformGrade))),
              Expanded(child: _GradeBadge('Punctuality', a.punctualityGrade, _gradeC(a.punctualityGrade))),
            ]),
            if (a.remarks.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                child: Text('📝 ${a.remarks}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
              ),
            ],
          ]),
        );
      },
    );
  }
}

class _GradeBadge extends StatelessWidget {
  final String label, grade;
  final Color color;
  const _GradeBadge(this.label, this.grade, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Center(child: Text(grade, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: color))),
    ),
    const SizedBox(height: 4),
    Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textHint)),
  ]);
}