// lib/screens/teacher/take_attendance_screen.dart
// Enhanced attendance:
//   P = Present  |  A = Absent  |  L = Leave  |  H = Holiday
// Sundays auto-marked as H
// Teacher can pick any date (past or today)
// View attendance history by class + date
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';

// ── Status helpers ─────────────────────────────────────────────────────────────
const _P = 'P'; // Present
const _A = 'A'; // Absent
const _L = 'L'; // Leave
const _H = 'H'; // Holiday

Color _statusColor(String s) {
  switch (s) {
    case _P: return const Color(0xFF059669); // green
    case _A: return const Color(0xFFDC2626); // red
    case _L: return const Color(0xFFD97706); // amber
    case _H: return const Color(0xFF6366F1); // indigo
    default: return AppColors.textHint;
  }
}

String _statusLabel(String s) {
  switch (s) {
    case _P: return 'Present';
    case _A: return 'Absent';
    case _L: return 'Leave';
    case _H: return 'Holiday';
    default: return '—';
  }
}

// Cycle P → A → L → P (H cannot be cycled manually)
String _nextStatus(String current) {
  switch (current) {
    case _P: return _A;
    case _A: return _L;
    default: return _P;
  }
}

// ─── Screen ────────────────────────────────────────────────────────────────────
class TakeAttendanceScreen extends StatefulWidget {
  const TakeAttendanceScreen({super.key});
  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen>
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
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        title: Text('Attendance',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: '✏️ Mark Attendance'),
            Tab(text: '📋 View History'),
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

// ─── Mark Attendance Tab ───────────────────────────────────────────────────────
class _MarkTab extends StatefulWidget {
  const _MarkTab();
  @override
  State<_MarkTab> createState() => _MarkTabState();
}

class _MarkTabState extends State<_MarkTab> {
  static const List<String> _classes = [
    'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
  ];

  String _selectedClass = 'Class 1';
  DateTime _selectedDate = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);

  List<Map<String, dynamic>> _students = [];
  Map<String, String> _status = {}; // uid → P/A/L/H
  bool _loading  = false;
  bool _saving   = false;
  bool _isSunday = false;
  String _holidayName = '';

  @override
  void initState() {
    super.initState();
    _checkAndLoad();
  }

  DateTime get _dateOnly =>
      DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
                primary: Color(0xFF2563EB))),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _checkAndLoad();
    }
  }

  Future<void> _checkAndLoad() async {
    setState(() { _loading = true; _holidayName = ''; });

    // 1️⃣ Check Sunday
    final isSunday = _selectedDate.weekday == DateTime.sunday;

    // 2️⃣ Check Firestore holidays
    String holidayName = '';
    if (!isSunday) {
      final start = Timestamp.fromDate(_dateOnly);
      final end = Timestamp.fromDate(
          _dateOnly.add(const Duration(days: 1)));
      try {
        final hSnap = await FirebaseFirestore.instance
            .collection('school_holidays')
            .where('date', isGreaterThanOrEqualTo: start)
            .where('date', isLessThan: end)
            .limit(1)
            .get();
        if (hSnap.docs.isNotEmpty) {
          holidayName = hSnap.docs.first.data()['reason'] as String? ??
              'Holiday';
        }
      } catch (_) {}
    }

    setState(() {
      _isSunday = isSunday;
      _holidayName = holidayName;
    });

    if (isSunday || holidayName.isNotEmpty) {
      setState(() => _loading = false);
      return;
    }

    await _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() { _loading = true; _students = []; _status = {}; });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('students')
          .where('className', isEqualTo: _selectedClass)
          .where('approvalStatus', isEqualTo: 'approved')
          .get();

      final students = snap.docs.map((d) => {
            'uid': d.id,
            'name': d.data()['fullName'] ?? 'Unknown',
            'roll': d.data()['rollNumber'] ?? '',
          }).toList()
        ..sort((a, b) =>
            (a['roll'] as String).compareTo(b['roll'] as String));

      // Load saved attendance for this date + class
      final existing = await FirebaseFirestore.instance
          .collection('attendance')
          .where('className', isEqualTo: _selectedClass)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_dateOnly))
          .where('date',
              isLessThan: Timestamp.fromDate(
                  _dateOnly.add(const Duration(days: 1))))
          .get();

      final savedMap = <String, String>{};
      for (final d in existing.docs) {
        savedMap[d.data()['studentId'] as String] =
            d.data()['status'] as String? ??
                (d.data()['isPresent'] == true ? _P : _A);
      }

      final statusMap = <String, String>{};
      for (final s in students) {
        final uid = s['uid'] as String;
        statusMap[uid] = savedMap[uid] ?? _P;
      }

      setState(() {
        _students = students;
        _status   = statusMap;
        _loading  = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _markHoliday() async {
    final nameCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Mark as Holiday',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            hintText: 'Holiday name (e.g. Eid, Diwali)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                  backgroundColor: const Color(0xFF6366F1)),
              child: Text('Mark Holiday',
                  style: GoogleFonts.poppins(color: Colors.white))),
        ],
      ),
    );
    if (confirmed == true && nameCtrl.text.trim().isNotEmpty) {
      await FirebaseFirestore.instance.collection('school_holidays').add({
        'date': Timestamp.fromDate(_dateOnly),
        'dateStr': DateFormat('yyyy-MM-dd').format(_dateOnly),
        'reason': nameCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() => _holidayName = nameCtrl.text.trim());
    }
  }

  Future<void> _saveAttendance() async {
    if (_students.isEmpty) return;
    setState(() => _saving = true);
    final user = context.read<AppAuthProvider>().currentUser;
    try {
      // Delete existing
      final existing = await FirebaseFirestore.instance
          .collection('attendance')
          .where('className', isEqualTo: _selectedClass)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_dateOnly))
          .where('date',
              isLessThan: Timestamp.fromDate(
                  _dateOnly.add(const Duration(days: 1))))
          .get();
      final del = FirebaseFirestore.instance.batch();
      for (final d in existing.docs) del.delete(d.reference);
      await del.commit();

      // Write new
      final write = FirebaseFirestore.instance.batch();
      for (final s in _students) {
        final uid = s['uid'] as String;
        final st  = _status[uid] ?? _P;
        final ref = FirebaseFirestore.instance.collection('attendance').doc();
        write.set(ref, {
          'studentId': uid,
          'studentName': s['name'],
          'rollNumber': s['roll'],
          'className': _selectedClass,
          'status': st,
          'isPresent': st == _P,           // backward-compat
          'date': Timestamp.fromDate(_dateOnly),
          'markedBy': user?.uid ?? '',
          'markedByName': user?.fullName ?? 'Teacher',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await write.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Attendance saved!'),
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

  void _setAll(String st) =>
      setState(() { for (final s in _students) _status[s['uid'] as String] = st; });

  int _count(String st) => _status.values.where((v) => v == st).length;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEE, dd MMM yyyy').format(_selectedDate);
    final isSpecialDay = _isSunday || _holidayName.isNotEmpty;

    return Column(children: [
      // ── Date + Class selector ─────────────────────────────────────
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          // Date picker button
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2563EB)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    color: Color(0xFF2563EB), size: 18),
                const SizedBox(width: 10),
                Text(dateLabel,
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: const Color(0xFF2563EB))),
                const Spacer(),
                if (_isSunday)
                  _pill('Sunday', const Color(0xFF6366F1))
                else if (_holidayName.isNotEmpty)
                  _pill(_holidayName, const Color(0xFF6366F1))
                else
                  Text('Tap to change date',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textHint)),
              ]),
            ),
          ),
          const SizedBox(height: 10),

          // Class dropdown
          DropdownButtonFormField<String>(
            value: _selectedClass,
            decoration: InputDecoration(
              labelText: 'Select Class',
              labelStyle: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.class_rounded,
                  color: Color(0xFF2563EB), size: 20),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
            items: _classes.map((c) => DropdownMenuItem(
                value: c,
                child: Text(c,
                    style: GoogleFonts.poppins(fontSize: 13)))).toList(),
            onChanged: isSpecialDay ? null : (v) {
              setState(() => _selectedClass = v!);
              _fetchStudents();
            },
          ),

          // Stats row when students loaded
          if (!isSpecialDay && _students.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: [
              _statChip('${_count(_P)}', 'Present', _statusColor(_P)),
              const SizedBox(width: 6),
              _statChip('${_count(_A)}', 'Absent', _statusColor(_A)),
              const SizedBox(width: 6),
              _statChip('${_count(_L)}', 'Leave', _statusColor(_L)),
              const SizedBox(width: 6),
              _statChip('${_students.length}', 'Total',
                  const Color(0xFF2563EB)),
            ]),
            const SizedBox(height: 10),
            // Quick buttons
            Row(children: [
              Expanded(child: _quickBtn('All P', _P, _statusColor(_P))),
              const SizedBox(width: 6),
              Expanded(child: _quickBtn('All A', _A, _statusColor(_A))),
              const SizedBox(width: 6),
              Expanded(child: _quickBtn('All L', _L, _statusColor(_L))),
              const SizedBox(width: 6),
              // Mark as Holiday button
              OutlinedButton(
                onPressed: _markHoliday,
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  side: BorderSide(color: _statusColor(_H)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('H',
                    style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w800,
                        color: _statusColor(_H))),
              ),
            ]),
          ],
        ]),
      ),
      const Divider(height: 1),

      // ── Content area ─────────────────────────────────────────────
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(
                color: Color(0xFF2563EB)))
            : isSpecialDay
                ? _holidayView()
                : _students.isEmpty
                    ? _emptyView()
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _students.length,
                        itemBuilder: (_, i) => _studentRow(i),
                      ),
      ),

      // ── Save button ───────────────────────────────────────────────
      if (!isSpecialDay && _students.isNotEmpty)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _saveAttendance,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: AppColors.divider,
              ),
              icon: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Icon(Icons.save_rounded,
                      color: Colors.white, size: 20),
              label: Text(_saving ? 'Saving...' : 'Save Attendance',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ),
    ]);
  }

  Widget _studentRow(int i) {
    final s   = _students[i];
    final uid = s['uid'] as String;
    final st  = _status[uid] ?? _P;
    final name = s['name'] as String;
    final roll = s['roll'] as String;
    final color = _statusColor(st);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Row(children: [
        // Roll
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
              shape: BoxShape.circle),
          child: Center(child: Text(roll.isNotEmpty ? roll : '${i + 1}',
              style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: const Color(0xFF2563EB)))),
        ),
        const SizedBox(width: 10),
        // Initial avatar
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ),
        const SizedBox(width: 10),
        // Name
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w700)),
            Text(_statusLabel(st),
                style: GoogleFonts.poppins(
                    fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        )),

        // Tap to cycle P → A → L → P
        GestureDetector(
          onTap: () =>
              setState(() => _status[uid] = _nextStatus(_status[uid] ?? _P)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46, height: 38,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(20)),
            child: Center(child: Text(st,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w900,
                    color: Colors.white))),
          ),
        ),

        // Long-press to mark H
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => setState(() => _status[uid] = _H),
          child: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: st == _H
                  ? _statusColor(_H)
                  : _statusColor(_H).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: _statusColor(_H).withValues(alpha: 0.5)),
            ),
            child: Center(child: Text('H',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w900,
                    color: st == _H ? Colors.white : _statusColor(_H)))),
          ),
        ),
      ]),
    );
  }

  Widget _holidayView() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(_isSunday ? '☀️' : '🎉',
              style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text(_isSunday ? 'Sunday' : _holidayName,
              style: GoogleFonts.poppins(
                  fontSize: 24, fontWeight: FontWeight.w900,
                  color: _statusColor(_H))),
          const SizedBox(height: 8),
          Text(
            _isSunday
                ? 'No attendance on Sundays'
                : 'This date is marked as a holiday',
            style: GoogleFonts.poppins(
                fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (_holidayName.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () async {
                // Remove holiday
                final start = Timestamp.fromDate(_dateOnly);
                final end = Timestamp.fromDate(
                    _dateOnly.add(const Duration(days: 1)));
                final snap = await FirebaseFirestore.instance
                    .collection('school_holidays')
                    .where('date', isGreaterThanOrEqualTo: start)
                    .where('date', isLessThan: end)
                    .get();
                final batch = FirebaseFirestore.instance.batch();
                for (final d in snap.docs) batch.delete(d.reference);
                await batch.commit();
                setState(() => _holidayName = '');
                _fetchStudents();
              },
              icon: const Icon(Icons.undo_rounded, size: 16),
              label: Text('Remove Holiday',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error)),
            ),
        ]),
      );

  Widget _emptyView() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.people_outline_rounded, size: 64,
              color: AppColors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No students in $_selectedClass',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Approve students first',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary)),
        ]),
      );

  Widget _statChip(String val, String label, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(children: [
            Text(val, style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: GoogleFonts.poppins(
                fontSize: 9, color: AppColors.textSecondary)),
          ]),
        ),
      );

  Widget _quickBtn(String label, String st, Color color) => GestureDetector(
        onTap: () => _setAll(st),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Center(child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, fontWeight: FontWeight.w800, color: color))),
        ),
      );

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.4))),
        child: Text(text, style: GoogleFonts.poppins(
            fontSize: 10, fontWeight: FontWeight.w800, color: color)),
      );
}

// ─── View History Tab ──────────────────────────────────────────────────────────
class _ViewTab extends StatefulWidget {
  const _ViewTab();
  @override
  State<_ViewTab> createState() => _ViewTabState();
}

class _ViewTabState extends State<_ViewTab> {
  static const List<String> _classes = [
    'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
  ];

  String _selectedClass = 'Class 1';
  DateTime _selectedDate = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);

  DateTime get _dateOnly =>
      DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
                primary: Color(0xFF2563EB))),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEE, dd MMM yyyy').format(_selectedDate);
    final isSunday  = _selectedDate.weekday == DateTime.sunday;

    return Column(children: [
      // Filters
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          // Date picker
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2563EB)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    color: Color(0xFF2563EB), size: 18),
                const SizedBox(width: 10),
                Text(dateLabel,
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: const Color(0xFF2563EB))),
                const Spacer(),
                if (isSunday) _pill('Sunday', const Color(0xFF6366F1))
                else const Icon(Icons.arrow_drop_down_rounded,
                    color: Color(0xFF2563EB)),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          // Class
          DropdownButtonFormField<String>(
            value: _selectedClass,
            decoration: InputDecoration(
              labelText: 'Class', isDense: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixIcon: const Icon(Icons.class_rounded,
                  color: Color(0xFF2563EB), size: 20),
            ),
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
            items: _classes.map((c) => DropdownMenuItem(
                value: c,
                child: Text(c, style: GoogleFonts.poppins(fontSize: 13)))).toList(),
            onChanged: (v) => setState(() => _selectedClass = v!),
          ),
        ]),
      ),
      const Divider(height: 1),

      // Results
      Expanded(child: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('attendance')
            .where('className', isEqualTo: _selectedClass)
            .where('date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(_dateOnly))
            .where('date',
                isLessThan: Timestamp.fromDate(
                    _dateOnly.add(const Duration(days: 1))))
            .get(),
        key: ValueKey('$_selectedClass-$_selectedDate'),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
                color: Color(0xFF2563EB)));
          }

          if (isSunday) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('☀️', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 12),
                Text('Sunday — No Attendance',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: _statusColor(_H))),
              ],
            ));
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy_rounded, size: 64,
                    color: AppColors.primary.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('No attendance for this date',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('$_selectedClass  •  $dateLabel',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ));
          }

          // Summary
          final records = docs.map((d) => d.data() as Map<String, dynamic>).toList();
          records.sort((a, b) =>
              (a['rollNumber'] as String? ?? '')
                  .compareTo(b['rollNumber'] as String? ?? ''));
          final pCount = records.where((r) => (r['status'] ?? _P) == _P).length;
          final aCount = records.where((r) => (r['status'] ?? _P) == _A).length;
          final lCount = records.where((r) => r['status'] == _L).length;
          final hCount = records.where((r) => r['status'] == _H).length;

          return Column(children: [
            // Summary banner
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _summaryItem('$pCount', 'Present', Colors.greenAccent),
                  _vDivider(),
                  _summaryItem('$aCount', 'Absent', Colors.redAccent),
                  _vDivider(),
                  _summaryItem('$lCount', 'Leave', Colors.orangeAccent),
                  _vDivider(),
                  _summaryItem('$hCount', 'Holiday', Colors.white60),
                  _vDivider(),
                  _summaryItem('${records.length}', 'Total', Colors.white70),
                ],
              ),
            ),

            // Student records
            Expanded(child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
              itemCount: records.length,
              itemBuilder: (_, i) {
                final r  = records[i];
                final st = r['status'] as String? ?? _P;
                final color = _statusColor(st);
                final name = r['studentName'] as String? ?? '—';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                        left: BorderSide(color: color, width: 4)),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6)],
                  ),
                  child: Row(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                          shape: BoxShape.circle),
                      child: Center(child: Text(
                          r['rollNumber'] as String? ?? '—',
                          style: GoogleFonts.poppins(
                              fontSize: 11, fontWeight: FontWeight.w800,
                              color: const Color(0xFF2563EB)))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                        Text('By: ${r['markedByName'] ?? '—'}',
                            style: GoogleFonts.poppins(
                                fontSize: 10, color: AppColors.textHint)),
                      ],
                    )),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color),
                      ),
                      child: Text('$st  ${_statusLabel(st)}',
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w800,
                              color: color)),
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

  Widget _summaryItem(String val, String label, Color color) =>
      Column(children: [
        Text(val, style: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: GoogleFonts.poppins(
            fontSize: 9, color: Colors.white60)),
      ]);

  Widget _vDivider() => Container(
      width: 1, height: 32,
      color: Colors.white.withValues(alpha: 0.2));

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4))),
        child: Text(text, style: GoogleFonts.poppins(
            fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      );
}