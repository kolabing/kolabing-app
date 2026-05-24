import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../features/auth/models/user_model.dart';

/// App-wide OneSignal integration layer.
class OneSignalService {
  OneSignalService._();

  static final OneSignalService instance = OneSignalService._();

  static const String _appId = '5fe7283d-a93e-46c7-b12a-f5d88b7c6571';

  bool _initialized = false;
  bool _clickListenerRegistered = false;
  bool _foregroundListenerRegistered = false;
  String? _currentExternalId;
  void Function(String? type, String? id, String? deeplink)? _onTap;
  void Function(OSNotification notification)? _onForegroundNotification;

  /// Initialize the OneSignal SDK once during app startup.
  Future<void> initialize() async {
    if (_initialized) return;

    if (kDebugMode) {
      await OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    }

    await OneSignal.initialize(_appId);
    _initialized = true;
  }

  /// Request native notification permission through OneSignal.
  Future<bool> requestPermission({bool fallbackToSettings = true}) async {
    await initialize();
    return OneSignal.Notifications.requestPermission(fallbackToSettings);
  }

  /// Attach push click events to app navigation.
  Future<void> connectRouter(
    void Function(String? type, String? id, String? deeplink) onTap,
  ) async {
    await initialize();
    _onTap = onTap;

    if (_clickListenerRegistered) return;

    OneSignal.Notifications.addClickListener(_handleNotificationClick);
    _clickListenerRegistered = true;
  }

  /// Route foreground OneSignal pushes through the app's custom presenter.
  Future<void> connectForegroundPresenter(
    void Function(OSNotification notification) onForegroundNotification,
  ) async {
    await initialize();
    _onForegroundNotification = onForegroundNotification;

    if (_foregroundListenerRegistered) return;

    OneSignal.Notifications.addForegroundWillDisplayListener(
      _handleForegroundNotification,
    );
    _foregroundListenerRegistered = true;
  }

  /// Identify the signed-in user for transactional and targeted messages.
  Future<void> loginUser(UserModel user, {bool force = false}) async {
    await initialize();

    final externalId = user.id.trim();
    if (externalId.isEmpty) return;

    if (force || _currentExternalId != externalId) {
      await OneSignal.login(externalId);
      _currentExternalId = externalId;
    }

    await OneSignal.User.addTags(<String, dynamic>{
      'user_type': user.userType.toApiValue(),
      'subscription_status': user.hasActiveSubscription ? 'active' : 'inactive',
    });
  }

  /// Reconnect the current authenticated user after notification permission
  /// becomes available so the push subscription is opted-in and attached.
  Future<void> syncUserAfterPermissionGrant(UserModel user) async {
    await initialize();
    await OneSignal.User.pushSubscription.optIn();
    await loginUser(user, force: true);
  }

  /// Remove the current authenticated user context from OneSignal.
  Future<void> logout() async {
    if (!_initialized) return;

    await OneSignal.logout();
    _currentExternalId = null;
  }

  void _handleNotificationClick(OSNotificationClickEvent event) {
    final data = event.notification.additionalData ?? const <String, dynamic>{};
    final type = _normalizeNullable(data['type']?.toString());
    final id = _normalizeNullable(data['id']?.toString());
    final deeplink = _resolveActionDeeplink(
      actionId: event.result.actionId,
      type: type,
      id: id,
      deeplink:
          data['deeplink']?.toString() ??
          event.result.url ??
          event.notification.launchUrl,
      actionDeeplinks: _parseActionDeeplinks(
        data['action_deeplinks'],
        rawValues: data,
      ),
    );

    _onTap?.call(type, id, _normalizeNullable(deeplink));
  }

  void _handleForegroundNotification(OSNotificationWillDisplayEvent event) {
    event.preventDefault();
    _onForegroundNotification?.call(event.notification);
  }

  String? _normalizeNullable(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
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
      'open_message_thread' => normalizedDeeplink ?? _defaultChatDeeplink(id),
      'view_application' =>
        normalizedDeeplink ?? _defaultApplicationDeeplink(id),
      'open_app' => normalizedDeeplink ?? _defaultDeeplinkForType(type, id),
      'open_notifications' => '/notifications',
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
        'open_message_thread': flatValues['action_open_message_thread_deeplink']
            ?.toString(),
      if (_normalizeNullable(
            flatValues['action_view_application_deeplink']?.toString(),
          ) !=
          null)
        'view_application': flatValues['action_view_application_deeplink']
            ?.toString(),
      if (_normalizeNullable(
            flatValues['action_open_app_deeplink']?.toString(),
          ) !=
          null)
        'open_app': flatValues['action_open_app_deeplink']?.toString(),
      if (_normalizeNullable(
            flatValues['action_open_notifications_deeplink']?.toString(),
          ) !=
          null)
        'open_notifications': flatValues['action_open_notifications_deeplink']
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

  String? _defaultDeeplinkForType(String? type, String? id) => switch (type) {
    'new_message' => _defaultChatDeeplink(id),
    'application_received' ||
    'application_accepted' ||
    'application_declined' => _defaultApplicationDeeplink(id),
    _ => '/notifications',
  };

  String _defaultChatDeeplink(String? id) {
    final normalizedId = _normalizeNullable(id);
    return normalizedId == null
        ? '/notifications'
        : '/application/$normalizedId/chat';
  }

  String _defaultApplicationDeeplink(String? id) {
    final normalizedId = _normalizeNullable(id);
    return normalizedId == null
        ? '/notifications'
        : '/application/$normalizedId';
  }
}
