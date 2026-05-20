// lib/services/attendance_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _attendance => _db.collection('attendance');

  Future<bool> markAttendance({
    required String className,
    required Map<String, bool> studentAttendance,
    required Map<String, String> studentNames,
    required String teacherId,
    String teacherName = '',
    required DateTime date,
  }) async {
    try {
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final batch = _db.batch();
      for (final entry in studentAttendance.entries) {
        final docId = '${entry.key}_$dateKey';
        batch.set(_attendance.doc(docId), {
          'id': docId,
          'studentId': entry.key,
          'studentName': studentNames[entry.key] ?? '',
          'className': className,
          'date': Timestamp.fromDate(date),
          'isPresent': entry.value,
          'markedBy': teacherId,
          'markedByName': teacherName,
          'markedAt': Timestamp.now(),
        });
      }
      await batch.commit();
      _updateAttendancePercentages(studentAttendance.keys.toList(), className);
      return true;
    } catch (e) {
      return false;
    }
  }

  void _updateAttendancePercentages(List<String> studentIds, String className) async {
    for (final sid in studentIds) {
      try {
        final snap = await _attendance.where('studentId', isEqualTo: sid).get();
        final total = snap.docs.length;
        final present = snap.docs.where((d) => (d.data() as Map)['isPresent'] == true).length;
        final pct = total > 0 ? (present / total) * 100 : 0.0;
        await _db.collection('students').doc(sid).update({'attendancePercentage': pct});
        await _db.collection('users').doc(sid).update({'attendancePercentage': pct});
      } catch (_) {}
    }
  }

  Future<List<AttendanceRecord>> getStudentAttendance({
    required String studentId,
    required String className,
  }) async {
    try {
      final snap = await _attendance.where('studentId', isEqualTo: studentId).get();
      final records = snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return AttendanceRecord(
          id: d.id,
          studentId: data['studentId'] ?? '',
          studentName: data['studentName'] ?? '',
          className: data['className'] ?? '',
          date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isPresent: data['isPresent'] ?? false,
          markedBy: data['markedBy'] ?? '',
          markedByName: data['markedByName'] ?? '',
          markedAt: (data['markedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
      records.sort((a, b) => b.date.compareTo(a.date));
      return records;
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, bool>> getClassAttendanceForDate(String className, DateTime date) async {
    try {
      final snap = await _attendance
          .where('className', isEqualTo: className)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(date.year, date.month, date.day)))
          .where('date', isLessThan: Timestamp.fromDate(DateTime(date.year, date.month, date.day + 1)))
          .get();
      final result = <String, bool>{};
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        result[data['studentId'] as String] = data['isPresent'] as bool? ?? false;
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<bool> isAttendanceTaken(String className, DateTime date) async {
    try {
      final snap = await _attendance
          .where('className', isEqualTo: className)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(date.year, date.month, date.day)))
          .where('date', isLessThan: Timestamp.fromDate(DateTime(date.year, date.month, date.day + 1)))
          .get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

class NoticeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _notices => _db.collection('notices');

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
      await _notices.add({
        'title': title.trim(),
        'content': content.trim(),
        'postedBy': postedBy,
        'postedByName': postedByName,
        'postedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'targetAudience': targetAudience,
        'isPinned': isPinned,
        'className': className,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Stream<List<NoticeModel>> getNotices({String? audience}) {
    return _notices.snapshots().map((s) {
      final notices = s.docs
          .map((d) => NoticeModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .where((n) => audience == null || n.targetAudience == 'all' || n.targetAudience == audience)
          .toList();
      notices.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.postedAt.compareTo(a.postedAt);
      });
      return notices;
    });
  }

  Future<bool> deleteNotice(String id) async {
    try { await _notices.doc(id).delete(); return true; } catch (_) { return false; }
  }

  Future<bool> togglePin(String id, bool isPinned) async {
    try { await _notices.doc(id).update({'isPinned': isPinned}); return true; } catch (_) { return false; }
  }
}