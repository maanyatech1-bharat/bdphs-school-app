import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import 'auth_service.dart';

class AppAuthProvider extends ChangeNotifier {

  final AuthService _authService = AuthService();

  UserModel? _currentUser;

  bool _isLoading = true;

  String? _error;

  bool _disposed = false;

  UserModel? get currentUser => _currentUser;

  bool get isLoading => _isLoading;

  String? get error => _error;

  bool get isLoggedIn => _currentUser != null;

  bool get isAdmin =>
      _currentUser?.role == UserRole.admin;

  bool get isTeacher =>
      _currentUser?.role == UserRole.teacher;

  bool get isStudent =>
      _currentUser?.role == UserRole.student;

  bool get isApproved =>
      _currentUser?.approvalStatus ==
      ApprovalStatus.approved;

  // ───────────────── INITIALIZE ─────────────────

  void initialize() {

    _isLoading = true;

    FirebaseAuth.instance
        .authStateChanges()
        .listen((user) async {

      if (_disposed) return;

      debugPrint(
        '🔥 Auth state: ${user?.uid ?? "no user"}',
      );

      // USER LOGGED OUT
      if (user == null) {

        _currentUser = null;

        _isLoading = false;

        _notify();

        return;
      }

      try {

        await _loadUser(user.uid);

      } catch (e) {

        debugPrint(
          '💥 Auth listener error: $e',
        );

        _currentUser = null;
      }

      _isLoading = false;

      _notify();
    });
  }

  // ───────────────── LOAD USER ─────────────────

  Future<void> _loadUser(String uid) async {

    debugPrint('📖 Loading user: $uid');

    try {

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      debugPrint(
        '📄 User doc exists: ${doc.exists}',
      );

      if (!doc.exists) {

        _currentUser = null;

        return;
      }

      final data =
          Map<String, dynamic>.from(doc.data()!);

      final role =
          data['role']?.toString() ?? 'student';

      debugPrint('👤 Role: $role');

      // STUDENT
      if (role == 'student') {

        try {

          final studentDoc =
              await FirebaseFirestore.instance
                  .collection('students')
                  .doc(uid)
                  .get();

          if (studentDoc.exists) {

            _currentUser =
                StudentModel.fromMap(
              Map<String, dynamic>.from(
                studentDoc.data()!,
              ),
            );

          } else {

            _currentUser =
                _fallbackUser(data);
          }

        } catch (_) {

          _currentUser =
              _fallbackUser(data);
        }

      }

      // TEACHER
      else if (role == 'teacher') {

        try {

          final teacherDoc =
              await FirebaseFirestore.instance
                  .collection('teachers')
                  .doc(uid)
                  .get();

          if (teacherDoc.exists) {

            _currentUser =
                TeacherModel.fromMap(
              Map<String, dynamic>.from(
                teacherDoc.data()!,
              ),
            );

          } else {

            _currentUser =
                _fallbackUser(data);
          }

        } catch (_) {

          _currentUser =
              _fallbackUser(data);
        }

      }

      // ADMIN
      else {

        _currentUser =
            _fallbackUser(data);
      }

      debugPrint(
        '✅ Loaded: ${_currentUser?.fullName}',
      );

    } catch (e) {

      debugPrint(
        '💥 Load error: $e',
      );

      _currentUser = null;
    }
  }

  // ───────────────── FALLBACK USER ─────────────────

  UserModel _fallbackUser(
    Map<String, dynamic> data,
  ) {

    try {

      final role =
          data['role']?.toString() ?? 'admin';

      if (role == 'student') {

        return StudentModel.fromMap(data);
      }

      if (role == 'teacher') {

        return TeacherModel.fromMap(data);
      }

    } catch (_) {}

    return UserModel(
      uid: data['uid']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      fullName:
          data['fullName']?.toString() ?? 'User',
      phone: data['phone']?.toString() ?? '',
      role: _toRole(
        data['role']?.toString(),
      ),
      approvalStatus: _toApproval(
        data['approvalStatus']?.toString(),
      ),
      createdAt: DateTime.now(),
      isActive: true,
    );
  }

  // ───────────────── ROLE ─────────────────

  UserRole _toRole(String? role) {

    if (role == 'admin') {
      return UserRole.admin;
    }

    if (role == 'teacher') {
      return UserRole.teacher;
    }

    return UserRole.student;
  }

  // ───────────────── APPROVAL ─────────────────

  ApprovalStatus _toApproval(
    String? status,
  ) {

    if (status == 'approved') {
      return ApprovalStatus.approved;
    }

    if (status == 'rejected') {
      return ApprovalStatus.rejected;
    }

    return ApprovalStatus.pending;
  }

  // ───────────────── LOGIN ─────────────────

  Future<AuthResult> login(
    String email,
    String password,
  ) async {

    try {

      print('🔑 Login: $email');

      final result =
          await _authService.login(
        email,
        password,
      );

      print(
        '🔑 Result: ${result.success}',
      );

      // LOGIN FAILED
      if (!result.success) {

        _error = result.error;

        _notify();

        return result;
      }

      // UPDATE USER
      if (result.user != null) {

        _currentUser = result.user;

        print(
          '✅ User assigned to provider',
        );

        _notify();
      }

      return result;

    } catch (e) {

      print(
        '💥 LOGIN ERROR: $e',
      );

      _error = e.toString();

      _notify();

      return AuthResult(
        success: false,
        error: 'Login failed',
      );
    }
  }

  // ───────────────── LOAD CURRENT USER ─────────────────

  Future<void> loadCurrentUser() async {

    final uid =
        FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    _isLoading = true;

    _notify();

    await _loadUser(uid);

    _isLoading = false;

    _notify();
  }

  // ───────────────── REGISTER STUDENT ─────────────────

  Future<AuthResult> registerStudent({

    required String email,
    required String password,
    required String fullName,
    required String fatherName,
    required String motherName,
    required String gender,
    required DateTime dateOfBirth,
    required String phone,
    required String address,
    required String className,
    required String rollNumber,
    required String aadharNumber,

    dynamic photoFile,

    String? studentId,

  }) async {

    _isLoading = true;

    _error = null;

    _notify();

    try {

      final result =
          await _authService.registerStudent(

        email: email,
        password: password,
        fullName: fullName,
        fatherName: fatherName,
        motherName: motherName,
        gender: gender,
        dateOfBirth: dateOfBirth,
        phone: phone,
        address: address,
        className: className,
        rollNumber: rollNumber,
        aadharNumber: aadharNumber,
        photoFile: photoFile,
        studentId: studentId,
      );

      if (!result.success) {

        _error = result.error;
      }

      _isLoading = false;

      _notify();

      return result;

    } catch (e) {

      _error = e.toString();

      _isLoading = false;

      _notify();

      return AuthResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // ───────────────── REGISTER TEACHER ─────────────────

  Future<AuthResult> registerTeacher({

    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String address,
    required String qualification,
    required String subject,
    required String employeeId,

    dynamic photoFile,

  }) async {

    _isLoading = true;

    _error = null;

    _notify();

    try {

      final result =
          await _authService.registerTeacher(

        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        address: address,
        qualification: qualification,
        subject: subject,
        employeeId: employeeId,
        photoFile: photoFile,
      );

      if (!result.success) {

        _error = result.error;
      }

      _isLoading = false;

      _notify();

      return result;

    } catch (e) {

      _error = e.toString();

      _isLoading = false;

      _notify();

      return AuthResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // ───────────────── SIGN OUT ─────────────────

  Future<void> signOut() async {

    await _authService.signOut();

    _currentUser = null;

    _error = null;

    _isLoading = false;

    _notify();
  }

  // ───────────────── APPROVE ─────────────────

  Future<bool> approveUser(
    String uid,
    UserRole role,
  ) async {

    if (_currentUser == null) {
      return false;
    }

    return _authService.approveUser(
      uid,
      _currentUser!.uid,
      role,
    );
  }

  // ───────────────── REJECT ─────────────────

  Future<bool> rejectUser(
    String uid,
    UserRole role,
  ) async {

    return _authService.rejectUser(
      uid,
      role,
    );
  }

  // ───────────────── UPDATE ─────────────────

  void updateUser(UserModel user) {

    _currentUser = user;

    _notify();
  }

  void clearError() {

    _error = null;

    _notify();
  }

  AuthService get authService => _authService;

  // ───────────────── NOTIFY ─────────────────

  void _notify() {

    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {

    _disposed = true;

    super.dispose();
  }
}