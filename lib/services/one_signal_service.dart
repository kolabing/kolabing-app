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
  String? _currentExternalId;
  void Function(String? type, String? id, String? deeplink)? _onTap;

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

  /// Identify the signed-in user for transactional and targeted messages.
  Future<void> loginUser(UserModel user) async {
    await initialize();

    final externalId = user.id.trim();
    if (externalId.isEmpty) return;

    if (_currentExternalId != externalId) {
      await OneSignal.login(externalId);
      _currentExternalId = externalId;
    }

    await OneSignal.User.addTags(<String, dynamic>{
      'user_type': user.userType.toApiValue(),
      'subscription_status': user.hasActiveSubscription ? 'active' : 'inactive',
    });
  }

  /// Remove the current authenticated user context from OneSignal.
  Future<void> logout() async {
    if (!_initialized) return;

    await OneSignal.logout();
    _currentExternalId = null;
  }

  void _handleNotificationClick(OSNotificationClickEvent event) {
    final data = event.notification.additionalData ?? const <String, dynamic>{};
    final type = data['type']?.toString();
    final id = data['id']?.toString();
    final deeplink =
        data['deeplink']?.toString() ?? event.notification.launchUrl;

    _onTap?.call(
      _normalizeNullable(type),
      _normalizeNullable(id),
      _normalizeNullable(deeplink),
    );
  }

  String? _normalizeNullable(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
