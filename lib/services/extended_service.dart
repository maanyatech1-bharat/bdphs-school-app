// lib/services/extended_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// ─── FEE MODELS ───────────────────────────────────────────────────────────────
class FeeStructure {
  final String id, className, feeType;
  final double amount;
  final String academicYear;

  FeeStructure({required this.id, required this.className, required this.feeType,
    required this.amount, required this.academicYear});

  factory FeeStructure.fromMap(Map<String, dynamic> m, String id) => FeeStructure(
    id: id, className: m['className'] ?? '', feeType: m['feeType'] ?? '',
    amount: (m['amount'] as num?)?.toDouble() ?? 0,
    academicYear: m['academicYear'] ?? '2024-25');

  Map<String, dynamic> toMap() => {'className': className, 'feeType': feeType,
    'amount': amount, 'academicYear': academicYear};
}

class FeeRecord {
  final String id, studentId, studentName, className, feeType, status, collectedBy, receiptNo;
  final double amount, paid, balance;
  final DateTime dueDate, createdAt;
  final DateTime? paidAt;

  FeeRecord({required this.id, required this.studentId, required this.studentName,
    required this.className, required this.feeType, required this.status,
    required this.amount, required this.paid, required this.balance,
    required this.dueDate, required this.createdAt, required this.collectedBy,
    required this.receiptNo, this.paidAt});

  factory FeeRecord.fromMap(Map<String, dynamic> m, String id) => FeeRecord(
    id: id, studentId: m['studentId'] ?? '', studentName: m['studentName'] ?? '',
    className: m['className'] ?? '', feeType: m['feeType'] ?? 'Monthly',
    status: m['status'] ?? 'pending', amount: (m['amount'] as num?)?.toDouble() ?? 0,
    paid: (m['paid'] as num?)?.toDouble() ?? 0,
    balance: (m['balance'] as num?)?.toDouble() ?? 0,
    dueDate: (m['dueDate'] as dynamic)?.toDate() ?? DateTime.now(),
    createdAt: (m['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    paidAt: (m['paidAt'] as dynamic)?.toDate(),
    collectedBy: m['collectedBy'] ?? '', receiptNo: m['receiptNo'] ?? '');

  Map<String, dynamic> toMap() => {
    'studentId': studentId, 'studentName': studentName, 'className': className,
    'feeType': feeType, 'status': status, 'amount': amount, 'paid': paid,
    'balance': balance, 'dueDate': dueDate, 'createdAt': createdAt,
    'paidAt': paidAt, 'collectedBy': collectedBy, 'receiptNo': receiptNo};
}

// ─── TIMETABLE MODELS ─────────────────────────────────────────────────────────
class TimetableEntry {
  final String id, className, day, period, subject, teacherName, room;
  final String startTime, endTime;

  TimetableEntry({required this.id, required this.className, required this.day,
    required this.period, required this.subject, required this.teacherName,
    required this.room, required this.startTime, required this.endTime});

  factory TimetableEntry.fromMap(Map<String, dynamic> m, String id) => TimetableEntry(
    id: id, className: m['className'] ?? '', day: m['day'] ?? '',
    period: m['period'] ?? '', subject: m['subject'] ?? '',
    teacherName: m['teacherName'] ?? '', room: m['room'] ?? '',
    startTime: m['startTime'] ?? '', endTime: m['endTime'] ?? '');

  Map<String, dynamic> toMap() => {'className': className, 'day': day,
    'period': period, 'subject': subject, 'teacherName': teacherName,
    'room': room, 'startTime': startTime, 'endTime': endTime};
}

// ─── EXAM SCHEDULE ────────────────────────────────────────────────────────────
class ExamSchedule {
  final String id, className, examType, subject;
  final DateTime examDate;
  final String startTime, endTime, venue, addedBy;
  final DateTime createdAt;

  ExamSchedule({required this.id, required this.className, required this.examType,
    required this.subject, required this.examDate, required this.startTime,
    required this.endTime, required this.venue, required this.addedBy,
    required this.createdAt});

  factory ExamSchedule.fromMap(Map<String, dynamic> m, String id) => ExamSchedule(
    id: id, className: m['className'] ?? '', examType: m['examType'] ?? '',
    subject: m['subject'] ?? '',
    examDate: (m['examDate'] as dynamic)?.toDate() ?? DateTime.now(),
    startTime: m['startTime'] ?? '', endTime: m['endTime'] ?? '',
    venue: m['venue'] ?? '', addedBy: m['addedBy'] ?? '',
    createdAt: (m['createdAt'] as dynamic)?.toDate() ?? DateTime.now());

  Map<String, dynamic> toMap() => {'className': className, 'examType': examType,
    'subject': subject, 'examDate': examDate, 'startTime': startTime,
    'endTime': endTime, 'venue': venue, 'addedBy': addedBy, 'createdAt': createdAt};
}

// ─── SCHOOL CALENDAR EVENT ────────────────────────────────────────────────────
class CalendarEvent {
  final String id, title, description, eventType, addedBy;
  // eventType: holiday, ptm, exam, sports, cultural, other
  final DateTime eventDate;
  final DateTime? endDate;
  final DateTime createdAt;

  CalendarEvent({required this.id, required this.title, required this.description,
    required this.eventType, required this.addedBy, required this.eventDate,
    this.endDate, required this.createdAt});

  factory CalendarEvent.fromMap(Map<String, dynamic> m, String id) => CalendarEvent(
    id: id, title: m['title'] ?? '', description: m['description'] ?? '',
    eventType: m['eventType'] ?? 'other', addedBy: m['addedBy'] ?? '',
    eventDate: (m['eventDate'] as dynamic)?.toDate() ?? DateTime.now(),
    endDate: (m['endDate'] as dynamic)?.toDate(),
    createdAt: (m['createdAt'] as dynamic)?.toDate() ?? DateTime.now());

  Map<String, dynamic> toMap() => {'title': title, 'description': description,
    'eventType': eventType, 'addedBy': addedBy, 'eventDate': eventDate,
    'endDate': endDate, 'createdAt': createdAt};
}

// ─── EMERGENCY CONTACT ────────────────────────────────────────────────────────
class EmergencyContact {
  final String id, name, designation, phone, alternatePhone;
  final int priority;
  final bool isActive;

  EmergencyContact({required this.id, required this.name, required this.designation,
    required this.phone, this.alternatePhone = '', required this.priority,
    this.isActive = true});

  factory EmergencyContact.fromMap(Map<String, dynamic> m, String id) => EmergencyContact(
    id: id, name: m['name'] ?? '', designation: m['designation'] ?? '',
    phone: m['phone'] ?? '', alternatePhone: m['alternatePhone'] ?? '',
    priority: m['priority'] ?? 99, isActive: m['isActive'] ?? true);

  Map<String, dynamic> toMap() => {'name': name, 'designation': designation,
    'phone': phone, 'alternatePhone': alternatePhone,
    'priority': priority, 'isActive': isActive};
}

// ─── SYLLABUS ─────────────────────────────────────────────────────────────────
class SyllabusItem {
  final String id, className, subject, chapter, topic, status, teacherId, teacherName;
  // status: pending, in_progress, completed
  final int? chapterNo;
  final DateTime? completedAt, createdAt;

  SyllabusItem({required this.id, required this.className, required this.subject,
    required this.chapter, required this.topic, required this.status,
    required this.teacherId, required this.teacherName,
    this.chapterNo, this.completedAt, this.createdAt});

  factory SyllabusItem.fromMap(Map<String, dynamic> m, String id) => SyllabusItem(
    id: id, className: m['className'] ?? '', subject: m['subject'] ?? '',
    chapter: m['chapter'] ?? '', topic: m['topic'] ?? '',
    status: m['status'] ?? 'pending', teacherId: m['teacherId'] ?? '',
    teacherName: m['teacherName'] ?? '', chapterNo: m['chapterNo'],
    completedAt: (m['completedAt'] as dynamic)?.toDate(),
    createdAt: (m['createdAt'] as dynamic)?.toDate() ?? DateTime.now());

  Map<String, dynamic> toMap() => {'className': className, 'subject': subject,
    'chapter': chapter, 'topic': topic, 'status': status,
    'teacherId': teacherId, 'teacherName': teacherName,
    'chapterNo': chapterNo, 'completedAt': completedAt, 'createdAt': createdAt};
}

// ─── COMPLAINT ────────────────────────────────────────────────────────────────
class ComplaintModel {
  final String id, category, description, status;
  final bool isAnonymous;
  final String? submittedBy, submittedByName, response;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  ComplaintModel({required this.id, required this.category, required this.description,
    required this.status, required this.isAnonymous, this.submittedBy,
    this.submittedByName, this.response, required this.createdAt, this.resolvedAt});

  factory ComplaintModel.fromMap(Map<String, dynamic> m, String id) => ComplaintModel(
    id: id, category: m['category'] ?? '', description: m['description'] ?? '',
    status: m['status'] ?? 'open', isAnonymous: m['isAnonymous'] ?? true,
    submittedBy: m['submittedBy'], submittedByName: m['submittedByName'],
    response: m['response'],
    createdAt: (m['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    resolvedAt: (m['resolvedAt'] as dynamic)?.toDate());

  Map<String, dynamic> toMap() => {'category': category, 'description': description,
    'status': status, 'isAnonymous': isAnonymous, 'submittedBy': submittedBy,
    'submittedByName': submittedByName, 'response': response,
    'createdAt': createdAt, 'resolvedAt': resolvedAt};
}

// ─── GALLERY PHOTO ────────────────────────────────────────────────────────────
class GalleryPhoto {
  final String id, title, description, imageUrl, albumName, addedBy, addedByName;
  final String? storagePath;
  final DateTime createdAt;

  GalleryPhoto({required this.id, required this.title, required this.description,
    required this.imageUrl, required this.albumName,
    required this.addedBy, required this.addedByName,
    this.storagePath, required this.createdAt});

  factory GalleryPhoto.fromMap(Map<String, dynamic> m, String id) => GalleryPhoto(
    id: id, title: m['title'] ?? '', description: m['description'] ?? '',
    imageUrl: m['imageUrl'] ?? '', albumName: m['albumName'] ?? '',
    addedBy: m['addedBy'] ?? '', addedByName: m['addedByName'] ?? '',
    storagePath: m['storagePath'],
    createdAt: (m['createdAt'] as dynamic)?.toDate() ?? DateTime.now());

  Map<String, dynamic> toMap() => {'title': title, 'description': description,
    'imageUrl': imageUrl, 'albumName': albumName, 'addedBy': addedBy,
    'addedByName': addedByName, 'storagePath': storagePath,
    'createdAt': createdAt};
}

// ─── LEAVE BALANCE ────────────────────────────────────────────────────────────
class LeaveBalance {
  final String userId;
  final String userType; // teacher, student
  final int casualTotal, casualUsed, medicalTotal, medicalUsed;
  final String academicYear;

  LeaveBalance({required this.userId, required this.userType,
    required this.casualTotal, required this.casualUsed,
    required this.medicalTotal, required this.medicalUsed,
    required this.academicYear});

  int get casualRemaining => casualTotal - casualUsed;
  int get medicalRemaining => medicalTotal - medicalUsed;

  factory LeaveBalance.fromMap(Map<String, dynamic> m) => LeaveBalance(
    userId: m['userId'] ?? '', userType: m['userType'] ?? 'student',
    casualTotal: m['casualTotal'] ?? 15, casualUsed: m['casualUsed'] ?? 0,
    medicalTotal: m['medicalTotal'] ?? 30, medicalUsed: m['medicalUsed'] ?? 0,
    academicYear: m['academicYear'] ?? '2024-25');

  Map<String, dynamic> toMap() => {'userId': userId, 'userType': userType,
    'casualTotal': casualTotal, 'casualUsed': casualUsed,
    'medicalTotal': medicalTotal, 'medicalUsed': medicalUsed,
    'academicYear': academicYear};
}

class LeaveApplication {
  final String id, applicantId, applicantName, applicantType, leaveType, reason, status;
  final String? className, reviewedBy, reviewedByName, reviewerRemarks;
  final DateTime fromDate, toDate, appliedAt;
  final DateTime? reviewedAt;
  final List<String> attachmentUrls;

  LeaveApplication({required this.id, required this.applicantId,
    required this.applicantName, required this.applicantType,
    required this.leaveType, required this.reason, required this.status,
    this.className, this.reviewedBy, this.reviewedByName, this.reviewerRemarks,
    required this.fromDate, required this.toDate, required this.appliedAt,
    this.reviewedAt, this.attachmentUrls = const []});

  int get days => toDate.difference(fromDate).inDays + 1;

  factory LeaveApplication.fromMap(Map<String, dynamic> m, String id) => LeaveApplication(
    id: id, applicantId: m['applicantId'] ?? '', applicantName: m['applicantName'] ?? '',
    applicantType: m['applicantType'] ?? 'student', leaveType: m['leaveType'] ?? 'casual',
    reason: m['reason'] ?? '', status: m['status'] ?? 'pending',
    className: m['className'], reviewedBy: m['reviewedBy'],
    reviewedByName: m['reviewedByName'], reviewerRemarks: m['reviewerRemarks'],
    fromDate: (m['fromDate'] as dynamic)?.toDate() ?? DateTime.now(),
    toDate: (m['toDate'] as dynamic)?.toDate() ?? DateTime.now(),
    appliedAt: (m['appliedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    reviewedAt: (m['reviewedAt'] as dynamic)?.toDate(),
    attachmentUrls: List<String>.from(m['attachmentUrls'] ?? []));

  Map<String, dynamic> toMap() => {'applicantId': applicantId, 'applicantName': applicantName,
    'applicantType': applicantType, 'leaveType': leaveType, 'reason': reason,
    'status': status, 'className': className, 'reviewedBy': reviewedBy,
    'reviewedByName': reviewedByName, 'reviewerRemarks': reviewerRemarks,
    'fromDate': fromDate, 'toDate': toDate, 'appliedAt': appliedAt,
    'reviewedAt': reviewedAt, 'attachmentUrls': attachmentUrls};
}

// ─── PARENT PORTAL ────────────────────────────────────────────────────────────
class ParentAccount {
  final String id, parentName, phone, email, studentId, studentName, relation;
  final bool isActive;
  final DateTime createdAt;

  ParentAccount({required this.id, required this.parentName, required this.phone,
    required this.email, required this.studentId, required this.studentName,
    required this.relation, this.isActive = true, required this.createdAt});

  factory ParentAccount.fromMap(Map<String, dynamic> m, String id) => ParentAccount(
    id: id, parentName: m['parentName'] ?? '', phone: m['phone'] ?? '',
    email: m['email'] ?? '', studentId: m['studentId'] ?? '',
    studentName: m['studentName'] ?? '', relation: m['relation'] ?? 'Father',
    isActive: m['isActive'] ?? true,
    createdAt: (m['createdAt'] as dynamic)?.toDate() ?? DateTime.now());

  Map<String, dynamic> toMap() => {'parentName': parentName, 'phone': phone,
    'email': email, 'studentId': studentId, 'studentName': studentName,
    'relation': relation, 'isActive': isActive, 'createdAt': createdAt};
}

// ═════════════════════════════════════════════════════════════════════════════
//  EXTENDED SERVICE
// ═════════════════════════════════════════════════════════════════════════════
class ExtendedService {
  final _db = FirebaseFirestore.instance;

  CollectionReference get _fees => _db.collection('fees');
  CollectionReference get _feeStructure => _db.collection('fee_structure');
  CollectionReference get _timetable => _db.collection('timetable');
  CollectionReference get _examSchedule => _db.collection('exam_schedule');
  CollectionReference get _calendarEvents => _db.collection('calendar_events');
  CollectionReference get _emergencyContacts => _db.collection('emergency_contacts');
  CollectionReference get _syllabus => _db.collection('syllabus');
  CollectionReference get _complaints => _db.collection('complaints');
  CollectionReference get _gallery => _db.collection('gallery');
  CollectionReference get _leaveBalances => _db.collection('leave_balances');
  CollectionReference get _leaveApplications => _db.collection('leave_applications');
  CollectionReference get _parents => _db.collection('parents');

  // ── FEES ──────────────────────────────────────────────────────────────────
  Future<bool> addFeeRecord(FeeRecord r) async {
    try { await _fees.add(r.toMap()); return true; } catch (_) { return false; }
  }
  Future<bool> markFeePaid(String id, double paid, String by) async {
    try {
      final doc = await _fees.doc(id).get();
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['amount'] as num).toDouble();
      await _fees.doc(id).update({'paid': paid, 'balance': amount - paid,
        'status': paid >= amount ? 'paid' : 'partial',
        'paidAt': DateTime.now(), 'collectedBy': by});
      return true;
    } catch (_) { return false; }
  }
  Stream<List<FeeRecord>> getStudentFees(String studentId) =>
    _fees.where('studentId', isEqualTo: studentId).snapshots()
      .map((s) => s.docs.map((d) => FeeRecord.fromMap(d.data() as Map<String,dynamic>, d.id)).toList()
        ..sort((a,b) => b.createdAt.compareTo(a.createdAt)));
  Stream<List<FeeRecord>> getClassFees(String className) =>
    _fees.where('className', isEqualTo: className).snapshots()
      .map((s) => s.docs.map((d) => FeeRecord.fromMap(d.data() as Map<String,dynamic>, d.id)).toList());
  Stream<List<FeeRecord>> getPendingFees() =>
    _fees.where('status', isEqualTo: 'pending').snapshots()
      .map((s) => s.docs.map((d) => FeeRecord.fromMap(d.data() as Map<String,dynamic>, d.id)).toList());

  // ── TIMETABLE ─────────────────────────────────────────────────────────────
  Future<bool> saveTimetableEntry(TimetableEntry e) async {
    try { await _timetable.add(e.toMap()); return true; } catch (_) { return false; }
  }
  Future<bool> deleteTimetableEntry(String id) async {
    try { await _timetable.doc(id).delete(); return true; } catch (_) { return false; }
  }
  Stream<List<TimetableEntry>> getClassTimetable(String className) =>
    _timetable.where('className', isEqualTo: className).snapshots()
      .map((s) => s.docs.map((d) => TimetableEntry.fromMap(d.data() as Map<String,dynamic>, d.id)).toList());

  // ── EXAM SCHEDULE ─────────────────────────────────────────────────────────
  Future<bool> addExamSchedule(ExamSchedule e) async {
    try { await _examSchedule.add(e.toMap()); return true; } catch (_) { return false; }
  }
  Future<bool> deleteExamSchedule(String id) async {
    try { await _examSchedule.doc(id).delete(); return true; } catch (_) { return false; }
  }
  Stream<List<ExamSchedule>> getClassExamSchedule(String className) =>
    _examSchedule.where('className', isEqualTo: className).snapshots()
      .map((s) => s.docs.map((d) => ExamSchedule.fromMap(d.data() as Map<String,dynamic>, d.id)).toList()
        ..sort((a,b) => a.examDate.compareTo(b.examDate)));
  Stream<List<ExamSchedule>> getAllUpcomingExams() =>
    _examSchedule.snapshots().map((s) => s.docs
      .map((d) => ExamSchedule.fromMap(d.data() as Map<String,dynamic>, d.id))
      .where((e) => e.examDate.isAfter(DateTime.now().subtract(const Duration(days: 1)))).toList()
      ..sort((a,b) => a.examDate.compareTo(b.examDate)));

  // ── CALENDAR ──────────────────────────────────────────────────────────────
  Future<bool> addCalendarEvent(CalendarEvent e) async {
    try { await _calendarEvents.add(e.toMap()); return true; } catch (_) { return false; }
  }
  Future<bool> deleteCalendarEvent(String id) async {
    try { await _calendarEvents.doc(id).delete(); return true; } catch (_) { return false; }
  }
  Stream<List<CalendarEvent>> getCalendarEvents() =>
    _calendarEvents.snapshots().map((s) => s.docs
      .map((d) => CalendarEvent.fromMap(d.data() as Map<String,dynamic>, d.id)).toList()
      ..sort((a,b) => a.eventDate.compareTo(b.eventDate)));

  // ── EMERGENCY CONTACTS ────────────────────────────────────────────────────
  Future<bool> addEmergencyContact(EmergencyContact c) async {
    try { await _emergencyContacts.add(c.toMap()); return true; } catch (_) { return false; }
  }
  Future<bool> deleteEmergencyContact(String id) async {
    try { await _emergencyContacts.doc(id).delete(); return true; } catch (_) { return false; }
  }
  Stream<List<EmergencyContact>> getEmergencyContacts() =>
    _emergencyContacts.where('isActive', isEqualTo: true).snapshots()
      .map((s) => s.docs.map((d) => EmergencyContact.fromMap(d.data() as Map<String,dynamic>, d.id)).toList()
        ..sort((a,b) => a.priority.compareTo(b.priority)));

  // ── SYLLABUS ──────────────────────────────────────────────────────────────
  Future<bool> addSyllabusItem(SyllabusItem s) async {
    try { await _syllabus.add(s.toMap()); return true; } catch (_) { return false; }
  }
  Future<bool> updateSyllabusStatus(String id, String status) async {
    try {
      await _syllabus.doc(id).update({'status': status,
        'completedAt': status == 'completed' ? DateTime.now() : null});
      return true;
    } catch (_) { return false; }
  }
  Future<bool> deleteSyllabusItem(String id) async {
    try { await _syllabus.doc(id).delete(); return true; } catch (_) { return false; }
  }
  Stream<List<SyllabusItem>> getClassSyllabus(String className, String subject) =>
    _syllabus.where('className', isEqualTo: className).where('subject', isEqualTo: subject).snapshots()
      .map((s) => s.docs.map((d) => SyllabusItem.fromMap(d.data() as Map<String,dynamic>, d.id)).toList()
        ..sort((a,b) => (a.chapterNo ?? 99).compareTo(b.chapterNo ?? 99)));

  // ── COMPLAINTS ────────────────────────────────────────────────────────────
  Future<bool> submitComplaint(ComplaintModel c) async {
    try { await _complaints.add(c.toMap()); return true; } catch (_) { return false; }
  }
  Future<bool> resolveComplaint(String id, String response) async {
    try {
      await _complaints.doc(id).update({'status': 'resolved', 'response': response, 'resolvedAt': DateTime.now()});
      return true;
    } catch (_) { return false; }
  }
  Stream<List<ComplaintModel>> getAllComplaints() =>
    _complaints.snapshots().map((s) => s.docs
      .map((d) => ComplaintModel.fromMap(d.data() as Map<String,dynamic>, d.id)).toList()
      ..sort((a,b) => b.createdAt.compareTo(a.createdAt)));
  Stream<List<ComplaintModel>> getUserComplaints(String userId) =>
    _complaints.where('submittedBy', isEqualTo: userId).snapshots()
      .map((s) => s.docs.map((d) => ComplaintModel.fromMap(d.data() as Map<String,dynamic>, d.id)).toList()
        ..sort((a,b) => b.createdAt.compareTo(a.createdAt)));

  // ── GALLERY ───────────────────────────────────────────────────────────────
  Future<bool> addPhoto(GalleryPhoto p) async {
    try { await _gallery.add(p.toMap()); return true; } catch (_) { return false; }
  }
  Future<bool> deletePhoto(String id, {String? storagePath}) async {
    try {
      if (storagePath != null && storagePath.isNotEmpty) {
        try { await FirebaseStorage.instance.ref(storagePath).delete(); } catch (_) {}
      }
      await _gallery.doc(id).delete();
      return true;
    } catch (_) { return false; }
  }
  Stream<List<GalleryPhoto>> getGalleryByAlbum(String album) =>
    _gallery.where('albumName', isEqualTo: album).snapshots()
      .map((s) => s.docs.map((d) => GalleryPhoto.fromMap(d.data() as Map<String,dynamic>, d.id)).toList()
        ..sort((a,b) => b.createdAt.compareTo(a.createdAt)));
  Stream<List<String>> getAlbums() =>
    _gallery.snapshots().map((s) {
      final albums = s.docs.map((d) => (d.data() as Map<String,dynamic>)['albumName'] as String? ?? '').toSet().toList();
      albums.sort();
      return albums;
    });

  // ── LEAVE BALANCE ─────────────────────────────────────────────────────────
  Future<LeaveBalance> getLeaveBalance(String userId, String userType) async {
    final snap = await _leaveBalances.where('userId', isEqualTo: userId).where('userType', isEqualTo: userType).get();
    if (snap.docs.isNotEmpty) return LeaveBalance.fromMap(snap.docs.first.data() as Map<String,dynamic>);
    return LeaveBalance(userId: userId, userType: userType, casualTotal: 15, casualUsed: 0, medicalTotal: 30, medicalUsed: 0, academicYear: '2024-25');
  }

  Future<bool> applyLeave(LeaveApplication leave) async {
    try {
      await _leaveApplications.add(leave.toMap());
      return true;
    } catch (_) { return false; }
  }

  Future<bool> reviewLeaveApplication(String id, String status, String by, String byName, String remarks) async {
    try {
      await _leaveApplications.doc(id).update({'status': status, 'reviewedBy': by,
        'reviewedByName': byName, 'reviewerRemarks': remarks, 'reviewedAt': DateTime.now()});
      if (status == 'approved') {
        final doc = await _leaveApplications.doc(id).get();
        final data = doc.data() as Map<String,dynamic>;
        final applicantId = data['applicantId'] as String;
        final applicantType = data['applicantType'] as String;
        final leaveType = data['leaveType'] as String;
        final from = (data['fromDate'] as dynamic).toDate() as DateTime;
        final to = (data['toDate'] as dynamic).toDate() as DateTime;
        final days = to.difference(from).inDays + 1;
        final balSnap = await _leaveBalances.where('userId', isEqualTo: applicantId).where('userType', isEqualTo: applicantType).get();
        if (balSnap.docs.isNotEmpty) {
          final balDoc = balSnap.docs.first;
          final field = leaveType == 'casual' ? 'casualUsed' : 'medicalUsed';
          final current = (balDoc.data() as Map<String,dynamic>)[field] as int? ?? 0;
          await _leaveBalances.doc(balDoc.id).update({field: current + days});
        } else {
          final bal = LeaveBalance(userId: applicantId, userType: applicantType,
            casualTotal: 15, casualUsed: leaveType == 'casual' ? days : 0,
            medicalTotal: 30, medicalUsed: leaveType == 'medical' ? days : 0, academicYear: '2024-25');
          await _leaveBalances.add(bal.toMap());
        }
      }
      return true;
    } catch (_) { return false; }
  }

  Stream<List<LeaveApplication>> getUserLeaves(String userId) =>
    _leaveApplications.where('applicantId', isEqualTo: userId).snapshots()
      .map((s) => s.docs.map((d) => LeaveApplication.fromMap(d.data() as Map<String,dynamic>, d.id)).toList()
        ..sort((a,b) => b.appliedAt.compareTo(a.appliedAt)));
  Stream<List<LeaveApplication>> getPendingLeaveApplications() =>
    _leaveApplications.where('status', isEqualTo: 'pending').snapshots()
      .map((s) => s.docs.map((d) => LeaveApplication.fromMap(d.data() as Map<String,dynamic>, d.id)).toList()
        ..sort((a,b) => b.appliedAt.compareTo(a.appliedAt)));
  Stream<List<LeaveApplication>> getTeacherLeaves() =>
    _leaveApplications.where('applicantType', isEqualTo: 'teacher').snapshots()
      .map((s) => s.docs.map((d) => LeaveApplication.fromMap(d.data() as Map<String,dynamic>, d.id)).toList()
        ..sort((a,b) => b.appliedAt.compareTo(a.appliedAt)));

  // ── PARENT PORTAL ─────────────────────────────────────────────────────────
  Future<bool> addParent(ParentAccount p) async {
    try { await _parents.add(p.toMap()); return true; } catch (_) { return false; }
  }
  Future<ParentAccount?> getParentByPhone(String phone) async {
    final snap = await _parents.where('phone', isEqualTo: phone).get();
    if (snap.docs.isEmpty) return null;
    return ParentAccount.fromMap(snap.docs.first.data() as Map<String,dynamic>, snap.docs.first.id);
  }
  Stream<List<ParentAccount>> getStudentParents(String studentId) =>
    _parents.where('studentId', isEqualTo: studentId).snapshots()
      .map((s) => s.docs.map((d) => ParentAccount.fromMap(d.data() as Map<String,dynamic>, d.id)).toList());
}