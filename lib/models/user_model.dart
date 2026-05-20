// lib/models/user_model.dart

enum UserRole { student, teacher, admin }
enum ApprovalStatus { pending, approved, rejected }

extension UserRoleX on UserRole {
  static UserRole fromString(String v) => UserRoleExtension.fromString(v);
}

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.student: return 'student';
      case UserRole.teacher: return 'teacher';
      case UserRole.admin: return 'admin';
    }
  }
  String get displayName {
    switch (this) {
      case UserRole.student: return 'Student';
      case UserRole.teacher: return 'Teacher';
      case UserRole.admin: return 'Admin';
    }
  }
  static UserRole fromString(String value) {
    switch (value) {
      case 'teacher': return UserRole.teacher;
      case 'admin': return UserRole.admin;
      default: return UserRole.student;
    }
  }
}

// ─── BASE USER MODEL ─────────────────────────────────────────────────────────
class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String phone;
  final UserRole role;
  final ApprovalStatus approvalStatus;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final bool isActive;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    this.approvalStatus = ApprovalStatus.pending,
    this.photoUrl,
    required this.createdAt,
    this.approvedAt,
    this.approvedBy,
    this.isActive = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      phone: map['phone'] ?? '',
      role: UserRoleExtension.fromString(map['role'] ?? 'student'),
      approvalStatus: _parseApproval(map['approvalStatus']),
      photoUrl: map['photoUrl'],
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      approvedAt: (map['approvedAt'] as dynamic)?.toDate(),
      approvedBy: map['approvedBy'],
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'fullName': fullName,
    'phone': phone,
    'role': role.name,
    'approvalStatus': approvalStatus.name,
    'photoUrl': photoUrl,
    'createdAt': createdAt,
    'approvedAt': approvedAt,
    'approvedBy': approvedBy,
    'isActive': isActive,
  };

  static ApprovalStatus _parseApproval(String? value) {
    switch (value) {
      case 'approved': return ApprovalStatus.approved;
      case 'rejected': return ApprovalStatus.rejected;
      default: return ApprovalStatus.pending;
    }
  }

  UserModel copyWith({
    String? photoUrl,
    ApprovalStatus? approvalStatus,
    DateTime? approvedAt,
    String? approvedBy,
    bool? isActive,
  }) => UserModel(
    uid: uid, email: email, fullName: fullName, phone: phone, role: role,
    approvalStatus: approvalStatus ?? this.approvalStatus,
    photoUrl: photoUrl ?? this.photoUrl,
    createdAt: createdAt,
    approvedAt: approvedAt ?? this.approvedAt,
    approvedBy: approvedBy ?? this.approvedBy,
    isActive: isActive ?? this.isActive,
  );
}

// ─── STUDENT MODEL ────────────────────────────────────────────────────────────
class StudentModel extends UserModel {
  final String fatherName;
  final String motherName;
  final String gender;
  final DateTime dateOfBirth;
  final String address;
  final String className;
  final String rollNumber;
  final String aadharNumber;
  final String? assignedTeacherId;
  final String? sectionId;
  final double? attendancePercentage;

  StudentModel({
    required super.uid,
    required super.email,
    required super.fullName,
    required super.phone,
    super.approvalStatus,
    super.photoUrl,
    required super.createdAt,
    super.approvedAt,
    super.approvedBy,
    super.isActive,
    required this.fatherName,
    required this.motherName,
    required this.gender,
    required this.dateOfBirth,
    required this.address,
    required this.className,
    required this.rollNumber,
    required this.aadharNumber,
    this.assignedTeacherId,
    this.sectionId,
    this.attendancePercentage,
  }) : super(role: UserRole.student);

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      phone: map['phone'] ?? '',
      approvalStatus: UserModel._parseApproval(map['approvalStatus']),
      photoUrl: map['photoUrl'],
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      approvedAt: (map['approvedAt'] as dynamic)?.toDate(),
      approvedBy: map['approvedBy'],
      isActive: map['isActive'] ?? true,
      fatherName: map['fatherName'] ?? '',
      motherName: map['motherName'] ?? '',
      gender: map['gender'] ?? '',
      dateOfBirth: (map['dateOfBirth'] as dynamic)?.toDate() ?? DateTime.now(),
      address: map['address'] ?? '',
      className: map['className'] ?? '',
      rollNumber: map['rollNumber'] ?? '',
      aadharNumber: map['aadharNumber'] ?? '',
      assignedTeacherId: map['assignedTeacherId'],
      sectionId: map['sectionId'],
      attendancePercentage: (map['attendancePercentage'] as num?)?.toDouble(),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
    ...super.toMap(),
    'fatherName': fatherName,
    'motherName': motherName,
    'gender': gender,
    'dateOfBirth': dateOfBirth,
    'address': address,
    'className': className,
    'rollNumber': rollNumber,
    'aadharNumber': aadharNumber,
    'assignedTeacherId': assignedTeacherId,
    'sectionId': sectionId,
    'attendancePercentage': attendancePercentage,
  };

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }
}

// ─── TEACHER MODEL ────────────────────────────────────────────────────────────
class TeacherModel extends UserModel {
  final String employeeId;
  final String qualification;
  final String subject;
  final String address;
  final List<String> assignedClasses;
  final DateTime joiningDate;

  TeacherModel({
    required super.uid,
    required super.email,
    required super.fullName,
    required super.phone,
    super.approvalStatus,
    super.photoUrl,
    required super.createdAt,
    super.approvedAt,
    super.approvedBy,
    super.isActive,
    required this.employeeId,
    required this.qualification,
    required this.subject,
    required this.address,
    this.assignedClasses = const [],
    required this.joiningDate,
  }) : super(role: UserRole.teacher);

  factory TeacherModel.fromMap(Map<String, dynamic> map) {
    return TeacherModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      phone: map['phone'] ?? '',
      approvalStatus: UserModel._parseApproval(map['approvalStatus']),
      photoUrl: map['photoUrl'],
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      approvedAt: (map['approvedAt'] as dynamic)?.toDate(),
      approvedBy: map['approvedBy'],
      isActive: map['isActive'] ?? true,
      employeeId: map['employeeId'] ?? '',
      qualification: map['qualification'] ?? '',
      subject: map['subject'] ?? '',
      address: map['address'] ?? '',
      assignedClasses: List<String>.from(map['assignedClasses'] ?? []),
      joiningDate: (map['joiningDate'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
    ...super.toMap(),
    'employeeId': employeeId,
    'qualification': qualification,
    'subject': subject,
    'address': address,
    'assignedClasses': assignedClasses,
    'joiningDate': joiningDate,
  };
}

// ─── ATTENDANCE MODEL ─────────────────────────────────────────────────────────
class AttendanceRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String className;
  final DateTime date;
  final bool isPresent;
  final String markedBy;
  final String markedByName;
  final DateTime markedAt;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.date,
    required this.isPresent,
    required this.markedBy,
    this.markedByName = '',
    required this.markedAt,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceRecord(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      className: map['className'] ?? '',
      date: (map['date'] as dynamic)?.toDate() ?? DateTime.now(),
      isPresent: map['isPresent'] ?? false,
      markedBy: map['markedBy'] ?? '',
      markedByName: map['markedByName'] ?? '',
      markedAt: (map['markedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'studentId': studentId,
    'studentName': studentName,
    'className': className,
    'date': date,
    'isPresent': isPresent,
    'markedBy': markedBy,
    'markedByName': markedByName,
    'markedAt': markedAt,
  };
}

// ─── NOTICE MODEL ─────────────────────────────────────────────────────────────
class NoticeModel {
  final String id;
  final String title;
  final String content;
  final String postedBy;
  final String postedByName;
  final DateTime postedAt;
  final String targetAudience; // 'all', 'students', 'teachers'
  final bool isPinned;
  final String? className;

  NoticeModel({
    required this.id,
    required this.title,
    required this.content,
    required this.postedBy,
    required this.postedByName,
    required this.postedAt,
    this.targetAudience = 'all',
    this.isPinned = false,
    this.className,
  });

  factory NoticeModel.fromMap(Map<String, dynamic> map, String id) {
    return NoticeModel(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      postedBy: map['postedBy'] ?? '',
      postedByName: map['postedByName'] ?? '',
      postedAt: (map['postedAt'] as dynamic)?.toDate() ?? DateTime.now(),
      targetAudience: map['targetAudience'] ?? 'all',
      isPinned: map['isPinned'] ?? false,
      className: map['className'],
    );
  }

  DateTime get createdAt => postedAt;

  Map<String, dynamic> toMap() => {
    'title': title,
    'content': content,
    'postedBy': postedBy,
    'postedByName': postedByName,
    'postedAt': postedAt,
    'createdAt': postedAt,
    'targetAudience': targetAudience,
    'isPinned': isPinned,
    'className': className,
  };
}