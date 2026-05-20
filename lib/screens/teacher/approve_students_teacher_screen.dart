// lib/screens/teacher/approve_students_teacher_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class ApproveStudentsTeacherScreen extends StatelessWidget {
  const ApproveStudentsTeacherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final teacher = context.watch<AppAuthProvider>().currentUser;
    final authService = AuthService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Approve Students',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.teacherColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<StudentModel>>(
        stream: authService.getPendingStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (_, __) => const ShimmerCard(),
            );
          }
          final students = snapshot.data ?? [];
          if (students.isEmpty) {
            return const EmptyState(
              icon: Icons.how_to_reg_rounded,
              title: 'No Pending Students',
              subtitle: 'All student registrations have been reviewed',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (_, i) => _StudentCard(
              student: students[i],
              teacher: teacher,
              authService: authService,
            ),
          );
        },
      ),
    );
  }
}

class _StudentCard extends StatefulWidget {
  final StudentModel student;
  final UserModel? teacher;
  final AuthService authService;
  const _StudentCard({
    required this.student,
    required this.teacher,
    required this.authService,
  });

  @override
  State<_StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<_StudentCard> {
  bool _processing = false;

  Future<void> _approve() async {
    setState(() => _processing = true);
    await widget.authService.approveUser(
      widget.student.uid,
      widget.teacher?.uid ?? '',
      UserRole.student,
    );
    if (mounted) setState(() => _processing = false);
  }

  Future<void> _reject() async {
    setState(() => _processing = true);
    await widget.authService.rejectUser(
      widget.student.uid,
      UserRole.student,
    );
    if (mounted) setState(() => _processing = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            UserAvatar(photoUrl: s.photoUrl, name: s.fullName, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.fullName,
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  Text('${s.className}  •  Roll: ${s.rollNumber}',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textSecondary)),
                  Text('Father: ${s.fatherName}',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ),
            const StatusBadge(status: 'pending'),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _processing ? null : _reject,
                icon: const Icon(Icons.close_rounded,
                    size: 16, color: AppColors.error),
                label: Text('Reject',
                    style: GoogleFonts.poppins(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _processing ? null : _approve,
                icon: _processing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_rounded,
                        size: 16, color: Colors.white),
                label: Text('Approve',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teacherColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}