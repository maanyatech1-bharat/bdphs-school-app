// lib/screens/admin/all_teachers_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../models/user_model.dart';

class AllTeachersScreen extends StatefulWidget {
  const AllTeachersScreen({super.key});
  @override
  State<AllTeachersScreen> createState() => _AllTeachersScreenState();
}

class _AllTeachersScreenState extends State<AllTeachersScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedSubject = 'All';

  final List<String> _subjects = [
    'All', 'English', 'Hindi', 'Mathematics', 'Science',
    'Social Science', 'Computer', 'Sanskrit', 'Urdu',
    'EVS', 'GK', 'Drawing', 'Physical Education',
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
        title: Text('All Teachers', style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        // Search + Filter
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            // Search
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search teachers...',
                hintStyle: GoogleFonts.poppins(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); })
                    : null,
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            // Subject filter
            SizedBox(height: 34, child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _subjects.length,
              itemBuilder: (ctx, i) {
                final sub = _subjects[i];
                final sel = _selectedSubject == sub;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSubject = sub),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.teacherColor : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? AppColors.teacherColor : AppColors.divider),
                    ),
                    child: Text(sub, style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : AppColors.textSecondary)),
                  ),
                );
              },
            )),
          ]),
        ),

        // Teacher list from Firestore
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('teachers')
              .where('approvalStatus', isEqualTo: 'approved')
              .snapshots(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            var docs = snap.data?.docs ?? [];

            // Filter
            var teachers = docs.map((d) =>
                TeacherModel.fromMap(d.data() as Map<String, dynamic>)).toList();

            if (_selectedSubject != 'All') {
              teachers = teachers.where((t) => t.subject == _selectedSubject).toList();
            }
            if (_searchQuery.isNotEmpty) {
              teachers = teachers.where((t) =>
                  t.fullName.toLowerCase().contains(_searchQuery) ||
                  t.subject.toLowerCase().contains(_searchQuery) ||
                  t.email.toLowerCase().contains(_searchQuery)).toList();
            }

            teachers.sort((a, b) => a.fullName.compareTo(b.fullName));

            if (teachers.isEmpty) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.school_outlined, size: 64,
                    color: AppColors.textHint.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Text(_searchQuery.isNotEmpty
                    ? 'No teachers matching "$_searchQuery"'
                    : 'No approved teachers yet',
                    style: GoogleFonts.poppins(fontSize: 15, color: AppColors.textSecondary),
                    textAlign: TextAlign.center),
              ]));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: teachers.length,
              itemBuilder: (ctx, i) => _TeacherCard(teacher: teachers[i]),
            );
          },
        )),
      ]),
    );
  }
}

class _TeacherCard extends StatelessWidget {
  final TeacherModel teacher;
  const _TeacherCard({required this.teacher});

  Color get _subjectColor {
    switch (teacher.subject) {
      case 'Mathematics': return const Color(0xFF2563EB);
      case 'Science': return const Color(0xFF059669);
      case 'Hindi': return const Color(0xFFDC2626);
      case 'English': return const Color(0xFF7C3AED);
      case 'Computer': return const Color(0xFF0891B2);
      default: return AppColors.teacherColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _subjectColor.withValues(alpha: 0.15),
            backgroundImage: teacher.photoUrl != null
                ? NetworkImage(teacher.photoUrl!) : null,
            child: teacher.photoUrl == null
                ? Text(teacher.fullName.isNotEmpty
                    ? teacher.fullName[0].toUpperCase() : 'T',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700,
                        fontSize: 18, color: _subjectColor))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(teacher.fullName, style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 15)),
            Text(teacher.subject, style: GoogleFonts.poppins(
                fontSize: 13, color: _subjectColor, fontWeight: FontWeight.w600)),
            if (teacher.phone.isNotEmpty)
              Text(teacher.phone, style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary)),
            if (teacher.qualification.isNotEmpty)
              Text(teacher.qualification, style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textHint)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Text('Active', style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success)),
          ),
        ]),
      ),
    );
  }
}