// lib/screens/shared/timetable_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';

// ── Model ─────────────────────────────────────────────────────────────────────
class PeriodModel {
  final String id;
  final String className;
  final String day;
  final int period;
  final String subject;
  final String teacherName;
  final String forClass; // which class this period is for
  final String startTime;
  final String endTime;
  final String addedBy;

  PeriodModel({
    required this.id,
    required this.className,
    required this.day,
    required this.period,
    required this.subject,
    required this.teacherName,
    required this.forClass,
    required this.startTime,
    required this.endTime,
    required this.addedBy,
  });

  factory PeriodModel.fromMap(Map<String, dynamic> map, String id) {
    return PeriodModel(
      id: id,
      className: map['className'] ?? '',
      day: map['day'] ?? '',
      period: map['period'] ?? 1,
      subject: map['subject'] ?? '',
      teacherName: map['teacherName'] ?? '',
      forClass: map['forClass'] ?? map['roomNo'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      addedBy: map['addedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'className': className,
        'day': day,
        'period': period,
        'subject': subject,
        'teacherName': teacherName,
        'forClass': forClass,
        'startTime': startTime,
        'endTime': endTime,
        'addedBy': addedBy,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

// ── Main Screen ───────────────────────────────────────────────────────────────
class TimetableScreen extends StatefulWidget {
  final bool isTeacher;
  const TimetableScreen({super.key, this.isTeacher = false});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final _db = FirebaseFirestore.instance;

  String _selectedClass = 'Class 1';
  String _selectedDay = 'Mon';

  final List<String> _classes = [
    'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
  ];

  final List<String> _days = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'
  ];

  final Map<String, String> _dayFull = {
    'Mon': 'Monday',
    'Tue': 'Tuesday',
    'Wed': 'Wednesday',
    'Thu': 'Thursday',
    'Fri': 'Friday',
    'Sat': 'Saturday',
  };

  @override
  Widget build(BuildContext context) {
    final user = context.read<AppAuthProvider>().currentUser;
    final canAdd =
        widget.isTeacher || (user?.role.name == 'admin');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Class Timetable',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── Header: Class selector + Day tabs ────────────────
          Container(
            color: AppColors.primary,
            child: Column(
              children: [
                // Class dropdown
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedClass,
                      isExpanded: true,
                      underline: const SizedBox(),
                      dropdownColor: AppColors.primary,
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white),
                      items: _classes
                          .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c,
                                  style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      color: Colors.white))))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedClass = v!),
                    ),
                  ),
                ),

                // Day tabs
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _days.length,
                    itemBuilder: (ctx, i) {
                      final day = _days[i];
                      final selected = _selectedDay == day;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedDay = day),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: selected
                                    ? Colors.white
                                    : Colors.white38),
                          ),
                          child: Text(
                            day,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? AppColors.primary
                                  : Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // ── Period List ───────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('timetable')
                  .where('className', isEqualTo: _selectedClass)
                  .where('day', isEqualTo: _selectedDay)
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final docs = snap.data?.docs ?? [];

                // Build period map
                final Map<int, PeriodModel> periodMap = {};
                for (final doc in docs) {
                  final p = PeriodModel.fromMap(
                      doc.data() as Map<String, dynamic>, doc.id);
                  periodMap[p.period] = p;
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(14),
                  // Always show 10 periods
                  itemCount: 10,
                  itemBuilder: (ctx, i) {
                    final periodNum = i + 1;
                    final period = periodMap[periodNum];

                    return _PeriodTile(
                      periodNumber: periodNum,
                      period: period,
                      canEdit: canAdd,
                      onAdd: () => _showAddPeriod(
                          context, periodNum, user),
                      onDelete: period != null
                          ? () => _deletePeriod(period.id)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => _showAddPeriod(context, null, user),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text('Add Period',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  void _deletePeriod(String id) {
    _db.collection('timetable').doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Period deleted'),
      backgroundColor: AppColors.error,
    ));
  }

  void _showAddPeriod(
      BuildContext context, int? periodNum, dynamic user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPeriodSheet(
        className: _selectedClass,
        day: _selectedDay,
        dayFull: _dayFull[_selectedDay] ?? _selectedDay,
        initialPeriod: periodNum,
        user: user,
      ),
    );
  }
}

// ── Period Tile ───────────────────────────────────────────────────────────────
class _PeriodTile extends StatelessWidget {
  final int periodNumber;
  final PeriodModel? period;
  final bool canEdit;
  final VoidCallback onAdd;
  final VoidCallback? onDelete;

  const _PeriodTile({
    required this.periodNumber,
    required this.period,
    required this.canEdit,
    required this.onAdd,
    this.onDelete,
  });

  Color get _subjectColor {
    if (period == null) return AppColors.divider;
    switch (period!.subject) {
      case 'Mathematics':
        return const Color(0xFF2563EB);
      case 'Science':
        return const Color(0xFF059669);
      case 'Hindi':
        return const Color(0xFFDC2626);
      case 'English':
        return const Color(0xFF7C3AED);
      case 'Social Science':
        return const Color(0xFFD97706);
      case 'Computer':
        return const Color(0xFF0891B2);
      case 'Break':
      case 'Lunch':
        return const Color(0xFFF59E0B);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = period == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEmpty
              ? AppColors.divider
              : _subjectColor.withValues(alpha: 0.3),
          width: isEmpty ? 1 : 1.5,
        ),
        boxShadow: isEmpty
            ? []
            : [
                BoxShadow(
                  color: _subjectColor.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: isEmpty && canEdit ? onAdd : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Period number badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isEmpty
                      ? AppColors.background
                      : _subjectColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'P$periodNumber',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isEmpty
                        ? AppColors.textHint
                        : _subjectColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: isEmpty
                    ? Text(
                        canEdit
                            ? 'Tap to add Period $periodNumber'
                            : 'No class scheduled',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textHint,
                            fontStyle: FontStyle.italic),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            period!.subject,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded,
                                  size: 13,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(period!.teacherName,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color:
                                          AppColors.textSecondary)),
                              const SizedBox(width: 10),
                              if (period!.forClass.isNotEmpty) ...[
                                Icon(Icons.class_outlined,
                                    size: 13,
                                    color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(period!.forClass,
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColors
                                            .textSecondary)),
                              ],
                            ],
                          ),
                          if (period!.startTime.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded,
                                    size: 13,
                                    color: AppColors.textHint),
                                const SizedBox(width: 4),
                                Text(
                                  '${period!.startTime} — ${period!.endTime}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppColors.textHint),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
              ),

              // Actions
              if (!isEmpty && canEdit)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error, size: 20),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              else if (isEmpty && canEdit)
                Icon(Icons.add_circle_outline_rounded,
                    color: AppColors.textHint.withValues(alpha: 0.5),
                    size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add Period Sheet ──────────────────────────────────────────────────────────
class _AddPeriodSheet extends StatefulWidget {
  final String className;
  final String day;
  final String dayFull;
  final int? initialPeriod;
  final dynamic user;

  const _AddPeriodSheet({
    required this.className,
    required this.day,
    required this.dayFull,
    this.initialPeriod,
    required this.user,
  });

  @override
  State<_AddPeriodSheet> createState() => _AddPeriodSheetState();
}

class _AddPeriodSheetState extends State<_AddPeriodSheet> {
  final _db = FirebaseFirestore.instance;
  final _teacherCtrl = TextEditingController();
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();

  int _period = 1;
  String _subject = 'English';
  String _forClass = 'Class 1';
  bool _loading = false;

  final List<String> _subjects = [
    'English', 'Hindi', 'Mathematics', 'Science',
    'Social Science', 'Computer', 'Sanskrit', 'Urdu',
    'EVS', 'GK', 'Drawing', 'Physical Education',
    'Break', 'Lunch', 'Assembly', 'Sports',
  ];

  final List<String> _allClasses = [
    'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialPeriod != null) {
      _period = widget.initialPeriod!;
    }
    _forClass = widget.className;
  }

  @override
  void dispose() {
    _teacherCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_teacherCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter teacher name')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      // Check if period already exists for this class+day+period
      final existing = await _db
          .collection('timetable')
          .where('className', isEqualTo: widget.className)
          .where('day', isEqualTo: widget.day)
          .where('period', isEqualTo: _period)
          .get();

      // Delete existing if any
      for (final doc in existing.docs) {
        await doc.reference.delete();
      }

      final model = PeriodModel(
        id: '',
        className: widget.className,
        day: widget.day,
        period: _period,
        subject: _subject,
        teacherName: _teacherCtrl.text.trim(),
        forClass: _forClass,
        startTime: _startCtrl.text.trim(),
        endTime: _endCtrl.text.trim(),
        addedBy: widget.user?.uid ?? '',
      );

      await _db.collection('timetable').add(model.toMap());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Period added!'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    color: AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  'Add Period — ${widget.dayFull}',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
              ],
            ),
            Text(
              widget.className,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),

            // Period selector (1–10)
            _label('Period Number'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(10, (i) {
                final num = i + 1;
                final selected = _period == num;
                return GestureDetector(
                  onTap: () => setState(() => _period = num),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$num',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Subject
            _label('Subject'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _subject,
              decoration: _dropDeco(),
              items: _subjects
                  .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s,
                          style: GoogleFonts.poppins(fontSize: 14))))
                  .toList(),
              onChanged: (v) => setState(() => _subject = v!),
            ),
            const SizedBox(height: 14),

            // Teacher Name
            _label('Teacher Name'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _teacherCtrl,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: _inputDeco('e.g. Mrs. Sharma'),
            ),
            const SizedBox(height: 14),

            // For Class (replaces Room No)
            _label('Class'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _forClass,
              decoration: _dropDeco(),
              items: _allClasses
                  .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c,
                          style: GoogleFonts.poppins(fontSize: 14))))
                  .toList(),
              onChanged: (v) => setState(() => _forClass = v!),
            ),
            const SizedBox(height: 14),

            // Time row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Start Time'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _startCtrl,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: _inputDeco('e.g. 9:00 AM'),
                        onTap: () => _pickTime(_startCtrl),
                        readOnly: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('End Time'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _endCtrl,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: _inputDeco('e.g. 9:45 AM'),
                        onTap: () => _pickTime(_endCtrl),
                        readOnly: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _save,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_rounded,
                        color: Colors.white),
                label: Text(
                    _loading ? 'Saving...' : 'Add Period',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      ctrl.text = picked.format(context);
    }
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary));

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
            fontSize: 13, color: AppColors.textHint),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2)),
      );

  InputDecoration _dropDeco() => InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2)),
      );
}