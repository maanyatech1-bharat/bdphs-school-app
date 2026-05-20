// lib/screens/shared/fee_screen.dart
// Simple fee management — Admin/Teacher: add & view all | Student: view own fees
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';

// ─── Fee Model ────────────────────────────────────────────────────────────────
class FeeRecord {
  final String id;
  final String studentName;
  final String studentId;
  final String className;
  final String rollNumber;
  final String feeType;
  final String month;
  final double amount;
  final String status; // 'paid' | 'pending' | 'overdue'
  final DateTime dueDate;
  final DateTime? paidDate;
  final String addedBy;
  final DateTime createdAt;

  const FeeRecord({
    required this.id, required this.studentName, required this.studentId,
    required this.className, required this.rollNumber, required this.feeType,
    required this.month, required this.amount, required this.status,
    required this.dueDate, this.paidDate, required this.addedBy,
    required this.createdAt,
  });

  factory FeeRecord.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FeeRecord(
      id: doc.id,
      studentName: d['studentName'] ?? '',
      studentId: d['studentId'] ?? '',
      className: d['className'] ?? '',
      rollNumber: d['rollNumber'] ?? '',
      feeType: d['feeType'] ?? 'Tuition Fee',
      month: d['month'] ?? '',
      amount: (d['amount'] as num?)?.toDouble() ?? 0,
      status: d['status'] ?? 'pending',
      dueDate: (d['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paidDate: (d['paidDate'] as Timestamp?)?.toDate(),
      addedBy: d['addedBy'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// ─── Fee Screen ───────────────────────────────────────────────────────────────
class FeeScreen extends StatefulWidget {
  const FeeScreen({super.key});
  @override
  State<FeeScreen> createState() => _FeeScreenState();
}

class _FeeScreenState extends State<FeeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser;
    final isAdmin = user?.role.name == 'admin';
    final isTeacher = user?.role.name == 'teacher';
    final canManage = isAdmin || isTeacher;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Fee Management',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: canManage ? 'All Records' : 'My Fees'),
            if (canManage) const Tab(text: 'Add Fee Record'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // Tab 1: View Records
          _FeeListTab(user: user, canManage: canManage),
          // Tab 2: Add Record (admin/teacher only)
          if (canManage) _AddFeeTab(user: user),
        ],
      ),
    );
  }
}

// ─── Fee List Tab ─────────────────────────────────────────────────────────────
class _FeeListTab extends StatefulWidget {
  final dynamic user;
  final bool canManage;
  const _FeeListTab({required this.user, required this.canManage});
  @override
  State<_FeeListTab> createState() => _FeeListTabState();
}

class _FeeListTabState extends State<_FeeListTab> {
  String _filterClass = 'All';
  String _filterStatus = 'All';

  final _classes = ['All', 'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10'];
  final _statuses = ['All', 'pending', 'paid', 'overdue'];

  Color _statusColor(String s) {
    switch (s) {
      case 'paid': return AppColors.success;
      case 'overdue': return AppColors.error;
      default: return const Color(0xFFD97706);
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'paid': return Icons.check_circle_rounded;
      case 'overdue': return Icons.warning_rounded;
      default: return Icons.schedule_rounded;
    }
  }

  Stream<QuerySnapshot> _buildQuery() {
    // Students see only their own fees
    if (!widget.canManage) {
      return FirebaseFirestore.instance
          .collection('fees')
          .where('studentId', isEqualTo: widget.user?.uid ?? '')
          // ✅ No orderBy — avoids composite index; sorted client-side
          .snapshots();
    }
    // Admin/teacher see all, with optional class filter
    Query q = FirebaseFirestore.instance.collection('fees');
    if (_filterClass != 'All') q = q.where('className', isEqualTo: _filterClass);
    // ✅ No orderBy — sorted client-side
    return q.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Filters (admin/teacher only) ─────────────────────────────
      if (widget.canManage) ...[
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: _drop('Class', _filterClass, _classes,
                (v) => setState(() => _filterClass = v!))),
            const SizedBox(width: 10),
            Expanded(child: _drop('Status', _filterStatus, _statuses,
                (v) => setState(() => _filterStatus = v!))),
          ]),
        ),
        const Divider(height: 1),
      ],

      // ── List ──────────────────────────────────────────────────────
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: _buildQuery(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
            }
            var docs = snap.data?.docs ?? [];
            // ✅ Sort client-side by createdAt descending
            docs = List.from(docs)..sort((a, b) {
              final at = (a.data() as Map)['createdAt'] as Timestamp?;
              final bt = (b.data() as Map)['createdAt'] as Timestamp?;
              if (at == null) return 1;
              if (bt == null) return -1;
              return bt.compareTo(at);
            });
            // Client-side status filter
            if (_filterStatus != 'All') {
              docs = docs.where((d) =>
                  (d.data() as Map)['status'] == _filterStatus).toList();
            }

            if (docs.isEmpty) {
              return _empty();
            }

            // Summary banner
            final records = docs.map(FeeRecord.fromDoc).toList();
            final totalAmt = records.fold<double>(0, (s, r) => s + r.amount);
            final paidAmt = records.where((r) => r.status == 'paid')
                .fold<double>(0, (s, r) => s + r.amount);
            final pendingAmt = totalAmt - paidAmt;

            return Column(children: [
              // Summary
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF059669).withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  _summaryPill('₹${_fmt(totalAmt)}', 'Total',
                      const Color(0xFF059669)),
                  _summaryPill('₹${_fmt(paidAmt)}', 'Paid', AppColors.success),
                  _summaryPill('₹${_fmt(pendingAmt)}', 'Pending',
                      const Color(0xFFD97706)),
                ]),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                  itemCount: records.length,
                  itemBuilder: (_, i) {
                    final r = records[i];
                    final color = _statusColor(r.status);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border(
                            left: BorderSide(color: color, width: 4)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8)
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(r.studentName,
                                    style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: color),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(_statusIcon(r.status), size: 12, color: color),
                                  const SizedBox(width: 4),
                                  Text(r.status.toUpperCase(),
                                      style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: color)),
                                ]),
                              ),
                            ]),
                            const SizedBox(height: 6),
                            Wrap(spacing: 12, children: [
                              _chip(Icons.class_rounded, r.className),
                              _chip(Icons.badge_rounded, 'Roll: ${r.rollNumber}'),
                              _chip(Icons.category_rounded, r.feeType),
                              _chip(Icons.calendar_month_rounded, r.month),
                            ]),
                            const SizedBox(height: 8),
                            Row(children: [
                              Text('₹${_fmt(r.amount)}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF059669))),
                              const Spacer(),
                              Text(
                                'Due: ${DateFormat('dd MMM yyyy').format(r.dueDate)}',
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: AppColors.textHint),
                              ),
                            ]),
                            // Mark paid button (admin/teacher)
                            if (widget.canManage && r.status != 'paid') ...[
                              const SizedBox(height: 10),
                              Row(children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _markPaid(r),
                                    icon: const Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 16, color: AppColors.success),
                                    label: Text('Mark as Paid',
                                        style: GoogleFonts.poppins(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.success),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: AppColors.error, size: 20),
                                  onPressed: () => _delete(r.id),
                                  tooltip: 'Delete',
                                ),
                              ]),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ]);
          },
        ),
      ),
    ]);
  }

  Future<void> _markPaid(FeeRecord r) async {
    await FirebaseFirestore.instance.collection('fees').doc(r.id).update({
      'status': 'paid',
      'paidDate': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Marked as Paid'),
          backgroundColor: AppColors.success));
    }
  }

  Future<void> _delete(String id) async {
    await FirebaseFirestore.instance.collection('fees').doc(id).delete();
  }

  Widget _empty() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No fee records found',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('No fees have been added yet',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textSecondary)),
        ]),
      );

  Widget _summaryPill(String value, String label, Color color) => Expanded(
        child: Column(children: [
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textSecondary)),
        ]),
      );

  Widget _chip(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: AppColors.textHint),
        const SizedBox(width: 3),
        Text(text,
            style: GoogleFonts.poppins(
                fontSize: 11, color: AppColors.textSecondary)),
      ]);

  Widget _drop(String label, String value, List<String> items,
      void Function(String?) onChange) =>
      DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary),
        items: items
            .map((i) => DropdownMenuItem(
                value: i, child: Text(i, style: GoogleFonts.poppins(fontSize: 13))))
            .toList(),
        onChanged: onChange,
      );

  String _fmt(double v) => NumberFormat('#,##,###').format(v);
}

// ─── Add Fee Tab ──────────────────────────────────────────────────────────────
class _AddFeeTab extends StatefulWidget {
  final dynamic user;
  const _AddFeeTab({required this.user});
  @override
  State<_AddFeeTab> createState() => _AddFeeTabState();
}

class _AddFeeTabState extends State<_AddFeeTab> {
  final _nameCtrl   = TextEditingController();
  final _rollCtrl   = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _formKey    = GlobalKey<FormState>();

  String _selectedClass = 'Class 1';
  String _feeType = 'Tuition Fee';
  String _month = 'April';
  String _status = 'pending';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 15));
  bool _saving = false;

  // Students fetched from Firestore for autocomplete
  List<Map<String, dynamic>> _students = [];
  bool _loadingStudents = false;

  final _classes = ['Nursery','LKG','UKG',
    'Class 1','Class 2','Class 3','Class 4','Class 5',
    'Class 6','Class 7','Class 8','Class 9','Class 10'];
  final _feeTypes = ['Tuition Fee','Admission Fee','Exam Fee',
    'Lab Fee','Sports Fee','Bus Fee','Library Fee','Other'];
  final _months = ['January','February','March','April','May','June',
    'July','August','September','October','November','December'];
  final _statuses = ['pending','paid','overdue'];

  @override
  void dispose() {
    _nameCtrl.dispose(); _rollCtrl.dispose(); _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents(String className) async {
    setState(() { _loadingStudents = true; _students = []; });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('students')
          .where('className', isEqualTo: className)
          .where('approvalStatus', isEqualTo: 'approved')
          .get();
      _students = snap.docs.map((d) {
        final data = d.data();
        return {
          'uid': d.id,
          'name': data['fullName'] ?? '',
          'roll': data['rollNumber'] ?? '',
        };
      }).toList();
    } catch (_) {}
    setState(() => _loadingStudents = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter student name'),
          backgroundColor: AppColors.error));
      return;
    }

    setState(() => _saving = true);

    // Try to match student UID from fetched list
    final match = _students.firstWhere(
        (s) => (s['name'] as String).toLowerCase() ==
            _nameCtrl.text.trim().toLowerCase(),
        orElse: () => {'uid': '', 'name': _nameCtrl.text.trim(), 'roll': _rollCtrl.text.trim()});

    try {
      await FirebaseFirestore.instance.collection('fees').add({
        'studentName': _nameCtrl.text.trim(),
        'studentId': match['uid'],
        'className': _selectedClass,
        'rollNumber': _rollCtrl.text.trim(),
        'feeType': _feeType,
        'month': _month,
        'amount': double.tryParse(_amountCtrl.text.trim()) ?? 0,
        'status': _status,
        'dueDate': Timestamp.fromDate(_dueDate),
        'paidDate': _status == 'paid' ? FieldValue.serverTimestamp() : null,
        'addedBy': widget.user?.uid ?? '',
        'addedByName': widget.user?.fullName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _nameCtrl.clear(); _rollCtrl.clear(); _amountCtrl.clear();
        setState(() { _status = 'pending'; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Fee record added successfully!'),
            backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Class + Roll ────────────────────────────────────────────
          Row(children: [
            Expanded(
              flex: 3,
              child: _label('Class',
                  DropdownButtonFormField<String>(
                    value: _selectedClass,
                    decoration: _dec('Select class'),
                    style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
                    items: _classes.map((c) => DropdownMenuItem(
                        value: c, child: Text(c, style: GoogleFonts.poppins()))).toList(),
                    onChanged: (v) {
                      setState(() => _selectedClass = v!);
                      _nameCtrl.clear(); _rollCtrl.clear();
                      _fetchStudents(v!);
                    },
                  )),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _label('Roll No.',
                  TextFormField(
                    controller: _rollCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: _dec('e.g. 5'),
                  )),
            ),
          ]),
          const SizedBox(height: 14),

          // ── Student Name (with suggestions) ─────────────────────────
          _label('Student Name *',
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextFormField(
                  controller: _nameCtrl,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: _dec('Type or pick student name').copyWith(
                    suffixIcon: _loadingStudents
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2)))
                        : null,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Required' : null,
                ),
                // Quick pick buttons from fetched students
                if (_students.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6,
                    children: _students.take(8).map((s) => GestureDetector(
                      onTap: () => setState(() {
                        _nameCtrl.text = s['name'];
                        _rollCtrl.text = s['roll'];
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.4)),
                        ),
                        child: Text(s['name'],
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: const Color(0xFF059669))),
                      ),
                    )).toList(),
                  ),
                ],
              ])),
          const SizedBox(height: 14),

          // ── Fee Type + Month ─────────────────────────────────────────
          Row(children: [
            Expanded(child: _label('Fee Type',
                DropdownButtonFormField<String>(
                  value: _feeType,
                  decoration: _dec('Select type'),
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
                  items: _feeTypes.map((f) => DropdownMenuItem(
                      value: f, child: Text(f, style: GoogleFonts.poppins()))).toList(),
                  onChanged: (v) => setState(() => _feeType = v!),
                ))),
            const SizedBox(width: 12),
            Expanded(child: _label('Month',
                DropdownButtonFormField<String>(
                  value: _month,
                  decoration: _dec('Select month'),
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
                  items: _months.map((m) => DropdownMenuItem(
                      value: m, child: Text(m, style: GoogleFonts.poppins()))).toList(),
                  onChanged: (v) => setState(() => _month = v!),
                ))),
          ]),
          const SizedBox(height: 14),

          // ── Amount ────────────────────────────────────────────────────
          _label('Amount (₹) *',
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                decoration: _dec('e.g. 1500').copyWith(
                  prefixText: '₹ ',
                  prefixStyle: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: const Color(0xFF059669)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              )),
          const SizedBox(height: 14),

          // ── Due Date + Status ─────────────────────────────────────────
          Row(children: [
            Expanded(child: _label('Due Date',
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _dueDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.divider),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 18, color: Color(0xFF059669)),
                      const SizedBox(width: 8),
                      Text(DateFormat('dd MMM yyyy').format(_dueDate),
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: const Color(0xFF059669))),
                    ]),
                  ),
                ))),
            const SizedBox(width: 12),
            Expanded(child: _label('Status',
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: _dec('Status'),
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
                  items: _statuses.map((s) => DropdownMenuItem(
                      value: s, child: Text(s[0].toUpperCase() + s.substring(1),
                          style: GoogleFonts.poppins()))).toList(),
                  onChanged: (v) => setState(() => _status = v!),
                ))),
          ]),
          const SizedBox(height: 24),

          // ── Save Button ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                disabledBackgroundColor: AppColors.divider,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text('Add Fee Record',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: Colors.white)),
            ),
          ),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _label(String text, Widget child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          child,
        ],
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textHint),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFF059669), width: 2)),
      );
}