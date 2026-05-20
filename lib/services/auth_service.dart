import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/user_model.dart';

class AuthResult {
  final bool success;
  final String? error;
  final UserModel? user;
  AuthResult({required this.success, this.error, this.user});
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _users => _db.collection('users');
  CollectionReference get _students => _db.collection('students');
  CollectionReference get _teachers => _db.collection('teachers');

  // ── LOGIN ──────────────────────────────────────────────────────────────────
  Future<AuthResult> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final uid = credential.user?.uid;
      if (uid == null) {
        return AuthResult(success: false, error: 'Login failed. Please try again.');
      }
      final userModel = await _getUserModel(uid);
      if (userModel == null) {
        await _auth.signOut();
        return AuthResult(success: false, error: 'Account not found. Please register first.');
      }
      if (!userModel.isActive) {
        await _auth.signOut();
        return AuthResult(success: false, error: 'Your account has been deactivated.');
      }
      return AuthResult(success: true, user: userModel);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _authError(e.code));
    } catch (e) {
      return AuthResult(success: false, error: 'An error occurred. Please try again.');
    }
  }

  // ── GET CURRENT USER ───────────────────────────────────────────────────────
  Future<UserModel?> getCurrentUserModel() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;
      return await _getUserModel(uid);
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> _getUserModel(String uid) async {

  try {

    print('📖 Fetching user model for UID: $uid');

    // USERS COLLECTION
    final userDoc = await _users
        .doc(uid)
        .get();

    // USER DOCUMENT MISSING
    if (!userDoc.exists) {

      print('❌ users/$uid document does not exist');

      return null;
    }

    final data =
        userDoc.data() as Map<String, dynamic>;

    final role =
        (data['role'] ?? 'student').toString();

    print('👤 User role: $role');

    // =========================
    // STUDENT
    // =========================
    if (role == 'student') {

      final studentDoc = await _students
          .doc(uid)
          .get();

      // STUDENT DOC EXISTS
      if (studentDoc.exists) {

        print('✅ Student document found');

        return StudentModel.fromMap(
          studentDoc.data()
              as Map<String, dynamic>,
        );
      }

      // FALLBACK TO USERS DATA
      print(
        '⚠️ students/$uid missing — using users fallback',
      );

      return StudentModel.fromMap(data);
    }

    // =========================
    // TEACHER
    // =========================
    if (role == 'teacher') {

      final teacherDoc = await _teachers
          .doc(uid)
          .get();

      // TEACHER DOC EXISTS
      if (teacherDoc.exists) {

        print('✅ Teacher document found');

        return TeacherModel.fromMap(
          teacherDoc.data()
              as Map<String, dynamic>,
        );
      }

      // FALLBACK TO USERS DATA
      print(
        '⚠️ teachers/$uid missing — using users fallback',
      );

      return TeacherModel.fromMap(data);
    }

    // =========================
    // ADMIN
    // =========================
    print('✅ Admin user loaded');

    return UserModel.fromMap(data);

  } catch (e, stack) {

    print('💥 _getUserModel ERROR: $e');

    print(stack.toString());

    return null;
  }
}

  // ── REGISTER STUDENT ───────────────────────────────────────────────────────
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
    File? photoFile,
    String? studentId,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final uid = credential.user!.uid;

      String? photoUrl;
      if (photoFile != null) {
        photoUrl = await _uploadPhoto(uid, photoFile, 'student');
      }

      final student = StudentModel(
        uid: uid,
        email: email.trim(),
        fullName: fullName.trim(),
        phone: phone.trim(),
        approvalStatus: ApprovalStatus.pending,
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
        isActive: true,
        fatherName: fatherName.trim(),
        motherName: motherName.trim(),
        gender: gender,
        dateOfBirth: dateOfBirth,
        address: address.trim(),
        className: className,
        rollNumber: rollNumber.trim(),
        aadharNumber: aadharNumber.trim(),
        attendancePercentage: 0.0,
      );

      final batch = _db.batch();
      final studentData = {
        ...student.toMap(),
        if (studentId != null) 'studentId': studentId,
      };
      batch.set(_users.doc(uid), studentData);
      batch.set(_students.doc(uid), studentData);
      await batch.commit();

      await _auth.signOut();
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _authError(e.code));
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  // ── REGISTER TEACHER ───────────────────────────────────────────────────────
  Future<AuthResult> registerTeacher({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String address,
    required String qualification,
    required String subject,
    required String employeeId,
    File? photoFile,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final uid = credential.user!.uid;

      String? photoUrl;
      if (photoFile != null) {
        photoUrl = await _uploadPhoto(uid, photoFile, 'teacher');
      }

      final teacher = TeacherModel(
        uid: uid,
        email: email.trim(),
        fullName: fullName.trim(),
        phone: phone.trim(),
        approvalStatus: ApprovalStatus.pending,
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
        isActive: true,
        employeeId: employeeId.trim(),
        qualification: qualification.trim(),
        subject: subject,
        address: address.trim(),
        joiningDate: DateTime.now(),
      );

      final batch = _db.batch();
      batch.set(_users.doc(uid), teacher.toMap());
      batch.set(_teachers.doc(uid), teacher.toMap());
      await batch.commit();

      await _auth.signOut();
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _authError(e.code));
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  // ── APPROVE / REJECT ───────────────────────────────────────────────────────
  Future<bool> approveUser(String uid, String approvedBy, UserRole role) async {
    try {
      final update = {
        'approvalStatus': 'approved',
        'approvedBy': approvedBy,
        'approvedAt': FieldValue.serverTimestamp(),
      };
      final batch = _db.batch();
      batch.update(_users.doc(uid), update);
      if (role == UserRole.student) batch.update(_students.doc(uid), update);
      if (role == UserRole.teacher) batch.update(_teachers.doc(uid), update);
      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectUser(String uid, UserRole role) async {
    try {
      final update = {'approvalStatus': 'rejected'};
      final batch = _db.batch();
      batch.update(_users.doc(uid), update);
      if (role == UserRole.student) batch.update(_students.doc(uid), update);
      if (role == UserRole.teacher) batch.update(_teachers.doc(uid), update);
      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── PENDING USERS — STREAM (for StreamBuilder) ─────────────────────────────
  Stream<List<StudentModel>> getPendingStudents() {
    return _students
        .where('approvalStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => StudentModel.fromMap(d.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<TeacherModel>> getPendingTeachers() {
    return _teachers
        .where('approvalStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => TeacherModel.fromMap(d.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // ── ALL APPROVED — STREAM (for StreamBuilder) ──────────────────────────────
  Stream<List<StudentModel>> getAllApprovedStudents() {
    return _students
        .where('approvalStatus', isEqualTo: 'approved')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => StudentModel.fromMap(d.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => a.fullName.compareTo(b.fullName));
      return list;
    });
  }

  Stream<List<TeacherModel>> getAllApprovedTeachers() {
    return _teachers
        .where('approvalStatus', isEqualTo: 'approved')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => TeacherModel.fromMap(d.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) => a.fullName.compareTo(b.fullName));
      return list;
    });
  }

  // ── STUDENTS BY CLASS — STREAM (for StreamBuilder + listen) ───────────────
  Stream<List<StudentModel>> getStudentsByClass(String className) {
    return _students
        .where('className', isEqualTo: className)
        .where('approvalStatus', isEqualTo: 'approved')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => StudentModel.fromMap(d.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) {
        final aRoll = int.tryParse(a.rollNumber) ?? 0;
        final bRoll = int.tryParse(b.rollNumber) ?? 0;
        return aRoll.compareTo(bRoll);
      });
      return list;
    });
  }

  // ── SEARCH STUDENTS ────────────────────────────────────────────────────────
  Future<List<StudentModel>> searchStudents(String query) async {
    try {
      final snap = await _students
          .where('approvalStatus', isEqualTo: 'approved')
          .get();
      final q = query.toLowerCase();
      return snap.docs
          .map((d) => StudentModel.fromMap(d.data() as Map<String, dynamic>))
          .where((s) =>
              s.fullName.toLowerCase().contains(q) ||
              s.rollNumber.toLowerCase().contains(q) ||
              s.phone.contains(q) ||
              s.className.toLowerCase().contains(q))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ── PASSWORD ───────────────────────────────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── SIGN OUT ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── PHOTO UPLOAD ───────────────────────────────────────────────────────────
  Future<String?> _uploadPhoto(String uid, File file, String role) async {
    try {
      final ref = _storage.ref().child('profile_photos/$role/$uid.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // ── NOTICES — STREAM ───────────────────────────────────────────────────────
  Stream<List<NoticeModel>> getNotices({String? targetAudience}) {
    return _db.collection('notices').snapshots().map((snap) {
      final list = snap.docs
          .map((d) => NoticeModel.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    });
  }

  Future<bool> postNotice({
    required String title,
    required String content,
    required String postedBy,
    required String postedByName,
    String targetAudience = 'all',
    bool isPinned = false,
    String? className,
  }) async {
    try {
      await _db.collection('notices').add({
        'title': title,
        'content': content,
        'postedBy': postedBy,
        'postedByName': postedByName,
        'createdAt': FieldValue.serverTimestamp(),
        'targetAudience': targetAudience,
        'isPinned': isPinned,
        'className': className,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNotice(String noticeId) async {
    try {
      await _db.collection('notices').doc(noticeId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── ERROR MESSAGES ─────────────────────────────────────────────────────────
  String _authError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check and try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Login failed. Please check your credentials and try again.';
    }
  }
}