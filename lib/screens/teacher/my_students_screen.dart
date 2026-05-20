// lib/screens/teacher/my_students_screen.dart
// Teacher: view students class-wise — only Nursery, LKG, UKG, Class 1-10
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../shared/student_profile_screen.dart';

class MyStudentsScreen extends StatefulWidget {
  const MyStudentsScreen({super.key});
  @override
  State<MyStudentsScreen> createState() => _MyStudentsScreenState();
}

class _MyStudentsScreenState extends State<MyStudentsScreen> {
  // ✅ Only standard classes
  static const List<String> _classes = [
    'All',
    'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
  ];

  String _selectedClass = 'All';
  String _search = '';
  bool _loading = false;
  List<Map<String, dynamic>> _students = [];
  Map<String, int> _classCount = {};

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    try {
      // Fetch only from standard classes
      Query q = FirebaseFirestore.instance
          .collection('students')
          .where('approvalStatus', isEqualTo: 'approved')
          .where('className', whereIn: _classes.where((c) => c != 'All').toList());

      final snap = await q.get();
      final students = snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return {
          'uid': d.id,
          'name': data['fullName'] ?? '',
          'roll': data['rollNumber'] ?? '',
          'className': data['className'] ?? '',
          'phone': data['phone'] ?? '',
          'fatherName': data['fatherName'] ?? '',
          'photoUrl': data['photoUrl'],
          'data': data,
        };
      }).toList()
        ..sort((a, b) {
          final classOrder = _classes.indexOf(a['className'] as String)
              .compareTo(_classes.indexOf(b['className'] as String));
          if (classOrder != 0) return classOrder;
          return (a['roll'] as String).compareTo(b['roll'] as String);
        });

      // Count per class
      final count = <String, int>{};
      for (final s in students) {
        final cls = s['className'] as String;
        count[cls] = (count[cls] ?? 0) + 1;
      }

      setState(() {
        _students = students;
        _classCount = count;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _students;
    if (_selectedClass != 'All') {
      list = list.where((s) => s['className'] == _selectedClass).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((s) =>
          (s['name'] as String).toLowerCase().contains(q) ||
          (s['roll'] as String).contains(q) ||
          (s['phone'] as String).contains(q)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.teacherColor,
        foregroundColor: Colors.white,
        title: Text('My Students',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadStudents,
          ),
        ],
      ),
      body: Column(children: [
        // ── Search ──────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Search by name, roll number, phone...',
              hintStyle: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textHint),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          ),
        ),

        // ── Class filter chips ───────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _classes.length,
              itemBuilder: (_, i) {
                final cls = _classes[i];
                final sel = _selectedClass == cls;
                final count = cls == 'All'
                    ? _students.length
                    : (_classCount[cls] ?? 0);
                return GestureDetector(
                  onTap: () => setState(() => _selectedClass = cls),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.teacherColor
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel
                              ? AppColors.teacherColor
                              : AppColors.divider),
                      boxShadow: sel
                          ? [BoxShadow(
                              color: AppColors.teacherColor
                                  .withValues(alpha: 0.25),
                              blurRadius: 6)]
                          : [],
                    ),
                    child: Row(children: [
                      Text(cls,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: sel
                                  ? Colors.white
                                  : AppColors.textPrimary)),
                      if (count > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: sel
                                ? Colors.white.withValues(alpha: 0.25)
                                : AppColors.teacherColor
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('$count',
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: sel
                                      ? Colors.white
                                      : AppColors.teacherColor)),
                        ),
                      ],
                    ]),
                  ),
                );
              },
            ),
          ),
        ),
        const Divider(height: 1),

        // ── Count label ──────────────────────────────────────────────
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Text('${filtered.length} student${filtered.length != 1 ? 's' : ''} found',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
          ]),
        ),

        // ── Student list ─────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(
                  color: AppColors.teacherColor))
              : filtered.isEmpty
                  ? _empty()
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final s = filtered[i];
                        return _StudentCard(
                          student: s,
                          onTap: () => _openProfile(context, s),
                        );
                      },
                    ),
        ),
      ]),
    );
  }

  void _openProfile(BuildContext context, Map<String, dynamic> s) {
    try {
      final data = Map<String, dynamic>.from(s['data'] as Map<String, dynamic>)
        ..['uid'] = s['uid']; // ✅ inject uid into map
      final student = StudentModel.fromMap(data);
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => StudentProfileScreen(student: student)),
      );
    } catch (_) {}
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 72,
                color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No students found',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(
              _search.isNotEmpty
                  ? 'No match for "$_search"'
                  : 'No approved students in $_selectedClass',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
}

// ── Student Card ──────────────────────────────────────────────────────────────
class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> student;
  final VoidCallback onTap;
  const _StudentCard({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = student['name'] as String;
    final roll = student['roll'] as String;
    final cls  = student['className'] as String;
    final phone = student['phone'] as String;
    final photoUrl = student['photoUrl'] as String?;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          // Avatar
          CircleAvatar(
            radius: 26,
            backgroundColor:
                AppColors.teacherColor.withValues(alpha: 0.12),
            backgroundImage:
                photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Text(initial,
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.teacherColor))
                : null,
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Row(children: [
                _badge(cls, AppColors.teacherColor),
                const SizedBox(width: 6),
                if (roll.isNotEmpty) _badge('Roll: $roll', AppColors.primary),
              ]),
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.phone_rounded,
                      size: 12, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(phone,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textHint)),
                ]),
              ],
            ],
          )),

          // Attendance badge
          _AttendanceBadge(uid: student['uid'] as String),

          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textHint, size: 20),
        ]),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Text(text,
            style: GoogleFonts.poppins(
                fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      );
}

// ── Live attendance badge per student ─────────────────────────────────────────
class _AttendanceBadge extends StatelessWidget {
  final String uid;
  const _AttendanceBadge({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('studentId', isEqualTo: uid)
          .snapshots(),
      builder: (_, snap) {
        final docs = snap.data?.docs ?? [];
        final present =
            docs.where((d) => (d.data() as Map)['isPresent'] == true).length;
        final total = docs.length;
        final pct = total == 0 ? 0 : (present / total * 100).round();
        final color = pct >= 75
            ? AppColors.success
            : pct >= 50
                ? const Color(0xFFD97706)
                : AppColors.error;

        return Container(
          width: 52,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Column(children: [
            Text('$pct%',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w900, color: color)),
            Text('Att.',
                style: GoogleFonts.poppins(
                    fontSize: 9, color: AppColors.textHint)),
          ]),
        );
      },
    );
  }
}