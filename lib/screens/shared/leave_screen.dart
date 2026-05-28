// lib/screens/shared/leave_screen.dart
//
// STUDENT  → Tab 1: My Leaves | Tab 2: Apply Leave (to teacher)
// TEACHER  → Tab 1: Student Requests | Tab 2: My Leaves | Tab 3: Apply Leave (to admin)
// ADMIN    → Tab 1: Pending | Tab 2: All History

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/fcm_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

// ── Helpers ────────────────────────────────────────────────────────────────────
Color _statusColor(String s) {
  if (s == 'approved') return AppColors.success;
  if (s == 'rejected') return AppColors.error;
  return const Color(0xFFD97706);
}

Color _typeColor(String t) {
  switch (t) {
    case 'Medical':   return const Color(0xFFDC2626);
    case 'Casual':    return const Color(0xFF2563EB);
    case 'Emergency': return const Color(0xFFDC2626);
    case 'Personal':  return const Color(0xFF7C3AED);
    default:          return AppColors.primary;
  }
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// ✅ Safe role string — no .name getter (UserRole is a class not enum)
String _roleStr(dynamic role) {
  if (role == UserRole.admin)   return 'admin';
  if (role == UserRole.teacher) return 'teacher';
  return 'student';
}

// ─── Main Screen ───────────────────────────────────────────────────────────────
class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});
  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this); // overridden below
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user      = context.watch<AppAuthProvider>().currentUser;
    final isAdmin   = user?.role == UserRole.admin;
    final isTeacher = user?.role == UserRole.teacher;

    // ── ADMIN ──────────────────────────────────────────────────────────
    if (isAdmin) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text('Leave Management',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            backgroundColor: const Color(0xFFD97706),
            foregroundColor: Colors.white,
            bottom: const TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: [
                Tab(text: '⏳ Pending'),
                Tab(text: '📜 All History'),
              ],
            ),
          ),
          body: TabBarView(children: [
            _LeaveListTab(
                user: user, canApprove: true, filterStatus: 'pending',
                filterRole: 'all'),
            _LeaveListTab(
                user: user, canApprove: true, filterStatus: 'all',
                filterRole: 'all'),
          ]),
        ),
      );
    }

    // ── TEACHER: 3 tabs ────────────────────────────────────────────────
    if (isTeacher) {
      return DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text('Leave Management',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            backgroundColor: const Color(0xFFD97706),
            foregroundColor: Colors.white,
            bottom: const TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              isScrollable: true,
              tabs: [
                Tab(text: '👩‍🎓 Student Requests'),
                Tab(text: '📋 My Leaves'),
                Tab(text: '➕ Apply Leave'),
              ],
            ),
          ),
          body: TabBarView(children: [
            // Tab 1: approve/reject student leaves
            _LeaveListTab(
                user: user, canApprove: true,
                filterStatus: 'all', filterRole: 'student'),
            // Tab 2: teacher's own leave history
            _LeaveListTab(
                user: user, canApprove: false,
                filterStatus: 'all', filterRole: 'self'),
            // Tab 3: apply leave to admin
            _ApplyLeaveForm(user: user, applyTo: 'admin'),
          ]),
        ),
      );
    }

    // ── STUDENT: 2 tabs ────────────────────────────────────────────────
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Leave Management',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          backgroundColor: const Color(0xFFD97706),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: '📋 My Leaves'),
              Tab(text: '➕ Apply Leave'),
            ],
          ),
        ),
        body: TabBarView(children: [
          _LeaveListTab(
              user: user, canApprove: false,
              filterStatus: 'all', filterRole: 'self'),
          _ApplyLeaveForm(user: user, applyTo: 'teacher'),
        ]),
      ),
    );
  }
}

// ─── Leave List Tab ────────────────────────────────────────────────────────────
// filterRole: 'all' | 'student' | 'teacher' | 'self'
// filterStatus: 'all' | 'pending'
class _LeaveListTab extends StatefulWidget {
  final dynamic user;
  final bool canApprove;
  final String filterStatus;
  final String filterRole;
  const _LeaveListTab({
    required this.user,
    required this.canApprove,
    required this.filterStatus,
    required this.filterRole,
  });
  @override
  State<_LeaveListTab> createState() => _LeaveListTabState();
}

class _LeaveListTabState extends State<_LeaveListTab> {
  String _roleFilter = 'All'; // for admin only

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Admin role filter chips
      if (widget.canApprove && widget.filterRole == 'all') ...[
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            _chip('All'),
            const SizedBox(width: 8),
            _chip('Teacher'),
            const SizedBox(width: 8),
            _chip('Student'),
          ]),
        ),
        const Divider(height: 1),
      ],

      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: _buildQuery(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
                color: Color(0xFFD97706)));
          }
          var docs = snap.data?.docs ?? [];

          // ✅ Sort client-side by createdAt descending
          docs = List.from(docs)..sort((a, b) {
            final aTime = (a.data() as Map)['createdAt'] as Timestamp?;
            final bTime = (b.data() as Map)['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

          // Apply role filter for admin
          if (widget.filterRole == 'all' && _roleFilter != 'All') {
            docs = docs.where((d) =>
                (d.data() as Map)['applicantRole'] ==
                _roleFilter.toLowerCase()).toList();
          }

          if (docs.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy_rounded, size: 72,
                    color: const Color(0xFFD97706).withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('No Leave Applications',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  widget.filterRole == 'self'
                      ? 'Your leave history will appear here'
                      : 'No leave requests found',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) => _leaveCard(docs[i], context),
          );
        },
      )),
    ]);
  }

  Widget _leaveCard(QueryDocumentSnapshot doc, BuildContext context) {
    final d      = doc.data() as Map<String, dynamic>;
    final docId  = doc.id;
    final status = d['status'] as String? ?? 'pending';
    final sColor = _statusColor(status);
    final type   = d['leaveType'] as String? ?? 'Casual';
    final tColor = _typeColor(type);
    final from   = (d['fromDate'] as Timestamp?)?.toDate();
    final to     = (d['toDate'] as Timestamp?)?.toDate();
    final days   = (from != null && to != null)
        ? to.difference(from).inDays + 1 : 1;
    final role   = d['applicantRole'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: tColor, width: 4)),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d['applicantName'] as String? ?? '—',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Wrap(spacing: 6, children: [
                  _tag(type, tColor),
                  if (role.isNotEmpty) _tag(_cap(role), AppColors.primary),
                ]),
              ],
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sColor),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  status == 'approved' ? Icons.check_circle_rounded
                      : status == 'rejected' ? Icons.cancel_rounded
                      : Icons.schedule_rounded,
                  size: 12, color: sColor),
                const SizedBox(width: 4),
                Text(_cap(status), style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w800, color: sColor)),
              ]),
            ),
          ]),
          const SizedBox(height: 10),

          Row(children: [
            const Icon(Icons.date_range_rounded,
                size: 14, color: AppColors.textHint),
            const SizedBox(width: 6),
            Expanded(child: Text(
              from != null
                  ? '${DateFormat('dd MMM').format(from)} → '
                    '${to != null ? DateFormat('dd MMM yyyy').format(to) : ''}'
                    '  ($days day${days != 1 ? 's' : ''})'
                  : '—',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600),
            )),
          ]),
          const SizedBox(height: 6),

          Text(d['reason'] as String? ?? '',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.4)),

          // Approve / Reject buttons
          if (widget.canApprove && status == 'pending') ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => _updateLeave(context, docId, 'rejected'),
                icon: const Icon(Icons.close_rounded,
                    size: 16, color: AppColors.error),
                label: Text('Reject', style: GoogleFonts.poppins(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton.icon(
                onPressed: () => _updateLeave(context, docId, 'approved'),
                icon: const Icon(Icons.check_rounded,
                    size: 16, color: Colors.white),
                label: Text('Approve', style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              )),
            ]),
          ],

          // Remark
          if ((d['adminRemark'] as String? ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.comment_rounded,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(child: Text(d['adminRemark'] as String,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary))),
              ]),
            ),
          ],

          const SizedBox(height: 6),
          if (d['createdAt'] != null)
            Text(
              'Applied: ${DateFormat('dd MMM yyyy').format((d['createdAt'] as Timestamp).toDate())}',
              style: GoogleFonts.poppins(
                  fontSize: 10, color: AppColors.textHint),
            ),
        ]),
      ),
    );
  }

  Future<void> _updateLeave(
      BuildContext ctx, String docId, String status) async {
    final remarkCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
            status == 'approved' ? '✅ Approve Leave' : '❌ Reject Leave',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: remarkCtrl,
          decoration: InputDecoration(
            hintText: 'Add remark (optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          style: GoogleFonts.poppins(), maxLines: 2,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.poppins())),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: status == 'approved'
                    ? AppColors.success : AppColors.error,
              ),
              child: Text(status == 'approved' ? 'Approve' : 'Reject',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('leaves').doc(docId).update({
        'status': status,
        'adminRemark': remarkCtrl.text.trim(),
        'processedAt': FieldValue.serverTimestamp(),
      });
      // Notify student
      final leaveDoc = await FirebaseFirestore.instance.collection('leaves').doc(docId).get();
      final applicantId = (leaveDoc.data() as Map?)?['applicantId'] as String? ?? '';
      await NotificationSender.notifyUser(
        userId: applicantId,
        title: status == 'approved' ? '✅ Leave Approved' : '❌ Leave Rejected',
        body: status == 'approved'
            ? 'Your leave request has been approved.'
            : 'Your leave request has been rejected.',
        type: 'leave',
      );
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(status == 'approved'
                ? '✅ Leave Approved' : '❌ Leave Rejected'),
            backgroundColor: status == 'approved'
                ? AppColors.success : AppColors.error));
      }
    }
  }

  Stream<QuerySnapshot> _buildQuery() {
    Query q = FirebaseFirestore.instance.collection('leaves');
    if (widget.filterRole == 'self') {
      q = q.where('applicantId', isEqualTo: widget.user?.uid ?? '');
    } else if (widget.filterRole == 'student') {
      q = q.where('applicantRole', isEqualTo: 'student');
    } else if (widget.filterRole == 'teacher') {
      q = q.where('applicantRole', isEqualTo: 'teacher');
    }
    if (widget.filterStatus == 'pending') {
      q = q.where('status', isEqualTo: 'pending');
    }
    // ✅ No orderBy — avoids composite index requirement
    // Sorting done client-side below
    return q.snapshots();
  }

  Widget _chip(String role) {
    final sel = _roleFilter == role;
    return GestureDetector(
      onTap: () => setState(() => _roleFilter = role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFD97706) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: sel ? const Color(0xFFD97706) : AppColors.divider),
        ),
        child: Text(role, style: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: sel ? Colors.white : AppColors.textPrimary)),
      ),
    );
  }

  Widget _tag(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: GoogleFonts.poppins(
            fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      );
}

// ─── Apply Leave Form ─────────────────────────────────────────────────────────
class _ApplyLeaveForm extends StatefulWidget {
  final dynamic user;
  final String applyTo; // 'teacher' | 'admin'
  const _ApplyLeaveForm({required this.user, required this.applyTo});
  @override
  State<_ApplyLeaveForm> createState() => _ApplyLeaveFormState();
}

class _ApplyLeaveFormState extends State<_ApplyLeaveForm> {
  final _formKey    = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();

  String   _leaveType = 'Casual';
  DateTime _from = DateTime.now();
  DateTime _to   = DateTime.now();
  bool     _saving = false;

  static const _types = [
    'Casual', 'Medical', 'Emergency', 'Personal', 'Other'
  ];

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  int get _days => _to.difference(_from).inDays + 1;

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
                primary: Color(0xFFD97706))),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _from = picked;
          if (_to.isBefore(_from)) _to = _from;
        } else {
          _to = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter reason for leave'),
          backgroundColor: AppColors.error));
      return;
    }
    setState(() => _saving = true);
    try {
      final user = widget.user;
      // ✅ No .name getter — UserRole is a class, use direct comparison
      final role = _roleStr(user?.role);

      await FirebaseFirestore.instance.collection('leaves').add({
        'applicantId':   user?.uid ?? '',
        'applicantName': user?.fullName ?? '',
        'applicantRole': role,
        'leaveType':     _leaveType,
        'fromDate':      Timestamp.fromDate(_from),
        'toDate':        Timestamp.fromDate(_to),
        'totalDays':     _days,
        'reason':        _reasonCtrl.text.trim(),
        'status':        'pending',
        'reviewedBy':    widget.applyTo,
        'adminRemark':   '',
        'createdAt':     FieldValue.serverTimestamp(),
      });

      _reasonCtrl.clear();
      setState(() {
        _from = DateTime.now();
        _to   = DateTime.now();
        _leaveType = 'Casual';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(widget.applyTo == 'admin'
                ? '✅ Leave submitted to Admin!'
                : '✅ Leave submitted to Teacher!'),
            backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user    = widget.user;
    final name    = user?.fullName ?? '';
    // ✅ No .name getter
    String roleLabel = 'Student';
    if (user?.role == UserRole.admin)   roleLabel = 'Admin';
    if (user?.role == UserRole.teacher) roleLabel = 'Teacher';
    final color = _typeColor(_leaveType);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Applicant card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFD97706), Color(0xFFB45309)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.w800,
                        fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w800,
                      color: Colors.white)),
                  Text(
                    '$roleLabel  →  Applying to ${_cap(widget.applyTo)}',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.white70),
                  ),
                ],
              )),
            ]),
          ),
          const SizedBox(height: 20),

          // Leave type
          _lbl('Leave Type'),
          Wrap(spacing: 8, runSpacing: 8,
            children: _types.map((t) {
              final sel = _leaveType == t;
              final tc  = _typeColor(t);
              return GestureDetector(
                onTap: () => setState(() => _leaveType = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: sel ? tc : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: tc, width: sel ? 2 : 1),
                    boxShadow: sel ? [BoxShadow(
                        color: tc.withValues(alpha: 0.25),
                        blurRadius: 8)] : [],
                  ),
                  child: Text(t, style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : tc)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Duration
          _lbl('Leave Duration'),
          Row(children: [
            Expanded(child: _dateBtn('From', _from, () => _pickDate(true))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(Icons.arrow_forward_rounded,
                  color: AppColors.textHint, size: 20),
            ),
            Expanded(child: _dateBtn('To', _to, () => _pickDate(false))),
          ]),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              Icon(Icons.schedule_rounded, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                '$_days day${_days != 1 ? 's' : ''}  •  '
                '${DateFormat('dd MMM').format(_from)} → '
                '${DateFormat('dd MMM yyyy').format(_to)}',
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Reason
          _lbl('Reason for Leave *'),
          TextFormField(
            controller: _reasonCtrl,
            maxLines: 4,
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Please enter reason' : null,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Explain the reason for your leave application...',
              hintStyle: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textHint),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFFD97706), width: 2)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.error)),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 28),

          // Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 18),
              label: Text(
                _saving ? 'Submitting...' : 'Submit Leave Application',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                shadowColor: const Color(0xFFD97706).withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text(
            'Will be reviewed by ${_cap(widget.applyTo)}',
            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint),
          )),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _lbl(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w700)),
      );

  Widget _dateBtn(String label, DateTime date, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFD97706)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.poppins(
                fontSize: 10, color: AppColors.textHint)),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 14, color: Color(0xFFD97706)),
              const SizedBox(width: 4),
              Text(DateFormat('dd MMM yyyy').format(date),
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: const Color(0xFFD97706))),
            ]),
          ]),
        ),
      );
}