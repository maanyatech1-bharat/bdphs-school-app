// lib/screens/teacher/teacher_dashboard.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../shared/ai_chatbot_screen.dart';

import '../shared/notices_screen.dart';
import '../shared/books_screen.dart';
import '../shared/timetable_screen.dart';
import '../shared/search_students_screen.dart';
import '../shared/syllabus_gallery_material.dart' hide StudyMaterialScreen;
import '../shared/videos_screen.dart';
import '../shared/more_screens.dart';
import '../shared/leave_screen.dart';
import '../shared/fee_screen.dart';
import '../shared/ai_chatbot_screen.dart';
import '../shared/dictionary_screen.dart';
import '../shared/profile_edit_screen.dart';
import '../shared/homework_screen.dart';
import '../shared/study_material_screen.dart';
import '../shared/study_notes_screen.dart';
import '../shared/quiz_screen.dart';

import '../teacher/monthly_assessment_screen.dart';
import '../teacher/take_attendance_screen.dart';
import '../teacher/enter_marks_screen.dart';
import '../teacher/my_students_screen.dart';
import '../shared/exam_schedule_screen.dart';

import '../auth/login_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});
  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser;
    final pages = [
      _HomeTab(user: user),
      const SearchStudentsScreen(),
      const NoticesScreen(),
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
        indicatorColor: AppColors.teacherColor.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.teacherColor),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded, color: AppColors.teacherColor),
            label: 'Students',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications_rounded, color: AppColors.teacherColor),
            label: 'Notices',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.teacherColor),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final dynamic user;
  const _HomeTab({required this.user});

  void _go(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName ?? 'Teacher';
    final firstName = name.split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.teacherColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF047857), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(children: [
                      GestureDetector(
                        onTap: () => _go(context, const ProfileEditScreen()),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          backgroundImage: user?.photoUrl != null
                              ? NetworkImage(user!.photoUrl!) : null,
                          child: user?.photoUrl == null
                              ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'T',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18, color: Colors.white))
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Hello, $firstName! 👋',
                              style: GoogleFonts.poppins(
                                  fontSize: 18, fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          Text('BDPHS Teacher Portal',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.white70)),
                        ],
                      )),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                        onPressed: () => _go(context, const NoticesScreen()),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                _sectionHead('📋 Class Management', 'Manage your students'),
                const SizedBox(height: 12),
                _grid([
                  _card(Icons.how_to_reg_rounded, 'Take\nAttendance',
                      const Color(0xFF2563EB),
                      () => _go(context, const TakeAttendanceScreen())),
                  _card(Icons.assessment_rounded, 'Monthly\nAssessment',
                      AppColors.primary,
                      () => _go(context, const MonthlyAssessmentScreen())),
                  _card(Icons.grade_rounded, 'Enter\nMarks',
                      const Color(0xFFD97706),
                      () => _go(context, const EnterMarksScreen(examCategory: 'classTests'))),
                  _card(Icons.people_rounded, 'My\nStudents',
                      const Color(0xFF059669),
                      () => _go(context, const MyStudentsScreen())),
                  _card(Icons.event_note_rounded, 'Leave\nRequests',
                      const Color(0xFF7C3AED),
                      () => _go(context, const LeaveScreen())),
                  _card(Icons.bar_chart_rounded, 'Formal\nExams',
                      const Color(0xFF0891B2),
                      () => _go(context, const EnterMarksScreen(examCategory: 'formal'))),
                ]),
                const SizedBox(height: 20),

                _sectionHead('📚 Academics', 'Teaching resources'),
                const SizedBox(height: 12),
                _grid([
                  _card(Icons.menu_book_rounded, 'Class\nBooks',
                      const Color(0xFF059669),
                      () => _go(context, const BooksScreen())),
                  _card(Icons.assignment_rounded, 'Homework',
                      const Color(0xFF7C3AED),
                      () => _go(context, const HomeworkScreen())),
                  _card(Icons.checklist_rounded, 'Syllabus',
                      const Color(0xFFDC2626),
                      () => _go(context, const SyllabusScreen())),
                  _card(Icons.folder_open_rounded, 'Study\nNotes',
                      const Color(0xFF0891B2),
                      () => _go(context, const StudyMaterialScreen())),
                  _card(Icons.photo_library_rounded, 'Gallery',
                      const Color(0xFF7C3AED),
                      () => _go(context, const GalleryScreen())),
                  _card(Icons.play_circle_rounded, 'Videos',
                      const Color(0xFFDC2626),
                      () => _go(context, const VideosScreen())),
                  _card(Icons.quiz_rounded, 'Quiz',
                      const Color(0xFFD97706),
                      () => _go(context, const QuizListScreen())),
                  _card(Icons.event_rounded, 'Exam\nDates',
                      const Color(0xFFDC2626),
                      () => _go(context, const ExamScheduleScreen())),
                ]),
                const SizedBox(height: 20),

                _sectionHead('🛠️ Tools', 'Helpful resources'),
                const SizedBox(height: 12),
                _grid([
                  _card(Icons.table_chart_rounded, 'Timetable',
                      AppColors.primary,
                      () => _go(context, const TimetableScreen())),
                  _card(Icons.calendar_month_rounded, 'Calendar',
                      const Color(0xFF0891B2),
                      () => _go(context, const SchoolCalendarScreen())),
                  _card(Icons.account_balance_wallet_rounded, 'Fee\nStatus',
                      const Color(0xFF059669),
                      () => _go(context, const FeeScreen())),
                  _card(Icons.phone_rounded, 'Emergency',
                      const Color(0xFFDC2626),
                      () => _go(context, const EmergencyContactsScreen())),
                  _card(Icons.smart_toy_rounded, 'AI Tutor',
                      const Color(0xFF7C3AED),
                      () => _go(context, AIChatbotScreen())),
                  _card(Icons.translate_rounded, 'Dictionary',
                      const Color(0xFF2563EB),
                      () => _go(context, const DictionaryScreen())),
                ]),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHead(String title, String subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(subtitle, style: GoogleFonts.poppins(
              fontSize: 12, color: AppColors.textSecondary)),
        ],
      );

  Widget _grid(List<Widget> children) => GridView.count(
        crossAxisCount: 3, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.0,
        children: children,
      );

  Widget _card(IconData icon, String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(label,
                  textAlign: TextAlign.center, maxLines: 2,
                  style: GoogleFonts.poppins(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ),
          ]),
        ),
      );
}

class _ProfileTab extends StatelessWidget {
  final dynamic user;
  const _ProfileTab({required this.user});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AppAuthProvider>();
    final name = user?.fullName ?? 'Teacher';

    Future<void> goEdit() async {
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ProfileEditScreen()));
      auth.loadCurrentUser();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Profile',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: AppColors.teacherColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit Profile',
            onPressed: goEdit,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
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
                            style: GoogleFonts.poppins(color: AppColors.primary))),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Sign Out',
                            style: GoogleFonts.poppins(
                                color: AppColors.error, fontWeight: FontWeight.w700))),
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
          Stack(children: [
            CircleAvatar(
              radius: 54,
              backgroundColor: AppColors.teacherColor.withValues(alpha: 0.12),
              backgroundImage: user?.photoUrl != null
                  ? NetworkImage(user!.photoUrl!) : null,
              child: user?.photoUrl == null
                  ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'T',
                      style: GoogleFonts.poppins(
                          fontSize: 40, fontWeight: FontWeight.w700,
                          color: AppColors.teacherColor))
                  : null,
            ),
            Positioned(
              bottom: 2, right: 2,
              child: GestureDetector(
                onTap: goEdit,
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.teacherColor, shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [BoxShadow(
                        color: AppColors.teacherColor.withValues(alpha: 0.4),
                        blurRadius: 8)],
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Text(name, style: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 3),
          Text(user?.email ?? '', style: GoogleFonts.poppins(
              fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.teacherColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Teacher ✅', style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColors.teacherColor)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: goEdit,
              icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
              label: Text('Edit Profile & Photo',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teacherColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                shadowColor: AppColors.teacherColor.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _row('Email', user?.email ?? '—', Icons.email_rounded),
          _row('Phone', (user?.phone ?? '').isNotEmpty ? user!.phone : '—', Icons.phone_rounded),
          _row('Role', 'Teacher', Icons.school_rounded),
          _row('Status', 'Approved ✅', Icons.verified_rounded),
          if ((user?.subject as String? ?? '').isNotEmpty)
            _row('Subject', user!.subject as String, Icons.subject_rounded),
          if ((user?.qualification as String? ?? '').isNotEmpty)
            _row('Qualification', user!.qualification as String, Icons.workspace_premium_rounded),
          if ((user?.employeeId as String? ?? '').isNotEmpty)
            _row('Employee ID', user!.employeeId as String, Icons.badge_rounded),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _row(String label, String value, IconData icon) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: AppColors.teacherColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppColors.teacherColor),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textSecondary)),
              Text(value, style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          )),
        ]),
      );
}