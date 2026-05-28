// lib/services/school_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ResultModel {
  final String id, studentId, studentName, className, subject, examType, grade, month, enteredBy, enteredByName;
  final double maxMarks, obtainedMarks;
  final int year;
  final DateTime createdAt;

  ResultModel({required this.id, required this.studentId, required this.studentName,
    required this.className, required this.subject, required this.examType,
    required this.maxMarks, required this.obtainedMarks, required this.grade,
    required this.month, required this.year, required this.enteredBy,
    required this.enteredByName, required this.createdAt});

  factory ResultModel.fromMap(Map<String, dynamic> m, String id) => ResultModel(
    id: id, studentId: m['studentId'] ?? '', studentName: m['studentName'] ?? '',
    className: m['className'] ?? '', subject: m['subject'] ?? '',
    examType: m['examType'] ?? '', maxMarks: (m['maxMarks'] as num?)?.toDouble() ?? 0,
    obtainedMarks: (m['obtainedMarks'] as num?)?.toDouble() ?? 0,
    grade: m['grade'] ?? '', month: m['month'] ?? '', year: m['year'] ?? DateTime.now().year,
    enteredBy: m['enteredBy'] ?? '', enteredByName: m['enteredByName'] ?? '',
    createdAt: m['createdAt'] is Timestamp ? (m['createdAt'] as Timestamp).toDate() : DateTime.now());

  Map<String, dynamic> toMap() => {
    'studentId': studentId, 'studentName': studentName, 'className': className,
    'subject': subject, 'examType': examType, 'maxMarks': maxMarks,
    'obtainedMarks': obtainedMarks, 'grade': grade, 'month': month, 'year': year,
    'enteredBy': enteredBy, 'enteredByName': enteredByName, 'createdAt': createdAt};

  double get percentage => maxMarks > 0 ? (obtainedMarks / maxMarks) * 100 : 0;
}

class MonthlyAssessment {
  final String id, studentId, studentName, className, month, disciplineGrade,
      uniformGrade, punctualityGrade, remarks, assessedBy, assessedByName;
  final int year, daysPresent, totalDays;
  final DateTime createdAt;

  MonthlyAssessment({required this.id, required this.studentId, required this.studentName,
    required this.className, required this.month, required this.year,
    required this.daysPresent, required this.totalDays, required this.disciplineGrade,
    required this.uniformGrade, required this.punctualityGrade, required this.remarks,
    required this.assessedBy, required this.assessedByName, required this.createdAt});

  factory MonthlyAssessment.fromMap(Map<String, dynamic> m, String id) => MonthlyAssessment(
    id: id, studentId: m['studentId'] ?? '', studentName: m['studentName'] ?? '',
    className: m['className'] ?? '', month: m['month'] ?? '',
    year: m['year'] ?? DateTime.now().year, daysPresent: m['daysPresent'] ?? 0,
    totalDays: m['totalDays'] ?? 0, disciplineGrade: m['disciplineGrade'] ?? 'A',
    uniformGrade: m['uniformGrade'] ?? 'A', punctualityGrade: m['punctualityGrade'] ?? 'A',
    remarks: m['remarks'] ?? '', assessedBy: m['assessedBy'] ?? '',
    assessedByName: m['assessedByName'] ?? '',
    createdAt: m['createdAt'] is Timestamp ? (m['createdAt'] as Timestamp).toDate() : DateTime.now());

  Map<String, dynamic> toMap() => {
    'studentId': studentId, 'studentName': studentName, 'className': className,
    'month': month, 'year': year, 'daysPresent': daysPresent, 'totalDays': totalDays,
    'disciplineGrade': disciplineGrade, 'uniformGrade': uniformGrade,
    'punctualityGrade': punctualityGrade, 'remarks': remarks,
    'assessedBy': assessedBy, 'assessedByName': assessedByName, 'createdAt': createdAt};
}

class HomeworkModel {
  final String id, className, subject, title, description, postedBy, postedByName;
  final DateTime dueDate, createdAt;

  HomeworkModel({required this.id, required this.className, required this.subject,
    required this.title, required this.description, required this.dueDate,
    required this.postedBy, required this.postedByName, required this.createdAt});

  factory HomeworkModel.fromMap(Map<String, dynamic> m, String id) => HomeworkModel(
    id: id, className: m['className'] ?? '', subject: m['subject'] ?? '',
    title: m['title'] ?? '', description: m['description'] ?? '',
    dueDate: m['dueDate'] is Timestamp ? (m['dueDate'] as Timestamp).toDate() : DateTime.now(),
    postedBy: m['postedBy'] ?? '', postedByName: m['postedByName'] ?? '',
    createdAt: m['createdAt'] is Timestamp ? (m['createdAt'] as Timestamp).toDate() : DateTime.now());

  Map<String, dynamic> toMap() => {'className': className, 'subject': subject,
    'title': title, 'description': description, 'dueDate': dueDate,
    'postedBy': postedBy, 'postedByName': postedByName, 'createdAt': createdAt};
}

class LeaveModel {
  final String id, studentId, studentName, className, reason, status;
  final String? reviewedBy, reviewedByName;
  final DateTime fromDate, toDate, appliedAt;
  final DateTime? reviewedAt;

  LeaveModel({required this.id, required this.studentId, required this.studentName,
    required this.className, required this.reason, required this.fromDate,
    required this.toDate, required this.status, this.reviewedBy, this.reviewedByName,
    required this.appliedAt, this.reviewedAt});

  int get days => toDate.difference(fromDate).inDays + 1;

  factory LeaveModel.fromMap(Map<String, dynamic> m, String id) => LeaveModel(
    id: id, studentId: m['studentId'] ?? '', studentName: m['studentName'] ?? '',
    className: m['className'] ?? '', reason: m['reason'] ?? '',
    fromDate: m['fromDate'] is Timestamp ? (m['fromDate'] as Timestamp).toDate() : DateTime.now(),
    toDate: m['toDate'] is Timestamp ? (m['toDate'] as Timestamp).toDate() : DateTime.now(),
    status: m['status'] ?? 'pending', reviewedBy: m['reviewedBy'],
    reviewedByName: m['reviewedByName'],
    appliedAt: m['appliedAt'] is Timestamp ? (m['appliedAt'] as Timestamp).toDate() : DateTime.now(),
    reviewedAt: m['reviewedAt'] is Timestamp ? (m['reviewedAt'] as Timestamp).toDate() : null);

  Map<String, dynamic> toMap() => {'studentId': studentId, 'studentName': studentName,
    'className': className, 'reason': reason, 'fromDate': fromDate, 'toDate': toDate,
    'status': status, 'reviewedBy': reviewedBy, 'reviewedByName': reviewedByName,
    'appliedAt': appliedAt, 'reviewedAt': reviewedAt};
}

class BookModel {
  final String id, className, title, author, publisher, subject, addedBy, addedByName;
  final String? description;
  final DateTime createdAt;

  BookModel({required this.id, required this.className, required this.title,
    required this.author, required this.publisher, required this.subject,
    required this.addedBy, required this.addedByName, this.description,
    required this.createdAt});

  factory BookModel.fromMap(Map<String, dynamic> m, String id) => BookModel(
    id: id, className: m['className'] ?? '', title: m['title'] ?? '',
    author: m['author'] ?? '', publisher: m['publisher'] ?? '',
    subject: m['subject'] ?? '', addedBy: m['addedBy'] ?? '',
    addedByName: m['addedByName'] ?? '', description: m['description'],
    createdAt: m['createdAt'] is Timestamp ? (m['createdAt'] as Timestamp).toDate() : DateTime.now());

  Map<String, dynamic> toMap() => {'className': className, 'title': title,
    'author': author, 'publisher': publisher, 'subject': subject,
    'addedBy': addedBy, 'addedByName': addedByName,
    'description': description, 'createdAt': createdAt};
}

class StudyMaterial {
  final String id, className, subject, title, description, fileUrl, fileType, addedBy, addedByName;
  final DateTime createdAt;

  StudyMaterial({required this.id, required this.className, required this.subject,
    required this.title, required this.description, required this.fileUrl,
    required this.fileType, required this.addedBy, required this.addedByName,
    required this.createdAt});

  factory StudyMaterial.fromMap(Map<String, dynamic> m, String id) => StudyMaterial(
    id: id, className: m['className'] ?? '', subject: m['subject'] ?? '',
    title: m['title'] ?? '', description: m['description'] ?? '',
    fileUrl: m['fileUrl'] ?? '', fileType: m['fileType'] ?? 'note',
    addedBy: m['addedBy'] ?? '', addedByName: m['addedByName'] ?? '',
    createdAt: m['createdAt'] is Timestamp ? (m['createdAt'] as Timestamp).toDate() : DateTime.now());

  Map<String, dynamic> toMap() => {'className': className, 'subject': subject,
    'title': title, 'description': description, 'fileUrl': fileUrl,
    'fileType': fileType, 'addedBy': addedBy, 'addedByName': addedByName,
    'createdAt': createdAt};
}

class QuizModel {
  final String id, className, subject, chapter, title, createdBy, createdByName;
  final List<QuizQuestion> questions;
  final int timeLimitMinutes;
  final DateTime createdAt;

  QuizModel({required this.id, required this.className, required this.subject,
    required this.chapter, required this.title, required this.createdBy,
    required this.createdByName, required this.questions,
    required this.timeLimitMinutes, required this.createdAt});

  factory QuizModel.fromMap(Map<String, dynamic> m, String id) => QuizModel(
    id: id, className: m['className'] ?? '', subject: m['subject'] ?? '',
    chapter: m['chapter'] ?? '', title: m['title'] ?? '',
    createdBy: m['createdBy'] ?? '', createdByName: m['createdByName'] ?? '',
    questions: (m['questions'] as List<dynamic>? ?? [])
        .map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>)).toList(),
    timeLimitMinutes: m['timeLimitMinutes'] ?? 10,
    createdAt: m['createdAt'] is Timestamp ? (m['createdAt'] as Timestamp).toDate() : DateTime.now());

  Map<String, dynamic> toMap() => {'className': className, 'subject': subject,
    'chapter': chapter, 'title': title, 'createdBy': createdBy,
    'createdByName': createdByName,
    'questions': questions.map((q) => q.toMap()).toList(),
    'timeLimitMinutes': timeLimitMinutes, 'createdAt': createdAt};
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({required this.question, required this.options, required this.correctIndex});

  factory QuizQuestion.fromMap(Map<String, dynamic> m) => QuizQuestion(
    question: m['question'] ?? '',
    options: List<String>.from(m['options'] ?? []),
    correctIndex: m['correctIndex'] ?? 0);

  Map<String, dynamic> toMap() => {'question': question, 'options': options, 'correctIndex': correctIndex};
}

class QuizAttempt {
  final String id, quizId, studentId, studentName, className;
  final List<int> answers;
  final int score, totalQuestions;
  final DateTime attemptedAt;

  QuizAttempt({required this.id, required this.quizId, required this.studentId,
    required this.studentName, required this.className, required this.answers,
    required this.score, required this.totalQuestions, required this.attemptedAt});

  double get percentage => totalQuestions > 0 ? (score / totalQuestions) * 100 : 0;

  factory QuizAttempt.fromMap(Map<String, dynamic> m, String id) => QuizAttempt(
    id: id, quizId: m['quizId'] ?? '', studentId: m['studentId'] ?? '',
    studentName: m['studentName'] ?? '', className: m['className'] ?? '',
    answers: List<int>.from(m['answers'] ?? []),
    score: m['score'] ?? 0, totalQuestions: m['totalQuestions'] ?? 0,
    attemptedAt: m['attemptedAt'] is Timestamp ? (m['attemptedAt'] as Timestamp).toDate() : DateTime.now());

  Map<String, dynamic> toMap() => {'quizId': quizId, 'studentId': studentId,
    'studentName': studentName, 'className': className, 'answers': answers,
    'score': score, 'totalQuestions': totalQuestions, 'attemptedAt': attemptedAt};
}

class SchoolVideo {
  final String id, title, description, url, videoType, postedBy, postedByName;
  final DateTime createdAt;

  SchoolVideo({required this.id, required this.title, required this.description,
    required this.url, required this.videoType, required this.postedBy,
    required this.postedByName, required this.createdAt});

  factory SchoolVideo.fromMap(Map<String, dynamic> m, String id) => SchoolVideo(
    id: id, title: m['title'] ?? '', description: m['description'] ?? '',
    url: m['url'] ?? '', videoType: m['videoType'] ?? 'youtube',
    postedBy: m['postedBy'] ?? '', postedByName: m['postedByName'] ?? '',
    createdAt: m['createdAt'] is Timestamp ? (m['createdAt'] as Timestamp).toDate() : DateTime.now());

  Map<String, dynamic> toMap() => {'title': title, 'description': description,
    'url': url, 'videoType': videoType, 'postedBy': postedBy,
    'postedByName': postedByName, 'createdAt': createdAt};

  String? get youtubeId {
    if (!url.contains('youtube') && !url.contains('youtu.be')) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (url.contains('youtu.be')) return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
    return uri.queryParameters['v'];
  }
}

class AlertModel {
  final String id, message, type, postedBy;
  final bool isActive;
  final DateTime createdAt;

  AlertModel({required this.id, required this.message, required this.type,
    required this.postedBy, required this.isActive, required this.createdAt});

  factory AlertModel.fromMap(Map<String, dynamic> m, String id) => AlertModel(
    id: id, message: m['message'] ?? '', type: m['type'] ?? 'info',
    postedBy: m['postedBy'] ?? '', isActive: m['isActive'] ?? true,
    createdAt: m['createdAt'] is Timestamp ? (m['createdAt'] as Timestamp).toDate() : DateTime.now());

  Map<String, dynamic> toMap() => {'message': message, 'type': type,
    'postedBy': postedBy, 'isActive': isActive, 'createdAt': createdAt};
}

// ─── SCHOOL SERVICE ───────────────────────────────────────────────────────────
class SchoolService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _results => _db.collection('results');
  CollectionReference get _assessments => _db.collection('monthly_assessments');
  CollectionReference get _homework => _db.collection('homework');
  CollectionReference get _leaves => _db.collection('leaves');
  CollectionReference get _books => _db.collection('books');
  CollectionReference get _materials => _db.collection('study_materials');
  CollectionReference get _quizzes => _db.collection('quizzes');
  CollectionReference get _attempts => _db.collection('quiz_attempts');
  CollectionReference get _videos => _db.collection('school_videos');
  CollectionReference get _alerts => _db.collection('alerts');

  static String calculateGrade(double obtained, double max) {
    if (max == 0) return 'N/A';
    final pct = (obtained / max) * 100;
    if (pct >= 90) return 'A+';
    if (pct >= 80) return 'A';
    if (pct >= 70) return 'B+';
    if (pct >= 60) return 'B';
    if (pct >= 50) return 'C';
    if (pct >= 40) return 'D';
    return 'F';
  }

  // ── RESULTS ───────────────────────────────────────────────────────────────
  Future<bool> saveResult(ResultModel r) async {
    try { await _results.add(r.toMap()); return true; } catch (e) { print('SchoolService error: $e'); return false; }
  }

  Stream<List<ResultModel>> getStudentResults(String studentId) =>
      _results.where('studentId', isEqualTo: studentId).snapshots()
          .map((s) => s.docs
              .map((d) => ResultModel.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  Stream<List<ResultModel>> getClassResults(String className, String examType) =>
      _results.where('className', isEqualTo: className).snapshots()
          .map((s) => s.docs
              .map((d) => ResultModel.fromMap(d.data() as Map<String, dynamic>, d.id))
              .where((r) => examType.isEmpty || r.examType == examType)
              .toList()..sort((a, b) => b.percentage.compareTo(a.percentage)));

  Future<bool> deleteResult(String id) async {
    try { await _results.doc(id).delete(); return true; } catch (e) { print('SchoolService error: $e'); return false; }
  }

  // ── MONTHLY ASSESSMENT ────────────────────────────────────────────────────
  Future<bool> saveAssessment(MonthlyAssessment a) async {
    try { await _assessments.add(a.toMap()); return true; } catch (e) { print('SchoolService error: $e'); return false; }
  }

  Stream<List<MonthlyAssessment>> getStudentAssessments(String studentId) =>
      _assessments.where('studentId', isEqualTo: studentId).snapshots()
          .map((s) => s.docs
              .map((d) => MonthlyAssessment.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList()..sort((a, b) {
                final y = b.year.compareTo(a.year);
                return y != 0 ? y : b.month.compareTo(a.month);
              }));

  Stream<List<MonthlyAssessment>> getClassAssessments(
      String className, String month, int year) =>
      _assessments
          .where('className', isEqualTo: className)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .snapshots()
          .map((s) => s.docs
              .map((d) => MonthlyAssessment.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList());

  // ── HOMEWORK ──────────────────────────────────────────────────────────────
  Future<bool> postHomework(HomeworkModel hw) async {
    try { await _homework.add(hw.toMap()); return true; } catch (e) { print('SchoolService error: $e'); return false; }
  }

  Stream<List<HomeworkModel>> getHomework(String className) =>
      _homework.where('className', isEqualTo: className).snapshots()
          .map((s) => s.docs
              .map((d) => HomeworkModel.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  Future<bool> deleteHomework(String id) async {
    try { await _homework.doc(id).delete(); return true; } catch (e) { print('SchoolService error: $e'); return false; }
  }

  // ── LEAVES ────────────────────────────────────────────────────────────────
  Future<bool> applyLeave(LeaveModel l) async {
    try { await _leaves.add(l.toMap()); return true; } catch (e) { print('SchoolService error: $e'); return false; }
  }

  Stream<List<LeaveModel>> getPendingLeaves(String className) =>
      _leaves
          .where('className', isEqualTo: className)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((s) => s.docs
              .map((d) => LeaveModel.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList()..sort((a, b) => b.appliedAt.compareTo(a.appliedAt)));

  Stream<List<LeaveModel>> getStudentLeaves(String studentId) =>
      _leaves.where('studentId', isEqualTo: studentId).snapshots()
          .map((s) => s.docs
              .map((d) => LeaveModel.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList()..sort((a, b) => b.appliedAt.compareTo(a.appliedAt)));

  Future<bool> reviewLeave(String id, String status, String by, String byName) async {
    try {
      await _leaves.doc(id).update({'status': status, 'reviewedBy': by,
        'reviewedByName': byName, 'reviewedAt': DateTime.now()});
      return true;
    } catch (e) { print('SchoolService error: $e'); return false; }
  }

  // ── BOOKS ─────────────────────────────────────────────────────────────────
  Future<bool> addBook(BookModel b) async {
    try { await _books.add(b.toMap()); return true; } catch (e) { print('SchoolService error: $e'); return false; }
  }

  Stream<List<BookModel>> getBooks(String className) =>
      _books.where('className', isEqualTo: className).snapshots()
          .map((s) => s.docs
              .map((d) => BookModel.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList()..sort((a, b) => a.subject.compareTo(b.subject)));

  Future<bool> deleteBook(String id) async {
    try { await _books.doc(id).delete(); return true; } catch (e) { print('SchoolService error: $e'); return false; }
  }

  // ── STUDY MATERIAL ────────────────────────────────────────────────────────
  Future<bool> addMaterial(StudyMaterial m) async {
    try { await _materials.add(m.toMap()); return true; } catch (e) { print('SchoolService error: $e'); return false; }
  }

  Stream<List<StudyMaterial>> getMaterials(String className) =>
      _materials.where('className', isEqualTo: className).snapshots()
          .map((s) => s.docs
              .map((d) => StudyMaterial.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  Future<bool> deleteMaterial(String id) async {
    try { await _materials.doc(id).delete(); return true; } catch (e) { print('SchoolService error: $e'); return false; }
  }

  // ── QUIZ ──────────────────────────────────────────────────────────────────
  Future<bool> createQuiz(QuizModel q) async {
    try { await _quizzes.add(q.toMap()); return true; } catch (e) { print('SchoolService error: $e'); return false; }
  }

  // ✅ FIX: Returns ALL quizzes (used in QuizListScreen when class = 'All')
  Stream<List<QuizModel>> getAllQuizzes() =>
      _quizzes.limit(100).snapshots()
          .map((s) => s.docs
              .map((d) => QuizModel.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  Stream<List<QuizModel>> getQuizzes(String className) =>
      _quizzes.where('className', isEqualTo: className).snapshots()
          .map((s) => s.docs
              .map((d) => QuizModel.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  Future<bool> submitAttempt(QuizAttempt a) async {
    try { await _attempts.add(a.toMap()); return true; } catch (e) { print('SchoolService error: $e'); return false; }
  }

  Future<bool> hasAttempted(String quizId, String studentId) async {
    final snap = await _attempts
        .where('quizId', isEqualTo: quizId)
        .where('studentId', isEqualTo: studentId)
        .get();
    return snap.docs.isNotEmpty;
  }

  Stream<List<QuizAttempt>> getStudentAttempts(String studentId) =>
      _attempts.where('studentId', isEqualTo: studentId).snapshots()
          .map((s) => s.docs
              .map((d) => QuizAttempt.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList()..sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt)));

  // ✅ FIX: Returns attempts for a specific quiz (used in QuizAttemptsScreen)
  Stream<List<QuizAttempt>> getQuizAttempts(String quizId) =>
      _attempts.where('quizId', isEqualTo: quizId).snapshots()
          .map((s) => s.docs
              .map((d) => QuizAttempt.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList()..sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt)));

  Future<bool> deleteQuiz(String id) async {
    try { await _quizzes.doc(id).delete(); return true; } catch (e) { print('SchoolService error: $e'); return false; }
  }

  // ── VIDEOS ────────────────────────────────────────────────────────────────
  Future<bool> postVideo(SchoolVideo v) async {
    try { await _videos.add(v.toMap()); return true; } catch (e) { print('SchoolService error: $e'); return false; }
  }

  Stream<List<SchoolVideo>> getVideos() =>
      _videos.limit(50).snapshots().map((s) => s.docs
          .map((d) => SchoolVideo.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  Future<bool> deleteVideo(String id) async {
    try { await _videos.doc(id).delete(); return true; } catch (e) { print('SchoolService error: $e'); return false; }
  }

  // ── ALERTS ────────────────────────────────────────────────────────────────
  Future<bool> postAlert(AlertModel a) async {
    try { await _alerts.add(a.toMap()); return true; } catch (e) { print('SchoolService error: $e'); return false; }
  }

  Stream<List<AlertModel>> getActiveAlerts() =>
      _alerts.where('isActive', isEqualTo: true).limit(10).snapshots()
          .map((s) => s.docs
              .map((d) => AlertModel.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  Future<bool> deactivateAlert(String id) async {
    try { await _alerts.doc(id).update({'isActive': false}); return true; } catch (e) { print('SchoolService error: $e'); return false; }
  }
}