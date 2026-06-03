// lib/screens/student/student_dashboard.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_model.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';

// Shared screens
import '../shared/notices_screen.dart';
import '../shared/homework_screen.dart';
import '../shared/exam_schedule_screen.dart'; // ✅ Dedicated exam screen
import '../shared/fee_screen.dart';
import '../shared/timetable_screen.dart';
import '../shared/leave_screen.dart';
import '../shared/books_screen.dart';
import '../shared/videos_screen.dart';
import '../shared/quiz_screen.dart';
import '../shared/ai_chatbot_screen.dart';
import '../shared/study_planner_screen.dart';
import '../shared/daily_content_screen.dart';
import '../shared/bharat_ko_jano_screen.dart';
import '../shared/more_screens.dart';
import '../shared/progress_screen.dart';
import '../shared/syllabus_gallery_material.dart' hide StudyMaterialScreen;
import '../shared/profile_edit_screen.dart'; // ✅ Profile edit
import '../shared/study_notes_screen.dart';
import '../shared/chat_screen.dart';          // ✅ Chat
import '../shared/meeting_screen.dart';       // ✅ Meetings

// Student-specific
import 'student_attendance_screen.dart';
import 'student_id_card_screen.dart';

// Auth
import '../auth/login_screen.dart';

// ─── Main Dashboard ──────────────────────────────────────────────────────────
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser;
    final pages = [
      _HomeTab(user: user),
      const StudentAttendanceScreen(),
      StudentProgressScreen(
          studentId: user?.uid ?? '',
          studentName: user?.fullName ?? 'Student',
          className: (user is StudentModel) ? (user as StudentModel).className : ''),
      _ProfileTab(user: user),
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
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.studentColor.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.studentColor),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon:
                Icon(Icons.calendar_today, color: AppColors.studentColor),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: AppColors.studentColor),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.studentColor),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─── Home Tab ────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final dynamic user;
  const _HomeTab({required this.user});

  void _go(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName ?? 'Student';
    final className =
        (user is StudentModel) ? (user as StudentModel).className : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.studentColor,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            // ✅ FIX: no title — was overlapping the avatar
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration:
                    const BoxDecoration(gradient: AppColors.studentGradient),
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // School name at top
                    Text('BDPHS Student',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white60,
                            letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Row(children: [
                      // Tappable avatar → profile edit
                      GestureDetector(
                        onTap: () => _go(context, const ProfileEditScreen()),
                        child: Stack(children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white.withValues(alpha: 0.3),
                            backgroundImage: user?.photoUrl != null
                                ? NetworkImage(user!.photoUrl!)
                                : null,
                            child: user?.photoUrl == null
                                ? Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                    style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white))
                                : null,
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 18, height: 18,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.studentColor,
                                      width: 1.5)),
                              child: Icon(Icons.edit,
                                  size: 10, color: AppColors.studentColor),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Welcome back! 👋',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: Colors.white70)),
                            Text(name,
                                style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            if (className.isNotEmpty)
                              Text(className,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: Colors.white70)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined,
                            color: Colors.white),
                        onPressed: () => _go(context, const NoticesScreen()),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Live attendance quick stats ───────────────────────
                _QuickStats(uid: user?.uid ?? ''),
                const SizedBox(height: 20),

                // ── ACADEMICS ─────────────────────────────────────────
                _section('📚 Academics'),
                const SizedBox(height: 12),
                _grid([
                  _card(Icons.assignment_rounded, 'Homework',
                      const Color(0xFF3B82F6),
                      () => _go(context, const HomeworkScreen())),
                  // ✅ Exam Sheet → dedicated ExamScheduleScreen
                  _card(Icons.event_rounded, 'Exam Sheet',
                      const Color(0xFFDC2626),
                      () => _go(context, const ExamScheduleScreen())),
                  // ✅ Results → StudentProgressScreen
                  _card(Icons.leaderboard_rounded, 'Results',
                      const Color(0xFF7C3AED),
                      () {
                        final u = context.read<AppAuthProvider>().currentUser;
                        _go(context, StudentProgressScreen(
                          studentId: u?.uid ?? '',
                          studentName: u?.fullName ?? 'Student',
                          className: (u is StudentModel) ? (u as StudentModel).className : '',
                        ));
                      }),
                  _card(Icons.table_chart_rounded, 'Timetable',
                      const Color(0xFF0891B2),
                      () => _go(context, const TimetableScreen())),
                  _card(Icons.checklist_rounded, 'Syllabus',
                      const Color(0xFF16A34A),
                      () => _go(context, const SyllabusScreen())),
                  _card(Icons.menu_book_rounded, 'Books',
                      const Color(0xFF059669),
                      () => _go(context, const BooksScreen())),
                ]),
                const SizedBox(height: 20),

                // ── COMMUNICATION ─────────────────────────────────────
                _section('💬 Communication'),
                const SizedBox(height: 12),
                _grid([
                  _card(Icons.chat_rounded, 'Chat', const Color(0xFF059669),
                      () => _go(context, const ChatScreen())),
                  _card(Icons.video_call_rounded, 'Meetings',
                      const Color(0xFF2563EB),
                      () => _go(context, const MeetingScreen())),
                ]),
                const SizedBox(height: 20),

                // ── LEARNING ──────────────────────────────────────────
                _section('🎓 Learning'),
                const SizedBox(height: 12),
                _grid([
                  _card(Icons.quiz_rounded, 'Quiz', const Color(0xFFD97706),
                      () => _go(context, const QuizListScreen())),
                  _card(Icons.play_circle_rounded, 'Videos',
                      const Color(0xFFEF4444),
                      () => _go(context, VideoScreen(user: user!))),
                  _card(Icons.smart_toy_rounded, 'AI Tutor',
                      const Color(0xFF7C3AED),
                      () => _go(context, AiChatbotScreen())),
                  _card(Icons.timer_rounded, 'Study Planner', AppColors.primary,
                      () => _go(context, const StudyPlannerScreen())),
                  _card(Icons.auto_stories_rounded, 'Study Notes',
                      const Color(0xFF0891B2),
                      () => _go(context, StudyNotesScreen())),
                ]),
                const SizedBox(height: 20),

                // ── MY SCHOOL ─────────────────────────────────────────
                _section('🏫 My School'),
                const SizedBox(height: 12),
                _grid([
                  _card(Icons.account_balance_wallet_rounded, 'Fee',
                      const Color(0xFF059669),
                      () => _go(context, const FeeScreen())),
                  _card(Icons.beach_access_rounded, 'Leave',
                      const Color(0xFFD97706),
                      () => _go(context, const LeaveScreen())),
                  _card(Icons.campaign_rounded, 'Notices',
                      const Color(0xFF7C3AED),
                      () => _go(context, const NoticesScreen())),
                  _card(Icons.credit_card_rounded, 'ID Card', AppColors.primary,
                      () => _go(context, const StudentIdCardScreen())),
                  _card(Icons.photo_library_rounded, 'Gallery',
                      const Color(0xFFEC4899),
                      () => _go(context, const GalleryScreen())),
                  _card(Icons.feedback_rounded, 'Complaint',
                      const Color(0xFFDC2626),
                      () => _go(context, const ComplaintBoxScreen())),
                ]),
                const SizedBox(height: 20),

                // ── DAILY & FUN ───────────────────────────────────────
                _section('🌟 Daily & Fun'),
                const SizedBox(height: 12),
                _grid([
                  _card(Icons.lightbulb_rounded, 'Daily Inspire',
                      const Color(0xFF7C3AED),
                      () => _go(context, const DailyInspirationScreen())),
                  _card(Icons.flag_rounded, 'Bharat Ko Jano',
                      const Color(0xFF059669),
                      () => _go(context, const BharatKoJanoScreen())),
                  _card(Icons.self_improvement_rounded, 'Yoga',
                      const Color(0xFFD97706),
                      () => _go(context, const YogaScreen())),
                  _card(Icons.restaurant_rounded, 'Diet Chart',
                      const Color(0xFF10B981),
                      () => _go(context, const DietChartScreen())),
                  _card(Icons.fitness_center_rounded, 'Exercise',
                      const Color(0xFFEF4444),
                      () => _go(context, const ExerciseScreen())),
                  _card(Icons.emergency_rounded, 'Emergency',
                      const Color(0xFFDC2626),
                      () => _go(context, const EmergencyContactsScreen())),
                  _card(Icons.language_rounded, 'Our Website',
                      const Color(0xFF6366F1),
                      () => launchUrl(Uri.parse('https://bdphs.in'), mode: LaunchMode.externalApplication)),
                  _card(Icons.payment_rounded, 'Pay Fees',
                      const Color(0xFF10B981),
                      () => launchUrl(Uri.parse('https://bdphs.in/fees.php'), mode: LaunchMode.externalApplication)),
                ]),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String t) => Text(t,
      style: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary));

  Widget _grid(List<Widget> c) => GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
        children: c,
      );

  Widget _card(IconData icon, String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ),
          ]),
        ),
      );
}

// ─── Quick Stats ──────────────────────────────────────────────────────────────
class _QuickStats extends StatelessWidget {
  final String uid;
  const _QuickStats({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('studentId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final present =
            docs.where((d) => (d.data() as Map)['isPresent'] == true).length;
        final total = docs.length;
        final pct = total == 0 ? 0 : (present / total * 100).round();
        final isGood = pct >= 75;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF1E3A5F), Color(0xFF2D5986)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            _stat('$present', 'Present', Colors.greenAccent),
            _div(),
            _stat('${total - present}', 'Absent', Colors.redAccent),
            _div(),
            _stat('$total', 'Total Days', Colors.white70),
            _div(),
            _stat('$pct%', 'Attendance',
                isGood ? Colors.greenAccent : Colors.redAccent),
          ]),
        );
      },
    );
  }

  Widget _div() => Container(
      width: 1,
      height: 36,
      color: Colors.white24,
      margin: const EdgeInsets.symmetric(horizontal: 6));

  Widget _stat(String val, String label, Color color) => Expanded(
        child: Column(children: [
          Text(val,
              style: GoogleFonts.poppins(
                  fontSize: 17, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: GoogleFonts.poppins(fontSize: 9, color: Colors.white60),
              textAlign: TextAlign.center),
        ]),
      );
}

// ─── Profile Tab ──────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final dynamic user;
  const _ProfileTab({required this.user});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AppAuthProvider>();
    final name = user?.fullName ?? 'Student';
    final student = user is StudentModel ? user as StudentModel : null;

    Future<void> goEdit() async {
      await Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ProfileEditScreen()));
      auth.loadCurrentUser(); // ✅ refresh after editing
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.studentColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text('My Profile',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: Colors.white)),
        actions: [
          // ✅ Edit pencil in AppBar
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit Profile',
            onPressed: goEdit,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('Sign Out',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                  content: Text('Are you sure?', style: GoogleFonts.poppins()),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel',
                            style:
                                GoogleFonts.poppins(color: AppColors.primary))),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Sign Out',
                            style: GoogleFonts.poppins(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700))),
                  ],
                ),
              );
              if (ok == true) {
                await auth.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (r) => false);
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 8),

          // ── Avatar + camera button ─────────────────────────────────
          Stack(children: [
            CircleAvatar(
              radius: 56,
              backgroundColor: AppColors.studentColor.withValues(alpha: 0.12),
              backgroundImage: user?.photoUrl != null
                  ? NetworkImage(user!.photoUrl!)
                  : null,
              child: user?.photoUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'S',
                      style: GoogleFonts.poppins(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: AppColors.studentColor))
                  : null,
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: GestureDetector(
                onTap: goEdit,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.studentColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.studentColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      size: 17, color: Colors.white),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),

          Text(name,
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 3),
          Text(user?.email ?? '',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.studentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Student ✅',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.studentColor)),
          ),
          const SizedBox(height: 20),

          // ✅ Big "Edit Profile & Photo" button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: goEdit,
              icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
              label: Text('Edit Profile & Photo',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.studentColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                shadowColor: AppColors.studentColor.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Info rows ──────────────────────────────────────────────
          if (student != null) ...[
            _row(Icons.school_rounded, 'Class', student.className),
            _row(Icons.badge_rounded, 'Roll Number',
                student.rollNumber.isNotEmpty ? student.rollNumber : '—'),
            if (student.fatherName.isNotEmpty)
              _row(Icons.person_rounded, "Father's Name", student.fatherName),
            if (student.motherName.isNotEmpty)
              _row(Icons.person_rounded, "Mother's Name", student.motherName),
          ],
          _row(Icons.phone_rounded, 'Phone',
              (user?.phone ?? '').isNotEmpty ? user!.phone : '—'),
          _row(Icons.email_rounded, 'Email', user?.email ?? '—'),
          _row(Icons.verified_rounded, 'Status', 'Approved ✅'),
          const SizedBox(height: 20),

          // ── Quick action row ───────────────────────────────────────
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const StudentIdCardScreen())),
                icon: Icon(Icons.credit_card_rounded,
                    color: AppColors.studentColor, size: 18),
                label: Text('ID Card',
                    style: GoogleFonts.poppins(
                        color: AppColors.studentColor,
                        fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: BorderSide(color: AppColors.studentColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const StudentAttendanceScreen())),
                icon: const Icon(Icons.calendar_today_rounded,
                    color: AppColors.primary, size: 18),
                label: Text('Attendance',
                    style: GoogleFonts.poppins(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Container(
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary)),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ]),
          ),
        ]),
      );
}