import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'one_signal_service.dart';

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
///   NotificationService.instance.registerNotificationTapHandler(
///     navigateCallback,
///   );
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

  static const String _messagesCategory = 'kolabing_messages';
  static const String _applicationsCategory = 'kolabing_applications';
  static const String _generalCategory = 'kolabing_general';
  static const String _messagesPrimaryActionId = 'open_message_thread';
  static const String _applicationsPrimaryActionId = 'view_application';
  static const String _generalPrimaryActionId = 'open_app';
  static const String _notificationsActionId = 'open_notifications';

  /// Called when a notification is tapped.
  /// Set this via [connectRouter] to enable deep-link navigation.
  void Function(String? type, String? id, String? deeplink)? _onNotificationTap;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initialize FCM. Call once from main() after Firebase.initializeApp().
  Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // We render foreground iOS notifications ourselves to avoid duplicate
    // system + local banners while still keeping custom metadata.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    // Setup local notifications for foreground display
    await _setupLocalNotifications();

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await OneSignalService.instance.connectForegroundPresenter(
        _handleOneSignalForegroundNotification,
      );
    }

    // Handle notification tap when app is in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app was terminated
    await _checkInitialMessage();
  }

  /// Connect GoRouter navigation to notification taps.
  ///
  /// Call after the router is set up in main().
  /// [navigate] receives `(type, id, deeplink)` from the notification payload.
  void registerNotificationTapHandler(
    void Function(String? type, String? id, String? deeplink) navigate,
  ) {
    if (_onNotificationTap == navigate) {
      return;
    }

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
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: false,
      defaultPresentBadge: false,
      defaultPresentSound: false,
      defaultPresentBanner: false,
      defaultPresentList: false,
      notificationCategories: <DarwinNotificationCategory>[
        DarwinNotificationCategory(
          _messagesCategory,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              _messagesPrimaryActionId,
              'Open Chat',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              _notificationsActionId,
              'Notifications',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
          options: <DarwinNotificationCategoryOption>{
            DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
            DarwinNotificationCategoryOption.hiddenPreviewShowSubtitle,
          },
        ),
        DarwinNotificationCategory(
          _applicationsCategory,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              _applicationsPrimaryActionId,
              'View Application',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              _notificationsActionId,
              'Notifications',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
          options: <DarwinNotificationCategoryOption>{
            DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
            DarwinNotificationCategoryOption.hiddenPreviewShowSubtitle,
          },
        ),
        DarwinNotificationCategory(
          _generalCategory,
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              _generalPrimaryActionId,
              'Open',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              _notificationsActionId,
              'Notifications',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
          options: <DarwinNotificationCategoryOption>{
            DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
            DarwinNotificationCategoryOption.hiddenPreviewShowSubtitle,
          },
        ),
      ],
    );

    await _localNotifications.initialize(
      InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundLocalNotificationTap,
    );

    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
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

    final type = message.data['type']?.toString() ?? '';
    final id = message.data['id']?.toString() ?? '';
    final deeplink = message.data['deeplink']?.toString();
    final title =
        message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    await _showForegroundNotification(
      notificationId: message.hashCode,
      title: title,
      body: body,
      type: type,
      id: id,
      deeplink: deeplink,
      subtitle: message.data['subtitle']?.toString(),
      threadIdentifier: message.data['thread_id']?.toString(),
      categoryIdentifier: message.data['category']?.toString(),
      interruptionLevel: _parseInterruptionLevel(
        message.data['interruption_level']?.toString(),
      ),
      badgeNumber: _parseBadgeNumber(message.data['badge']),
      attachmentUrl: _extractAttachmentUrl(
        message.data['ios_attachments'] ??
            message.data['image_url'] ??
            message.data['attachment_url'] ??
            message.data['image'],
      ),
      actionDeeplinks: _parseActionDeeplinks(
        message.data['action_deeplinks'],
        rawValues: message.data,
      ),
    );
  }

  Future<void> _handleOneSignalForegroundNotification(
    OSNotification notification,
  ) async {
    debugPrint(
      '[OneSignal] Foreground notification: ${notification.notificationId}',
    );

    final data = notification.additionalData ?? const <String, dynamic>{};
    final type = data['type']?.toString() ?? '';
    final id = data['id']?.toString() ?? '';
    final deeplink = data['deeplink']?.toString() ?? notification.launchUrl;
    final title = notification.title ?? data['title']?.toString();
    final body = notification.body ?? data['body']?.toString();
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    await _showForegroundNotification(
      notificationId: notification.notificationId.hashCode,
      title: title,
      body: body,
      type: type,
      id: id,
      deeplink: deeplink,
      subtitle: notification.subtitle ?? data['subtitle']?.toString(),
      threadIdentifier: data['thread_id']?.toString(),
      categoryIdentifier: notification.category ?? data['category']?.toString(),
      interruptionLevel: _parseInterruptionLevel(
        notification.interruptionLevel,
      ),
      badgeNumber: notification.badge ?? _parseBadgeNumber(data['badge']),
      attachmentUrl: _extractAttachmentUrl(
        notification.attachments ??
            data['ios_attachments'] ??
            data['image_url'] ??
            data['attachment_url'] ??
            data['image'],
      ),
      actionDeeplinks: _parseActionDeeplinks(
        data['action_deeplinks'],
        rawValues: data,
      ),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.data}');

    final type = message.data['type']?.toString();
    final id = message.data['id']?.toString();
    final deeplink = message.data['deeplink']?.toString();

    if ((type?.isNotEmpty ?? false) || (deeplink?.isNotEmpty ?? false)) {
      _onNotificationTap?.call(
        type,
        id?.isNotEmpty ?? false ? id : null,
        deeplink?.isNotEmpty ?? false ? deeplink : null,
      );
    }
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint('[FCM] Local notification tapped: ${response.payload}');

    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    final decoded = _parseLocalNotificationPayload(payload);
    final type = _normalizeNullable(decoded['type']?.toString());
    final id = _normalizeNullable(decoded['id']?.toString());
    final deeplink = _resolveActionDeeplink(
      actionId:
          response.notificationResponseType ==
              NotificationResponseType.selectedNotificationAction
          ? response.actionId
          : null,
      type: type,
      id: id,
      deeplink: decoded['deeplink']?.toString(),
      actionDeeplinks: _parseActionDeeplinks(decoded['action_deeplinks']),
    );

    if ((type?.isNotEmpty ?? false) || (deeplink?.isNotEmpty ?? false)) {
      _onNotificationTap?.call(type, id, deeplink);
    }
  }

  String _buildLocalNotificationPayload({
    String? type,
    String? id,
    String? deeplink,
    Map<String, String?> actionDeeplinks = const <String, String?>{},
  }) => jsonEncode(<String, Object?>{
    if (type != null && type.isNotEmpty) 'type': type,
    if (id != null && id.isNotEmpty) 'id': id,
    if (deeplink != null && deeplink.isNotEmpty) 'deeplink': deeplink,
    if (actionDeeplinks.isNotEmpty)
      'action_deeplinks': <String, String>{
        for (final entry in actionDeeplinks.entries)
          if (_normalizeNullable(entry.value) != null) entry.key: entry.value!,
      },
  });

  Map<String, dynamic> _parseLocalNotificationPayload(String payload) {
    try {
      return jsonDecode(payload) as Map<String, dynamic>;
    } on FormatException {
      final parts = payload.split('|');
      return <String, dynamic>{
        'type': parts.isNotEmpty ? parts[0] : null,
        'id': parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null,
        'deeplink': null,
        'action_deeplinks': const <String, String>{},
      };
    }
  }

  Future<void> _showForegroundNotification({
    required int notificationId,
    required String? title,
    required String? body,
    String? type,
    String? id,
    String? deeplink,
    String? subtitle,
    String? threadIdentifier,
    String? categoryIdentifier,
    InterruptionLevel? interruptionLevel,
    int? badgeNumber,
    String? attachmentUrl,
    Map<String, String?> actionDeeplinks = const <String, String?>{},
  }) async {
    final normalizedType = _normalizeNullable(type);
    final normalizedId = _normalizeNullable(id);
    final normalizedDeeplink = _normalizeNullable(deeplink);
    final normalizedTitle = _normalizeNullable(title);
    final normalizedBody = _normalizeNullable(body);

    if (normalizedTitle == null && normalizedBody == null) {
      return;
    }

    final resolvedThreadIdentifier =
        _normalizeNullable(threadIdentifier) ??
        _defaultThreadIdentifier(normalizedType, normalizedId);
    final resolvedCategoryIdentifier =
        _normalizeNullable(categoryIdentifier) ??
        _defaultCategoryIdentifier(normalizedType);
    final resolvedSubtitle =
        _normalizeNullable(subtitle) ?? _defaultSubtitle(normalizedType);
    final resolvedInterruptionLevel =
        interruptionLevel ?? _defaultInterruptionLevel(normalizedType);
    final resolvedActionDeeplinks = <String, String?>{
      ..._defaultActionDeeplinks(
        categoryIdentifier: resolvedCategoryIdentifier,
        type: normalizedType,
        id: normalizedId,
        deeplink: normalizedDeeplink,
      ),
      ...actionDeeplinks,
    };
    final attachments = await _buildDarwinAttachments(attachmentUrl);

    await _localNotifications.show(
      notificationId,
      normalizedTitle,
      normalizedBody,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentList: true,
          presentBadge: badgeNumber != null,
          presentSound: true,
          badgeNumber: badgeNumber,
          attachments: attachments,
          subtitle: resolvedSubtitle,
          threadIdentifier: resolvedThreadIdentifier,
          categoryIdentifier: resolvedCategoryIdentifier,
          interruptionLevel: resolvedInterruptionLevel,
        ),
      ),
      payload: _buildLocalNotificationPayload(
        type: normalizedType,
        id: normalizedId,
        deeplink: normalizedDeeplink,
        actionDeeplinks: resolvedActionDeeplinks,
      ),
    );
  }

  String _defaultSubtitle(String? type) {
    switch (type) {
      case 'new_message':
        return 'Messages';
      case 'application_received':
        return 'New application';
      case 'application_accepted':
      case 'application_declined':
        return 'Application update';
      default:
        return 'Kolabing';
    }
  }

  String _defaultThreadIdentifier(String? type, String? id) {
    switch (type) {
      case 'new_message':
        return id != null ? 'messages_$id' : 'messages';
      case 'application_received':
      case 'application_accepted':
      case 'application_declined':
        return id != null ? 'applications_$id' : 'applications';
      default:
        return 'kolabing_general';
    }
  }

  String _defaultCategoryIdentifier(String? type) {
    switch (type) {
      case 'new_message':
        return _messagesCategory;
      case 'application_received':
      case 'application_accepted':
      case 'application_declined':
        return _applicationsCategory;
      default:
        return _generalCategory;
    }
  }

  InterruptionLevel _defaultInterruptionLevel(String? type) {
    switch (type) {
      case 'new_message':
      case 'application_received':
      case 'application_accepted':
      case 'application_declined':
        return InterruptionLevel.active;
      default:
        return InterruptionLevel.passive;
    }
  }

  InterruptionLevel? _parseInterruptionLevel(String? rawValue) {
    switch (_normalizeNullable(rawValue)?.toLowerCase()) {
      case 'active':
        return InterruptionLevel.active;
      case 'passive':
        return InterruptionLevel.passive;
      case 'time-sensitive':
      case 'time_sensitive':
      case 'timesensitive':
        return InterruptionLevel.timeSensitive;
      case 'critical':
        // Critical alerts require a separate Apple entitlement. Until the app
        // is provisioned for that, keep the foreground presentation safe.
        return InterruptionLevel.active;
      default:
        return null;
    }
  }

  int? _parseBadgeNumber(Object? rawValue) {
    if (rawValue == null) {
      return null;
    }

    if (rawValue is int) {
      return rawValue;
    }

    return int.tryParse(rawValue.toString());
  }

  String? _normalizeNullable(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  Map<String, String?> _defaultActionDeeplinks({
    required String categoryIdentifier,
    String? type,
    String? id,
    String? deeplink,
  }) {
    final resolvedDefaultDeeplink = _normalizeNullable(deeplink);

    switch (categoryIdentifier) {
      case _messagesCategory:
        return <String, String?>{
          _messagesPrimaryActionId:
              resolvedDefaultDeeplink ?? _defaultChatDeeplink(id),
          _notificationsActionId: '/notifications',
        };
      case _applicationsCategory:
        return <String, String?>{
          _applicationsPrimaryActionId:
              resolvedDefaultDeeplink ?? _defaultApplicationDeeplink(id),
          _notificationsActionId: '/notifications',
        };
      case _generalCategory:
      default:
        return <String, String?>{
          _generalPrimaryActionId:
              resolvedDefaultDeeplink ?? _defaultDeeplinkForType(type, id),
          _notificationsActionId: '/notifications',
        };
    }
  }

  String? _resolveActionDeeplink({
    String? actionId,
    String? type,
    String? id,
    String? deeplink,
    Map<String, String?> actionDeeplinks = const <String, String?>{},
  }) {
    final normalizedActionId = _normalizeNullable(actionId);
    final normalizedDeeplink = _normalizeNullable(deeplink);

    if (normalizedActionId == null) {
      return normalizedDeeplink;
    }

    final explicitDeeplink = _normalizeNullable(
      actionDeeplinks[normalizedActionId],
    );
    if (explicitDeeplink != null) {
      return explicitDeeplink;
    }

    return switch (normalizedActionId) {
      _messagesPrimaryActionId =>
        normalizedDeeplink ?? _defaultChatDeeplink(id),
      _applicationsPrimaryActionId =>
        normalizedDeeplink ?? _defaultApplicationDeeplink(id),
      _generalPrimaryActionId =>
        normalizedDeeplink ?? _defaultDeeplinkForType(type, id),
      _notificationsActionId => '/notifications',
      _ => normalizedDeeplink,
    };
  }

  Map<String, String?> _parseActionDeeplinks(
    Object? rawValue, {
    Map<String, dynamic>? rawValues,
  }) {
    final parsed = _coerceStringMap(rawValue);
    final flatValues = rawValues ?? const <String, dynamic>{};

    return <String, String?>{
      ...parsed,
      if (_normalizeNullable(
            flatValues['action_open_message_thread_deeplink']?.toString(),
          ) !=
          null)
        _messagesPrimaryActionId:
            flatValues['action_open_message_thread_deeplink']?.toString(),
      if (_normalizeNullable(
            flatValues['action_view_application_deeplink']?.toString(),
          ) !=
          null)
        _applicationsPrimaryActionId:
            flatValues['action_view_application_deeplink']?.toString(),
      if (_normalizeNullable(
            flatValues['action_open_app_deeplink']?.toString(),
          ) !=
          null)
        _generalPrimaryActionId: flatValues['action_open_app_deeplink']
            ?.toString(),
      if (_normalizeNullable(
            flatValues['action_open_notifications_deeplink']?.toString(),
          ) !=
          null)
        _notificationsActionId: flatValues['action_open_notifications_deeplink']
            ?.toString(),
    };
  }

  Map<String, String?> _coerceStringMap(Object? rawValue) {
    if (rawValue == null) {
      return const <String, String?>{};
    }

    if (rawValue is Map<Object?, Object?>) {
      return <String, String?>{
        for (final entry in rawValue.entries)
          if (_normalizeNullable(entry.key?.toString()) != null)
            entry.key!.toString(): entry.value?.toString(),
      };
    }

    if (rawValue is String) {
      final normalized = _normalizeNullable(rawValue);
      if (normalized == null) {
        return const <String, String?>{};
      }

      try {
        final decoded = jsonDecode(normalized);
        return _coerceStringMap(decoded);
      } on FormatException {
        return const <String, String?>{};
      }
    }

    return const <String, String?>{};
  }

  String? _extractAttachmentUrl(Object? rawValue) {
    if (rawValue == null) {
      return null;
    }

    if (rawValue is String) {
      final normalized = _normalizeNullable(rawValue);
      if (normalized == null) {
        return null;
      }

      if (normalized.startsWith('{') || normalized.startsWith('[')) {
        try {
          return _extractAttachmentUrl(jsonDecode(normalized));
        } on FormatException {
          return normalized;
        }
      }

      return normalized;
    }

    if (rawValue is Map<Object?, Object?>) {
      for (final preferredKey in <String>['url', 'image', 'href']) {
        final value = rawValue[preferredKey];
        final normalized = _extractAttachmentUrl(value);
        if (normalized != null) {
          return normalized;
        }
      }

      for (final value in rawValue.values) {
        final normalized = _extractAttachmentUrl(value);
        if (normalized != null) {
          return normalized;
        }
      }
    }

    if (rawValue is Iterable<Object?>) {
      for (final value in rawValue) {
        final normalized = _extractAttachmentUrl(value);
        if (normalized != null) {
          return normalized;
        }
      }
    }

    return null;
  }

  Future<List<DarwinNotificationAttachment>?> _buildDarwinAttachments(
    String? attachmentUrl,
  ) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return null;
    }

    final normalizedUrl = _normalizeNullable(attachmentUrl);
    if (normalizedUrl == null) {
      return null;
    }

    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return null;
    }

    try {
      final response = await http.get(uri);
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          response.bodyBytes.isEmpty) {
        debugPrint(
          '[Push] Attachment download failed: ${response.statusCode} for $normalizedUrl',
        );
        return null;
      }

      final file = File(
        '${Directory.systemTemp.path}/kolabing_push_${DateTime.now().microsecondsSinceEpoch}${_attachmentFileExtension(uri, response.headers['content-type'])}',
      );
      await file.writeAsBytes(response.bodyBytes, flush: true);

      return <DarwinNotificationAttachment>[
        DarwinNotificationAttachment(file.path),
      ];
    } on Exception catch (e) {
      debugPrint('[Push] Failed to build iOS attachment: $e');
      return null;
    }
  }

  String _attachmentFileExtension(Uri uri, String? contentType) {
    final lastSegment = uri.pathSegments.isEmpty
        ? ''
        : uri.pathSegments.last.toLowerCase();
    for (final extension in <String>[
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.mp4',
      '.mov',
    ]) {
      if (lastSegment.endsWith(extension)) {
        return extension;
      }
    }

    return switch (contentType?.split(';').first.trim().toLowerCase()) {
      'image/png' => '.png',
      'image/gif' => '.gif',
      'video/mp4' => '.mp4',
      'video/quicktime' => '.mov',
      _ => '.jpg',
    };
  }

  String? _defaultDeeplinkForType(String? type, String? id) => switch (type) {
    'new_message' => _defaultChatDeeplink(id),
    'application_received' ||
    'application_accepted' ||
    'application_declined' => _defaultApplicationDeeplink(id),
    _ => '/notifications',
  };

  String? _defaultChatDeeplink(String? id) {
    final normalizedId = _normalizeNullable(id);
    return normalizedId == null
        ? '/notifications'
        : '/application/$normalizedId/chat';
  }

  String? _defaultApplicationDeeplink(String? id) {
    final normalizedId = _normalizeNullable(id);
    return normalizedId == null
        ? '/notifications'
        : '/application/$normalizedId';
  }
}
