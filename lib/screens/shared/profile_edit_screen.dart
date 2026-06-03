// lib/screens/shared/profile_edit_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Common controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;

  // Student-specific
  late TextEditingController _fatherNameCtrl;
  late TextEditingController _motherNameCtrl;
  late TextEditingController _rollNumberCtrl;
  late TextEditingController _addressCtrl;
  String? _selectedClass;
  String? _selectedGender;
  DateTime? _dateOfBirth;

  // Teacher-specific
  late TextEditingController _qualificationCtrl;
  late TextEditingController _employeeIdCtrl;
  String? _selectedSubject;

  // State
  File? _pickedImage;
  bool _saving = false;
  bool _uploadingPhoto = false;
  String? _currentPhotoUrl;

  static const List<String> _classes = [
    'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
  ];

  static const List<String> _subjects = [
    'Hindi', 'English', 'Mathematics', 'Science', 'Social Science',
    'Sanskrit', 'Computer', 'Drawing', 'Physical Education',
    'General Knowledge',
  ];

  static const List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    final user = context.read<AppAuthProvider>().currentUser!;
    _nameCtrl = TextEditingController(text: user.fullName);
    _phoneCtrl = TextEditingController(text: user.phone);
    _currentPhotoUrl = user.photoUrl;

    if (user is StudentModel) {
      _fatherNameCtrl = TextEditingController(text: user.fatherName);
      _motherNameCtrl = TextEditingController(text: user.motherName);
      _rollNumberCtrl = TextEditingController(text: user.rollNumber);
      _addressCtrl = TextEditingController(text: user.address);
      _selectedClass =
          _classes.contains(user.className) ? user.className : null;
      _selectedGender =
          _genders.contains(user.gender) ? user.gender : null;
      _dateOfBirth = user.dateOfBirth;
      _qualificationCtrl = TextEditingController();
      _employeeIdCtrl = TextEditingController();
    } else if (user is TeacherModel) {
      _fatherNameCtrl = TextEditingController();
      _motherNameCtrl = TextEditingController();
      _rollNumberCtrl = TextEditingController();
      _addressCtrl = TextEditingController(text: user.address);
      _qualificationCtrl = TextEditingController(text: user.qualification);
      _employeeIdCtrl = TextEditingController(text: user.employeeId);
      _selectedSubject =
          _subjects.contains(user.subject) ? user.subject : null;
    } else {
      _fatherNameCtrl = TextEditingController();
      _motherNameCtrl = TextEditingController();
      _rollNumberCtrl = TextEditingController();
      _addressCtrl = TextEditingController();
      _qualificationCtrl = TextEditingController();
      _employeeIdCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _fatherNameCtrl.dispose();
    _motherNameCtrl.dispose();
    _rollNumberCtrl.dispose();
    _addressCtrl.dispose();
    _qualificationCtrl.dispose();
    _employeeIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.primary),
              title: Text('Choose from Gallery',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 75,
                    maxWidth: 800);
                if (picked != null) {
                  setState(() => _pickedImage = File(picked.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.teacherColor),
              title: Text('Take a Photo',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 75,
                    maxWidth: 800);
                if (picked != null) {
                  setState(() => _pickedImage = File(picked.path));
                }
              },
            ),
            if (_currentPhotoUrl != null || _pickedImage != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error),
                title: Text('Remove Photo',
                    style: GoogleFonts.poppins(
                        color: AppColors.error, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _pickedImage = null;
                    _currentPhotoUrl = null;
                  });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadPhoto(String uid) async {
    if (_pickedImage == null) return _currentPhotoUrl;
    setState(() => _uploadingPhoto = true);
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos/$uid.jpg');
      final task = await ref.putFile(_pickedImage!);
      return await task.ref.getDownloadURL();
    } catch (_) {
      return _currentPhotoUrl;
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AppAuthProvider>();
    final user = auth.currentUser!;
    setState(() => _saving = true);

    try {
      final newPhotoUrl = await _uploadPhoto(user.uid);
      final db = FirebaseFirestore.instance;

      final baseUpdate = {
        'fullName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'photoUrl': newPhotoUrl,
      };

      if (user is StudentModel) {
        final update = {
          ...baseUpdate,
          'address': _addressCtrl.text.trim(),
          'fatherName': _fatherNameCtrl.text.trim(),
          'motherName': _motherNameCtrl.text.trim(),
          'rollNumber': _rollNumberCtrl.text.trim(),
          if (_selectedClass != null) 'className': _selectedClass,
          if (_selectedGender != null) 'gender': _selectedGender,
          if (_dateOfBirth != null) 'dateOfBirth': _dateOfBirth,
        };
        final batch = db.batch();
        batch.update(db.collection('users').doc(user.uid), update);
        batch.update(db.collection('students').doc(user.uid), update);
        await batch.commit();
      } else if (user is TeacherModel) {
        final update = {
          ...baseUpdate,
          'address': _addressCtrl.text.trim(),
          'qualification': _qualificationCtrl.text.trim(),
          if (_selectedSubject != null) 'subject': _selectedSubject,
        };
        final batch = db.batch();
        batch.update(db.collection('users').doc(user.uid), update);
        batch.update(db.collection('teachers').doc(user.uid), update);
        await batch.commit();
      } else {
        await db.collection('users').doc(user.uid).update(baseUpdate);
      }

      await auth.loadCurrentUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully! ✅'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser!;
    final isStudent = user is StudentModel;
    final isTeacher = user is TeacherModel;

    final Color themeColor = isStudent
        ? AppColors.studentColor
        : isTeacher
            ? AppColors.teacherColor
            : AppColors.adminColor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        title: Text('Edit Profile',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: (_saving || _uploadingPhoto) ? null : _save,
              child: Text(
                _saving
                    ? 'Saving...'
                    : _uploadingPhoto
                        ? 'Uploading...'
                        : 'Save',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile Photo ─────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: themeColor, width: 3),
                          color: themeColor.withValues(alpha: 0.08),
                        ),
                        child: ClipOval(
                          child: _pickedImage != null
                              ? Image.file(_pickedImage!,
                                  fit: BoxFit.cover)
                              : _currentPhotoUrl != null
                                  ? Image.network(_currentPhotoUrl!,
                                      fit: BoxFit.cover)
                                  : Center(
                                      child: Text(
                                        user.fullName.isNotEmpty
                                            ? user.fullName[0].toUpperCase()
                                            : '?',
                                        style: GoogleFonts.poppins(
                                            fontSize: 40,
                                            fontWeight: FontWeight.w700,
                                            color: themeColor),
                                      ),
                                    ),
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: themeColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 16, color: Colors.white),
                        ),
                      ),
                      if (_uploadingPhoto)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('Tap to change profile photo',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textHint)),
              ),
              const SizedBox(height: 28),

              // ── Basic Info ────────────────────────────────────────────
              _sectionHeader('Basic Information', Icons.person_rounded),
              const SizedBox(height: 14),
              _formField(
                label: 'Full Name',
                controller: _nameCtrl,
                icon: Icons.person_outline_rounded,
                required: true,
              ),
              const SizedBox(height: 12),
              _formField(
                label: 'Phone Number',
                controller: _phoneCtrl,
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                required: true,
              ),

              // ── Student Fields ────────────────────────────────────────
              if (isStudent) ...[
                const SizedBox(height: 24),
                _sectionHeader(
                    'Academic Details', Icons.school_rounded),
                const SizedBox(height: 14),
                // Class & Roll — read-only for student, editable only by admin
                _readOnlyInfoTile(
                  label: 'Class',
                  value: _selectedClass ?? 'Not assigned',
                  icon: Icons.class_rounded,
                ),
                const SizedBox(height: 12),
                _readOnlyInfoTile(
                  label: 'Roll Number',
                  value: _rollNumberCtrl.text.isEmpty ? 'Not assigned' : _rollNumberCtrl.text,
                  icon: Icons.numbers_rounded,
                ),
                const SizedBox(height: 24),
                _sectionHeader(
                    'Personal Details', Icons.family_restroom_rounded),
                const SizedBox(height: 14),
                _formField(
                  label: "Father's Name",
                  controller: _fatherNameCtrl,
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 12),
                _formField(
                  label: "Mother's Name",
                  controller: _motherNameCtrl,
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 12),
                _dropdownField(
                  label: 'Gender',
                  value: _selectedGender,
                  items: _genders,
                  icon: Icons.wc_rounded,
                  onChanged: (v) =>
                      setState(() => _selectedGender = v),
                ),
                const SizedBox(height: 12),
                _datePickerField(),
                const SizedBox(height: 12),
                _formField(
                  label: 'Home Address',
                  controller: _addressCtrl,
                  icon: Icons.home_rounded,
                  maxLines: 2,
                ),
              ],

              // ── Teacher Fields ────────────────────────────────────────
              if (isTeacher) ...[
                const SizedBox(height: 24),
                _sectionHeader(
                    'Professional Details', Icons.work_rounded),
                const SizedBox(height: 14),
                _formField(
                  label: 'Employee ID',
                  controller: _employeeIdCtrl,
                  icon: Icons.badge_rounded,
                  readOnly: true,
                  hint: 'Cannot be changed',
                ),
                const SizedBox(height: 12),
                _dropdownField(
                  label: 'Subject Taught',
                  value: _selectedSubject,
                  items: _subjects,
                  icon: Icons.subject_rounded,
                  onChanged: (v) =>
                      setState(() => _selectedSubject = v),
                ),
                const SizedBox(height: 12),
                _formField(
                  label: 'Qualification',
                  controller: _qualificationCtrl,
                  icon: Icons.school_rounded,
                ),
                const SizedBox(height: 12),
                _formField(
                  label: 'Address',
                  controller: _addressCtrl,
                  icon: Icons.home_rounded,
                  maxLines: 2,
                ),
              ],

              const SizedBox(height: 32),

              // ── Save Button ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      (_saving || _uploadingPhoto) ? null : _save,
                  icon: (_saving || _uploadingPhoto)
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded,
                          color: Colors.white),
                  label: Text(
                    _uploadingPhoto
                        ? 'Uploading Photo...'
                        : _saving
                            ? 'Saving...'
                            : 'Save Changes',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    disabledBackgroundColor:
                        themeColor.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) {
    return Row(children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
      const SizedBox(width: 10),
      Text(title,
          style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
    ]);
  }

  Widget _formField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = false,
    bool readOnly = false,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      style: GoogleFonts.poppins(
          fontSize: 14,
          color: readOnly ? AppColors.textSecondary : AppColors.textPrimary),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.poppins(
            fontSize: 13, color: AppColors.textSecondary),
        hintStyle:
            GoogleFonts.poppins(fontSize: 13, color: AppColors.textHint),
        prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
        filled: true,
        fillColor: readOnly
            ? AppColors.background
            : Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
            fontSize: 13, color: AppColors.textSecondary),
        prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: GoogleFonts.poppins(
          fontSize: 14, color: AppColors.textPrimary),
      isExpanded: true,
      items: items
          .map((item) => DropdownMenuItem(
              value: item,
              child: Text(item, style: GoogleFonts.poppins(fontSize: 14))))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _datePickerField() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _dateOfBirth ?? DateTime(2010),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(
                  primary: AppColors.primary),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _dateOfBirth = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          const Icon(Icons.cake_rounded,
              size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date of Birth',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  _dateOfBirth != null
                      ? DateFormat('dd MMMM yyyy').format(_dateOfBirth!)
                      : 'Tap to select date',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: _dateOfBirth != null
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: _dateOfBirth != null
                          ? AppColors.textPrimary
                          : AppColors.textHint),
                ),
              ],
            ),
          ),
          const Icon(Icons.calendar_today_rounded,
              size: 18, color: AppColors.primary),
        ]),
      ),
    );
  }

  Widget _readOnlyInfoTile({required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }

}