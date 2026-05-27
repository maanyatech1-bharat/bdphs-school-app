// lib/screens/admin/all_students_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';
import '../shared/student_profile_screen.dart'; // ✅ Added

class AllStudentsScreen extends StatefulWidget {
  const AllStudentsScreen({super.key});
  @override
  State<AllStudentsScreen> createState() => _AllStudentsScreenState();
}

class _AllStudentsScreenState extends State<AllStudentsScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedClass = 'All';
  String _searchQuery = '';

  final List<String> _classes = [
    'All', 'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('All Students', style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: AppColors.studentColor,
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        // Search + Filter header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by name, roll, phone...',
                hintStyle: GoogleFonts.poppins(
                    color: AppColors.textHint, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        })
                    : null,
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
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
                                : AppColors.divider),
                      ),
                      child: Text(cls, style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: sel
                              ? Colors.white
                              : AppColors.textSecondary)),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),

        // Students list from Firestore
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _selectedClass == 'All'
                ? FirebaseFirestore.instance
                    .collection('students')
                    .where('approvalStatus', isEqualTo: 'approved')
                    .snapshots()
                : FirebaseFirestore.instance
                    .collection('students')
                    .where('approvalStatus', isEqualTo: 'approved')
                    .where('className', isEqualTo: _selectedClass)
                    .snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(
                    color: AppColors.studentColor));
              }

              final docs = snap.data?.docs ?? [];
              var students = docs.map((d) =>
                  StudentModel.fromMap(
                      d.data() as Map<String, dynamic>)).toList();

              if (_searchQuery.isNotEmpty) {
                students = students.where((s) =>
                    s.fullName.toLowerCase().contains(_searchQuery) ||
                    s.rollNumber.toLowerCase().contains(_searchQuery) ||
                    s.phone.contains(_searchQuery) ||
                    s.className.toLowerCase().contains(_searchQuery)).toList();
              }

              students.sort((a, b) {
                final classComp = a.className.compareTo(b.className);
                if (classComp != 0) return classComp;
                final aRoll = int.tryParse(a.rollNumber) ?? 0;
                final bRoll = int.tryParse(b.rollNumber) ?? 0;
                return aRoll.compareTo(bRoll);
              });

              if (students.isEmpty) {
                return Center(child: Column(mainAxisSize: MainAxisSize.min,
                    children: [
                  Icon(Icons.people_outline_rounded, size: 64,
                      color: AppColors.textHint.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No students matching "$_searchQuery"'
                        : 'No approved students yet',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 15, color: AppColors.textSecondary),
                  ),
                ]));
              }

              return Column(children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  color: AppColors.studentColor.withValues(alpha: 0.05),
                  child: Text(
                    '${students.length} student${students.length == 1 ? '' : 's'} found',
                    style: GoogleFonts.poppins(fontSize: 13,
                        color: AppColors.studentColor,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(child: ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: students.length,
                  itemBuilder: (ctx, i) =>
                      _StudentCard(student: students[i]),
                )),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final StudentModel student;
  const _StudentCard({required this.student});

  Color get _classColor {
    final c = student.className;
    if (c == 'Nursery' || c == 'LKG' || c == 'UKG') {
      return const Color(0xFF059669);
    }
    if (c.contains('1') || c.contains('2') || c.contains('3')) {
      return const Color(0xFF2563EB);
    }
    if (c.contains('4') || c.contains('5') || c.contains('6')) {
      return const Color(0xFF7C3AED);
    }
    if (c.contains('7') || c.contains('8') || c.contains('9')) {
      return const Color(0xFFD97706);
    }
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final attendance = student.attendancePercentage ?? 0.0;

    return GestureDetector(
      // ✅ Fixed: tap now opens full student profile
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentProfileScreen(student: student),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 1,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _classColor.withValues(alpha: 0.15),
              backgroundImage: student.photoUrl != null
                  ? NetworkImage(student.photoUrl!) : null,
              child: student.photoUrl == null
                  ? Text(
                      student.fullName.isNotEmpty
                          ? student.fullName[0].toUpperCase() : 'S',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 18, color: _classColor))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(student.fullName, style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 14)),
              Row(children: [
                _chip(student.className, _classColor),
                const SizedBox(width: 6),
                _chip('Roll ${student.rollNumber}',
                    AppColors.textSecondary),
              ]),
              if (student.phone.isNotEmpty)
                Text(student.phone, style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textHint)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Text('Active', style: GoogleFonts.poppins(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppColors.success)),
              ),
              if (attendance > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${attendance.toStringAsFixed(0)}%',
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: attendance >= 75
                              ? AppColors.success : AppColors.error)),
                ),
              const SizedBox(height: 4),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textHint, size: 18),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: GoogleFonts.poppins(
        fontSize: 10, fontWeight: FontWeight.w600, color: color)),
  );
}