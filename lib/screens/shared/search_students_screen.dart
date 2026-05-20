// lib/screens/shared/search_students_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import 'student_profile_screen.dart';

class SearchStudentsScreen extends StatefulWidget {
  const SearchStudentsScreen({super.key});
  @override
  State<SearchStudentsScreen> createState() => _SearchStudentsScreenState();
}

class _SearchStudentsScreenState extends State<SearchStudentsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<StudentModel> _allStudents = [];
  List<StudentModel> _filtered = [];
  bool _loading = true;
  String _selectedClass = 'All Classes';

  final List<String> _classes = [
    'All Classes',
    'Nursery', 'KG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
    'Class 11 - Science', 'Class 11 - Arts', 'Class 11 - Commerce',
    'Class 12 - Science', 'Class 12 - Arts', 'Class 12 - Commerce',
  ];

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('students')
          .where('approvalStatus', isEqualTo: 'approved')
          .where('isActive', isEqualTo: true)
          .get();
      _allStudents = snap.docs
          .map((d) => StudentModel.fromMap(d.data()))
          .toList()
        ..sort((a, b) => a.fullName.compareTo(b.fullName));
      _filtered = List.from(_allStudents);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _filter() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = _allStudents.where((s) {
        final matchQuery = query.isEmpty ||
            s.fullName.toLowerCase().contains(query) ||
            s.rollNumber.toLowerCase().contains(query) ||
            s.fatherName.toLowerCase().contains(query) ||
            s.email.toLowerCase().contains(query) ||
            s.phone.contains(query);
        final matchClass = _selectedClass == 'All Classes' ||
            s.className == _selectedClass;
        return matchQuery && matchClass;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Search Students',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by name, roll number, phone...',
                hintStyle: GoogleFonts.poppins(
                    color: Colors.white60, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Colors.white70),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: Colors.white70),
                        onPressed: () {
                          _searchCtrl.clear();
                          _filter();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Class filter
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              itemCount: _classes.length,
              itemBuilder: (_, i) {
                final c = _classes[i];
                final selected = _selectedClass == c;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedClass = c);
                    _filter();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      c,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Result count
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Text(
                  '${_filtered.length} student${_filtered.length != 1 ? 's' : ''} found',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Results
          Expanded(
            child: _loading
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 6,
                    itemBuilder: (_, __) => const ShimmerCard(),
                  )
                : _filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.person_search_rounded,
                        title: 'No Students Found',
                        subtitle: _searchCtrl.text.isNotEmpty
                            ? 'Try different keywords or adjust filters'
                            : 'No students match the selected class',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) =>
                            _StudentSearchCard(student: _filtered[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── SEARCH RESULT CARD ────────────────────────────────────────────────────────
class _StudentSearchCard extends StatelessWidget {
  final StudentModel student;
  const _StudentSearchCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentProfileScreen(student: student),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            UserAvatar(
              photoUrl: student.photoUrl,
              name: student.fullName,
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Roll: ${student.rollNumber} • ${student.className}',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    student.phone,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
            // Attendance badge
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _attColor(student.attendancePercentage).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(student.attendancePercentage ?? 0).toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _attColor(student.attendancePercentage),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text('Att.',
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: AppColors.textHint)),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Color _attColor(double? p) { final pct = p ?? 0;
    if (pct >= 75) return AppColors.success;
    if (pct >= 60) return AppColors.warning;
    return AppColors.error;
  }
}