// lib/screens/auth/student_registration_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});
  @override
  State<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState
    extends State<StudentRegistrationScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Form keys
  final _key1 = GlobalKey<FormState>();
  final _key2 = GlobalKey<FormState>();
  final _key3 = GlobalKey<FormState>();

  // Controllers
  final _fullName = TextEditingController();
  final _fatherName = TextEditingController();
  final _motherName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _address = TextEditingController();
  final _rollNumber = TextEditingController();
  final _aadhar = TextEditingController();

  // Values
  String _gender = 'Male';
  DateTime? _dob;
  String _className = 'Nursery';
  File? _photo;
  bool _obscure = true;

  // Auto-generated credentials
  late String _studentId;
  final List<String> _classes = [
    'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
  ];

  @override
  void initState() {
    super.initState();
    _generateCredentials();
  }

  String _getClassCode(String className) {
    switch (className) {
      case 'Nursery': return 'N';
      case 'LKG':     return 'LKG';
      case 'UKG':     return 'UKG';
      default:        return className.replaceAll('Class ', '');
    }
  }

  void _generateCredentials() {
    // ID generated from class + roll number on preview
    _updateStudentId();
  }

  void _updateStudentId() {
    final classCode = _getClassCode(_className);
    final roll = _rollNumber.text.trim().isNotEmpty ? _rollNumber.text.trim() : '0';
    _studentId = 'BDPHS$classCode$roll';
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _fullName.dispose(); _fatherName.dispose(); _motherName.dispose();
    _phone.dispose(); _email.dispose(); _password.dispose();
    _address.dispose(); _rollNumber.dispose(); _aadhar.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 60);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _pickDOB() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2010),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _nextPage() {
    bool valid = false;
    if (_currentPage == 0) valid = _key1.currentState?.validate() ?? false;
    else if (_currentPage == 1) valid = _key2.currentState?.validate() ?? false;
    else if (_currentPage == 2) valid = _key3.currentState?.validate() ?? false;
    else if (_currentPage == 3) { _submit(); return; }

    if (_currentPage == 0 && _dob == null) {
      _showSnack('Please select Date of Birth', AppColors.error);
      return;
    }

    if (valid) {
      if (_currentPage == 2) _updateStudentId(); // refresh ID before preview
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
      setState(() => _currentPage++);
    }
  }

  void _prevPage() {
    _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    setState(() => _currentPage--);
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final result = await AuthService().registerStudent(
        fullName: _fullName.text.trim(),
        fatherName: _fatherName.text.trim(),
        motherName: _motherName.text.trim(),
        gender: _gender,
        dateOfBirth: _dob!,
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        password: _password.text.trim(),
        address: _address.text.trim(),
        className: _className,
        rollNumber: _rollNumber.text.trim(),
        aadharNumber: _aadhar.text.trim(),
        studentId: _studentId,
        photoFile: _photo,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        if (result.success) {
          _showSuccessDialog();
        } else {
          _showSnack(result.error ?? 'Registration failed', AppColors.error);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack(e.toString(), AppColors.error);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(
                color: AppColors.success, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 20),
            Text('Registration Successful!',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            // Credentials card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🎫 Your School Reference ID',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  const SizedBox(height: 10),
                  _CredRow(label: 'Student ID', value: _studentId),
                  _CredRow(label: 'Email', value: _email.text.trim()),

                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Save your credentials! Your account needs teacher approval before you can login.',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('Done', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Student Registration',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('Step ${_currentPage + 1}/4',
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          _ProgressBar(current: _currentPage),

          // Pages
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Page1(
                  formKey: _key1,
                  photo: _photo, onPickPhoto: _pickPhoto,
                  fullName: _fullName, fatherName: _fatherName,
                  motherName: _motherName,
                  gender: _gender, onGenderChanged: (v) => setState(() => _gender = v!),
                  dob: _dob, onPickDOB: _pickDOB,
                ),
                _Page2(
                  formKey: _key2,
                  phone: _phone, email: _email, password: _password,
                  address: _address, obscure: _obscure,
                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                ),
                _Page3(
                  formKey: _key3,
                  className: _className,
                  classes: _classes,
                  onClassChanged: (v) => setState(() => _className = v!),
                  rollNumber: _rollNumber, aadhar: _aadhar,
                ),
                _PreviewPage(
                  photo: _photo,
                  fullName: _fullName.text, fatherName: _fatherName.text,
                  motherName: _motherName.text, gender: _gender, dob: _dob,
                  phone: _phone.text, email: _email.text,
                  address: _address.text, className: _className,
                  rollNumber: _rollNumber.text, aadhar: _aadhar.text,
                  studentId: _studentId, password: _password.text,
                ),
              ],
            ),
          ),

          // Bottom buttons
          _BottomButtons(
            currentPage: _currentPage,
            isLoading: _isLoading,
            onNext: _nextPage,
            onPrev: _prevPage,
          ),
        ],
      ),
    );
  }
}

// ─── PROGRESS BAR ─────────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final int current;
  const _ProgressBar({required this.current});
  @override
  Widget build(BuildContext context) {
    final labels = ['Personal', 'Contact', 'Academic', 'Preview'];
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Row(
            children: List.generate(4, (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: i <= current ? AppColors.accent : Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (i) => Text(
              labels[i],
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: i <= current ? Colors.white : Colors.white54,
                fontWeight: i == current ? FontWeight.w700 : FontWeight.w400,
              ),
            )),
          ),
        ],
      ),
    );
  }
}

// ─── PAGE 1: PERSONAL ─────────────────────────────────────────────────────────
class _Page1 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final File? photo;
  final VoidCallback onPickPhoto;
  final TextEditingController fullName, fatherName, motherName;
  final String gender;
  final void Function(String?) onGenderChanged;
  final DateTime? dob;
  final VoidCallback onPickDOB;

  const _Page1({
    required this.formKey, required this.photo, required this.onPickPhoto,
    required this.fullName, required this.fatherName, required this.motherName,
    required this.gender, required this.onGenderChanged,
    required this.dob, required this.onPickDOB,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Photo picker
            GestureDetector(
              onTap: onPickPhoto,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage: photo != null ? FileImage(photo!) : null,
                    child: photo == null
                        ? const Icon(Icons.person_rounded, size: 55, color: AppColors.primary)
                        : null,
                  ),
                  Positioned(
                    bottom: 4, right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: AppColors.accent, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text('Upload Photo (Optional)',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textHint)),
            const SizedBox(height: 20),
            _Field(label: 'Full Name', controller: fullName, icon: Icons.person_outline_rounded),
            _Field(label: "Father's Name", controller: fatherName, icon: Icons.man_rounded),
            _Field(label: "Mother's Name", controller: motherName, icon: Icons.woman_rounded),
            // Gender
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DropdownButtonFormField<String>(
                value: gender,
                decoration: _deco('Gender', Icons.people_rounded),
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g, style: GoogleFonts.poppins())))
                    .toList(),
                onChanged: onGenderChanged,
              ),
            ),
            // DOB
            GestureDetector(
              onTap: onPickDOB,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: dob != null ? AppColors.primary : AppColors.divider,
                      width: dob != null ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        color: dob != null ? AppColors.primary : AppColors.textHint, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      dob != null
                          ? DateFormat('dd MMMM, yyyy').format(dob!)
                          : 'Date of Birth *',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: dob != null ? AppColors.textPrimary : AppColors.textHint,
                        fontWeight: dob != null ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down_rounded,
                        color: dob != null ? AppColors.primary : AppColors.textHint),
                  ],
                ),
              ),
            ),
            if (dob != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Age: ${DateTime.now().year - dob!.year} years',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.success),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── PAGE 2: CONTACT ──────────────────────────────────────────────────────────
class _Page2 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController phone, email, password, address;
  final bool obscure;
  final VoidCallback onToggleObscure;

  const _Page2({
    required this.formKey, required this.phone, required this.email,
    required this.password, required this.address, required this.obscure,
    required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Field(label: 'Phone Number', controller: phone,
                icon: Icons.phone_rounded, type: TextInputType.phone,
                validator: (v) => v?.length != 10 ? 'Enter 10-digit phone number' : null),
            _Field(label: 'Email Address', controller: email,
                icon: Icons.email_outlined, type: TextInputType.emailAddress,
                validator: (v) => !v!.contains('@') ? 'Enter valid email' : null),
            _Field(label: 'Address', controller: address,
                icon: Icons.home_outlined, maxLines: 2),
            // Password field
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: password,
                obscureText: obscure,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Password *',
                  labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textHint, size: 20),
                    onPressed: onToggleObscure,
                  ),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                  helperText: 'Create your own password. Min 6 characters. You can change it anytime from profile.',
                  helperStyle: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint),
                ),
                validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PAGE 3: ACADEMIC ─────────────────────────────────────────────────────────
class _Page3 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String className;
  final List<String> classes;
  final void Function(String?) onClassChanged;
  final TextEditingController rollNumber, aadhar;

  const _Page3({
    required this.formKey, required this.className, required this.classes,
    required this.onClassChanged, required this.rollNumber, required this.aadhar,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Class dropdown
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DropdownButtonFormField<String>(
                value: className,
                decoration: _deco('Class / Grade', Icons.class_rounded),
                items: classes.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c, style: GoogleFonts.poppins()),
                )).toList(),
                onChanged: onClassChanged,
                validator: (v) => v == null ? 'Select class' : null,
              ),
            ),
            _Field(label: 'Roll Number', controller: rollNumber,
                icon: Icons.format_list_numbered_rounded,
                type: TextInputType.number),
            _Field(label: 'Aadhar Number', controller: aadhar,
                icon: Icons.credit_card_rounded,
                type: TextInputType.number,
                maxLength: 12,
                validator: (v) => v?.length != 12 ? 'Enter 12-digit Aadhar number' : null),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'After registration, your account will be reviewed and approved by a teacher. You\'ll be able to login after approval.',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PAGE 4: PREVIEW ──────────────────────────────────────────────────────────
class _PreviewPage extends StatelessWidget {
  final File? photo;
  final String fullName, fatherName, motherName, gender, phone,
      email, address, className, rollNumber, aadhar, studentId, password;
  final DateTime? dob;

  const _PreviewPage({
    required this.photo, required this.fullName, required this.fatherName,
    required this.motherName, required this.gender, required this.dob,
    required this.phone, required this.email, required this.address,
    required this.className, required this.rollNumber, required this.aadhar,
    required this.studentId, required this.password,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: photo != null ? FileImage(photo!) : null,
                  child: photo == null
                      ? const Icon(Icons.person_rounded, size: 50, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(height: 10),
                Text(fullName, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(className, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Credentials (highlighted)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.badge_rounded, color: AppColors.accent, size: 18),
                  const SizedBox(width: 8),
                  Text('Your Student ID', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                ]),
                const SizedBox(height: 10),
                _WhiteRow('Student ID', studentId),
                _WhiteRow('Email', email),
                const SizedBox(height: 6),
                Text('📌 Your Student ID is your school reference number.',
                    style: GoogleFonts.poppins(fontSize: 11, color: AppColors.accentLight)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _PreviewSection(title: 'Personal Information', icon: Icons.person_rounded, color: AppColors.studentColor, rows: [
            _PRow('Full Name', fullName),
            _PRow("Father's Name", fatherName),
            _PRow("Mother's Name", motherName),
            _PRow('Gender', gender),
            _PRow('Date of Birth', dob != null ? DateFormat('dd MMM, yyyy').format(dob!) : '—'),
          ]),
          const SizedBox(height: 12),
          _PreviewSection(title: 'Contact Details', icon: Icons.phone_rounded, color: AppColors.teacherColor, rows: [
            _PRow('Phone', phone),
            _PRow('Email', email),
            _PRow('Address', address),
          ]),
          const SizedBox(height: 12),
          _PreviewSection(title: 'Academic Details', icon: Icons.school_rounded, color: AppColors.accent, rows: [
            _PRow('Class', className),
            _PRow('Roll Number', rollNumber),
            _PRow('Aadhar', aadhar.length >= 4 ? 'XXXX XXXX ${aadhar.substring(aadhar.length - 4)}' : aadhar),
          ]),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Everything looks good! Tap Submit to complete registration.',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _WhiteRow extends StatelessWidget {
  final String label, value;
  const _WhiteRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      SizedBox(width: 80, child: Text('$label:', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70))),
      Expanded(child: Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))),
    ]),
  );
}

class _PreviewSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_PRow> rows;
  const _PreviewSection({required this.title, required this.icon, required this.color, required this.rows});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color)),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
      ),
      const Divider(height: 1),
      ...rows.map((r) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 110, child: Text(r.label, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textHint))),
          Expanded(child: Text(r.value.isNotEmpty ? r.value : '—',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
        ]),
      )),
    ]),
  );
}

class _PRow {
  final String label, value;
  _PRow(this.label, this.value);
}

// ─── BOTTOM BUTTONS ───────────────────────────────────────────────────────────
class _BottomButtons extends StatelessWidget {
  final int currentPage;
  final bool isLoading;
  final VoidCallback onNext, onPrev;
  const _BottomButtons({required this.currentPage, required this.isLoading, required this.onNext, required this.onPrev});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          if (currentPage > 0)
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: onPrev,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text('Back', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          if (currentPage > 0) const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: isLoading ? null : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: currentPage == 3 ? AppColors.success : AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(currentPage == 3 ? Icons.check_rounded : Icons.arrow_forward_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(currentPage == 3 ? 'Submit Registration' : 'Next',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
                    ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── HELPERS ──────────────────────────────────────────────────────────────────
class _CredRow extends StatelessWidget {
  final String label, value;
  const _CredRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(width: 90, child: Text('$label:', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary))),
      Expanded(child: SelectableText(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary))),
    ]),
  );
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType type;
  final bool obscure;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;

  const _Field({
    required this.label, required this.controller, required this.icon,
    this.type = TextInputType.text, this.obscure = false,
    this.maxLines = 1, this.maxLength, this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        obscureText: obscure,
        maxLines: maxLines,
        maxLength: maxLength,
        style: GoogleFonts.poppins(fontSize: 14),
        inputFormatters: type == TextInputType.number
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: InputDecoration(
          labelText: '$label *',
          labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          counterText: '',
        ),
        validator: validator ?? (v) => v == null || v.isEmpty ? '$label is required' : null,
      ),
    );
  }
}

InputDecoration _deco(String label, IconData icon) => InputDecoration(
  labelText: '$label *',
  labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
  prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
  filled: true, fillColor: Colors.white,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.divider)),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.divider)),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 2)),
);