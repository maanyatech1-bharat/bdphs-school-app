// lib/screens/auth/teacher_registration_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class TeacherRegistrationScreen extends StatefulWidget {
  const TeacherRegistrationScreen({super.key});
  @override State<TeacherRegistrationScreen> createState() => _TeacherRegistrationScreenState();
}

class _TeacherRegistrationScreenState extends State<TeacherRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _qualificationCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _empIdCtrl = TextEditingController();
  bool _obscurePass = true;
  File? _photoFile;
  bool _isLoading = false;

  static const List<String> _qualifications = [
    'B.Ed', 'M.Ed', 'B.Sc + B.Ed', 'M.Sc + B.Ed', 'B.A + B.Ed', 'M.A + B.Ed',
    'B.Tech + B.Ed', 'NET/JRF', 'Ph.D', 'Other',
  ];
  static const List<String> _subjects = [
    'Mathematics', 'Physics', 'Chemistry', 'Biology', 'English', 'Hindi',
    'Urdu', 'Social Studies', 'History', 'Geography', 'Computer Science',
    'Physical Education', 'Art & Craft', 'Music', 'Other',
  ];
  String? _qualification, _subject;

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _photoFile = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final result = await context.read<AppAuthProvider>().registerTeacher(
      email: _emailCtrl.text, password: _passwordCtrl.text,
      fullName: _fullNameCtrl.text, phone: _phoneCtrl.text,
      address: _addressCtrl.text, qualification: _qualification ?? _qualificationCtrl.text,
      subject: _subject ?? _subjectCtrl.text, employeeId: _empIdCtrl.text,
      photoFile: _photoFile,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result.success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 60),
                const SizedBox(height: 16),
                Text('Registration Submitted!',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text('Your account is pending admin approval.',
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                GradientButton(
                  text: 'Go to Login',
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Failed'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Teacher Registration')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.teacherColor.withOpacity(0.1),
                        backgroundImage: _photoFile != null ? FileImage(_photoFile!) : null,
                        child: _photoFile == null
                            ? const Icon(Icons.person, size: 48, color: AppColors.teacherColor)
                            : null,
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppColors.teacherColor, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _sectionLabel('Personal Information'),
              const SizedBox(height: 12),
              AppTextField(label: 'Full Name *', prefixIcon: Icons.person_outline, controller: _fullNameCtrl,
                validator: (v) => v?.isEmpty == true ? 'Required' : null),
              const SizedBox(height: 12),
              AppTextField(label: 'Phone Number *', prefixIcon: Icons.phone_outlined, controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                validator: (v) => v?.length != 10 ? 'Enter 10-digit number' : null),
              const SizedBox(height: 12),
              AppTextField(label: 'Address *', prefixIcon: Icons.home_outlined, controller: _addressCtrl,
                maxLines: 2, validator: (v) => v?.isEmpty == true ? 'Required' : null),

              const SizedBox(height: 20),
              _sectionLabel('Account Details'),
              const SizedBox(height: 12),
              AppTextField(label: 'Email *', prefixIcon: Icons.email_outlined, controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => !v!.contains('@') ? 'Invalid email' : null),
              const SizedBox(height: 12),
              AppTextField(label: 'Password *', prefixIcon: Icons.lock_outlined, controller: _passwordCtrl,
                obscureText: _obscurePass,
                suffix: IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
                validator: (v) => v!.length < 6 ? 'Min 6 characters' : null),

              const SizedBox(height: 20),
              _sectionLabel('Professional Details'),
              const SizedBox(height: 12),
              AppTextField(label: 'Employee ID *', prefixIcon: Icons.badge_outlined, controller: _empIdCtrl,
                validator: (v) => v?.isEmpty == true ? 'Required' : null),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _qualification,
                decoration: _dropdownDecoration('Qualification *', Icons.school_outlined),
                items: _qualifications.map((q) => DropdownMenuItem(value: q,
                  child: Text(q, style: GoogleFonts.poppins(fontSize: 14)))).toList(),
                onChanged: (v) => setState(() => _qualification = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _subject,
                decoration: _dropdownDecoration('Subject *', Icons.menu_book_outlined),
                items: _subjects.map((s) => DropdownMenuItem(value: s,
                  child: Text(s, style: GoogleFonts.poppins(fontSize: 14)))).toList(),
                onChanged: (v) => setState(() => _subject = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 28),
              GradientButton(
                text: 'Submit Registration',
                gradient: AppColors.teacherGradient,
                icon: Icons.send_outlined,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _submit,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Row(
    children: [
      Container(width: 3, height: 16, decoration: BoxDecoration(color: AppColors.teacherColor, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    ],
  );

  InputDecoration _dropdownDecoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20),
    filled: true, fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
  );
}