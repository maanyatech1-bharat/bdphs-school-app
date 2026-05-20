// lib/screens/admin/approve_teachers_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class ApproveTeachersScreen extends StatelessWidget {
  const ApproveTeachersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AppAuthProvider>().authService;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Teacher Approvals',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: AppColors.teacherColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<TeacherModel>>(
        stream: authService.getPendingTeachers(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (_, __) => const ShimmerCard(height: 100),
            );
          }
          final teachers = snap.data ?? [];
          if (teachers.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 64,
                      color: AppColors.success.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text('No Pending Teachers!',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success)),
                  const SizedBox(height: 6),
                  Text('All teacher approvals are up to date',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.textHint)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: teachers.length,
            itemBuilder: (_, i) => _TeacherApprovalCard(
              teacher: teachers[i],
              onApprove: () async {
                final ok = await context
                    .read<AppAuthProvider>()
                    .approveUser(teachers[i].uid, UserRole.teacher);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text(ok
                        ? '✅ ${teachers[i].fullName} approved!'
                        : 'Error occurred'),
                    backgroundColor:
                        ok ? AppColors.success : AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ));
                }
              },
              onReject: () async {
                final ok = await context
                    .read<AppAuthProvider>()
                    .rejectUser(teachers[i].uid, UserRole.teacher);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text(
                        ok ? '${teachers[i].fullName} rejected' : 'Error'),
                    backgroundColor:
                        ok ? AppColors.warning : AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ));
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _TeacherApprovalCard extends StatelessWidget {
  final TeacherModel teacher;
  final VoidCallback onApprove, onReject;
  const _TeacherApprovalCard(
      {required this.teacher,
      required this.onApprove,
      required this.onReject});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                  photoUrl: teacher.photoUrl,
                  name: teacher.fullName,
                  size: 52,
                  backgroundColor:
                      AppColors.teacherColor.withValues(alpha: 0.1)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(teacher.fullName,
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    Text(teacher.subject,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.teacherColor,
                            fontWeight: FontWeight.w500)),
                    Text(teacher.email,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppColors.textHint)),
                  ],
                ),
              ),
              const StatusBadge(status: 'pending'),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                  icon: Icons.badge_outlined, label: teacher.employeeId),
              _InfoChip(
                  icon: Icons.school_outlined,
                  label: teacher.qualification),
              _InfoChip(
                  icon: Icons.phone_outlined, label: teacher.phone),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.error),
                  label: Text('Reject',
                      style: GoogleFonts.poppins(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white),
                  label: Text('Approve',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}