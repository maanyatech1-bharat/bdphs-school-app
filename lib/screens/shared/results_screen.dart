// lib/screens/shared/results_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _selectedTerm = 'All';
  final _terms = ['All', 'FA1', 'FA2', 'SA1', 'FA3', 'FA4', 'SA2'];

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

  Color _gradeColor(double pct) {
    if (pct >= 90) return const Color(0xFF059669);
    if (pct >= 75) return const Color(0xFF2563EB);
    if (pct >= 60) return const Color(0xFFD97706);
    if (pct >= 33) return const Color(0xFFDC2626);
    return const Color(0xFF6B7280);
  }

  String _grade(double pct) {
    if (pct >= 90) return 'A+';
    if (pct >= 80) return 'A';
    if (pct >= 70) return 'B+';
    if (pct >= 60) return 'B';
    if (pct >= 50) return 'C';
    if (pct >= 33) return 'D';
    return 'F';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser;
    final uid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Results',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [Tab(text: 'Subject-wise'), Tab(text: 'Summary')],
        ),
      ),
      body: Column(
        children: [
          // Term filter
          Container(
            color: Colors.white,
            child: SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _terms.length,
                itemBuilder: (_, i) {
                  final t = _terms[i];
                  final sel = _selectedTerm == t;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTerm = t),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF2563EB)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel
                                ? const Color(0xFF2563EB)
                                : AppColors.divider),
                      ),
                      child: Text(t,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? Colors.white
                                  : AppColors.textSecondary)),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _SubjectWiseTab(
                    uid: uid,
                    term: _selectedTerm,
                    gradeColor: _gradeColor,
                    grade: _grade),
                _SummaryTab(
                    uid: uid,
                    term: _selectedTerm,
                    gradeColor: _gradeColor,
                    grade: _grade),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subject-wise results ──────────────────────────────────────────────────────
class _SubjectWiseTab extends StatelessWidget {
  final String uid;
  final String term;
  final Color Function(double) gradeColor;
  final String Function(double) grade;
  const _SubjectWiseTab(
      {required this.uid,
      required this.term,
      required this.gradeColor,
      required this.grade});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('results')
        .where('studentId', isEqualTo: uid)
        .orderBy('createdAt', descending: true);

    if (term != 'All') {
      query = query.where('examTerm', isEqualTo: term);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bar_chart_rounded,
                    size: 64, color: AppColors.textHint),
                const SizedBox(height: 12),
                Text('No results found',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                Text(term == 'All'
                    ? 'Results will appear after your exams'
                    : 'No results for $term yet',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textHint)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final marksObtained = (d['marksObtained'] as num?)?.toDouble() ?? 0;
            final totalMarks = (d['totalMarks'] as num?)?.toDouble() ?? 100;
            final pct =
                totalMarks > 0 ? (marksObtained / totalMarks) * 100 : 0.0;
            final color = gradeColor(pct);
            final g = grade(pct);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border(left: BorderSide(color: color, width: 4)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d['subject'] ?? 'Unknown Subject',
                                style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            Text('${d['examTerm'] ?? ''} • ${d['examType'] ?? ''}',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10)),
                            child: Text(g,
                                style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: color)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                              '${marksObtained.toStringAsFixed(0)}/${totalMarks.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor:
                          color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${pct.toStringAsFixed(1)}%',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color)),
                      Text(
                          d['remarks'] ?? (pct >= 33 ? 'Pass' : 'Fail'),
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textHint)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Summary Tab ───────────────────────────────────────────────────────────────
class _SummaryTab extends StatelessWidget {
  final String uid;
  final String term;
  final Color Function(double) gradeColor;
  final String Function(double) grade;
  const _SummaryTab(
      {required this.uid,
      required this.term,
      required this.gradeColor,
      required this.grade});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('results')
        .where('studentId', isEqualTo: uid);
    if (term != 'All') {
      query = query.where('examTerm', isEqualTo: term);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text('No data to summarize',
                style: GoogleFonts.poppins(color: AppColors.textHint)),
          );
        }

        double totalObtained = 0;
        double totalMax = 0;
        final Map<String, List<double>> subjectPcts = {};

        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final mo = (d['marksObtained'] as num?)?.toDouble() ?? 0;
          final tm = (d['totalMarks'] as num?)?.toDouble() ?? 100;
          totalObtained += mo;
          totalMax += tm;
          final pct = tm > 0 ? (mo / tm) * 100 : 0.0;
          final subj = d['subject'] ?? 'Unknown';
          subjectPcts.putIfAbsent(subj, () => []).add(pct);
        }

        final overallPct =
            totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;
        final color = gradeColor(overallPct);
        final g = grade(overallPct);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Overall card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text('Overall Performance',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text(g,
                        style: GoogleFonts.poppins(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    Text('${overallPct.toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                        '${totalObtained.toStringAsFixed(0)} / ${totalMax.toStringAsFixed(0)} marks',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Per subject averages
              Text('Subject Average',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              ...subjectPcts.entries.map((entry) {
                final avg =
                    entry.value.reduce((a, b) => a + b) / entry.value.length;
                final c = gradeColor(avg);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6)
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.key,
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: avg / 100,
                                backgroundColor:
                                    c.withValues(alpha: 0.12),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(c),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text('${avg.toStringAsFixed(1)}%',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: c)),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}