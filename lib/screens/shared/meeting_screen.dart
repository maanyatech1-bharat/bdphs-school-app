// lib/screens/shared/meeting_screen.dart
// Class Meeting Scheduler — Teacher schedules, students join via Google Meet
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/fcm_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../services/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key});
  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AppAuthProvider>(context, listen: false)
        .currentUser;
    final canCreate = user?.role == UserRole.teacher ||
                      user?.role == UserRole.admin;
    _tabs = TabController(length: canCreate ? 2 : 1, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser;
    final canCreate = user?.role == UserRole.teacher ||
                      user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        title: Text('Class Meetings',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700)),
        bottom: canCreate ? TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: '📋 All Meetings'),
            Tab(text: '➕ Schedule Meeting'),
          ],
        ) : null,
      ),
      body: canCreate
          ? TabBarView(
              controller: _tabs,
              children: [
                _MeetingList(user: user),
                _ScheduleMeeting(user: user),
              ],
            )
          : _MeetingList(user: user),
    );
  }
}

// ─── Meeting List ─────────────────────────────────────────────────────────────
class _MeetingList extends StatefulWidget {
  final dynamic user;
  const _MeetingList({required this.user});
  @override
  State<_MeetingList> createState() => _MeetingListState();
}

class _MeetingListState extends State<_MeetingList> {
  String _filter = 'All';
  static const _classes = [
    'All', 'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
  ];

  Future<void> _joinMeeting(BuildContext ctx, String link) async {
    if (link.trim().isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
          content: Text('No meeting link provided'),
          backgroundColor: AppColors.error));
      return;
    }
    String url = link.trim();
    if (!url.startsWith('http')) url = 'https://$url';
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Could not open meeting link'),
              backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user      = widget.user;
    final isStudent = user?.role == UserRole.student;
    final isTeacher = user?.role == UserRole.teacher;
    final isAdmin   = user?.role == UserRole.admin;

    // Auto-filter for students
    if (isStudent && user?.className != null) {
      _filter = user!.className;
    }

    return Column(children: [
      // Filter (teacher/admin only)
      if (isTeacher || isAdmin) ...[
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(10),
          child: DropdownButtonFormField<String>(
            value: _filter,
            decoration: InputDecoration(
              labelText: 'Filter by Class',
              isDense: true,
              prefixIcon: const Icon(Icons.filter_list_rounded, size: 18),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textPrimary),
            items: _classes.map((c) => DropdownMenuItem(
                value: c,
                child: Text(c,
                    style: GoogleFonts.poppins(fontSize: 13)))).toList(),
            onChanged: (v) => setState(() => _filter = v!),
          ),
        ),
        const Divider(height: 1),
      ],

      // Meeting list
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('meetings')
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
                color: Color(0xFF2563EB)));
          }

          var docs = snap.data?.docs ?? [];

          // Filter by class
          if (_filter != 'All') {
            docs = docs.where((d) =>
                (d.data() as Map)['className'] == _filter ||
                (d.data() as Map)['className'] == 'All Classes').toList();
          }

          // Sort by meeting time
          docs = List.from(docs)..sort((a, b) {
            final at = (a.data() as Map)['meetingTime'] as Timestamp?;
            final bt = (b.data() as Map)['meetingTime'] as Timestamp?;
            if (at == null) return 1;
            if (bt == null) return -1;
            return bt.compareTo(at);
          });

          if (docs.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_call_outlined, size: 72,
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('No Meetings Scheduled',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  isStudent
                      ? 'Your teacher will schedule a class meeting here'
                      : 'Schedule a meeting from the "Schedule" tab',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d        = docs[i].data() as Map<String, dynamic>;
              final docId    = docs[i].id;
              final title    = d['title'] as String? ?? 'Class Meeting';
              final cls      = d['className'] as String? ?? '';
              final link     = d['meetingLink'] as String? ?? '';
              final duration = d['duration'] as String? ?? '60 mins';
              final platform = d['platform'] as String? ?? 'Google Meet';
              final teacher  = d['teacherName'] as String? ?? '';
              final agenda   = d['agenda'] as String? ?? '';
              final meetTime = (d['meetingTime'] as Timestamp?)?.toDate();
              final now      = DateTime.now();
              final isUpcoming = meetTime != null && meetTime.isAfter(now);
              final isLive   = meetTime != null &&
                  meetTime.isBefore(now) &&
                  meetTime.add(const Duration(hours: 2)).isAfter(now);
              final canDelete = isTeacher || isAdmin;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border(left: BorderSide(
                    color: isLive ? const Color(0xFF059669)
                        : isUpcoming ? const Color(0xFF2563EB)
                        : Colors.grey.shade300,
                    width: 4,
                  )),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10)],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(title,
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w800))),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLive
                                ? const Color(0xFF059669).withValues(alpha: 0.1)
                                : isUpcoming
                                ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isLive ? const Color(0xFF059669)
                                  : isUpcoming ? const Color(0xFF2563EB)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min,
                              children: [
                            if (isLive)
                              Container(
                                width: 6, height: 6,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: const BoxDecoration(
                                    color: Color(0xFF059669),
                                    shape: BoxShape.circle),
                              ),
                            Text(
                              isLive ? '🔴 LIVE'
                                  : isUpcoming ? '📅 Upcoming'
                                  : '✅ Completed',
                              style: GoogleFonts.poppins(
                                  fontSize: 10, fontWeight: FontWeight.w800,
                                  color: isLive ? const Color(0xFF059669)
                                      : isUpcoming ? const Color(0xFF2563EB)
                                      : Colors.grey),
                            ),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 10),

                      // Details
                      _detailRow(Icons.class_rounded, cls),
                      if (meetTime != null) ...[
                        const SizedBox(height: 4),
                        _detailRow(Icons.calendar_today_rounded,
                            DateFormat('EEEE, dd MMM yyyy').format(meetTime)),
                        const SizedBox(height: 4),
                        _detailRow(Icons.access_time_rounded,
                            '${DateFormat('hh:mm a').format(meetTime)}  •  $duration'),
                      ],
                      const SizedBox(height: 4),
                      _detailRow(Icons.video_call_rounded, platform),
                      const SizedBox(height: 4),
                      _detailRow(Icons.person_rounded, 'By $teacher'),
                      if (agenda.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.notes_rounded,
                                  size: 14, color: AppColors.textHint),
                              const SizedBox(width: 6),
                              Expanded(child: Text(agenda,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.textSecondary))),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      Row(children: [
                        // Join button
                        if (link.isNotEmpty)
                          Expanded(child: ElevatedButton.icon(
                            onPressed: () => _joinMeeting(context, link),
                            icon: const Icon(Icons.video_call_rounded,
                                color: Colors.white, size: 18),
                            label: Text(
                              isLive ? 'Join Now' : 'Join Meeting',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isLive
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF2563EB),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          )),
                        const SizedBox(width: 8),
                        // Copy link
                        if (link.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.copy_rounded,
                                color: AppColors.textSecondary, size: 20),
                            tooltip: 'Copy link',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: link));
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('✅ Meeting link copied!'),
                                      duration: Duration(seconds: 1)));
                            },
                          ),
                        // Delete
                        if (canDelete)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.error, size: 20),
                            onPressed: () => _confirmDelete(context, docId),
                          ),
                      ]),
                    ],
                  ),
                ),
              );
            },
          );
        },
      )),
    ]);
  }

  Future<void> _confirmDelete(BuildContext ctx, String docId) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Meeting?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('This will remove the meeting for all students.',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('No', style: GoogleFonts.poppins())),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error),
              child: Text('Delete',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseFirestore.instance
          .collection('meetings').doc(docId).delete();
    }
  }

  Widget _detailRow(IconData icon, String text) => Row(children: [
        Icon(icon, size: 13, color: AppColors.textHint),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: GoogleFonts.poppins(
            fontSize: 12, color: AppColors.textSecondary))),
      ]);
}

// ─── Schedule Meeting ─────────────────────────────────────────────────────────
class _ScheduleMeeting extends StatefulWidget {
  final dynamic user;
  const _ScheduleMeeting({required this.user});
  @override
  State<_ScheduleMeeting> createState() => _ScheduleMeetingState();
}

class _ScheduleMeetingState extends State<_ScheduleMeeting> {
  final _titleCtrl   = TextEditingController();
  final _linkCtrl    = TextEditingController();
  final _agendaCtrl  = TextEditingController();
  String _class    = 'Class 10';
  String _platform = 'Google Meet';
  String _duration = '30 mins';
  DateTime _date   = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time  = const TimeOfDay(hour: 10, minute: 0);
  bool _saving     = false;

  static const _classes = [
    'All Classes', 'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
  ];
  static const _platforms = [
    'Google Meet', 'Zoom', 'Microsoft Teams', 'Jitsi Meet', 'Other'
  ];
  static const _durations = [
    '30 mins', '45 mins', '1 Hour', '1.5 Hours', '2 Hours'
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _linkCtrl.dispose();
    _agendaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
                primary: Color(0xFF2563EB))),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
                primary: Color(0xFF2563EB))),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _schedule() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter a meeting title'),
          backgroundColor: AppColors.error));
      return;
    }
    if (_linkCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please paste the meeting link'),
          backgroundColor: AppColors.error));
      return;
    }

    setState(() => _saving = true);
    try {
      final meetDateTime = DateTime(
          _date.year, _date.month, _date.day,
          _time.hour, _time.minute);

      await FirebaseFirestore.instance.collection('meetings').add({
        'title':       _titleCtrl.text.trim(),
        'className':   _class,
        'meetingLink': _linkCtrl.text.trim(),
        'platform':    _platform,
        'duration':    _duration,
        'agenda':      _agendaCtrl.text.trim(),
        'meetingTime': Timestamp.fromDate(meetDateTime),
        'teacherId':   widget.user?.uid ?? '',
        'teacherName': widget.user?.fullName ?? '',
        'createdAt':   FieldValue.serverTimestamp(),
      });

      _titleCtrl.clear();
      _linkCtrl.clear();
      _agendaCtrl.clear();
      setState(() {
        _date = DateTime.now().add(const Duration(days: 1));
        _time = const TimeOfDay(hour: 10, minute: 0);
      });

      // Notify class
      await NotificationSender.notifyClass(
        className: _class,
        title: '📅 Meeting Scheduled - ${_titleCtrl.text.trim()}',
        body: 'A meeting has been scheduled. Check the meetings section for details.',
        type: 'meeting',
        senderId: widget.user?.uid,
        senderName: widget.user?.fullName,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Meeting scheduled! Students will see it.'),
              backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Info banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('How to create a meeting link:',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB))),
            const SizedBox(height: 6),
            _step('1',
                'Open meet.google.com on your phone/laptop'),
            _step('2', 'Click "New Meeting" → "Create for later"'),
            _step('3', 'Copy the meeting link'),
            _step('4', 'Paste it below'),
          ]),
        ),
        const SizedBox(height: 20),

        // Title
        _lbl('Meeting Title *'),
        TextField(
          controller: _titleCtrl,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: _dec('e.g. Class 10 - Science Doubt Session'),
        ),
        const SizedBox(height: 14),

        // Class
        _lbl('For Class *'),
        _dd('Class', _class, _classes,
            (v) => setState(() => _class = v!)),
        const SizedBox(height: 14),

        // Platform
        _lbl('Platform'),
        _dd('Platform', _platform, _platforms,
            (v) => setState(() => _platform = v!)),
        const SizedBox(height: 14),

        // Meeting link
        _lbl('Meeting Link *'),
        TextField(
          controller: _linkCtrl,
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: _dec('Paste Google Meet / Zoom link here').copyWith(
            prefixIcon: const Icon(Icons.link_rounded, size: 18),
          ),
        ),
        const SizedBox(height: 14),

        // Date & Time
        _lbl('Date & Time *'),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2563EB)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 16, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Text(DateFormat('dd MMM yyyy').format(_date),
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: const Color(0xFF2563EB))),
              ]),
            ),
          )),
          const SizedBox(width: 10),
          Expanded(child: GestureDetector(
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2563EB)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.access_time_rounded,
                    size: 16, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Text(_time.format(context),
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: const Color(0xFF2563EB))),
              ]),
            ),
          )),
        ]),
        const SizedBox(height: 14),

        // Duration
        _lbl('Duration'),
        _dd('Duration', _duration, _durations,
            (v) => setState(() => _duration = v!)),
        const SizedBox(height: 14),

        // Agenda
        _lbl('Agenda / Topic (optional)'),
        TextField(
          controller: _agendaCtrl,
          maxLines: 3,
          style: GoogleFonts.poppins(fontSize: 13),
          decoration: _dec('What will be covered in this meeting?'),
        ),
        const SizedBox(height: 28),

        // Schedule button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _schedule,
            icon: _saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : const Icon(Icons.video_call_rounded,
                    color: Colors.white, size: 20),
            label: Text(
              _saving ? 'Scheduling...' : 'Schedule Meeting',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(child: Text(
          'Students of $_class will see this meeting',
          style: GoogleFonts.poppins(
              fontSize: 11, color: AppColors.textHint),
        )),
        const SizedBox(height: 30),
      ]),
    );
  }

  Widget _lbl(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w700)),
      );

  Widget _step(String n, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 18, height: 18,
            decoration: const BoxDecoration(
                color: Color(0xFF2563EB), shape: BoxShape.circle),
            child: Center(child: Text(n, style: GoogleFonts.poppins(
                fontSize: 9, color: Colors.white,
                fontWeight: FontWeight.w800))),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.poppins(
              fontSize: 11, color: AppColors.textSecondary))),
        ]),
      );

  Widget _dd(String hint, String value, List<String> items,
      void Function(String?) fn) =>
      DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          hintText: hint, isDense: true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 13),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        style: GoogleFonts.poppins(
            fontSize: 13, color: AppColors.textPrimary),
        items: items.map((i) => DropdownMenuItem(
            value: i,
            child: Text(i, style: GoogleFonts.poppins(
                fontSize: 13)))).toList(),
        onChanged: fn,
      );

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.poppins(
        fontSize: 12, color: AppColors.textHint),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(
        horizontal: 12, vertical: 13),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.divider)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
            color: Color(0xFF2563EB), width: 2)),
  );
}