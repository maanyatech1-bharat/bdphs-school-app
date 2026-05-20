// lib/screens/shared/student_profile_screen.dart
// Read-only student profile — used by search_students_screen.dart
// when admin or teacher taps a student card
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class StudentProfileScreen extends StatefulWidget {
  final StudentModel student;
  const StudentProfileScreen({super.key, required this.student});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _loadingAttendance = true;
  int _present = 0;
  int _absent = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadAttendanceSummary();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadAttendanceSummary() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('attendance')
          .where('studentId', isEqualTo: widget.student.uid)
          .get();

      final docs = snap.docs;
      final present = docs.where((d) => d.data()['isPresent'] == true).length;
      setState(() {
        _total = docs.length;
        _present = present;
        _absent = docs.length - present;
        _loadingAttendance = false;
      });
    } catch (_) {
      setState(() => _loadingAttendance = false);
    }
  }

  double get _pct => _total == 0 ? 0 : (_present / _total * 100);

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    final name = s.fullName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.studentColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                    gradient: AppColors.studentGradient),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Avatar
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        backgroundImage: s.photoUrl != null
                            ? NetworkImage(s.photoUrl!)
                            : null,
                        child: s.photoUrl == null
                            ? Text(initial,
                                style: GoogleFonts.poppins(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white))
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Text(name,
                          style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      Text(s.className,
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabs,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Details'),
                Tab(text: 'Attendance'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            // ── TAB 1: Details ──────────────────────────────────────
            _DetailsTab(student: s),

            // ── TAB 2: Attendance ───────────────────────────────────
            _AttendanceTab(
              loading: _loadingAttendance,
              present: _present,
              absent: _absent,
              total: _total,
              pct: _pct,
              studentId: s.uid,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Details Tab ───────────────────────────────────────────────────────────────
class _DetailsTab extends StatelessWidget {
  final StudentModel student;
  const _DetailsTab({required this.student});

  @override
  Widget build(BuildContext context) {
    final s = student;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status badge
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: s.approvalStatus == 'approved'
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: s.approvalStatus == 'approved'
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ),
            child: Text(
              s.approvalStatus == 'approved'
                  ? '✅ Approved Student'
                  : '⏳ ${s.approvalStatus}',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: s.approvalStatus == 'approved'
                      ? AppColors.success
                      : AppColors.warning),
            ),
          ),
        ),
        const SizedBox(height: 20),

        _sectionHead('Personal Information'),
        _tile(Icons.person_rounded, 'Full Name', s.fullName),
        _tile(Icons.email_rounded, 'Email', s.email),
        _tile(Icons.phone_rounded, 'Phone',
            s.phone.isNotEmpty ? s.phone : '—'),
        if (s.gender.isNotEmpty)
          _tile(Icons.wc_rounded, 'Gender', s.gender),
        _tile(Icons.cake_rounded, 'Date of Birth',
            DateFormat('dd MMMM yyyy').format(s.dateOfBirth)),
        if (s.address.isNotEmpty)
          _tile(Icons.location_on_rounded, 'Address', s.address),

        const SizedBox(height: 16),
        _sectionHead('Academic Information'),
        _tile(Icons.school_rounded, 'Class', s.className),
        _tile(Icons.badge_rounded, 'Roll Number',
            s.rollNumber.isNotEmpty ? s.rollNumber : '—'),

        const SizedBox(height: 16),
        _sectionHead('Family Information'),
        _tile(Icons.person_rounded, "Father's Name",
            s.fatherName.isNotEmpty ? s.fatherName : '—'),
        _tile(Icons.person_rounded, "Mother's Name",
            s.motherName.isNotEmpty ? s.motherName : '—'),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _sectionHead(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5)),
      );

  Widget _tile(IconData icon, String label, String value) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
          ],
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: AppColors.studentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppColors.studentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary)),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
        ]),
      );
}

// ── Attendance Tab ────────────────────────────────────────────────────────────
class _AttendanceTab extends StatelessWidget {
  final bool loading;
  final int present, absent, total;
  final double pct;
  final String studentId;
  const _AttendanceTab({
    required this.loading, required this.present, required this.absent,
    required this.total, required this.pct, required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final pctColor = pct >= 75 ? AppColors.success : AppColors.error;
    final pctLabel = pct >= 75
        ? 'Good standing ✅'
        : pct >= 60
            ? '⚠️ Below 75% — needs attention'
            : '🚨 Critical — immediate action needed';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Big circle + summary
        Center(
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pctColor.withValues(alpha: 0.1),
              border: Border.all(color: pctColor, width: 6),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${pct.toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(
                      fontSize: 28, fontWeight: FontWeight.w900, color: pctColor)),
              Text('Attendance',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        Center(
          child: Text(pctLabel,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w700, color: pctColor)),
        ),
        const SizedBox(height: 20),

        // Stat cards
        Row(children: [
          _statBox('$present', 'Present', AppColors.success,
              Icons.check_circle_rounded),
          const SizedBox(width: 10),
          _statBox('$absent', 'Absent', AppColors.error, Icons.cancel_rounded),
          const SizedBox(width: 10),
          _statBox('$total', 'Total', AppColors.primary, Icons.people_rounded),
        ]),
        const SizedBox(height: 20),

        // Required 75% info
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.info_rounded,
                color: Color(0xFF2563EB), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Minimum required attendance is 75%. '
                'Student needs ${total == 0 ? '—' : '${(0.75 * total - present).ceil()} more'} '
                'present days to reach 75%.',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),

        // Recent records
        Text('RECENT RECORDS',
            style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1)),
        const SizedBox(height: 10),
        FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('attendance')
              .where('studentId', isEqualTo: studentId)
              .orderBy('date', descending: true)
              .limit(15)
              .get(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Text('No records found',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textHint)),
              );
            }
            return Column(
              children: docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                final isPresent = data['isPresent'] == true;
                final date = (data['date'] as Timestamp?)?.toDate();
                final dateStr = date != null
                    ? DateFormat('EEE, d MMM yyyy').format(date)
                    : '—';
                final teacher = data['markedByName'] ?? '—';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(
                        color: isPresent ? AppColors.success : AppColors.error,
                        width: 4,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6)
                    ],
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dateStr,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('By: $teacher',
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: AppColors.textHint)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isPresent
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isPresent
                                ? AppColors.success
                                : AppColors.error),
                      ),
                      child: Text(isPresent ? 'Present' : 'Absent',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isPresent
                                  ? AppColors.success
                                  : AppColors.error)),
                    ),
                  ]),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _statBox(String val, String label, Color color, IconData icon) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)
            ],
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(val,
                style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ),
      );
}