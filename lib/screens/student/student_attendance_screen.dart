// lib/screens/student/student_attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/user_model.dart';
import '../../services/auth_provider.dart';
import '../../services/attendance_service.dart';
import '../../theme/app_theme.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});
  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calFormat = CalendarFormat.month;

  Map<DateTime, bool> _attendanceMap = {};
  List<AttendanceRecord> _records = [];
  bool _loading = true;

  late StudentModel _student;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AppAuthProvider>().currentUser;
      if (user is StudentModel) {
        _student = user as StudentModel;
        _loadAttendance();
      }
    });
  }

  Future<void> _loadAttendance() async {
    setState(() => _loading = true);
    try {
      final records = await AttendanceService().getStudentAttendance(
        studentId: _student.uid,
        className: _student.className,
      );
      _records = records;
      _attendanceMap = {
        for (final r in records)
          DateTime(r.date.year, r.date.month, r.date.day): r.isPresent
      };
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  int get _presentDays => _records.where((r) => r.isPresent).length;
  int get _absentDays => _records.where((r) => !r.isPresent).length;
  double get _percentage =>
      _records.isEmpty ? 0 : (_presentDays / _records.length * 100);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 160,
                  pinned: true,
                  backgroundColor: AppColors.studentColor,
                  foregroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text('My Attendance',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    background: Container(
                      decoration: const BoxDecoration(
                          gradient: AppColors.studentGradient),
                      child: SafeArea(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 60, 20, 12),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                            children: [
                              _TopStat(
                                  label: 'Present',
                                  value: '$_presentDays',
                                  color: Colors.white),
                              _TopStat(
                                  label: 'Absent',
                                  value: '$_absentDays',
                                  color: Colors.white70),
                              _TopStat(
                                  label: 'Total',
                                  value: '${_records.length}',
                                  color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // ── Overall Card (overflow fixed) ──
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _OverallCard(percentage: _percentage),
                      ),

                      // ── Calendar ──
                      Container(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 10),
                          ],
                        ),
                        child: TableCalendar(
                          firstDay: DateTime(2020),
                          lastDay: DateTime.now(),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (d) =>
                              isSameDay(_selectedDay, d),
                          calendarFormat: _calFormat,
                          onFormatChanged: (f) =>
                              setState(() => _calFormat = f),
                          onDaySelected: (sel, foc) => setState(() {
                            _selectedDay = sel;
                            _focusedDay = foc;
                          }),
                          onPageChanged: (foc) =>
                              setState(() => _focusedDay = foc),
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: false,
                            todayDecoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            markerDecoration: const BoxDecoration(),
                            defaultTextStyle: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textPrimary),
                            weekendTextStyle: GoogleFonts.poppins(
                                fontSize: 13, color: AppColors.error),
                          ),
                          headerStyle: HeaderStyle(
                            formatButtonVisible: true,
                            titleCentered: true,
                            formatButtonDecoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            formatButtonTextStyle: GoogleFonts.poppins(
                                fontSize: 12, color: AppColors.primary),
                            titleTextStyle: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            leftChevronIcon: const Icon(
                                Icons.chevron_left_rounded,
                                color: AppColors.primary),
                            rightChevronIcon: const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.primary),
                          ),
                          daysOfWeekStyle: DaysOfWeekStyle(
                            weekdayStyle: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600),
                            weekendStyle: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.error,
                                fontWeight: FontWeight.w600),
                          ),
                          calendarBuilders: CalendarBuilders(
                            defaultBuilder: (ctx, day, focDay) {
                              final key = DateTime(
                                  day.year, day.month, day.day);
                              final isPresent = _attendanceMap[key];
                              if (isPresent == null) return null;
                              return Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isPresent
                                      ? AppColors.success.withValues(alpha: 0.2)
                                      : AppColors.error.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isPresent
                                        ? AppColors.success
                                        : AppColors.error,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isPresent
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // ── Legend ──
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Row(
                          children: [
                            _Legend(
                                color: AppColors.success,
                                label: 'Present'),
                            const SizedBox(width: 16),
                            _Legend(
                                color: AppColors.error, label: 'Absent'),
                            const SizedBox(width: 16),
                            _Legend(
                                color: AppColors.textHint,
                                label: 'No record'),
                          ],
                        ),
                      ),

                      // ── Monthly Summary ──
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${DateFormat('MMMM yyyy').format(_focusedDay).toUpperCase()} SUMMARY',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                      _MonthlySummary(
                          records: _records, month: _focusedDay),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ── OVERALL CARD — overflow fixed ─────────────────────────────────────────────
class _OverallCard extends StatelessWidget {
  final double percentage;
  const _OverallCard({required this.percentage});

  @override
  Widget build(BuildContext context) {
    final color = percentage >= 75
        ? AppColors.success
        : percentage >= 60
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Circle indicator — fixed width, never grows
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeWidth: 8,
                ),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // ✅ FIX: Expanded wraps the Column so it never overflows right
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall Attendance',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 4),
                Text(
                  percentage >= 75
                      ? 'Excellent — Great work!'
                      : percentage >= 60
                          ? 'Below 75% — Needs improvement'
                          : 'Critical — Below required minimum',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Required minimum: 75%',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── MONTHLY SUMMARY ───────────────────────────────────────────────────────────
class _MonthlySummary extends StatelessWidget {
  final List<AttendanceRecord> records;
  final DateTime month;
  const _MonthlySummary({required this.records, required this.month});

  @override
  Widget build(BuildContext context) {
    final monthRecords = records
        .where((r) =>
            r.date.month == month.month && r.date.year == month.year)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (monthRecords.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14)),
          child: Center(
            child: Text('No attendance records for this month',
                style: GoogleFonts.poppins(
                    color: AppColors.textHint, fontSize: 13)),
          ),
        ),
      );
    }

    final present = monthRecords.where((r) => r.isPresent).length;
    final total = monthRecords.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('$present / $total days present',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const Spacer(),
                  Text(
                    '${(total == 0 ? 0 : present / total * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: total == 0
                          ? AppColors.textHint
                          : (present / total) >= 0.75
                              ? AppColors.success
                              : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...monthRecords.take(15).map((r) => _DayRow(record: r)),
            if (monthRecords.length > 15)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '+ ${monthRecords.length - 15} more records',
                  style: GoogleFonts.poppins(
                      color: AppColors.textHint, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final AttendanceRecord record;
  const _DayRow({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: record.isPresent
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${record.date.day}',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: record.isPresent
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(record.date),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  record.className,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: record.isPresent
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              record.isPresent ? 'Present' : 'Absent',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: record.isPresent
                    ? AppColors.success
                    : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _TopStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color)),
        Text(label,
            style: GoogleFonts.poppins(fontSize: 11, color: color)),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}