import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}

/// Service for Firebase Cloud Messaging push notifications
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Android notification channel for high-importance notifications
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'kolabing_high_importance',
    'Kolabing Notifications',
    description: 'Notifications for new applications, messages, and updates.',
    importance: Importance.high,
  );

  /// Callback for notification tap → navigation
  void Function(Map<String, dynamic> data)? onNotificationTap;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initialize FCM. Call once from main() after Firebase.initializeApp().
  Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // iOS foreground presentation options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Setup local notifications for foreground display on Android
    await _setupLocalNotifications();

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background (but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app was terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  // ---------------------------------------------------------------------------
  // Token Management
  // ---------------------------------------------------------------------------

  /// Get the current FCM token. Returns null if not available.
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('[FCM] Token: $token');
      return token;
    } on Exception catch (e) {
      debugPrint('[FCM] Failed to get token: $e');
      return null;
    }
  }

  /// Subscribe to token refresh events.
  /// Call [onToken] whenever a new token is issued.
  void onTokenRefresh(void Function(String token) onToken) {
    _messaging.onTokenRefresh.listen(onToken);
  }

  // ---------------------------------------------------------------------------
  // Foreground Notifications
  // ---------------------------------------------------------------------------

  Future<void> _setupLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        debugPrint('[FCM] Local notification tapped: ${response.payload}');
      },
    );

    // Create Android channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM] Foreground message: ${message.messageId}');

    final notification = message.notification;
    if (notification == null) return;

    if (Platform.isAndroid) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.data}');
    onNotificationTap?.call(message.data);
  }
}
