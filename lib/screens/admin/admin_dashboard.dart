// lib/screens/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';

import '../shared/notices_screen.dart';
import '../shared/search_students_screen.dart';
import '../shared/timetable_screen.dart';
import '../shared/fee_screen.dart';
import '../shared/leave_screen.dart';
import '../shared/exam_schedule_screen.dart'; // ✅ Proper exam screen
import '../shared/books_screen.dart';
import '../shared/videos_screen.dart';
import '../shared/ai_chatbot_screen.dart';
import '../shared/progress_screen.dart';
import '../shared/leaderboard_screen.dart';
import '../shared/syllabus_gallery_material.dart';

import '../auth/login_screen.dart';
import '../shared/more_screens.dart' hide LeaderboardScreen;

import 'approve_students_screen.dart';
import 'approve_teachers_screen.dart';
import 'all_students_screen.dart';
import 'all_teachers_screen.dart';
import 'admin_teacher_attendance_screen.dart';
import '../shared/chat_screen.dart';
import '../shared/meeting_screen.dart';

// ─── Main Dashboard ──────────────────────────────────────────────────────────
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  Future<void> _signOut() async {
    final auth = context.read<AppAuthProvider>();
    await auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(onSignOut: _signOut),
      const AllStudentsScreen(),
      const AllTeachersScreen(),
      _ProfileTab(onSignOut: _signOut),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (!didPop && _currentIndex != 0) {
            setState(() => _currentIndex = 0);
          }
        },
        child: pages[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: AppColors.primary),
            label: 'Students',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school, color: AppColors.primary),
            label: 'Teachers',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─── Home Tab ────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final VoidCallback onSignOut;
  const _HomeTab({required this.onSignOut});

  void _go(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Dashboard',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white)),
            Text('Welcome, ${user?.fullName ?? 'Admin'}',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('Sign Out',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                  content: Text('Are you sure you want to sign out?',
                      style: GoogleFonts.poppins()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel',
                          style: GoogleFonts.poppins(color: AppColors.primary)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Sign Out',
                          style: GoogleFonts.poppins(
                              color: AppColors.error, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) onSignOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── APPROVALS ────────────────────────────────────────────
            _sectionHeader('✅ Pending Approvals', 'Review new registrations'),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: _ApprovalCard(
                  label: 'Students',
                  icon: Icons.person_add_rounded,
                  color: AppColors.studentColor,
                  collection: 'students',
                  onTap: () => _go(context, const ApproveStudentsScreen()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ApprovalCard(
                  label: 'Teachers',
                  icon: Icons.school_rounded,
                  color: AppColors.teacherColor,
                  collection: 'users',
                  roleFilter: 'teacher',
                  onTap: () => _go(context, const ApproveTeachersScreen()),
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // ── STUDENT MANAGEMENT ───────────────────────────────────
            _sectionHeader('👨‍🎓 Student Management', 'Manage all students'),
            const SizedBox(height: 14),
            _buildGrid([
              _FCard(Icons.people_rounded, 'All Students', AppColors.studentColor,
                  () => _go(context, const AllStudentsScreen())),
              _FCard(Icons.account_balance_wallet_rounded, 'Fee',
                  const Color(0xFF059669),
                  () => _go(context, const FeeScreen())),
              _FCard(Icons.beach_access_rounded, 'Leave', const Color(0xFFD97706),
                  () => _go(context, const LeaveScreen())),
              _FCard(Icons.event_rounded, 'Exams', const Color(0xFFDC2626),
                  () => _go(context, const ExamScheduleScreen())),
              _FCard(Icons.leaderboard_rounded, 'Leaderboard',
                  const Color(0xFF7C3AED),
                  () => _go(context, const LeaderboardScreen())),
            ]),
            const SizedBox(height: 24),

            // ── TEACHER MANAGEMENT ───────────────────────────────────
            _sectionHeader('👨‍🏫 Teacher Management', 'Manage all teachers'),
            const SizedBox(height: 14),
            _buildGrid([
              _FCard(Icons.school_rounded, 'Teachers', AppColors.teacherColor,
                  () => _go(context, const AllTeachersScreen())),
              _FCard(Icons.table_chart_rounded, 'Timetable', AppColors.primary,
                  () => _go(context, const TimetableScreen())),
              _FCard(Icons.menu_book_rounded, 'Books', const Color(0xFF059669),
                  () => _go(context, const BooksScreen())),
              _FCard(Icons.play_circle_rounded, 'Videos', const Color(0xFFDC2626),
                  () => _go(context, VideoScreen(user: user!))),
              _FCard(Icons.smart_toy_rounded, 'AI Tutor', const Color(0xFF7C3AED),
                  () => _go(context, AiChatbotScreen())),
              _FCard(Icons.notifications_rounded, 'Notices', AppColors.primary,
                  () => _go(context, const NoticesScreen())),
            ]),
            const SizedBox(height: 24),

            // ── COMMUNICATION ────────────────────────────────────────
            _sectionHeader('💬 Communication', 'Chat & Class Meetings'),
            const SizedBox(height: 14),
            _buildGrid([
              _FCard(Icons.chat_rounded, 'Class Chat', const Color(0xFF059669),
                  () => _go(context, const ChatScreen())),
              _FCard(Icons.video_call_rounded, 'Meetings',
                  const Color(0xFF2563EB),
                  () => _go(context, const MeetingScreen())),
            ]),
            const SizedBox(height: 24),

            // ── SCHOOL MANAGEMENT ────────────────────────────────────
            _sectionHeader('🏫 School Management', 'School-wide controls'),
            const SizedBox(height: 14),
            _buildGrid([
              _FCard(Icons.calendar_month_rounded, 'Calendar',
                  const Color(0xFF0891B2),
                  () => _go(context, SchoolCalendarScreen())),
              _FCard(Icons.phone_rounded, 'Emergency', const Color(0xFFDC2626),
                  () => _go(context, EmergencyContactsScreen())),
              _FCard(Icons.feedback_rounded, 'Complaints', const Color(0xFF7C3AED),
                  () => _go(context, ComplaintBoxScreen())),
              _FCard(Icons.how_to_reg_rounded, 'Teacher\nAttendance',
                  const Color(0xFFD97706),
                  () => _go(context, const AdminTeacherAttendanceScreen())),
              _FCard(Icons.bar_chart_rounded, 'Attendance', AppColors.primary,
                  () => _go(context, const AdminAttendanceViewScreen())),
              _FCard(Icons.checklist_rounded, 'Syllabus', const Color(0xFF16A34A),
                  () => _go(context, const SyllabusScreen())),
                _FCard(Icons.language_rounded, 'Our Website', const Color(0xFF0EA5E9),
                  () => launchUrl(Uri.parse('https://bdphs.in'), mode: LaunchMode.externalApplication)),
                _FCard(Icons.payment_rounded, 'Pay Fees', const Color(0xFF10B981),
                  () => launchUrl(Uri.parse('https://bdphs.in/fees.php'), mode: LaunchMode.externalApplication)),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(subtitle,
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
        ],
      );

  Widget _buildGrid(List<Widget> children) => GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
        children: children,
      );
}

// ─── Approval Card ───────────────────────────────────────────────────────────
class _ApprovalCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String collection;
  final String? roleFilter;
  final VoidCallback onTap;

  const _ApprovalCard({
    required this.label, required this.icon, required this.color,
    required this.collection, this.roleFilter, required this.onTap,
  });

  Stream<QuerySnapshot> _stream() {
    Query q = FirebaseFirestore.instance
        .collection(collection)
        .where('approvalStatus', isEqualTo: 'pending');
    if (roleFilter != null) q = q.where('role', isEqualTo: roleFilter);
    return q.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _stream(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: count > 0 ? color.withValues(alpha: 0.4) : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const Spacer(),
                  if (count > 0)
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      child: Center(
                        child: Text('$count',
                            style: GoogleFonts.poppins(
                                fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    )
                  else
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.success.withValues(alpha: 0.8), size: 18),
                ]),
                const SizedBox(height: 10),
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(
                  count > 0 ? '$count pending' : 'All reviewed',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: count > 0 ? color : AppColors.textSecondary,
                      fontWeight: count > 0 ? FontWeight.w600 : FontWeight.w400),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Feature Card ─────────────────────────────────────────────────────────────
class _FCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _FCard(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: GoogleFonts.poppins(
                        fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ),
            ],
          ),
        ),
      );
}

// ─── Profile Tab ──────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final VoidCallback onSignOut;
  const _ProfileTab({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text('Admin Profile',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 46,
            backgroundColor: AppColors.adminColor.withValues(alpha: 0.12),
            child: const Icon(Icons.admin_panel_settings_rounded,
                size: 50, color: AppColors.adminColor),
          ),
          const SizedBox(height: 16),
          Text(user?.fullName ?? 'Admin',
              style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(user?.email ?? '',
              style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          _infoTile(Icons.badge_rounded, 'Role', 'Administrator'),
          const SizedBox(height: 12),
          _infoTile(Icons.school_rounded, 'School', 'Blooming Dale Public High School'),
          const SizedBox(height: 12),
          if (user?.phone != null && user!.phone.isNotEmpty)
            _infoTile(Icons.phone_rounded, 'Phone', user.phone),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Sign Out',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                    content: Text('Are you sure you want to sign out?',
                        style: GoogleFonts.poppins()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel',
                            style: GoogleFonts.poppins(color: AppColors.primary)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Sign Out',
                            style: GoogleFonts.poppins(
                                color: AppColors.error, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) onSignOut();
              },
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              label: Text('Sign Out',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: AppColors.adminColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.adminColor, size: 20),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ]),
        ]),
      );
}

// ─── Admin Attendance View ────────────────────────────────────────────────────
class AdminAttendanceViewScreen extends StatefulWidget {
  const AdminAttendanceViewScreen({super.key});

  @override
  State<AdminAttendanceViewScreen> createState() =>
      _AdminAttendanceViewScreenState();
}

class _AdminAttendanceViewScreenState extends State<AdminAttendanceViewScreen> {
  final List<String> _classes = [
    'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
  ];
  String _selectedClass = 'Class 1';
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;
  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    setState(() => _loading = true);
    try {
      final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final end = start.add(const Duration(days: 1));

      // Composite index on attendance: className (ASC) + date (ASC)
      // Index created at Firebase Console → Firestore → Indexes
      final snap = await FirebaseFirestore.instance
          .collection('attendance')
          .where('className', isEqualTo: _selectedClass)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end))
          .get();

      final records = snap.docs.map((d) {
        final data = d.data();
        return {
          'studentId': data['studentId'] ?? '',
          'name': data['studentName'] ?? 'Unknown',
          'isPresent': data['isPresent'] ?? false,
          'markedByName': data['markedByName'] ?? '—',
        };
      }).toList();

      records.sort((a, b) {
        if (a['isPresent'] == b['isPresent']) {
          return (a['name'] as String).compareTo(b['name'] as String);
        }
        return (a['isPresent'] as bool) ? 1 : -1;
      });

      setState(() { _records = records; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _fetchAttendance();
    }
  }

  int get _presentCount => _records.where((r) => r['isPresent'] == true).length;
  int get _absentCount => _records.where((r) => r['isPresent'] == false).length;
  String get _dateLabel => DateFormat('dd MMM yyyy').format(_selectedDate);
  double get _attendancePct =>
      _records.isEmpty ? 0 : (_presentCount / _records.length) * 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text('Attendance Overview',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: _fetchAttendance,
          ),
        ],
      ),
      body: Column(children: [
        // ── Filters ──────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedClass,
                decoration: InputDecoration(
                  labelText: 'Class',
                  labelStyle: GoogleFonts.poppins(
                      color: AppColors.textSecondary, fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 13),
                items: _classes
                    .map((c) => DropdownMenuItem(
                        value: c, child: Text(c, style: GoogleFonts.poppins())))
                    .toList(),
                onChanged: (v) {
                  setState(() => _selectedClass = v!);
                  _fetchAttendance();
                },
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(_dateLabel,
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ]),
              ),
            ),
          ]),
        ),

        // ── Summary Cards ─────────────────────────────────────────────
        if (!_loading && _records.isNotEmpty)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(children: [
              _SummaryBox(
                  label: 'Present', count: _presentCount,
                  color: AppColors.success, icon: Icons.check_circle_rounded),
              const SizedBox(width: 10),
              _SummaryBox(
                  label: 'Absent', count: _absentCount,
                  color: AppColors.error, icon: Icons.cancel_rounded),
              const SizedBox(width: 10),
              _SummaryBox(
                  label: 'Total', count: _records.length,
                  color: AppColors.primary, icon: Icons.people_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    color: _attendancePct >= 75
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _attendancePct >= 75
                          ? AppColors.success.withValues(alpha: 0.4)
                          : AppColors.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(children: [
                    Text('${_attendancePct.toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _attendancePct >= 75
                                ? AppColors.success
                                : AppColors.error)),
                    Text('Attendance',
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: AppColors.textSecondary)),
                  ]),
                ),
              ),
            ]),
          ),

        const Divider(height: 1),

        // ── Student List ──────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _records.isEmpty
                  ? _EmptyAttendance(className: _selectedClass, date: _dateLabel)
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _records.length,
                      itemBuilder: (_, i) {
                        final r = _records[i];
                        final isPresent = r['isPresent'] as bool;
                        final name = r['name'] as String;
                        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
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
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: isPresent
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : AppColors.error.withValues(alpha: 0.15),
                              child: Text(initial,
                                  style: GoogleFonts.poppins(
                                      color: isPresent ? AppColors.success : AppColors.error,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: GoogleFonts.poppins(
                                          fontSize: 14, fontWeight: FontWeight.w600)),
                                  Text('Marked by: ${r['markedByName']}',
                                      style: GoogleFonts.poppins(
                                          fontSize: 11, color: AppColors.textHint)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isPresent
                                    ? AppColors.success.withValues(alpha: 0.12)
                                    : AppColors.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: isPresent ? AppColors.success : AppColors.error),
                              ),
                              child: Text(
                                isPresent ? 'Present' : 'Absent',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isPresent ? AppColors.success : AppColors.error),
                              ),
                            ),
                          ]),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}

// ── Summary Box ───────────────────────────────────────────────────────────────
class _SummaryBox extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _SummaryBox(
      {required this.label, required this.count, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 2),
          Text('$count',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary)),
        ]),
      );
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyAttendance extends StatelessWidget {
  final String className, date;
  const _EmptyAttendance({required this.className, required this.date});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded,
                size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No attendance recorded',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text('$className  •  $date',
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              'The teacher has not marked attendance\nfor this class on this date yet.',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textHint, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}