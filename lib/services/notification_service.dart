// lib/services/notification_service.dart
// Sends professional emails via Firebase Trigger Email extension
// (writes to 'mail' Firestore collection — extension auto-sends)

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
          'subject': '✅ Registration Received – BDPHS School',
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
    } catch (_) {
      // Silent fail — don't block registration if email fails
    }
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
          'subject': '✅ Registration Received – BDPHS School',
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
          'subject': '🎉 Welcome to BDPHS School – Account Approved!',
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
          'subject': '🎉 Welcome to BDPHS School – Account Approved!',
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
          'subject': 'Registration Update – BDPHS School',
          'html': _rejectionHtml(name: studentName, role: 'Student', reason: reason),
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
          'subject': 'Registration Update – BDPHS School',
          'html': _rejectionHtml(name: teacherName, role: 'Teacher', reason: reason),
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
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"></head>
<body style="margin:0;padding:0;background:#f0f4f8;font-family:'Segoe UI',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f0f4f8;padding:30px 0;">
    <tr><td align="center">
      <table width="600" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">

        <!-- Header -->
        <tr>
          <td style="background:linear-gradient(135deg,#1A3A5C,#2E5E8E);padding:36px 40px;text-align:center;">
            <p style="margin:0 0 6px;font-size:13px;color:#a8c5e0;letter-spacing:2px;text-transform:uppercase;">Blooming Dale Public High School</p>
            <h1 style="margin:0;font-size:26px;font-weight:700;color:#ffffff;">Registration Received</h1>
            <p style="margin:10px 0 0;font-size:14px;color:#90b8d4;">Your application is under review</p>
          </td>
        </tr>

        <!-- Body -->
        <tr>
          <td style="padding:36px 40px;">
            <p style="margin:0 0 8px;font-size:16px;color:#1A3A5C;font-weight:600;">Dear $name,</p>
            <p style="margin:0 0 24px;font-size:14px;color:#555;line-height:1.7;">
              Thank you for registering with <strong>BDPHS School</strong>. We have successfully received your registration and it is currently <strong>pending teacher approval</strong>.
            </p>

            <!-- Info Box -->
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#f7f9fc;border-radius:12px;border:1px solid #dce8f5;margin-bottom:24px;">
              <tr><td style="padding:20px 24px;">
                <p style="margin:0 0 14px;font-size:13px;font-weight:700;color:#1A3A5C;text-transform:uppercase;letter-spacing:1px;">📋 Your Registration Details</p>
                ${_infoRow('Student Name', name)}
                ${_infoRow('Student ID', studentId)}
                ${_infoRow('Class / Grade', className)}
                ${_infoRow("Father's Name", fatherName)}
                ${_infoRow('Registered Email', email)}
              </td></tr>
            </table>

            <!-- Status Timeline -->
            <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:24px;">
              <tr>
                <td width="33%" style="text-align:center;padding:16px 8px;">
                  <div style="width:40px;height:40px;background:#22c55e;border-radius:50%;margin:0 auto 8px;display:flex;align-items:center;justify-content:center;">
                    <span style="color:white;font-size:18px;">✓</span>
                  </div>
                  <p style="margin:0;font-size:12px;color:#22c55e;font-weight:600;">Submitted</p>
                </td>
                <td width="33%" style="text-align:center;padding:16px 8px;">
                  <div style="width:40px;height:40px;background:#f59e0b;border-radius:50%;margin:0 auto 8px;">
                    <span style="color:white;font-size:18px;line-height:40px;">⏳</span>
                  </div>
                  <p style="margin:0;font-size:12px;color:#f59e0b;font-weight:600;">Under Review</p>
                </td>
                <td width="33%" style="text-align:center;padding:16px 8px;">
                  <div style="width:40px;height:40px;background:#d1d5db;border-radius:50%;margin:0 auto 8px;">
                    <span style="color:white;font-size:18px;line-height:40px;">🎓</span>
                  </div>
                  <p style="margin:0;font-size:12px;color:#9ca3af;font-weight:600;">Access Granted</p>
                </td>
              </tr>
            </table>

            <!-- Note -->
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#fffbeb;border-left:4px solid #f59e0b;border-radius:8px;margin-bottom:24px;">
              <tr><td style="padding:16px 20px;">
                <p style="margin:0;font-size:13px;color:#92400e;line-height:1.6;">
                  <strong>⚠️ Important:</strong> Please save your Student ID <strong>$studentId</strong> and login email. You will receive another email once your account is approved by the teacher.
                </p>
              </td></tr>
            </table>

            <p style="margin:0;font-size:14px;color:#555;line-height:1.7;">
              If you have any questions, please contact the school office.<br>
              We look forward to welcoming you to the BDPHS family!
            </p>
          </td>
        </tr>

        <!-- Footer -->
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
<body style="margin:0;padding:0;background:#f0f4f8;font-family:'Segoe UI',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f0f4f8;padding:30px 0;">
    <tr><td align="center">
      <table width="600" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">

        <!-- Header -->
        <tr>
          <td style="background:linear-gradient(135deg,#1A3A5C,#2E5E8E);padding:36px 40px;text-align:center;">
            <p style="margin:0 0 6px;font-size:13px;color:#a8c5e0;letter-spacing:2px;text-transform:uppercase;">Blooming Dale Public High School</p>
            <h1 style="margin:0;font-size:26px;font-weight:700;color:#ffffff;">Registration Received</h1>
            <p style="margin:10px 0 0;font-size:14px;color:#90b8d4;">Your application is pending admin approval</p>
          </td>
        </tr>

        <!-- Body -->
        <tr>
          <td style="padding:36px 40px;">
            <p style="margin:0 0 8px;font-size:16px;color:#1A3A5C;font-weight:600;">Dear $name,</p>
            <p style="margin:0 0 24px;font-size:14px;color:#555;line-height:1.7;">
              Thank you for registering as a teacher with <strong>BDPHS School</strong>. Your application has been received and is currently <strong>pending admin approval</strong>.
            </p>

            <!-- Info Box -->
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#f7f9fc;border-radius:12px;border:1px solid #dce8f5;margin-bottom:24px;">
              <tr><td style="padding:20px 24px;">
                <p style="margin:0 0 14px;font-size:13px;font-weight:700;color:#1A3A5C;text-transform:uppercase;letter-spacing:1px;">📋 Your Registration Details</p>
                ${_infoRow('Teacher Name', name)}
                ${_infoRow('Employee ID', employeeId)}
                ${_infoRow('Subject', subject)}
                ${_infoRow('Qualification', qualification)}
                ${_infoRow('Registered Email', email)}
              </td></tr>
            </table>

            <!-- Note -->
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#fffbeb;border-left:4px solid #f59e0b;border-radius:8px;margin-bottom:24px;">
              <tr><td style="padding:16px 20px;">
                <p style="margin:0;font-size:13px;color:#92400e;line-height:1.6;">
                  <strong>⚠️ Note:</strong> Your account requires <strong>admin approval</strong> before you can log in. You will receive a welcome email once approved.
                </p>
              </td></tr>
            </table>

            <p style="margin:0;font-size:14px;color:#555;line-height:1.7;">
              For any queries, please contact the school administration.<br>
              Thank you for your patience.
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
<body style="margin:0;padding:0;background:#f0f4f8;font-family:'Segoe UI',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f0f4f8;padding:30px 0;">
    <tr><td align="center">
      <table width="600" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">

        <!-- Header - Green for approval -->
        <tr>
          <td style="background:linear-gradient(135deg,#16a34a,#22c55e);padding:36px 40px;text-align:center;">
            <div style="width:64px;height:64px;background:rgba(255,255,255,0.2);border-radius:50%;margin:0 auto 16px;line-height:64px;font-size:32px;">🎉</div>
            <p style="margin:0 0 6px;font-size:13px;color:#bbf7d0;letter-spacing:2px;text-transform:uppercase;">Blooming Dale Public High School</p>
            <h1 style="margin:0;font-size:26px;font-weight:700;color:#ffffff;">Account Approved!</h1>
            <p style="margin:10px 0 0;font-size:14px;color:#dcfce7;">Welcome to the BDPHS Family</p>
          </td>
        </tr>

        <!-- Body -->
        <tr>
          <td style="padding:36px 40px;">
            <p style="margin:0 0 8px;font-size:16px;color:#1A3A5C;font-weight:600;">Dear $name,</p>
            <p style="margin:0 0 24px;font-size:14px;color:#555;line-height:1.7;">
              We are delighted to inform you that your student account has been <strong style="color:#16a34a;">approved</strong>! You can now log in to the BDPHS School App and access all features.
            </p>

            <!-- Credentials Box -->
            <table width="100%" cellpadding="0" cellspacing="0" style="background:linear-gradient(135deg,#1A3A5C,#2E5E8E);border-radius:12px;margin-bottom:24px;">
              <tr><td style="padding:24px;">
                <p style="margin:0 0 16px;font-size:13px;font-weight:700;color:#a8c5e0;text-transform:uppercase;letter-spacing:1px;">🎫 Your Login Credentials</p>
                <table width="100%" cellpadding="0" cellspacing="0">
                  <tr>
                    <td style="padding:6px 0;font-size:13px;color:#90b8d4;width:120px;">Student ID:</td>
                    <td style="padding:6px 0;font-size:14px;color:#ffffff;font-weight:700;">$studentId</td>
                  </tr>
                  <tr>
                    <td style="padding:6px 0;font-size:13px;color:#90b8d4;">Email:</td>
                    <td style="padding:6px 0;font-size:14px;color:#ffffff;font-weight:700;">$email</td>
                  </tr>
                  <tr>
                    <td style="padding:6px 0;font-size:13px;color:#90b8d4;">Class:</td>
                    <td style="padding:6px 0;font-size:14px;color:#ffffff;font-weight:700;">$className</td>
                  </tr>
                </table>
              </td></tr>
            </table>

            <!-- What you can access -->
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#f0fdf4;border-radius:12px;border:1px solid #bbf7d0;margin-bottom:24px;">
              <tr><td style="padding:20px 24px;">
                <p style="margin:0 0 12px;font-size:13px;font-weight:700;color:#16a34a;text-transform:uppercase;letter-spacing:1px;">📚 What You Can Access Now</p>
                ${_featureRow('📊', 'View your marks and results')}
                ${_featureRow('📅', 'Check timetable and exam schedule')}
                ${_featureRow('📝', 'View homework and submit queries')}
                ${_featureRow('📚', 'Access study materials and books')}
                ${_featureRow('💰', 'Check your fee status')}
                ${_featureRow('🤖', 'Use AI Tutor for study help')}
                ${_featureRow('💬', 'Chat with your teachers')}
              </td></tr>
            </table>

            <table width="100%" cellpadding="0" cellspacing="0" style="background:#eff6ff;border-left:4px solid #3b82f6;border-radius:8px;margin-bottom:24px;">
              <tr><td style="padding:16px 20px;">
                <p style="margin:0;font-size:13px;color:#1e40af;line-height:1.6;">
                  <strong>📱 Download the App:</strong> Open the BDPHS School App on your device and log in using your registered email and password.
                </p>
              </td></tr>
            </table>

            <p style="margin:0;font-size:14px;color:#555;line-height:1.7;">
              We wish you a wonderful learning journey at BDPHS School!<br>
              <strong>Study hard, dream big, achieve great! 🌟</strong>
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
<body style="margin:0;padding:0;background:#f0f4f8;font-family:'Segoe UI',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f0f4f8;padding:30px 0;">
    <tr><td align="center">
      <table width="600" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">

        <!-- Header -->
        <tr>
          <td style="background:linear-gradient(135deg,#16a34a,#22c55e);padding:36px 40px;text-align:center;">
            <div style="width:64px;height:64px;background:rgba(255,255,255,0.2);border-radius:50%;margin:0 auto 16px;line-height:64px;font-size:32px;">🎉</div>
            <p style="margin:0 0 6px;font-size:13px;color:#bbf7d0;letter-spacing:2px;text-transform:uppercase;">Blooming Dale Public High School</p>
            <h1 style="margin:0;font-size:26px;font-weight:700;color:#ffffff;">Account Approved!</h1>
            <p style="margin:10px 0 0;font-size:14px;color:#dcfce7;">Welcome to the BDPHS Teaching Staff</p>
          </td>
        </tr>

        <!-- Body -->
        <tr>
          <td style="padding:36px 40px;">
            <p style="margin:0 0 8px;font-size:16px;color:#1A3A5C;font-weight:600;">Dear $name,</p>
            <p style="margin:0 0 24px;font-size:14px;color:#555;line-height:1.7;">
              Congratulations! Your teacher account at <strong>BDPHS School</strong> has been <strong style="color:#16a34a;">approved</strong> by the administration. You can now log in and start using all teacher features.
            </p>

            <!-- Credentials Box -->
            <table width="100%" cellpadding="0" cellspacing="0" style="background:linear-gradient(135deg,#1A3A5C,#2E5E8E);border-radius:12px;margin-bottom:24px;">
              <tr><td style="padding:24px;">
                <p style="margin:0 0 16px;font-size:13px;font-weight:700;color:#a8c5e0;text-transform:uppercase;letter-spacing:1px;">🪪 Your Account Details</p>
                <table width="100%" cellpadding="0" cellspacing="0">
                  <tr>
                    <td style="padding:6px 0;font-size:13px;color:#90b8d4;width:130px;">Employee ID:</td>
                    <td style="padding:6px 0;font-size:14px;color:#ffffff;font-weight:700;">$employeeId</td>
                  </tr>
                  <tr>
                    <td style="padding:6px 0;font-size:13px;color:#90b8d4;">Email:</td>
                    <td style="padding:6px 0;font-size:14px;color:#ffffff;font-weight:700;">$email</td>
                  </tr>
                  <tr>
                    <td style="padding:6px 0;font-size:13px;color:#90b8d4;">Subject:</td>
                    <td style="padding:6px 0;font-size:14px;color:#ffffff;font-weight:700;">$subject</td>
                  </tr>
                </table>
              </td></tr>
            </table>

            <!-- Features -->
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#f0fdf4;border-radius:12px;border:1px solid #bbf7d0;margin-bottom:24px;">
              <tr><td style="padding:20px 24px;">
                <p style="margin:0 0 12px;font-size:13px;font-weight:700;color:#16a34a;text-transform:uppercase;letter-spacing:1px;">🛠️ Your Teacher Features</p>
                ${_featureRow('✏️', 'Enter and manage student marks')}
                ${_featureRow('📋', 'Take daily class attendance')}
                ${_featureRow('📝', 'Post homework for your class')}
                ${_featureRow('📊', 'Monthly assessment and reports')}
                ${_featureRow('📚', 'Upload study materials & books')}
                ${_featureRow('✅', 'Approve student leave requests')}
                ${_featureRow('💬', 'Chat with students directly')}
              </td></tr>
            </table>

            <p style="margin:0;font-size:14px;color:#555;line-height:1.7;">
              We are proud to have you as part of the BDPHS teaching community.<br>
              <strong>Together, let's shape the future of our students! 🌟</strong>
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
  }) =>
      '''
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;background:#f0f4f8;font-family:'Segoe UI',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f0f4f8;padding:30px 0;">
    <tr><td align="center">
      <table width="600" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.08);">
        <tr>
          <td style="background:linear-gradient(135deg,#1A3A5C,#2E5E8E);padding:36px 40px;text-align:center;">
            <p style="margin:0 0 6px;font-size:13px;color:#a8c5e0;letter-spacing:2px;text-transform:uppercase;">Blooming Dale Public High School</p>
            <h1 style="margin:0;font-size:24px;font-weight:700;color:#ffffff;">Registration Update</h1>
          </td>
        </tr>
        <tr>
          <td style="padding:36px 40px;">
            <p style="margin:0 0 8px;font-size:16px;color:#1A3A5C;font-weight:600;">Dear $name,</p>
            <p style="margin:0 0 20px;font-size:14px;color:#555;line-height:1.7;">
              We regret to inform you that your $role registration at BDPHS School could not be approved at this time.
            </p>
            ${reason.isNotEmpty ? '''
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#fef2f2;border-left:4px solid #ef4444;border-radius:8px;margin-bottom:20px;">
              <tr><td style="padding:16px 20px;">
                <p style="margin:0;font-size:13px;color:#991b1b;"><strong>Reason:</strong> $reason</p>
              </td></tr>
            </table>
            ''' : ''}
            <p style="margin:0;font-size:14px;color:#555;line-height:1.7;">
              Please contact the school office for further assistance or to re-submit your application with correct information.
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

  // ─── HELPER WIDGETS ────────────────────────────────────────────────────────
  static String _infoRow(String label, String value) => '''
    <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:10px;">
      <tr>
        <td width="140" style="font-size:13px;color:#6b7280;vertical-align:top;">$label:</td>
        <td style="font-size:13px;color:#1A3A5C;font-weight:600;">$value</td>
      </tr>
    </table>
  ''';

  static String _featureRow(String emoji, String text) => '''
    <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:8px;">
      <tr>
        <td width="28" style="font-size:16px;vertical-align:middle;">$emoji</td>
        <td style="font-size:13px;color:#374151;padding-left:8px;">$text</td>
      </tr>
    </table>
  ''';

  static String _footer() => '''
    <tr>
      <td style="background:#f7f9fc;padding:24px 40px;text-align:center;border-top:1px solid #e5e7eb;">
        <p style="margin:0 0 4px;font-size:13px;color:#1A3A5C;font-weight:600;">Blooming Dale Public High School</p>
        <p style="margin:0 0 4px;font-size:12px;color:#6b7280;">Jammu and Kashmir, India</p>
        <p style="margin:0;font-size:12px;color:#6b7280;">📧 bdphschool1@gmail.com</p>
        <p style="margin:12px 0 0;font-size:11px;color:#9ca3af;">This is an automated message from the BDPHS School App. Please do not reply to this email.</p>
      </td>
    </tr>
  ''';
}