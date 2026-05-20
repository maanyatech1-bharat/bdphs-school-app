// lib/screens/admin/admin_teacher_attendance_screen.dart
// Admin marks and views daily attendance for all teachers
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

class AdminTeacherAttendanceScreen extends StatefulWidget {
  const AdminTeacherAttendanceScreen({super.key});
  @override
  State<AdminTeacherAttendanceScreen> createState() =>
      _AdminTeacherAttendanceScreenState();
}

class _AdminTeacherAttendanceScreenState
    extends State<AdminTeacherAttendanceScreen>
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
        title: Text('Teacher Attendance',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: '✏️ Mark Today'),
            Tab(text: '📋 View Records'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _MarkTab(),
          _ViewTab(),
        ],
      ),
    );
  }
}

// ─── Mark Attendance Tab ──────────────────────────────────────────────────────
class _MarkTab extends StatefulWidget {
  const _MarkTab();
  @override
  State<_MarkTab> createState() => _MarkTabState();
}

class _MarkTabState extends State<_MarkTab> {
  List<Map<String, dynamic>> _teachers = [];
  Map<String, bool> _attendance = {};   // uid → present/absent
  bool _loading = true;
  bool _saving = false;
  bool _alreadySaved = false;

  final _today = DateTime(
    DateTime.now().year, DateTime.now().month, DateTime.now().day);
  String get _todayLabel =>
      DateFormat('EEEE, dd MMMM yyyy').format(_today);

  // ✅ Sunday or marked holiday
  bool get _isSunday => _today.weekday == DateTime.sunday;
  bool _isHoliday = false;
  String _holidayName = '';

  @override
  void initState() {
    super.initState();
    _checkHoliday();
    if (!_isSunday) _loadTeachers();
  }

  Future<void> _checkHoliday() async {
    // Check if today is marked as holiday in Firestore
    try {
      final snap = await FirebaseFirestore.instance
          .collection('school_holidays')
          .where('date', isEqualTo: Timestamp.fromDate(_today))
          .get();
      if (snap.docs.isNotEmpty) {
        setState(() {
          _isHoliday = true;
          _holidayName = snap.docs.first.data()['name'] ?? 'Holiday';
        });
      }
    } catch (_) {}
  }

  Future<void> _markHoliday() async {
    final nameCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Mark Holiday',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            hintText: 'Holiday name (e.g. Diwali)',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.poppins())),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626)),
              child: Text('Mark Holiday',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('school_holidays').add({
        'date': Timestamp.fromDate(_today),
        'name': nameCtrl.text.trim().isEmpty
            ? 'Holiday' : nameCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _isHoliday = true;
        _holidayName = nameCtrl.text.trim().isEmpty
            ? 'Holiday' : nameCtrl.text.trim();
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Holiday marked!'),
              backgroundColor: AppColors.success));
    }
  }

  Future<void> _loadTeachers() async {
    setState(() => _loading = true);
    try {
      // Fetch approved teachers
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .where('approvalStatus', isEqualTo: 'approved')
          .get();

      final teachers = snap.docs.map((d) => {
        'uid': d.id,
        'name': d.data()['fullName'] ?? 'Unknown',
        'subject': d.data()['subject'] ?? '',
        'phone': d.data()['phone'] ?? '',
      }).toList();

      // Check if attendance already marked today
      final existing = await FirebaseFirestore.instance
          .collection('teacher_attendance')
          .where('date', isEqualTo: Timestamp.fromDate(_today))
          .limit(1)
          .get();

      Map<String, bool> saved = {};
      bool alreadySaved = false;

      if (existing.docs.isNotEmpty) {
        alreadySaved = true;
        final existingFull = await FirebaseFirestore.instance
            .collection('teacher_attendance')
            .where('date', isEqualTo: Timestamp.fromDate(_today))
            .get();
        for (final d in existingFull.docs) {
          saved[d.data()['teacherId'] as String] =
              d.data()['isPresent'] as bool? ?? true;
        }
      } else {
        // Default all to present
        for (final t in teachers) {
          saved[t['uid'] as String] = true;
        }
      }

      setState(() {
        _teachers = teachers;
        _attendance = saved;
        _alreadySaved = alreadySaved;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveAttendance() async {
    setState(() => _saving = true);
    try {
      // Delete existing records for today first
      final existing = await FirebaseFirestore.instance
          .collection('teacher_attendance')
          .where('date', isEqualTo: Timestamp.fromDate(_today))
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final d in existing.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();

      // Save new records
      final batch2 = FirebaseFirestore.instance.batch();
      for (final t in _teachers) {
        final uid = t['uid'] as String;
        final ref = FirebaseFirestore.instance.collection('teacher_attendance').doc();
        batch2.set(ref, {
          'teacherId': uid,
          'teacherName': t['name'],
          'subject': t['subject'],
          'isPresent': _attendance[uid] ?? true,
          'date': Timestamp.fromDate(_today),
          'markedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch2.commit();

      setState(() { _saving = false; _alreadySaved = true; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Teacher attendance saved!'),
            backgroundColor: AppColors.success));
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error));
      }
    }
  }

  Widget _holidayBanner(String title, String subtitle,
      {bool isAutomatic = false}) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.beach_access_rounded,
              size: 50, color: Color(0xFFDC2626)),
        ),
        const SizedBox(height: 20),
        Text(title, style: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.w800,
            color: const Color(0xFFDC2626)),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(subtitle, style: GoogleFonts.poppins(
            fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(DateFormat('EEEE, dd MMMM yyyy').format(_today),
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textHint)),
        if (isAutomatic) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFFD97706).withValues(alpha: 0.3)),
            ),
            child: Text('No attendance needed on Sundays',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: const Color(0xFFD97706),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ]),
    ));
  }

  void _toggleAll(bool present) {
    setState(() {
      for (final t in _teachers) {
        _attendance[t['uid'] as String] = present;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Sunday — auto holiday
    if (_isSunday) {
      return _holidayBanner('🌟 Sunday Holiday',
          'Today is Sunday — school holiday', isAutomatic: true);
    }
    // ✅ Marked holiday
    if (_isHoliday) {
      return _holidayBanner('🎉 $_holidayName',
          'This day has been marked as a school holiday');
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator(
          color: Color(0xFFD97706)));
    }
    if (_teachers.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64,
              color: AppColors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No approved teachers found',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          Text('Approve teachers first from the dashboard',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ));
    }

    final presentCount = _attendance.values.where((v) => v).length;
    final absentCount = _attendance.values.where((v) => !v).length;

    return Column(children: [
      // ── Header ─────────────────────────────────────────────────────
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.calendar_today_rounded,
                size: 16, color: Color(0xFFD97706)),
            const SizedBox(width: 8),
            Expanded(child: Text(_todayLabel,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary))),
            // ✅ Holiday button
            TextButton.icon(
              onPressed: _markHoliday,
              icon: const Icon(Icons.beach_access_rounded,
                  size: 14, color: Color(0xFFDC2626)),
              label: Text('Holiday',
                  style: GoogleFonts.poppins(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: const Color(0xFFDC2626))),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626).withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
            if (_alreadySaved) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success),
                ),
                child: Text('Saved ✅',
                    style: GoogleFonts.poppins(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppColors.success)),
              ),
            ],
          ]),
          const SizedBox(height: 12),

          // Summary row
          Row(children: [
            _summaryChip('${_teachers.length}', 'Total',
                const Color(0xFFD97706)),
            const SizedBox(width: 8),
            _summaryChip('$presentCount', 'Present', AppColors.success),
            const SizedBox(width: 8),
            _summaryChip('$absentCount', 'Absent', AppColors.error),
          ]),
          const SizedBox(height: 12),

          // Quick toggle buttons
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _toggleAll(true),
              icon: const Icon(Icons.check_circle_outline_rounded,
                  size: 16, color: AppColors.success),
              label: Text('All Present',
                  style: GoogleFonts.poppins(
                      color: AppColors.success, fontWeight: FontWeight.w600,
                      fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.success),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            )),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _toggleAll(false),
              icon: const Icon(Icons.cancel_outlined,
                  size: 16, color: AppColors.error),
              label: Text('All Absent',
                  style: GoogleFonts.poppins(
                      color: AppColors.error, fontWeight: FontWeight.w600,
                      fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            )),
          ]),
        ]),
      ),
      const Divider(height: 1),

      // ── Teacher list ───────────────────────────────────────────────
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _teachers.length,
        itemBuilder: (_, i) {
          final t = _teachers[i];
          final uid = t['uid'] as String;
          final isPresent = _attendance[uid] ?? true;
          final name = t['name'] as String;
          final subject = t['subject'] as String;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(
                color: isPresent ? AppColors.success : AppColors.error,
                width: 4,
              )),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6)],
            ),
            child: Row(children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: isPresent
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.error.withValues(alpha: 0.12),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'T',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w800,
                      color: isPresent ? AppColors.success : AppColors.error),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w700)),
                  if (subject.isNotEmpty)
                    Text(subject, style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textHint)),
                ],
              )),

              // P / A toggle
              GestureDetector(
                onTap: () => setState(() =>
                    _attendance[uid] = !(_attendance[uid] ?? true)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isPresent
                        ? AppColors.success
                        : AppColors.error,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPresent ? 'P' : 'A',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                ),
              ),
            ]),
          );
        },
      )),

      // ── Save button ────────────────────────────────────────────────
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _saveAttendance,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              disabledBackgroundColor: AppColors.divider,
            ),
            child: _saving
                ? const SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Text(
                    _alreadySaved ? 'Update Attendance' : 'Save Attendance',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: Colors.white)),
          ),
        ),
      ),
    ]);
  }

  Widget _summaryChip(String value, String label, Color color) =>
      Expanded(child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Text(value, style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: GoogleFonts.poppins(
              fontSize: 10, color: AppColors.textSecondary)),
        ]),
      ));
}

// ─── View Records Tab ─────────────────────────────────────────────────────────
class _ViewTab extends StatefulWidget {
  const _ViewTab();
  @override
  State<_ViewTab> createState() => _ViewTabState();
}

class _ViewTabState extends State<_ViewTab> {
  DateTime _selectedDate = DateTime.now();

  String get _dateLabel =>
      DateFormat('dd MMM yyyy').format(_selectedDate);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
                primary: Color(0xFFD97706))),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final start = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day);
    final end = start.add(const Duration(days: 1));

    return Column(children: [
      // Date picker
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(14),
        child: GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD97706)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 18, color: Color(0xFFD97706)),
              const SizedBox(width: 10),
              Text(_dateLabel, style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: const Color(0xFFD97706))),
              const Spacer(),
              const Icon(Icons.arrow_drop_down_rounded,
                  color: Color(0xFFD97706)),
            ]),
          ),
        ),
      ),
      const Divider(height: 1),

      // Records
      Expanded(child: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('teacher_attendance')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('date', isLessThan: Timestamp.fromDate(end))
            .get(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
                color: Color(0xFFD97706)));
          }
          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy_rounded, size: 64,
                    color: AppColors.primary.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('No records for $_dateLabel',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('Mark attendance from "Mark Today" tab',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ));
          }

          final records = docs.map((d) => d.data() as Map<String, dynamic>).toList();
          records.sort((a, b) =>
              (a['teacherName'] as String).compareTo(b['teacherName'] as String));

          final present = records.where((r) => r['isPresent'] == true).length;
          final absent  = records.length - present;

          return Column(children: [
            // Summary
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFD97706).withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                _viewStat('${records.length}', 'Total',
                    const Color(0xFFD97706)),
                _viewStat('$present', 'Present', AppColors.success),
                _viewStat('$absent', 'Absent', AppColors.error),
                _viewStat(
                  '${(present / records.length * 100).toStringAsFixed(0)}%',
                  'Rate',
                  present / records.length >= 0.75
                      ? AppColors.success : AppColors.error,
                ),
              ]),
            ),

            Expanded(child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
              itemCount: records.length,
              itemBuilder: (_, i) {
                final r = records[i];
                final isPresent = r['isPresent'] == true;
                final name = r['teacherName'] as String? ?? '—';
                final subject = r['subject'] as String? ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border(left: BorderSide(
                      color: isPresent ? AppColors.success : AppColors.error,
                      width: 4,
                    )),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6)],
                  ),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isPresent
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.error.withValues(alpha: 0.12),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'T',
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w800,
                            color: isPresent
                                ? AppColors.success : AppColors.error),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                        if (subject.isNotEmpty)
                          Text(subject, style: GoogleFonts.poppins(
                              fontSize: 11, color: AppColors.textHint)),
                      ],
                    )),
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
                                ? AppColors.success : AppColors.error),
                      ),
                      child: Text(isPresent ? 'Present' : 'Absent',
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: isPresent
                                  ? AppColors.success : AppColors.error)),
                    ),
                  ]),
                );
              },
            )),
          ]);
        },
      )),
    ]);
  }

  Widget _viewStat(String val, String label, Color color) =>
      Expanded(child: Column(children: [
        Text(val, style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: GoogleFonts.poppins(
            fontSize: 10, color: AppColors.textSecondary)),
      ]));
}