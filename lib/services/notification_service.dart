import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}

/// Top-level handler for local notification tap in background/terminated state.
@pragma('vm:entry-point')
void onBackgroundLocalNotificationTap(NotificationResponse response) {
  debugPrint('[FCM] Background local notification tapped: ${response.payload}');
  // Navigation is handled by _checkInitialMessage when app opens.
}

/// Service for Firebase Cloud Messaging push notifications.
///
/// Usage:
///   await NotificationService.instance.initialize();
///   NotificationService.instance.connectRouter(navigateCallback);
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Android notification channel
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'kolabing_default',
    'Kolabing Notifications',
    description: 'Notifications for new applications, messages, and updates.',
    importance: Importance.high,
    playSound: true,
  );

  /// Called when a notification is tapped.
  /// Set this via [connectRouter] to enable deep-link navigation.
  void Function(String type, String? id)? _onNotificationTap;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initialize FCM. Call once from main() after Firebase.initializeApp().
  Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // iOS foreground presentation options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Setup local notifications for foreground display
    await _setupLocalNotifications();

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app was terminated
    await _checkInitialMessage();
  }

  /// Connect GoRouter navigation to notification taps.
  ///
  /// Call after the router is set up in main().
  /// [navigate] receives `(type, id)` from the notification payload.
  void connectRouter(void Function(String type, String? id) navigate) {
    _onNotificationTap = navigate;
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
  void onTokenRefresh(void Function(String token) onToken) {
    _messaging.onTokenRefresh.listen(onToken);
  }

  /// Delete the FCM token from Firebase.
  /// Call on logout so this device stops receiving notifications.
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      debugPrint('[FCM] Token deleted');
    } on Exception catch (e) {
      debugPrint('[FCM] Failed to delete token: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Permission
  // ---------------------------------------------------------------------------

  /// Request notification permission from the user.
  /// iOS shows a dialog; Android 13+ requires this.
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    debugPrint(
      '[FCM] Permission status: ${settings.authorizationStatus}, granted: $granted',
    );

    return granted;
  }

  // ---------------------------------------------------------------------------
  // Private Setup
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
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
      onDidReceiveBackgroundNotificationResponse: onBackgroundLocalNotificationTap,
    );

    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // Delay to allow the router to be ready
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(initialMessage);
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Message Handlers
  // ---------------------------------------------------------------------------

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM] Foreground message: ${message.messageId}');

    final notification = message.notification;
    if (notification == null) return;

    final type = message.data['type'] as String? ?? '';
    final id = message.data['id'] as String? ?? '';
    final payload = '$type|$id';

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.data}');

    final type = message.data['type'] as String?;
    final id = message.data['id'] as String?;

    if (type != null && type.isNotEmpty) {
      _onNotificationTap?.call(type, id?.isNotEmpty ?? false ? id : null);
    }
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint('[FCM] Local notification tapped: ${response.payload}');

    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    final parts = payload.split('|');
    final type = parts.isNotEmpty ? parts[0] : null;
    final id = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;

    if (type != null && type.isNotEmpty) {
      _onNotificationTap?.call(type, id);
    }
  }
}
