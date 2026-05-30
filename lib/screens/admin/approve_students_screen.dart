// lib/screens/admin/approve_students_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class ApproveStudentsScreen extends StatefulWidget {
  const ApproveStudentsScreen({super.key});
  @override
  State<ApproveStudentsScreen> createState() => _ApproveStudentsScreenState();
}

class _ApproveStudentsScreenState extends State<ApproveStudentsScreen>
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

  Stream<QuerySnapshot> _stream(String status) => FirebaseFirestore.instance
      .collection('students')
      .where('approvalStatus', isEqualTo: status)
      .snapshots();

  Future<void> _updateStatus(
    BuildContext ctx,
    String uid,
    String status, {
    required String studentName,
    required String email,
    required String studentId,
    required String className,
    String reason = '',
  }) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final uRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final sRef = FirebaseFirestore.instance.collection('students').doc(uid);
      batch.update(uRef, {'approvalStatus': status});
      batch.update(sRef, {'approvalStatus': status});
      await batch.commit();

      // ── Send email based on decision ──────────────────────────────────
      if (status == 'approved') {
        NotificationService.sendStudentApprovalEmail(
          toEmail: email,
          studentName: studentName,
          studentId: studentId,
          className: className,
        );
      } else if (status == 'rejected') {
        NotificationService.sendStudentRejectionEmail(
          toEmail: email,
          studentName: studentName,
          reason: reason,
        );
      }
      // ──────────────────────────────────────────────────────────────────

      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text(status == 'approved'
              ? '✅ $studentName approved — welcome email sent!'
              : '❌ $studentName rejected'),
          backgroundColor: status == 'approved' ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _confirmReject(BuildContext ctx, String uid, Map<String, dynamic> data) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Registration', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rejecting ${data['fullName'] ?? ''}. Add a reason (optional):',
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Incomplete information, Invalid documents...',
                hintStyle: GoogleFonts.poppins(fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              maxLines: 2,
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Reject', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && ctx.mounted) {
      await _updateStatus(
        ctx, uid, 'rejected',
        studentName: data['fullName'] ?? '',
        email: data['email'] ?? '',
        studentId: data['studentId'] ?? '',
        className: data['className'] ?? '',
        reason: reasonCtrl.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Approve Students',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _StudentList(
            stream: _stream('pending'),
            emptyMsg: 'No pending registrations',
            emptyIcon: Icons.hourglass_empty_rounded,
            onApprove: (uid, data) => _updateStatus(
              context, uid, 'approved',
              studentName: data['fullName'] ?? '',
              email: data['email'] ?? '',
              studentId: data['studentId'] ?? '',
              className: data['className'] ?? '',
            ),
            onReject: (uid, data) => _confirmReject(context, uid, data),
            showActions: true,
          ),
          _StudentList(
            stream: _stream('approved'),
            emptyMsg: 'No approved students',
            emptyIcon: Icons.check_circle_outline_rounded,
            showActions: false,
          ),
          _StudentList(
            stream: _stream('rejected'),
            emptyMsg: 'No rejected students',
            emptyIcon: Icons.cancel_outlined,
            showActions: true,
            onApprove: (uid, data) => _updateStatus(
              context, uid, 'approved',
              studentName: data['fullName'] ?? '',
              email: data['email'] ?? '',
              studentId: data['studentId'] ?? '',
              className: data['className'] ?? '',
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentList extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final String emptyMsg;
  final IconData emptyIcon;
  final void Function(String uid, Map<String, dynamic> data)? onApprove;
  final void Function(String uid, Map<String, dynamic> data)? onReject;
  final bool showActions;

  const _StudentList({
    required this.stream,
    required this.emptyMsg,
    required this.emptyIcon,
    this.onApprove,
    this.onReject,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(emptyIcon, size: 64, color: AppColors.textHint),
                const SizedBox(height: 12),
                Text(emptyMsg,
                  style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 15)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final uid = doc.id;
            final name = data['fullName'] ?? 'Unknown';
            final className = data['className'] ?? '';
            final email = data['email'] ?? '';
            final phone = data['phone'] ?? '';
            final studentId = data['studentId'] ?? '';
            final fatherName = data['fatherName'] ?? '';
            final rollNo = data['rollNumber'] ?? '';
            final photoUrl = data['photoUrl'] as String?;
            final status = data['approvalStatus'] ?? 'pending';

            Color statusColor = status == 'approved'
                ? AppColors.success
                : status == 'rejected'
                    ? AppColors.error
                    : AppColors.warning;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.studentColor.withValues(alpha: 0.06),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.studentColor.withValues(alpha: 0.15),
                          backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl) : null,
                          child: photoUrl == null || photoUrl.isEmpty
                              ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700,
                                    color: AppColors.studentColor))
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w700,
                                  fontSize: 15, color: AppColors.textPrimary)),
                              Text('$className  •  Roll: $rollNo',
                                style: GoogleFonts.poppins(fontSize: 12,
                                  color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(status.toUpperCase(),
                            style: GoogleFonts.poppins(fontSize: 10,
                              fontWeight: FontWeight.w700, color: statusColor)),
                        ),
                      ],
                    ),
                  ),
                  // Details
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      children: [
                        _DetailRow(Icons.badge_outlined, 'Student ID', studentId),
                        _DetailRow(Icons.email_outlined, 'Email', email),
                        _DetailRow(Icons.phone_outlined, 'Phone', phone),
                        _DetailRow(Icons.person_outline, "Father's Name", fatherName),
                      ],
                    ),
                  ),
                  // Actions
                  if (showActions) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => onReject?.call(uid, data),
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: Text('Reject', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () => onApprove?.call(uid, data),
                              icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                              label: Text('Approve', style: GoogleFonts.poppins(
                                color: Colors.white, fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textHint),
        const SizedBox(width: 8),
        SizedBox(width: 90,
          child: Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textHint))),
        Expanded(
          child: Text(value.isNotEmpty ? value : '—',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600,
              color: AppColors.textPrimary))),
      ],
    ),
  );
}