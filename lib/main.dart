// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ✅ NEW
import 'package:myapp/firebase_options.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/services/auth_provider.dart';
import 'package:myapp/theme/app_theme.dart';
import 'package:myapp/screens/auth/login_screen.dart';
import 'package:myapp/screens/admin/admin_dashboard.dart';
import 'package:myapp/screens/teacher/teacher_dashboard.dart';
import 'package:myapp/screens/student/student_dashboard.dart';
import 'screens/auth/splash_screen.dart';

void main() async {
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsFlutterBinding.ensureInitialized());

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await dotenv.load(fileName: '.env'); // ✅ Load API keys from .env
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
  FlutterNativeSplash.remove();
  runApp(const BDPHSApp());
}

class BDPHSApp extends StatelessWidget {
  const BDPHSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppAuthProvider()..initialize(),
      child: MaterialApp(
        title: 'BDPHS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}

// ── App Router ────────────────────────────────────────────────────────────────
class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    if (auth.isLoading) return const _SplashScreen();

    if (!auth.isLoggedIn || auth.currentUser == null) {
      return const LoginScreen();
    }

    final user = auth.currentUser!;

    if (user.role == UserRole.admin) return const AdminDashboard();

    if (user.role == UserRole.teacher) {
      if (user.approvalStatus == ApprovalStatus.approved) {
        return const TeacherDashboard();
      }
      return _PendingScreen(
        role: 'Teacher',
        isRejected: user.approvalStatus == ApprovalStatus.rejected,
        userName: user.fullName,
      );
    }

    if (user.approvalStatus == ApprovalStatus.approved) {
      return const StudentDashboard();
    }
    return _PendingScreen(
      role: 'Student',
      isRejected: user.approvalStatus == ApprovalStatus.rejected,
      userName: user.fullName,
    );
  }
}

// ── Splash Screen ─────────────────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D2137), Color(0xFF1A3A5C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 130, height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: Colors.white,
                  boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 24, offset: const Offset(0, 10),
                  )],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png', fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1B8A3C),
                      child: const Icon(Icons.school_rounded,
                          size: 70, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text('BLOOMING DALE',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                      color: Colors.white, letterSpacing: 3)),
              const Text('PUBLIC HIGH SCHOOL',
                  style: TextStyle(fontSize: 11, color: Colors.white60,
                      letterSpacing: 5)),
              const SizedBox(height: 10),
              Container(width: 70, height: 2,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE8A020),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 10),
              const Text('Student Management System',
                  style: TextStyle(fontSize: 13, color: Colors.white54)),
              const Text('Est. 1982',
                  style: TextStyle(fontSize: 12, color: Color(0xFFE8A020),
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 48),
              const SizedBox(width: 32, height: 32,
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xFFE8A020)),
                      strokeWidth: 2.5)),
              const SizedBox(height: 14),
              const Text('Loading...',
                  style: TextStyle(fontSize: 12, color: Colors.white38)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pending Screen ────────────────────────────────────────────────────────────
class _PendingScreen extends StatelessWidget {
  final String role;
  final bool isRejected;
  final String userName;
  const _PendingScreen({
    required this.role, required this.isRejected, required this.userName});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AppAuthProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
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
                    isRejected ? Icons.cancel_rounded
                        : Icons.hourglass_empty_rounded,
                    size: 56,
                    color: isRejected
                        ? Colors.redAccent : const Color(0xFFE8A020),
                  ),
                ),
                const SizedBox(height: 28),
                Text(isRejected ? 'Account Rejected' : 'Pending Approval',
                    style: const TextStyle(fontSize: 26,
                        fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 8),
                Text('Hello, $userName',
                    style: const TextStyle(fontSize: 14, color: Colors.white70)),
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
                        ? 'Your $role account has been rejected. Please contact '
                          '${role == "Student" ? "your teacher" : "the administrator"}.'
                        : 'Your $role registration is pending approval by '
                          '${role == "Student" ? "your teacher" : "the administrator"}.'
                          '\n\nPlease wait for approval to access the app.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14,
                        color: Colors.white, height: 1.6),
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async => await auth.signOut(),
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.primary),
                    label: const Text('Sign Out',
                        style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
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