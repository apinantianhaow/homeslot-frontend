import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../core/client.dart';

/// Firebase Cloud Messaging (SRS 2.5, 3.3).
///
/// Enabled when the app is configured with `flutterfire configure`
/// (google-services.json / GoogleService-Info.plist). Without it the app
/// still works; notifications are shown in the in-app history.
abstract final class PushService {
  static bool enabled = false;
  static StreamSubscription<String>? _tokenRefresh;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      enabled = true;
    } catch (e) {
      debugPrint('Push notifications disabled: $e');
      enabled = false;
    }
  }

  static String get _platform => Platform.isIOS ? 'ios' : 'android';

  /// Asks for permission and registers this device with the server.
  static Future<void> register() async {
    if (!enabled) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token != null) {
        await client.account.registerDevice(token, _platform);
      }
      await _tokenRefresh?.cancel();
      _tokenRefresh = messaging.onTokenRefresh.listen(
        (t) => client.account.registerDevice(t, _platform),
      );
    } catch (e) {
      debugPrint('Push registration failed: $e');
    }
  }

  /// Stops pushes to this device, e.g. before signing out.
  static Future<void> unregister() async {
    if (!enabled) return;
    try {
      await _tokenRefresh?.cancel();
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await client.account.unregisterDevice(token);
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('Push unregistration failed: $e');
    }
  }

  static Stream<RemoteMessage> get foregroundMessages =>
      enabled ? FirebaseMessaging.onMessage : const Stream.empty();
}
