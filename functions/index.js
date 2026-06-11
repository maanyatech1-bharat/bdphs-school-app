const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getMessaging} = require("firebase-admin/messaging");
const {getFirestore} = require("firebase-admin/firestore");

initializeApp();

exports.onHomeworkPosted = onDocumentCreated("homework/{homeworkId}", async (event) => {
  const homework = event.data.data();
  if (!homework) return;
  const className = homework.className;
  const subject = homework.subject;
  const isUrgent = homework.isUrgent || false;
  const description = homework.description || "New homework posted";
  try {
    const db = getFirestore();
    const snap = await db.collection("students").where("className", "==", className).where("approvalStatus", "==", "approved").get();
    const tokens = [];
    snap.forEach((doc) => { const t = doc.data().fcmToken; if (t) tokens.push(t); });
    if (tokens.length === 0) { console.log("No tokens for class:", className); return; }
    const title = isUrgent ? "Urgent Homework - " + subject : "New Homework - " + subject;
    const body = description.length > 100 ? description.substring(0, 100) + "..." : description;
    const response = await getMessaging().sendEachForMulticast({notification: {title, body}, data: {type: "homework", className, subject}, tokens});
    console.log("Homework notifications sent:", response.successCount);
  } catch (e) { console.error("Error:", e); }
});

exports.onNoticePosted = onDocumentCreated("notices/{noticeId}", async (event) => {
  const notice = event.data.data();
  if (!notice) return;
  try {
    const db = getFirestore();
    const snap = await db.collection("students").where("approvalStatus", "==", "approved").get();
    const tokens = [];
    snap.forEach((doc) => { const t = doc.data().fcmToken; if (t) tokens.push(t); });
    if (tokens.length === 0) return;
    const response = await getMessaging().sendEachForMulticast({notification: {title: "New Notice - " + (notice.title || "BDPHS"), body: notice.content || "A new notice has been posted"}, data: {type: "notice"}, tokens});
    console.log("Notice notifications sent:", response.successCount);
  } catch (e) { console.error("Error:", e); }
});

exports.onMarksUploaded = onDocumentCreated("marks/{markId}", async (event) => {
  const mark = event.data.data();
  if (!mark) return;
  try {
    const db = getFirestore();
    const snap = await db.collection("students").where("className", "==", mark.className).where("approvalStatus", "==", "approved").get();
    const tokens = [];
    snap.forEach((doc) => { const t = doc.data().fcmToken; if (t) tokens.push(t); });
    if (tokens.length === 0) return;
    const response = await getMessaging().sendEachForMulticast({notification: {title: "Marks Published - " + (mark.subject || "Subject"), body: (mark.examType || "Exam") + " marks for " + mark.className + " uploaded!"}, data: {type: "marks"}, tokens});
    console.log("Marks notifications sent:", response.successCount);
  } catch (e) { console.error("Error:", e); }
});


const {onDocumentUpdated} = require("firebase-functions/v2/firestore");

exports.onLeaveStatusChanged = onDocumentUpdated("leaves/{leaveId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!before || !after) return;
  // Only notify when status changes from pending to approved/rejected
  if (before.status !== "pending") return;
  if (after.status !== "approved" && after.status !== "rejected") return;
  const applicantId = after.applicantId;
  const applicantRole = after.applicantRole || "teacher";
  if (!applicantId) return;
  try {
    const db = getFirestore();
    const collection = applicantRole === "student" ? "students" : "teachers";
    const doc = await db.collection(collection).doc(applicantId).get();
    const token = doc.exists ? doc.data().fcmToken : null;
    if (!token) { console.log("No token for applicant:", applicantId); return; }
    const approved = after.status === "approved";
    await getMessaging().send({
      notification: {
        title: approved ? "Leave Approved" : "Leave Rejected",
        body: approved ? "Your leave request has been approved." : "Your leave request has been rejected." + (after.adminRemark ? " Remark: " + after.adminRemark : ""),
      },
      data: {type: "leave", status: after.status},
      token,
    });
    console.log("Leave notification sent to:", applicantId);
  } catch (e) { console.error("Leave notification error:", e); }
});

exports.onMeetingScheduled = onDocumentCreated("meetings/{meetingId}", async (event) => {
  const meeting = event.data.data();
  if (!meeting) return;
  const className = meeting.className;
  const title = meeting.title || "Meeting";
  const teacherName = meeting.teacherName || "";
  try {
    const db = getFirestore();
    const tokens = [];
    if (className && className !== "All" && className !== "Staff") {
      // Meeting for a specific class - notify students
      const snap = await db.collection("students").where("className", "==", className).where("approvalStatus", "==", "approved").get();
      snap.forEach((doc) => { const t = doc.data().fcmToken; if (t) tokens.push(t); });
    } else {
      // Staff/All meeting - notify all teachers
      const snap = await db.collection("teachers").where("approvalStatus", "==", "approved").get();
      snap.forEach((doc) => { const t = doc.data().fcmToken; if (t) tokens.push(t); });
    }
    if (tokens.length === 0) { console.log("No tokens for meeting:", title); return; }
    await getMessaging().sendEachForMulticast({
      notification: {
        title: "Meeting Scheduled - " + title,
        body: (teacherName ? teacherName + " scheduled a meeting" : "A meeting has been scheduled") + (className ? " for " + className : ""),
      },
      data: {type: "meeting"},
      tokens,
    });
    console.log("Meeting notifications sent:", tokens.length);
  } catch (e) { console.error("Meeting notification error:", e); }
});
