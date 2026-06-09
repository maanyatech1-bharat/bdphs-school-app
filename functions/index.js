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
