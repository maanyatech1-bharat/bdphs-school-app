// lib/services/notification_service.dart
// Sends professional emails via Firebase Trigger Email extension

import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final _mail = FirebaseFirestore.instance.collection('mail');

  // ─── STUDENT REGISTRATION ──────────────────────────────────────────────────
  static Future<void> sendStudentRegistrationEmail({
    required String toEmail,
    required String studentName,
    required String studentId,
    required String className,
    required String fatherName,
  }) async {
    try {
      await _mail.add({
        'to': toEmail,
        'message': {
          'subject': '✅ Registration Received — Blooming Dale Public High School',
          'html': _studentRegistrationHtml(
            name: studentName,
            studentId: studentId,
            className: className,
            fatherName: fatherName,
            email: toEmail,
          ),
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ─── TEACHER REGISTRATION ──────────────────────────────────────────────────
  static Future<void> sendTeacherRegistrationEmail({
    required String toEmail,
    required String teacherName,
    required String employeeId,
    required String subject,
    required String qualification,
  }) async {
    try {
      await _mail.add({
        'to': toEmail,
        'message': {
          'subject': '✅ Registration Received — Blooming Dale Public High School',
          'html': _teacherRegistrationHtml(
            name: teacherName,
            employeeId: employeeId,
            subject: subject,
            qualification: qualification,
            email: toEmail,
          ),
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ─── STUDENT APPROVED ──────────────────────────────────────────────────────
  static Future<void> sendStudentApprovalEmail({
    required String toEmail,
    required String studentName,
    required String studentId,
    required String className,
  }) async {
    try {
      await _mail.add({
        'to': toEmail,
        'message': {
          'subject': '🎉 Account Approved — Welcome to Blooming Dale Public High School!',
          'html': _studentApprovalHtml(
            name: studentName,
            studentId: studentId,
            className: className,
            email: toEmail,
          ),
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ─── TEACHER APPROVED ──────────────────────────────────────────────────────
  static Future<void> sendTeacherApprovalEmail({
    required String toEmail,
    required String teacherName,
    required String employeeId,
    required String subject,
  }) async {
    try {
      await _mail.add({
        'to': toEmail,
        'message': {
          'subject': '🎉 Account Approved — Welcome to the BDPHS Teaching Staff!',
          'html': _teacherApprovalHtml(
            name: teacherName,
            employeeId: employeeId,
            subject: subject,
            email: toEmail,
          ),
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ─── STUDENT REJECTED ──────────────────────────────────────────────────────
  static Future<void> sendStudentRejectionEmail({
    required String toEmail,
    required String studentName,
    String reason = '',
  }) async {
    try {
      await _mail.add({
        'to': toEmail,
        'message': {
          'subject': 'Registration Update — Blooming Dale Public High School',
          'html': _rejectionHtml(name: studentName, role: 'student', reason: reason),
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ─── TEACHER REJECTED ──────────────────────────────────────────────────────
  static Future<void> sendTeacherRejectionEmail({
    required String toEmail,
    required String teacherName,
    String reason = '',
  }) async {
    try {
      await _mail.add({
        'to': toEmail,
        'message': {
          'subject': 'Registration Update — Blooming Dale Public High School',
          'html': _rejectionHtml(name: teacherName, role: 'teacher', reason: reason),
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HTML TEMPLATES
  // ══════════════════════════════════════════════════════════════════════════

  static String _studentRegistrationHtml({
    required String name,
    required String studentId,
    required String className,
    required String fatherName,
    required String email,
  }) =>
      '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin:0;padding:0;background:#f0f4f8;font-family:'Segoe UI',Helvetica,Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f0f4f8;padding:40px 0;">
    <tr><td align="center">
      <table width="600" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 8px 32px rgba(0,0,0,0.10);">
        <tr>
          <td style="background:linear-gradient(135deg,#1A3A5C 0%,#2E5E8E 100%);padding:40px;text-align:center;">
            <p style="margin:0 0 4px;font-size:12px;color:#a8c5e0;letter-spacing:3px;text-transform:uppercase;font-weight:600;">Blooming Dale Public High School</p>
            <h1 style="margin:10px 0 6px;font-size:28px;font-weight:700;color:#ffffff;">Registration Received</h1>
            <p style="margin:0;font-size:14px;color:#90b8d4;">Your application has been successfully submitted</p>
          </td>
        </tr>
        <tr>
          <td style="padding:40px;">
            <p style="margin:0 0 6px;font-size:17px;color:#1A3A5C;font-weight:700;">Dear $name,</p>
            <p style="margin:0 0 28px;font-size:14px;color:#4b5563;line-height:1.8;">
              Thank you for registering with <strong>Blooming Dale Public High School</strong>. We have successfully received your application, and it is currently <strong>pending approval</strong>. You will be notified by email once the review is complete.
            </p>
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#f8fafc;border-radius:12px;border:1px solid #e2e8f0;margin-bottom:28px;">
              <tr><td style="padding:22px 26px;">
                <p style="margin:0 0 16px;font-size:11px;font-weight:800;color:#1A3A5C;text-transform:uppercase;letter-spacing:2px;">📋 Registration Details</p>
                ${_infoRow('Student Name', name)}
                ${_infoRow('Student ID', studentId)}
                ${_infoRow('Class / Grade', className)}
                ${_infoRow("Father's Name", fatherName)}
                ${_infoRow('Registered Email', email)}
              </td></tr>
            </table>
            <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:28px;">
              <tr>
                <td style="text-align:center;padding:12px 6px;width:33%;">
                  <div style="width:44px;height:44px;background:#22c55e;border-radius:50%;margin:0 auto 8px;text-align:center;line-height:44px;font-size:20px;">✓</div>
                  <p style="margin:0;font-size:12px;color:#22c55e;font-weight:700;">Submitted</p>
                </td>
                <td style="text-align:center;padding:12px 6px;width:33%;">
                  <div style="width:44px;height:44px;background:#f59e0b;border-radius:50%;margin:0 auto 8px;text-align:center;line-height:44px;font-size:20px;">⏳</div>
                  <p style="margin:0;font-size:12px;color:#f59e0b;font-weight:700;">Under Review</p>
                </td>
                <td style="text-align:center;padding:12px 6px;width:33%;">
                  <div style="width:44px;height:44px;background:#d1d5db;border-radius:50%;margin:0 auto 8px;text-align:center;line-height:44px;font-size:20px;">🎓</div>
                  <p style="margin:0;font-size:12px;color:#9ca3af;font-weight:700;">Access Granted</p>
                </td>
              </tr>
            </table>
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#fffbeb;border-left:4px solid #f59e0b;border-radius:0 8px 8px 0;margin-bottom:28px;">
              <tr><td style="padding:16px 20px;">
                <p style="margin:0;font-size:13px;color:#78350f;line-height:1.7;">
                  <strong>⚠️ Please Note:</strong> Save your Student ID <strong style="color:#92400e;">$studentId</strong> and registered email address. You will need these to log in once your account is approved. Expected review time: <strong>24–48 hours</strong>.
                </p>
              </td></tr>
            </table>
            <p style="margin:0;font-size:14px;color:#4b5563;line-height:1.8;">
              Should you have any questions, please do not hesitate to contact the school office.<br>
              We look forward to welcoming you to the BDPHS family!
            </p>
          </td>
        </tr>
        ${_footer()}
      </table>
    </td></tr>
  </table>
</body>
</html>
''';

  static String _teacherRegistrationHtml({
    required String name,
    required String employeeId,
    required String subject,
    required String qualification,
    required String email,
  }) =>
      '''
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"></head>
<body style="margin:0;padding:0;background:#f0f4f8;font-family:'Segoe UI',Helvetica,Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f0f4f8;padding:40px 0;">
    <tr><td align="center">
      <table width="600" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 8px 32px rgba(0,0,0,0.10);">
        <tr>
          <td style="background:linear-gradient(135deg,#1A3A5C 0%,#2E5E8E 100%);padding:40px;text-align:center;">
            <p style="margin:0 0 4px;font-size:12px;color:#a8c5e0;letter-spacing:3px;text-transform:uppercase;font-weight:600;">Blooming Dale Public High School</p>
            <h1 style="margin:10px 0 6px;font-size:28px;font-weight:700;color:#ffffff;">Registration Received</h1>
            <p style="margin:0;font-size:14px;color:#90b8d4;">Your application is pending admin approval</p>
          </td>
        </tr>
        <tr>
          <td style="padding:40px;">
            <p style="margin:0 0 6px;font-size:17px;color:#1A3A5C;font-weight:700;">Dear $name,</p>
            <p style="margin:0 0 28px;font-size:14px;color:#4b5563;line-height:1.8;">
              Thank you for applying to join the teaching staff at <strong>Blooming Dale Public High School</strong>. Your application has been received and is currently under review by the administration. You will receive a confirmation email once it has been processed.
            </p>
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#f8fafc;border-radius:12px;border:1px solid #e2e8f0;margin-bottom:28px;">
              <tr><td style="padding:22px 26px;">
                <p style="margin:0 0 16px;font-size:11px;font-weight:800;color:#1A3A5C;text-transform:uppercase;letter-spacing:2px;">📋 Your Application Details</p>
                ${_infoRow('Teacher Name', name)}
                ${_infoRow('Employee ID', employeeId)}
                ${_infoRow('Subject', subject)}
                ${_infoRow('Qualification', qualification)}
                ${_infoRow('Registered Email', email)}
              </td></tr>
            </table>
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#fffbeb;border-left:4px solid #f59e0b;border-radius:0 8px 8px 0;margin-bottom:28px;">
              <tr><td style="padding:16px 20px;">
                <p style="margin:0;font-size:13px;color:#78350f;line-height:1.7;">
                  <strong>⚠️ Please Note:</strong> Your account requires <strong>admin approval</strong> before you can access the system. You will receive a welcome email once your account has been approved. Expected review time: <strong>24–48 hours</strong>.
                </p>
              </td></tr>
            </table>
            <p style="margin:0;font-size:14px;color:#4b5563;line-height:1.8;">
              For any queries, please contact the school administration office.<br>
              Thank you for your patience and interest in joining our team.
            </p>
          </td>
        </tr>
        ${_footer()}
      </table>
    </td></tr>
  </table>
</body>
</html>
''';

  static String _studentApprovalHtml({
    required String name,
    required String studentId,
    required String className,
    required String email,
  }) =>
      '''
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"></head>
<body style="margin:0;padding:0;background:#f0f4f8;font-family:'Segoe UI',Helvetica,Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f0f4f8;padding:40px 0;">
    <tr><td align="center">
      <table width="600" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 8px 32px rgba(0,0,0,0.10);">
        <tr>
          <td style="background:linear-gradient(135deg,#15803d 0%,#22c55e 100%);padding:40px;text-align:center;">
            <div style="width:68px;height:68px;background:rgba(255,255,255,0.2);border-radius:50%;margin:0 auto 16px;text-align:center;line-height:68px;font-size:34px;">🎉</div>
            <p style="margin:0 0 4px;font-size:12px;color:#bbf7d0;letter-spacing:3px;text-transform:uppercase;font-weight:600;">Blooming Dale Public High School</p>
            <h1 style="margin:10px 0 6px;font-size:28px;font-weight:700;color:#ffffff;">Account Approved!</h1>
            <p style="margin:0;font-size:14px;color:#dcfce7;">Welcome to the BDPHS Family 🌟</p>
          </td>
        </tr>
        <tr>
          <td style="padding:40px;">
            <p style="margin:0 0 6px;font-size:17px;color:#1A3A5C;font-weight:700;">Dear $name,</p>
            <p style="margin:0 0 28px;font-size:14px;color:#4b5563;line-height:1.8;">
              We are delighted to inform you that your student account has been <strong style="color:#15803d;">approved</strong>! You can now log in to the <strong>BDPHS School App</strong> and access all features available to you.
            </p>
            <table width="100%" cellpadding="0" cellspacing="0" style="background:linear-gradient(135deg,#1A3A5C 0%,#2E5E8E 100%);border-radius:12px;margin-bottom:28px;">
              <tr><td style="padding:26px;">
                <p style="margin:0 0 16px;font-size:11px;font-weight:800;color:#a8c5e0;text-transform:uppercase;letter-spacing:2px;">🎫 Your Login Credentials</p>
                <table width="100%" cellpadding="0" cellspacing="0">
                  <tr>
                    <td style="padding:7px 0;font-size:13px;color:#90b8d4;width:130px;">Student ID</td>
                    <td style="padding:7px 0;font-size:15px;color:#ffffff;font-weight:700;">$studentId</td>
                  </tr>
                  <tr>
                    <td style="padding:7px 0;font-size:13px;color:#90b8d4;">Email</td>
                    <td style="padding:7px 0;font-size:14px;color:#ffffff;font-weight:700;">$email</td>
                  </tr>
                  <tr>
                    <td style="padding:7px 0;font-size:13px;color:#90b8d4;">Class</td>
                    <td style="padding:7px 0;font-size:15px;color:#ffffff;font-weight:700;">$className</td>
                  </tr>
                </table>
              </td></tr>
            </table>
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#f0fdf4;border-radius:12px;border:1px solid #bbf7d0;margin-bottom:28px;">
              <tr><td style="padding:22px 26px;">
                <p style="margin:0 0 14px;font-size:11px;font-weight:800;color:#15803d;text-transform:uppercase;letter-spacing:2px;">📚 What You Can Access Now</p>
                ${_featureRow('📊', 'View your marks and academic results')}
                ${_featureRow('📅', 'Check your timetable and exam schedule')}
                ${_featureRow('📝', 'View homework assigned by your teacher')}
                ${_featureRow('📚', 'Access study materials, books and notes')}
                ${_featureRow('🤖', 'Use the AI Tutor for personalised study help')}
                ${_featureRow('💬', 'Chat directly with your teachers')}
                ${_featureRow('🏆', 'Track your performance on the leaderboard')}
              </td></tr>
            </table>
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#eff6ff;border-left:4px solid #3b82f6;border-radius:0 8px 8px 0;margin-bottom:28px;">
              <tr><td style="padding:16px 20px;">
                <p style="margin:0;font-size:13px;color:#1e40af;line-height:1.7;">
                  <strong>📱 Getting Started:</strong> Open the BDPHS School App on your device and log in using your registered email address and password.
                </p>
              </td></tr>
            </table>
            <p style="margin:0;font-size:14px;color:#4b5563;line-height:1.8;">
              We wish you a wonderful and successful learning journey at BDPHS School.<br>
              <strong style="color:#1A3A5C;">Study hard, dream big, and achieve great things! 🌟</strong>
            </p>
          </td>
        </tr>
        ${_footer()}
      </table>
    </td></tr>
  </table>
</body>
</html>
''';

  static String _teacherApprovalHtml({
    required String name,
    required String employeeId,
    required String subject,
    required String email,
  }) =>
      '''
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"></head>
<body style="margin:0;padding:0;background:#f0f4f8;font-family:'Segoe UI',Helvetica,Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f0f4f8;padding:40px 0;">
    <tr><td align="center">
      <table width="600" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 8px 32px rgba(0,0,0,0.10);">
        <tr>
          <td style="background:linear-gradient(135deg,#15803d 0%,#22c55e 100%);padding:40px;text-align:center;">
            <div style="width:68px;height:68px;background:rgba(255,255,255,0.2);border-radius:50%;margin:0 auto 16px;text-align:center;line-height:68px;font-size:34px;">🎉</div>
            <p style="margin:0 0 4px;font-size:12px;color:#bbf7d0;letter-spacing:3px;text-transform:uppercase;font-weight:600;">Blooming Dale Public High School</p>
            <h1 style="margin:10px 0 6px;font-size:28px;font-weight:700;color:#ffffff;">Account Approved!</h1>
            <p style="margin:0;font-size:14px;color:#dcfce7;">Welcome to the BDPHS Teaching Staff 🌟</p>
          </td>
        </tr>
        <tr>
          <td style="padding:40px;">
            <p style="margin:0 0 6px;font-size:17px;color:#1A3A5C;font-weight:700;">Dear $name,</p>
            <p style="margin:0 0 28px;font-size:14px;color:#4b5563;line-height:1.8;">
              Congratulations! Your teacher account at <strong>Blooming Dale Public High School</strong> has been <strong style="color:#15803d;">approved</strong> by the administration. You can now log in to the BDPHS School App and begin using all teacher features.
            </p>
            <table width="100%" cellpadding="0" cellspacing="0" style="background:linear-gradient(135deg,#1A3A5C 0%,#2E5E8E 100%);border-radius:12px;margin-bottom:28px;">
              <tr><td style="padding:26px;">
                <p style="margin:0 0 16px;font-size:11px;font-weight:800;color:#a8c5e0;text-transform:uppercase;letter-spacing:2px;">🪪 Your Account Details</p>
                <table width="100%" cellpadding="0" cellspacing="0">
                  <tr>
                    <td style="padding:7px 0;font-size:13px;color:#90b8d4;width:130px;">Employee ID</td>
                    <td style="padding:7px 0;font-size:15px;color:#ffffff;font-weight:700;">$employeeId</td>
                  </tr>
                  <tr>
                    <td style="padding:7px 0;font-size:13px;color:#90b8d4;">Email</td>
                    <td style="padding:7px 0;font-size:14px;color:#ffffff;font-weight:700;">$email</td>
                  </tr>
                  <tr>
                    <td style="padding:7px 0;font-size:13px;color:#90b8d4;">Subject</td>
                    <td style="padding:7px 0;font-size:15px;color:#ffffff;font-weight:700;">$subject</td>
                  </tr>
                </table>
              </td></tr>
            </table>
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#f0fdf4;border-radius:12px;border:1px solid #bbf7d0;margin-bottom:28px;">
              <tr><td style="padding:22px 26px;">
                <p style="margin:0 0 14px;font-size:11px;font-weight:800;color:#15803d;text-transform:uppercase;letter-spacing:2px;">🛠️ Your Teacher Features</p>
                ${_featureRow('✏️', 'Enter and manage student marks and grades')}
                ${_featureRow('📋', 'Record daily class attendance')}
                ${_featureRow('📝', 'Assign and manage homework for your class')}
                ${_featureRow('📊', 'Conduct monthly assessments and generate reports')}
                ${_featureRow('📚', 'Upload study materials, books and notes')}
                ${_featureRow('✅', 'Review and approve student leave requests')}
                ${_featureRow('💬', 'Communicate with students through in-app chat')}
                ${_featureRow('📅', 'Schedule online meetings with Google Meet')}
              </td></tr>
            </table>
            <p style="margin:0;font-size:14px;color:#4b5563;line-height:1.8;">
              We are proud to welcome you to the BDPHS teaching community. Your dedication and expertise will make a meaningful difference in the lives of our students.<br><br>
              <strong style="color:#1A3A5C;">Together, let us shape the future of our students! 🌟</strong>
            </p>
          </td>
        </tr>
        ${_footer()}
      </table>
    </td></tr>
  </table>
</body>
</html>
''';

  static String _rejectionHtml({
    required String name,
    required String role,
    required String reason,
  }) {
    final roleCapital = role[0].toUpperCase() + role.substring(1);
    return '''
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"></head>
<body style="margin:0;padding:0;background:#f0f4f8;font-family:'Segoe UI',Helvetica,Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f0f4f8;padding:40px 0;">
    <tr><td align="center">
      <table width="600" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 8px 32px rgba(0,0,0,0.10);">
        <tr>
          <td style="background:linear-gradient(135deg,#1A3A5C 0%,#2E5E8E 100%);padding:40px;text-align:center;">
            <p style="margin:0 0 4px;font-size:12px;color:#a8c5e0;letter-spacing:3px;text-transform:uppercase;font-weight:600;">Blooming Dale Public High School</p>
            <h1 style="margin:10px 0 6px;font-size:26px;font-weight:700;color:#ffffff;">Registration Update</h1>
            <p style="margin:0;font-size:14px;color:#90b8d4;">Important information regarding your application</p>
          </td>
        </tr>
        <tr>
          <td style="padding:40px;">
            <p style="margin:0 0 6px;font-size:17px;color:#1A3A5C;font-weight:700;">Dear $name,</p>
            <p style="margin:0 0 24px;font-size:14px;color:#4b5563;line-height:1.8;">
              We regret to inform you that your $roleCapital registration application at <strong>Blooming Dale Public High School</strong> could not be approved at this time.
            </p>
            ${reason.isNotEmpty ? '''
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#fef2f2;border-left:4px solid #ef4444;border-radius:0 8px 8px 0;margin-bottom:24px;">
              <tr><td style="padding:16px 20px;">
                <p style="margin:0;font-size:13px;color:#991b1b;line-height:1.7;"><strong>Reason:</strong> $reason</p>
              </td></tr>
            </table>
            ''' : ''}
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#f8fafc;border-radius:12px;border:1px solid #e2e8f0;margin-bottom:28px;">
              <tr><td style="padding:22px 26px;">
                <p style="margin:0 0 14px;font-size:11px;font-weight:800;color:#1A3A5C;text-transform:uppercase;letter-spacing:2px;">📌 What You Can Do Next</p>
                ${_featureRow('📞', 'Contact the school office for clarification')}
                ${_featureRow('✉️', 'Email us at bdphschool1@gmail.com')}
                ${_featureRow('📝', 'Re-submit your application with correct information')}
              </td></tr>
            </table>
            <p style="margin:0;font-size:14px;color:#4b5563;line-height:1.8;">
              We apologise for any inconvenience caused and appreciate your interest in BDPHS School. Please do not hesitate to reach out to us for further assistance.
            </p>
          </td>
        </tr>
        ${_footer()}
      </table>
    </td></tr>
  </table>
</body>
</html>
''';
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────
  static String _infoRow(String label, String value) => '''
    <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:10px;">
      <tr>
        <td width="150" style="font-size:13px;color:#6b7280;vertical-align:top;padding-right:12px;">$label:</td>
        <td style="font-size:13px;color:#1A3A5C;font-weight:600;">$value</td>
      </tr>
    </table>
  ''';

  static String _featureRow(String emoji, String text) => '''
    <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:9px;">
      <tr>
        <td width="28" style="font-size:15px;vertical-align:middle;">$emoji</td>
        <td style="font-size:13px;color:#374151;padding-left:8px;line-height:1.5;">$text</td>
      </tr>
    </table>
  ''';

  static String _footer() => '''
    <tr>
      <td style="background:#f8fafc;padding:28px 40px;text-align:center;border-top:1px solid #e5e7eb;">
        <p style="margin:0 0 4px;font-size:14px;color:#1A3A5C;font-weight:700;">Blooming Dale Public High School</p>
        <p style="margin:0 0 4px;font-size:12px;color:#6b7280;">Jammu and Kashmir, India</p>
        <p style="margin:0 0 16px;font-size:12px;color:#6b7280;">📧 bdphschool1@gmail.com</p>
        <p style="margin:0;font-size:11px;color:#9ca3af;line-height:1.6;">This is an automated message from the BDPHS School Management System.<br>Please do not reply directly to this email.</p>
      </td>
    </tr>
  ''';
}