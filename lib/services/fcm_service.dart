// lib/services/fcm_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background notification: \${message.notification?.title}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    final settings = await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );
    debugPrint('FCM permission: \${settings.authorizationStatus}');

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground: \${message.notification?.title}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Tapped: \${message.data}');
    });

    final token = await _fcm.getToken();
    debugPrint("✅ FCM Token: $token");
    debugPrint("FCM initialized");
  }

  Future<void> saveTokenToFirestore(String uid, String role) async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;
      final collection = role == 'student' ? 'students' : 'teachers';
      await FirebaseFirestore.instance
          .collection(collection).doc(uid)
          .update({'fcmToken': token, 'tokenUpdatedAt': FieldValue.serverTimestamp()});
      debugPrint('FCM token saved');
    } catch (e) {
      debugPrint('Error saving token: \$e');
    }
  }

  Future<void> subscribeUserTopics({required String role, String? className}) async {
    try { await _fcm.subscribeToTopic('all'); } catch (_) {}
    try { await _fcm.subscribeToTopic(role); } catch (_) {}
    if (role == 'student' && className != null) {
      final topic = className.replaceAll(' ', '_').toLowerCase();
      await _fcm.subscribeToTopic('class_\$topic');
    }
  }
}

class NotificationSender {
  static final _db = FirebaseFirestore.instance;

  static Future<void> notifyClass({
    required String className,
    required String title,
    required String body,
    required String type,
    String? senderId,
    String? senderName,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      await _db.collection('notifications').add({
        'title': title, 'body': body, 'type': type,
        'targetClass': className, 'targetRole': 'student',
        'senderId': senderId, 'senderName': senderName,
        'extraData': extraData ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) { debugPrint('Error: \$e'); }
  }

  static Future<void> notifyUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      await _db.collection('notifications').add({
        'title': title, 'body': body, 'type': type,
        'targetUserId': userId,
        'extraData': extraData ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) { debugPrint('Error: \$e'); }
  }
}
