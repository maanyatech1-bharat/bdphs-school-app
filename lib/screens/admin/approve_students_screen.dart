// lib/screens/admin/approve_students_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class ApproveStudentsScreen extends StatefulWidget {
  const ApproveStudentsScreen({super.key});
  @override
  State<ApproveStudentsScreen> createState() =>
      _ApproveStudentsScreenState();
}

class _ApproveStudentsScreenState extends State<ApproveStudentsScreen> {
  String _selectedClass = 'All';
  final List<String> _classes = [
    'All', 'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.read<AppAuthProvider>().currentUser;
    final isAdmin = user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isAdmin ? 'Approve Students' : 'Student Approvals',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: AppColors.studentColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── Class filter chips ──────────────────────────────────────
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _classes.length,
                itemBuilder: (ctx, i) {
                  final cls = _classes[i];
                  final sel = _selectedClass == cls;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedClass = cls),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.studentColor
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? AppColors.studentColor
                              : AppColors.divider,
                        ),
                      ),
                      child: Text(cls,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? Colors.white
                                  : AppColors.textSecondary)),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Pending students list ───────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _selectedClass == 'All'
                  ? FirebaseFirestore.instance
                      .collection('students')
                      .where('approvalStatus', isEqualTo: 'pending')
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('students')
                      .where('approvalStatus', isEqualTo: 'pending')
                      .where('className', isEqualTo: _selectedClass)
                      .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 64,
                            color: AppColors.success.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text('No Pending Students!',
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success)),
                        const SizedBox(height: 6),
                        Text('All student registrations are reviewed',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textHint)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data =
                        docs[i].data() as Map<String, dynamic>;
                    return _StudentCard(
                      data: data,
                      docId: docs[i].id,
                      approverUid: user?.uid ?? '',
                      approverName: user?.fullName ?? '',
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String approverUid;
  final String approverName;

  const _StudentCard({
    required this.data,
    required this.docId,
    required this.approverUid,
    required this.approverName,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['fullName'] ?? '';
    final className = data['className'] ?? '';
    final roll = data['rollNumber'] ?? '';
    final father = data['fatherName'] ?? '';
    final mother = data['motherName'] ?? '';
    final phone = data['phone'] ?? '';
    final email = data['email'] ?? '';
    final gender = data['gender'] ?? '';
    final address = data['address'] ?? '';
    final aadhar = data['aadharNumber'] ?? '';
    final createdAt =
        (data['createdAt'] as dynamic?)?.toDate() as DateTime?;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor:
                      AppColors.studentColor.withValues(alpha: 0.15),
                  backgroundImage: data['photoUrl'] != null
                      ? NetworkImage(data['photoUrl'])
                      : null,
                  child: data['photoUrl'] == null
                      ? Text(
                          name.isNotEmpty
                              ? name[0].toUpperCase()
                              : 'S',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: AppColors.studentColor))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      Text('$className · Roll $roll',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textSecondary)),
                      if (createdAt != null)
                        Text(
                            'Applied: ${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year}',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textHint)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('PENDING',
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD97706))),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Details ─────────────────────────────────────────────
            _detail(Icons.person_outline_rounded, 'Father', father),
            _detail(Icons.person_outline_rounded, 'Mother', mother),
            _detail(Icons.phone_rounded, 'Phone', phone),
            _detail(Icons.email_rounded, 'Email', email),
            _detail(Icons.wc_rounded, 'Gender', gender),
            if (address.isNotEmpty)
              _detail(Icons.location_on_rounded, 'Address', address),
            if (aadhar.isNotEmpty)
              _detail(
                  Icons.credit_card_rounded,
                  'Aadhar',
                  aadhar.length >= 4
                      ? 'XXXX XXXX ${aadhar.substring(aadhar.length - 4)}'
                      : aadhar),
            const SizedBox(height: 14),

            // ── Action buttons ───────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateStatus(context, 'rejected'),
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.error, size: 18),
                    label: Text('Reject',
                        style: GoogleFonts.poppins(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding:
                          const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(context, 'approved'),
                    icon: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 18),
                    label: Text('Approve',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding:
                          const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String status) async {
    try {
      final update = {
        'approvalStatus': status,
        'approvedBy': approverUid,
        'approvedByName': approverName,
        'approvedAt': FieldValue.serverTimestamp(),
      };
      final batch = FirebaseFirestore.instance.batch();
      batch.update(
          FirebaseFirestore.instance
              .collection('students')
              .doc(docId),
          update);
      batch.update(
          FirebaseFirestore.instance.collection('users').doc(docId),
          update);
      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'approved'
              ? '✅ Student approved successfully!'
              : '❌ Student registration rejected'),
          backgroundColor:
              status == 'approved' ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }
}