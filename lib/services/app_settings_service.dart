import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppCredential {
  const AppCredential({
    required this.secret,
    required this.isPin,
  });

  final String secret;
  final bool isPin;
}

class AppSettingsService {
  AppSettingsService._();

  static final AppSettingsService instance = AppSettingsService._();
  static const Duration _readTimeout = Duration(seconds: 3);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _settingsRootKey = 'appSettings';
  static const String _pushNotificationsEnabledKey =
      'push_notifications_enabled';
  static const String _inAppNotificationsEnabledKey =
      'in_app_notifications_enabled';
  static const String _appLockEnabledKey = 'app_lock_enabled';
  static const String _skipAppLockOnceKey = 'skip_app_lock_once';
  static const String _appCredentialKey = 'app_credential_secret';
  static const String _appCredentialIsPinKey = 'app_credential_is_pin';

  Future<Map<String, dynamic>> _readSettings() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        return {};
      }

      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(_readTimeout);
      final data = doc.data();
      final settings = data?[_settingsRootKey];

      if (settings is Map<String, dynamic>) {
        return settings;
      }
      if (settings is Map) {
        return Map<String, dynamic>.from(settings);
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeSettings(Map<String, dynamic> updates) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        return;
      }

      final docRef = _firestore.collection('users').doc(uid);
      final flattenedUpdates = <String, dynamic>{
        for (final entry in updates.entries)
          '$_settingsRootKey.${entry.key}': entry.value,
      };

      try {
        await docRef.update(flattenedUpdates);
      } on FirebaseException catch (e) {
        if (e.code == 'not-found') {
          await docRef.set(flattenedUpdates, SetOptions(merge: true));
        } else {
          rethrow;
        }
      }
    } catch (_) {}
  }

  Future<bool> isPushNotificationsEnabled() async {
    final settings = await _readSettings();
    return settings[_pushNotificationsEnabledKey] as bool? ?? true;
  }

  Future<void> setPushNotificationsEnabled(bool enabled) async {
    await _writeSettings({_pushNotificationsEnabledKey: enabled});
  }

  Future<bool> isInAppNotificationsEnabled() async {
    final settings = await _readSettings();
    return settings[_inAppNotificationsEnabledKey] as bool? ?? true;
  }

  Future<void> setInAppNotificationsEnabled(bool enabled) async {
    await _writeSettings({_inAppNotificationsEnabledKey: enabled});
  }

  Future<bool> isAppLockEnabled() async {
    final settings = await _readSettings();
    return settings[_appLockEnabledKey] as bool? ?? true;
  }

  Future<void> setAppLockEnabled(bool enabled) async {
    await _writeSettings({_appLockEnabledKey: enabled});
  }

  Future<bool> shouldSkipAppLockOnce() async {
    final settings = await _readSettings();
    return settings[_skipAppLockOnceKey] as bool? ?? false;
  }

  Future<void> setSkipAppLockOnce(bool enabled) async {
    await _writeSettings({_skipAppLockOnceKey: enabled});
  }

  Future<AppCredential?> getAppCredential() async {
    final settings = await _readSettings();
    final secret = settings[_appCredentialKey] as String?;
    if (secret == null || secret.isEmpty) {
      return null;
    }

    final isPin = settings[_appCredentialIsPinKey] as bool? ?? true;
    return AppCredential(secret: secret, isPin: isPin);
  }

  Future<void> saveAppCredential({
    required String secret,
    required bool isPin,
  }) async {
    await _writeSettings({
      _appCredentialKey: secret,
      _appCredentialIsPinKey: isPin,
    });
  }

  Future<void> clearAppCredential() async {
    await _writeSettings({
      _appCredentialKey: null,
      _appCredentialIsPinKey: null,
    });
  }
}
