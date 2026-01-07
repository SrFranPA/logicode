import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static const String _channelId = 'general_channel';

  static Future<void> init() async {
    await _initLocalNotifications();
    await _initFcm();
  }

  static Future<void> _initFcm() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    if (kDebugMode) {
      debugPrint('FCM token: $token');
    }
    if (token != null) {
      await _saveToken(token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen(_saveToken);

    FirebaseMessaging.onMessage.listen((message) {
      if (kDebugMode) {
        debugPrint('FCM foreground: ${message.messageId}');
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (kDebugMode) {
        debugPrint('FCM opened: ${message.messageId}');
      }
    });
  }

  static Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set(
        {
          'fcm_token': token,
          'fcm_tokens': FieldValue.arrayUnion([token]),
          'fcm_token_updated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Ignore token save errors.
    }
  }

  static Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await _local.initialize(initSettings);
  }

  static Future<void> showLivesFull() async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      'General',
      channelDescription: 'Notificaciones generales',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);
    await _local.show(
      1001,
      'Vidas completas',
      'Tus vidas ya estan completas. Puedes seguir jugando.',
      details,
    );
  }

  static Future<void> showStreakWarning() async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      'General',
      channelDescription: 'Notificaciones generales',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);
    await _local.show(
      1002,
      'Racha en riesgo',
      'Completa una leccion hoy para no perder tu racha.',
      details,
    );
  }
}
