import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user_model.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_dashboard.dart';
import '../student/student_dashboard.dart';
import '../teacher/teacher_dashboard.dart';
import 'student_registration_screen.dart';
import 'teacher_registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _loading = false;
  bool _hidePassword = true;

  AnimationController? _animController;
  Animation<double>? _fadeAnim;
  Animation<Offset>? _slideAnim;

  static const _darkNavy  = Color(0xFF0D1B2E);
  static const _accent    = Color(0xFF1B4F8A);
  static const _gold      = Color(0xFFC8A84B);
  static const _bodyBg    = Color(0xFFF4F6F9);
  static const _inputBg   = Color(0xFFF0F3F7);
  static const _textDark  = Color(0xFF1A1A2E);
  static const _textMuted = Color(0xFF8A94A6);
  static const _btnBlue   = Color(0xFF1B3F72);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController!, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController!, curve: Curves.easeOut));
    _animController!.forward();
  }

  @override
  void dispose() {
    _animController?.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ── FORGOT PASSWORD ──────────────────────────────────────────────────────
  Future<void> _showForgotPassword() async {
    final resetEmailCtrl = TextEditingController(
      text: _emailController.text.trim(),
    );
    final formKey = GlobalKey<FormState>();
    bool sending = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_reset_rounded,
                    color: _accent, size: 28),
              ),
              const SizedBox(height: 12),
              Text('Reset Password',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 20, fontWeight: FontWeight.w700, color: _textDark),
                  textAlign: TextAlign.center),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter your registered email address. We will send you a password reset link.',
                  style: GoogleFonts.dmSans(fontSize: 13, color: _textMuted, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: resetEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.dmSans(fontSize: 14, color: _textDark),
                  decoration: InputDecoration(
                    hintText: 'your@email.com',
                    hintStyle: GoogleFonts.dmSans(color: _textMuted),
                    prefixIcon: const Icon(Icons.email_outlined,
                        color: _accent, size: 20),
                    filled: true,
                    fillColor: _inputBg,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _accent, width: 1.5)),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.\w+$').hasMatch(v.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.dmSans(color: _textMuted, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: sending
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setS(() => sending = true);
                      try {
                        await FirebaseAuth.instance.sendPasswordResetEmail(
                          email: resetEmailCtrl.text.trim(),
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          _showResetSuccess(resetEmailCtrl.text.trim());
                        }
                      } on FirebaseAuthException catch (e) {
                        setS(() => sending = false);
                        String msg = 'Something went wrong. Please try again.';
                        if (e.code == 'user-not-found') {
                          msg = 'No account found with this email address.';
                        } else if (e.code == 'invalid-email') {
                          msg = 'Invalid email address.';
                        } else if (e.code == 'too-many-requests') {
                          msg = 'Too many attempts. Please try again later.';
                        }
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text(msg, style: GoogleFonts.dmSans()),
                            backgroundColor: Colors.red.shade700,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ));
                        }
                      } catch (e) {
                        setS(() => sending = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red.shade700,
                          ));
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _btnBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: sending
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Send Reset Link',
                      style: GoogleFonts.dmSans(
                          color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetSuccess(String email) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(
                  color: Color(0xFF22c55e), shape: BoxShape.circle),
              child: const Icon(Icons.mark_email_read_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            Text('Email Sent!',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 20, fontWeight: FontWeight.w700, color: _textDark),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              'Password reset link sent to:\n$email',
              style: GoogleFonts.dmSans(fontSize: 13, color: _textMuted, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Text(
                '⚠️ Check your spam/junk folder if you don\'t see it in inbox. Link expires in 1 hour.',
                style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF92400E)),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _btnBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: Text('OK, Got it!',
                  style: GoogleFonts.dmSans(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ── LOGIN ────────────────────────────────────────────────────────────────
  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = context.read<AppAuthProvider>();
    final result = await auth.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    if (!mounted) return;
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Login failed. Please try again.',
              style: GoogleFonts.dmSans(fontSize: 14)),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      setState(() => _loading = false);
      return;
    }
    final user = auth.currentUser;
    if (user == null) { setState(() => _loading = false); return; }
    Widget destination;
    if (user.role == UserRole.admin) {
      destination = const AdminDashboard();
    } else if (user.role == UserRole.teacher) {
      destination = user.approvalStatus == ApprovalStatus.approved
          ? const TeacherDashboard()
          : _buildPendingScreen(context, auth, 'Teacher', user.fullName,
              user.approvalStatus == ApprovalStatus.rejected);
    } else {
      destination = user.approvalStatus == ApprovalStatus.approved
          ? const StudentDashboard()
          : _buildPendingScreen(context, auth, 'Student', user.fullName,
              user.approvalStatus == ApprovalStatus.rejected);
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _bodyBg,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim ?? const AlwaysStoppedAnimation(1.0),
                child: SlideTransition(
                  position: _slideAnim ?? const AlwaysStoppedAnimation(Offset.zero),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome Back!',
                              style: GoogleFonts.playfairDisplay(
                                  fontSize: 28, fontWeight: FontWeight.w700,
                                  color: _textDark, letterSpacing: -0.3)),
                          const SizedBox(height: 6),
                          Text('Sign in to continue to your account',
                              style: GoogleFonts.dmSans(fontSize: 14, color: _textMuted)),
                          const SizedBox(height: 28),

                          // Email
                          _fieldLabel('Email Address'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).requestFocus(_passwordFocus),
                            style: GoogleFonts.dmSans(fontSize: 15, color: _textDark),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Email is required';
                              if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.\w+$').hasMatch(val.trim())) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                            decoration: _inputDecoration(
                                hint: 'you@example.com',
                                icon: Icons.mail_outline_rounded),
                          ),
                          const SizedBox(height: 20),

                          // Password
                          _fieldLabel('Password'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            obscureText: _hidePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _login(),
                            style: GoogleFonts.dmSans(fontSize: 15, color: _textDark),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Password is required';
                              if (val.trim().length < 6) return 'Minimum 6 characters required';
                              return null;
                            },
                            decoration: _inputDecoration(
                              hint: '••••••••••',
                              icon: Icons.lock_outline_rounded,
                            ).copyWith(
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _hidePassword = !_hidePassword),
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: _textMuted, size: 20,
                                ),
                              ),
                            ),
                          ),

                          // ── Forgot Password ── FIXED ──────────────────
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPassword, // ✅ now works
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.only(top: 10, bottom: 2),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text('Forgot Password?',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 13, fontWeight: FontWeight.w600,
                                      color: _accent)),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Sign In button
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: _loading ? null : _login,
                              icon: _loading
                                  ? const SizedBox.shrink()
                                  : const Icon(Icons.login_rounded,
                                      color: Colors.white, size: 20),
                              label: _loading
                                  ? const SizedBox(width: 22, height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2.5))
                                  : Text('Sign In',
                                      style: GoogleFonts.dmSans(
                                          fontSize: 16, fontWeight: FontWeight.w700,
                                          color: Colors.white, letterSpacing: 0.3)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _btnBlue,
                                disabledBackgroundColor: _btnBlue.withValues(alpha: 0.6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          Row(
                            children: [
                              const Expanded(child: Divider(thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('New to BDPHS?',
                                    style: GoogleFonts.dmSans(
                                        fontSize: 13, color: _textMuted)),
                              ),
                              const Expanded(child: Divider(thickness: 1)),
                            ],
                          ),

                          const SizedBox(height: 20),

                          _registrationTile(
                            icon: Icons.school_rounded,
                            iconColor: const Color(0xFF1B4F8A),
                            iconBg: const Color(0xFFE8F0FB),
                            title: 'Student Registration',
                            subtitle: 'Register as a new student',
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) => const StudentRegistrationScreen())),
                          ),
                          const SizedBox(height: 12),
                          _registrationTile(
                            icon: Icons.person_rounded,
                            iconColor: const Color(0xFF1A6B4A),
                            iconBg: const Color(0xFFE3F5EC),
                            title: 'Teacher Registration',
                            subtitle: 'Register as a teacher',
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) => const TeacherRegistrationScreen())),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _darkNavy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Column(
            children: [
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: _gold, width: 2.5),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset('assets/images/bdphs.png', fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('BLOOMING DALE',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 22, fontWeight: FontWeight.w800,
                      color: Colors.white, letterSpacing: 3)),
              const SizedBox(height: 3),
              Text('PUBLIC HIGH SCHOOL',
                  style: GoogleFonts.dmSans(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: Colors.white60, letterSpacing: 4)),
              const SizedBox(height: 8),
              Text('Student Management System',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: Colors.white54, letterSpacing: 0.3)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: _gold.withValues(alpha: 0.55)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Est. 1982',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: _gold,
                        fontWeight: FontWeight.w500, letterSpacing: 1)),
              ),
              const SizedBox(height: 14),
              Text('✦  Where Young Minds Bloom  ✦',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 12, fontStyle: FontStyle.italic,
                      color: Colors.white38, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text('and Bright Futures Begin.',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 12, fontStyle: FontStyle.italic,
                      color: Colors.white38, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(text,
      style: GoogleFonts.dmSans(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: _textDark, letterSpacing: 0.2));

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(fontSize: 14, color: _textMuted),
      prefixIcon: Icon(icon, color: _textMuted, size: 20),
      filled: true, fillColor: _inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.2)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5)),
    );
  }

  Widget _registrationTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8EDF3), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.dmSans(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: _textDark)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: GoogleFonts.dmSans(fontSize: 12, color: _textMuted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: _textMuted, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingScreen(BuildContext context, AppAuthProvider auth,
      String role, String userName, bool isRejected) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D2137), Color(0xFF1A3A5C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110, height: 110,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Colors.white24),
                  child: Icon(
                    isRejected ? Icons.cancel_rounded : Icons.hourglass_empty_rounded,
                    size: 56,
                    color: isRejected ? Colors.redAccent : const Color(0xFFE8A020),
                  ),
                ),
                const SizedBox(height: 28),
                Text(isRejected ? 'Account Rejected' : 'Pending Approval',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 26, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 8),
                Text('Hello, $userName',
                    style: GoogleFonts.dmSans(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    isRejected
                        ? 'Your $role account has been rejected. Please contact ${role == "Student" ? "your teacher" : "the administrator"}.'
                        : 'Your $role registration is pending approval.\n\nPlease wait for approval to access the app.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                        fontSize: 14, color: Colors.white, height: 1.6),
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await auth.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, color: _btnBlue),
                    label: Text('Sign Out',
                        style: GoogleFonts.dmSans(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: _btnBlue)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}