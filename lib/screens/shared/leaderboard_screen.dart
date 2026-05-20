// lib/screens/shared/leaderboard_screen.dart
// Combined leaderboard: Marks (50%) + Attendance (30%) + Monthly Assessment (20%)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _selectedClass = 'All';
  bool _loading = true;
  List<_StudentRank> _rankings = [];

  final _classes = ['All','Nursery','LKG','UKG',
    'Class 1','Class 2','Class 3','Class 4','Class 5',
    'Class 6','Class 7','Class 8','Class 9','Class 10'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadRankings();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadRankings() async {
    setState(() => _loading = true);
    try {
      // 1️⃣ Fetch all approved students
      Query q = FirebaseFirestore.instance.collection('students')
          .where('approvalStatus', isEqualTo: 'approved');
      if (_selectedClass != 'All') {
        q = q.where('className', isEqualTo: _selectedClass);
      }
      final studentsSnap = await q.get();
      final Map<String, _StudentRank> rankMap = {};
      for (final d in studentsSnap.docs) {
        final data = d.data() as Map<String, dynamic>;
        rankMap[d.id] = _StudentRank(
          studentId: d.id,
          name: data['fullName'] ?? 'Unknown',
          className: data['className'] ?? '',
          rollNumber: data['rollNumber'] ?? '',
        );
      }
      if (rankMap.isEmpty) { setState(() { _rankings = []; _loading = false; }); return; }

      // 2️⃣ Marks score (50%) — avg percentage across all results
      final resultsSnap = await FirebaseFirestore.instance
          .collection('results').get();
      final Map<String, List<double>> marksMap = {};
      for (final d in resultsSnap.docs) {
        final data = d.data();
        final sid = data['studentId'] as String? ?? '';
        if (!rankMap.containsKey(sid)) continue;
        marksMap.putIfAbsent(sid, () => [])
            .add((data['percentage'] as num?)?.toDouble() ?? 0);
      }

      // 3️⃣ Attendance score (30%) — % of days present
      final attendanceSnap = await FirebaseFirestore.instance
          .collection('attendance').get();
      final Map<String, List<bool>> attendMap = {};
      for (final d in attendanceSnap.docs) {
        final data = d.data();
        final sid = data['studentId'] as String? ?? '';
        if (!rankMap.containsKey(sid)) continue;
        attendMap.putIfAbsent(sid, () => [])
            .add(data['isPresent'] as bool? ?? false);
      }

      // 4️⃣ Monthly Assessment score (20%) — avg percentage
      final assessSnap = await FirebaseFirestore.instance
          .collection('monthly_assessments').get();
      final Map<String, List<double>> assessMap = {};
      for (final d in assessSnap.docs) {
        final data = d.data();
        final sid = data['studentId'] as String? ?? '';
        if (!rankMap.containsKey(sid)) continue;
        assessMap.putIfAbsent(sid, () => [])
            .add((data['percentage'] as num?)?.toDouble() ?? 0);
      }

      // 5️⃣ Compute combined score
      for (final entry in rankMap.entries) {
        final sid = entry.key;
        final r = entry.value;

        // Marks avg
        final marks = marksMap[sid] ?? [];
        r.marksScore = marks.isEmpty ? 0
            : marks.fold(0.0, (s, v) => s + v) / marks.length;
        r.marksCount = marks.length;

        // Attendance avg
        final attend = attendMap[sid] ?? [];
        r.attendanceScore = attend.isEmpty ? 0
            : (attend.where((v) => v).length / attend.length * 100);
        r.attendanceDays = attend.length;
        r.presentDays = attend.where((v) => v).length;

        // Assessment avg
        final assess = assessMap[sid] ?? [];
        r.assessmentScore = assess.isEmpty ? 0
            : assess.fold(0.0, (s, v) => s + v) / assess.length;
        r.assessmentCount = assess.length;

        // Combined (weighted)
        r.combinedScore =
            (r.marksScore * 0.50) +
            (r.attendanceScore * 0.30) +
            (r.assessmentScore * 0.20);
      }

      final list = rankMap.values.toList()
        ..sort((a, b) => b.combinedScore.compareTo(a.combinedScore));

      setState(() { _rankings = list; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        title: Text('Leaderboard 🏆',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadRankings,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: '🏅 Rankings'),
            Tab(text: '📊 Class Stats'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              color: Color(0xFF7C3AED)))
          : TabBarView(
              controller: _tabs,
              children: [
                _RankingsTab(
                  rankings: _rankings,
                  selectedClass: _selectedClass,
                  classes: _classes,
                  onClassChanged: (v) {
                    setState(() => _selectedClass = v!);
                    _loadRankings();
                  },
                ),
                _ClassStatsTab(rankings: _rankings),
              ],
            ),
    );
  }
}

// ── Rankings Tab ──────────────────────────────────────────────────────────────
class _RankingsTab extends StatelessWidget {
  final List<_StudentRank> rankings;
  final String selectedClass;
  final List<String> classes;
  final void Function(String?) onClassChanged;

  const _RankingsTab({
    required this.rankings, required this.selectedClass,
    required this.classes, required this.onClassChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Formula explanation
      Container(
        color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _weightBadge('Marks', '50%', const Color(0xFF7C3AED)),
            const Text('+', style: TextStyle(fontWeight: FontWeight.w900)),
            _weightBadge('Attendance', '30%', const Color(0xFF059669)),
            const Text('+', style: TextStyle(fontWeight: FontWeight.w900)),
            _weightBadge('Assessment', '20%', const Color(0xFF0891B2)),
          ],
        ),
      ),

      // Class filter
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(12),
        child: DropdownButtonFormField<String>(
          value: selectedClass,
          decoration: InputDecoration(
            labelText: 'Filter by Class',
            isDense: true,
            prefixIcon: const Icon(Icons.filter_list_rounded, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary),
          items: classes.map((c) => DropdownMenuItem(
              value: c, child: Text(c, style: GoogleFonts.poppins(fontSize: 13)))).toList(),
          onChanged: onClassChanged,
        ),
      ),
      const Divider(height: 1),

      if (rankings.isEmpty)
        Expanded(child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_outlined, size: 64,
                color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No data yet', style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Enter marks and mark attendance\nto build the leaderboard',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
          ],
        )))
      else
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: rankings.length,
          itemBuilder: (_, i) {
            final r = rankings[i];
            final rank = i + 1;
            final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : null;
            final score = r.combinedScore;
            final scoreColor = score >= 75 ? AppColors.success
                : score >= 50 ? const Color(0xFFD97706) : AppColors.error;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: rank <= 3
                    ? const Color(0xFF7C3AED).withValues(alpha: 0.04)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: rank <= 3 ? Border.all(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.15)) : null,
                boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6)],
              ),
              child: Column(children: [
                Row(children: [
                  SizedBox(
                    width: 40,
                    child: medal != null
                        ? Text(medal, style: const TextStyle(fontSize: 24))
                        : Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle),
                            child: Center(child: Text('#$rank',
                                style: GoogleFonts.poppins(
                                    fontSize: 11, fontWeight: FontWeight.w800,
                                    color: AppColors.primary)))),
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                    child: Text(r.name.isNotEmpty ? r.name[0].toUpperCase() : '?',
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w800,
                            color: const Color(0xFF7C3AED))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.name, style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w700),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${r.className}  Roll: ${r.rollNumber}',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: AppColors.textHint)),
                    ],
                  )),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${score.toStringAsFixed(1)}',
                        style: GoogleFonts.poppins(
                            fontSize: 20, fontWeight: FontWeight.w900,
                            color: scoreColor)),
                    Text('Combined %', style: GoogleFonts.poppins(
                        fontSize: 9, color: AppColors.textHint)),
                  ]),
                ]),
                const SizedBox(height: 8),
                // Mini breakdown
                Row(children: [
                  _miniScore('📝 Marks', r.marksScore, const Color(0xFF7C3AED),
                      r.marksCount == 0 ? 'No data' : '${r.marksScore.toStringAsFixed(0)}%'),
                  _miniScore('📅 Attend', r.attendanceScore, const Color(0xFF059669),
                      r.attendanceDays == 0 ? 'No data' : '${r.presentDays}/${r.attendanceDays}d'),
                  _miniScore('📋 Assess', r.assessmentScore, const Color(0xFF0891B2),
                      r.assessmentCount == 0 ? 'No data' : '${r.assessmentScore.toStringAsFixed(0)}%'),
                ]),
              ]),
            );
          },
        )),
    ]);
  }

  Widget _weightBadge(String label, String weight, Color color) => Column(children: [
    Text(weight, style: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w900, color: color)),
    Text(label, style: GoogleFonts.poppins(
        fontSize: 9, color: AppColors.textSecondary)),
  ]);

  Widget _miniScore(String label, double score, Color color, String sub) =>
      Expanded(child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(children: [
          Text(label, style: GoogleFonts.poppins(
              fontSize: 9, color: AppColors.textSecondary)),
          Text('${score.toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          Text(sub, style: GoogleFonts.poppins(
              fontSize: 9, color: AppColors.textHint)),
        ]),
      ));
}

// ── Class Stats Tab ───────────────────────────────────────────────────────────
class _ClassStatsTab extends StatelessWidget {
  final List<_StudentRank> rankings;
  const _ClassStatsTab({required this.rankings});

  @override
  Widget build(BuildContext context) {
    // Group by class
    final Map<String, List<_StudentRank>> grouped = {};
    for (final r in rankings) {
      grouped.putIfAbsent(r.className, () => []).add(r);
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (entries.isEmpty) {
      return Center(child: Text('No data',
          style: GoogleFonts.poppins(color: AppColors.textSecondary)));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // School overview
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Text('👨‍🎓', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${rankings.length}', style: GoogleFonts.poppins(
                  fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
              Text('Total Students',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
            ]),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                rankings.isEmpty ? '0%'
                    : '${(rankings.fold<double>(0, (s, r) => s + r.combinedScore) / rankings.length).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                    fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
              Text('Avg Score', style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.white70)),
            ]),
          ]),
        ),
        const SizedBox(height: 20),

        ...entries.map((entry) {
          final cls = entry.key;
          final students = entry.value;
          final avgScore = students.fold<double>(0,
                  (s, r) => s + r.combinedScore) / students.length;
          final avgMarks = students.fold<double>(0,
                  (s, r) => s + r.marksScore) / students.length;
          final avgAttend = students.fold<double>(0,
                  (s, r) => s + r.attendanceScore) / students.length;
          final topStudent = students.isNotEmpty
              ? students.reduce((a, b) =>
                  a.combinedScore >= b.combinedScore ? a : b)
              : null;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
            ),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16))),
                child: Row(children: [
                  const Icon(Icons.class_rounded,
                      size: 18, color: Color(0xFF7C3AED)),
                  const SizedBox(width: 8),
                  Text(cls, style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text('${students.length} students',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(children: [
                  Row(children: [
                    _classStat('Avg Score', '${avgScore.toStringAsFixed(0)}%',
                        const Color(0xFF7C3AED)),
                    _classStat('Avg Marks', '${avgMarks.toStringAsFixed(0)}%',
                        const Color(0xFF2563EB)),
                    _classStat('Avg Attend', '${avgAttend.toStringAsFixed(0)}%',
                        const Color(0xFF059669)),
                  ]),
                  if (topStudent != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
                      ),
                      child: Row(children: [
                        const Text('🥇', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          'Topper: ${topStudent.name}',
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        )),
                        Text('${topStudent.combinedScore.toStringAsFixed(0)}%',
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w900,
                                color: const Color(0xFFD97706))),
                      ]),
                    ),
                  ],
                ]),
              ),
            ]),
          );
        }),
      ],
    );
  }

  Widget _classStat(String label, String value, Color color) =>
      Expanded(child: Column(children: [
        Text(value, style: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: GoogleFonts.poppins(
            fontSize: 10, color: AppColors.textSecondary)),
      ]));
}

// ── Model ─────────────────────────────────────────────────────────────────────
class _StudentRank {
  final String studentId, name, className, rollNumber;
  double marksScore = 0;
  double attendanceScore = 0;
  double assessmentScore = 0;
  double combinedScore = 0;
  int marksCount = 0;
  int attendanceDays = 0;
  int presentDays = 0;
  int assessmentCount = 0;

  _StudentRank({
    required this.studentId, required this.name,
    required this.className, required this.rollNumber,
  });
}