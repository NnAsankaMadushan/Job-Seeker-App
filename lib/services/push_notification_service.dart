import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    await _requestMessagingPermission();
    await _setupMessageHandlers();
    await _registerDeviceToken();
    _watchAuthStateForTokenUpdates();
    _watchTokenRefresh();

    _initialized = true;
  }

  Future<void> _requestMessagingPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    debugPrint('FCM permission status: ${settings.authorizationStatus}');
  }

  Future<void> _setupMessageHandlers() async {
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground message received: ${message.messageId}');
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Notification opened: ${message.messageId}');
    });
  }

  Future<void> _registerDeviceToken() async {
    final token = await _messaging.getToken();
    debugPrint('FCM device token: $token');

    if (token == null) {
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }

    await _saveTokenToFirestore(token, currentUser.uid);
  }

  void _watchAuthStateForTokenUpdates() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _registerDeviceToken();
      }
    });
  }

  void _watchTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _saveTokenToFirestore(newToken, currentUser.uid);
      }
    });
  }

  Future<void> _saveTokenToFirestore(String token, String uid) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(
        {
          'fcmTokens': FieldValue.arrayUnion([token]),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }
}
