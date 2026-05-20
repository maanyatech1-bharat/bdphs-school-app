// lib/screens/shared/study_planner_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// ✅ FIX: removed unused import 'custom_widgets.dart' which caused the 1 error
import '../../theme/app_theme.dart';

class StudyPlannerScreen extends StatefulWidget {
  const StudyPlannerScreen({super.key});
  @override
  State<StudyPlannerScreen> createState() => _StudyPlannerScreenState();
}

class _StudyPlannerScreenState extends State<StudyPlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
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
        title: Text('Study Planner ⏱️',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'My Timetable'),
            Tab(text: 'Study Timer'),
            Tab(text: 'Study Tips'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _PersonalTimetable(),
          _StudyTimer(),
          _StudyTips(),
        ],
      ),
    );
  }
}

// ─── PERSONAL TIMETABLE ───────────────────────────────────────────────────────
class _PersonalTimetable extends StatefulWidget {
  const _PersonalTimetable();
  @override
  State<_PersonalTimetable> createState() => _PersonalTimetableState();
}

class _PersonalTimetableState extends State<_PersonalTimetable> {
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _subjects = [
    'Hindi', 'English', 'Math', 'Science', 'SST',
    'Sanskrit', 'Computer', 'Break', 'Exercise', 'Reading'
  ];
  final Map<String, Map<String, String>> _schedule = {};
  final List<String> _timeSlots = [
    '6-7 AM', '7-8 AM', '4-5 PM', '5-6 PM', '6-7 PM', '7-8 PM', '8-9 PM'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: AppColors.primary.withValues(alpha: 0.06),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded,
                color: AppColors.primary, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  'Tap any cell to assign a subject for self-study at home!',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textSecondary)),
            ),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                    AppColors.primary.withValues(alpha: 0.08)),
                columns: [
                  DataColumn(
                      label: Text('Time',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700, fontSize: 12))),
                  ..._days.map((d) => DataColumn(
                      label: Text(d,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700, fontSize: 12)))),
                ],
                rows: _timeSlots
                    .map((slot) => DataRow(cells: [
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(slot,
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary)),
                          )),
                          ..._days.map((day) {
                            final val = _schedule[slot]?[day] ?? '';
                            return DataCell(GestureDetector(
                              onTap: () => _showPicker(slot, day),
                              child: Container(
                                width: 72,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 6),
                                decoration: BoxDecoration(
                                  color: val.isEmpty
                                      ? AppColors.surface
                                      : _subjectColor(val)
                                          .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: val.isEmpty
                                          ? AppColors.divider
                                          : _subjectColor(val)),
                                ),
                                child: Text(val.isEmpty ? '+ Add' : val,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: val.isEmpty
                                            ? AppColors.textHint
                                            : _subjectColor(val))),
                              ),
                            ));
                          }),
                        ]))
                    .toList(),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _schedule.clear()),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text('Reset', style: GoogleFonts.poppins()),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('✅ Timetable saved!'),
                        backgroundColor: AppColors.success)),
                icon: const Icon(Icons.save_rounded, color: Colors.white, size: 16),
                label: Text('Save',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  void _showPicker(String slot, String day) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$slot — $day',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ..._subjects.map((s) => GestureDetector(
                    onTap: () {
                      setState(() {
                        _schedule.putIfAbsent(slot, () => {})[day] = s;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                          color: _subjectColor(s).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _subjectColor(s))),
                      child: Text(s,
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _subjectColor(s))),
                    ),
                  )),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _schedule.putIfAbsent(slot, () => {}).remove(day);
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.error)),
                  child: Text('Clear',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error)),
                ),
              ),
            ]),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Color _subjectColor(String s) {
    switch (s) {
      case 'Hindi':    return const Color(0xFFEF4444);
      case 'English':  return const Color(0xFF3B82F6);
      case 'Math':     return const Color(0xFF8B5CF6);
      case 'Science':  return const Color(0xFF10B981);
      case 'SST':      return const Color(0xFFF59E0B);
      case 'Sanskrit': return const Color(0xFFEC4899);
      case 'Computer': return const Color(0xFF06B6D4);
      case 'Break':    return const Color(0xFF6B7280);
      case 'Exercise': return const Color(0xFFEF4444);
      case 'Reading':  return const Color(0xFF059669);
      default:         return AppColors.primary;
    }
  }
}

// ─── STUDY TIMER ──────────────────────────────────────────────────────────────
class _StudyTimer extends StatefulWidget {
  const _StudyTimer();
  @override
  State<_StudyTimer> createState() => _StudyTimerState();
}

class _StudyTimerState extends State<_StudyTimer> {
  int _minutes = 25;
  int _seconds = 0;
  bool _running = false;
  bool _isBreak = false;
  int _sessions = 0;
  Timer? _timer;
  String _subject = 'Hindi';

  final List<String> _subjects = [
    'Hindi', 'English', 'Math', 'Science', 'SST', 'Sanskrit', 'Computer', 'Reading'
  ];
  final List<Map<String, dynamic>> _presets = [
    {'label': '⚡ Focus 25 min', 'min': 25},
    {'label': '📖 Deep 45 min', 'min': 45},
    {'label': '🎯 Quick 15 min', 'min': 15},
    {'label': '☕ Break 5 min', 'min': 5},
  ];

  void _start() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else if (_minutes > 0) {
          _minutes--;
          _seconds = 59;
        } else {
          _timer?.cancel();
          _running = false;
          _sessions++;
          if (!_isBreak) {
            _isBreak = true;
            _minutes = 5;
          } else {
            _isBreak = false;
            _minutes = 25;
          }
        }
      });
    });
    setState(() => _running = true);
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _minutes = 25;
      _seconds = 0;
      _isBreak = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _isBreak
        ? ((_minutes * 60 + _seconds) / 300)
        : ((_minutes * 60 + _seconds) / 1500);
    final color = _isBreak ? AppColors.success : AppColors.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        DropdownButtonFormField<String>(
          value: _subject,
          decoration: InputDecoration(
            labelText: 'Studying:',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            prefixIcon: const Icon(Icons.book_rounded),
          ),
          items: _subjects
              .map((s) => DropdownMenuItem(
                  value: s, child: Text(s, style: GoogleFonts.poppins())))
              .toList(),
          onChanged: (v) => setState(() => _subject = v!),
        ),
        const SizedBox(height: 24),

        Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: 220,
            height: 220,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 12,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_isBreak ? '☕ Break Time!' : '📚 Study Time',
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
            Text(
                '${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}',
                style: GoogleFonts.poppins(
                    fontSize: 48, fontWeight: FontWeight.w800, color: color)),
            Text(_subject,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            Text('Session $_sessions complete',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textHint)),
          ]),
        ]),
        const SizedBox(height: 24),

        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded,
                  size: 28, color: AppColors.error)),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: _running ? _pause : _start,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ]),
              child: Icon(
                  _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
              onPressed: () => setState(() {
                    _minutes = 5;
                    _seconds = 0;
                    _isBreak = true;
                  }),
              icon: const Icon(Icons.coffee_rounded,
                  size: 28, color: AppColors.success)),
        ]),
        const SizedBox(height: 24),

        Text('Quick Presets:',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presets
              .map((p) => GestureDetector(
                    onTap: () {
                      _timer?.cancel();
                      setState(() {
                        _running = false;
                        _minutes = p['min'] as int;
                        _seconds = 0;
                        _isBreak = p['min'] == 5;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3))),
                      child: Text(p['label'] as String,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('💡 Pomodoro Technique:',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success)),
            const SizedBox(height: 4),
            Text(
                'Study 25 min → Break 5 min → Repeat 4 times → Long break 15 min. This is proven to improve focus and memory!',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5)),
          ]),
        ),
      ]),
    );
  }
}

// ─── STUDY TIPS ───────────────────────────────────────────────────────────────
class _StudyTips extends StatelessWidget {
  const _StudyTips();

  static const List<Map<String, dynamic>> _tips = [
    {'emoji': '⏰', 'title': 'Early Morning Study', 'hindi': 'सुबह की पढ़ाई', 'desc': '5-7 AM is best time to study. Brain is fresh. Topics studied in morning are remembered longer.', 'color': Color(0xFFF59E0B)},
    {'emoji': '✍️', 'title': 'Write to Remember', 'hindi': 'लिखकर याद करें', 'desc': 'Write notes in your own words. Writing helps memory 3x better than just reading.', 'color': Color(0xFF3B82F6)},
    {'emoji': '🎯', 'title': 'One Subject at a Time', 'hindi': 'एक विषय एक बार', 'desc': 'Focus on ONE subject completely. Don\'t switch between subjects every 10 minutes.', 'color': Color(0xFF8B5CF6)},
    {'emoji': '🔄', 'title': 'Revise Daily', 'hindi': 'रोज दोहराएं', 'desc': 'Revise yesterday\'s topics for 15 minutes every morning. This locks it in long-term memory.', 'color': Color(0xFF10B981)},
    {'emoji': '💧', 'title': 'Stay Hydrated', 'hindi': 'पानी पीते रहें', 'desc': 'Drink water every 30 minutes while studying. Dehydration reduces brain performance by 15%!', 'color': Color(0xFF06B6D4)},
    {'emoji': '📵', 'title': 'Phone Away', 'hindi': 'फोन दूर रखें', 'desc': 'Keep phone in another room during study time. Phone notifications break concentration for 20+ minutes!', 'color': Color(0xFFEF4444)},
    {'emoji': '🌙', 'title': 'Sleep is Important', 'hindi': 'नींद जरूरी है', 'desc': '8-9 hours sleep is must for students. Brain processes and stores memories DURING sleep!', 'color': Color(0xFF6366F1)},
    {'emoji': '📊', 'title': 'Make Mind Maps', 'hindi': 'माइंड मैप बनाएं', 'desc': 'Draw diagrams and mind maps for complex topics. Visual learning is 60% more effective!', 'color': Color(0xFF059669)},
    {'emoji': '🏃', 'title': 'Exercise Boosts Brain', 'hindi': 'व्यायाम जरूरी', 'desc': '30 minutes exercise daily increases brain power and focus for next 4-6 hours. Study AFTER exercise!', 'color': Color(0xFFD97706)},
    {'emoji': '🎵', 'title': 'No Music While Studying', 'hindi': 'संगीत नहीं', 'desc': 'Music with lyrics reduces understanding by 40%. Use silence or nature sounds instead.', 'color': Color(0xFFEC4899)},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tips.length,
      itemBuilder: (_, i) {
        final t = _tips[i];
        final color = t['color'] as Color;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: color, width: 4)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t['emoji'] as String, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t['title'] as String,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: color)),
                    Text(t['hindi'] as String,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: color.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(t['desc'] as String,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}