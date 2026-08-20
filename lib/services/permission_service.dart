import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/feature_flags.dart';
import 'notification_service.dart';
import 'one_signal_service.dart';

/// Service for managing app permissions (location & notifications).
class PermissionService {
  const PermissionService._();

  /// Singleton instance
  static const PermissionService instance = PermissionService._();

  // ---------------------------------------------------------------------------
  // Permission Screen Gate
  // ---------------------------------------------------------------------------

  /// Whether the permission screen should be skipped.
  ///
  /// Returns true only when there is nothing left to request. Location is only
  /// part of that answer while the location row is actually shown — otherwise
  /// the app never requests it, so folding it in here would keep the screen
  /// pinned open forever (and would read a permission the screen deliberately
  /// leaves alone).
  Future<bool> hasShownPermissionScreen() async {
    try {
      final notificationStatus = await Permission.notification.status;
      if (!notificationStatus.isGranted) {
        return false;
      }

      if (!kLocationPermissionPromptEnabled) {
        return true;
      }

      final locationStatus = await Permission.locationWhenInUse.status;
      return locationStatus.isGranted;
    } on Exception {
      return false;
    }
  }

  /// No-op kept for API compatibility. The screen is now shown whenever
  /// permissions are not yet granted rather than relying on a stored flag.
  Future<void> markPermissionScreenShown() async {}

  // ---------------------------------------------------------------------------
  // Location Permission
  // ---------------------------------------------------------------------------

  /// Request location permission. Returns the resulting status.
  Future<PermissionStatus> requestLocationPermission() async {
    try {
      final status = await Permission.locationWhenInUse.request();
      debugPrint('[PermissionService] Location permission: $status');
      return status;
    } on Exception catch (e) {
      debugPrint('[PermissionService] Location permission error: $e');
      return PermissionStatus.denied;
    }
  }

  /// Check current location permission status.
  Future<PermissionStatus> checkLocationPermission() async {
    try {
      return await Permission.locationWhenInUse.status;
    } on Exception {
      return PermissionStatus.denied;
    }
  }

  // ---------------------------------------------------------------------------
  // Notification Permission
  // ---------------------------------------------------------------------------

  /// Request notification permission. Returns the resulting status.
  Future<PermissionStatus> requestNotificationPermission() async {
    try {
      try {
        await NotificationService.instance.requestPermission();
      } on Exception catch (e) {
        debugPrint('[PermissionService] FCM permission error: $e');
      }

      await OneSignalService.instance.requestPermission();
      final status = await Permission.notification.status;
      debugPrint('[PermissionService] Notification permission: $status');
      return status;
    } on Exception catch (e) {
      debugPrint('[PermissionService] Notification permission error: $e');
      try {
        final fallbackStatus = await Permission.notification.request();
        debugPrint(
          '[PermissionService] Notification permission fallback: '
          '$fallbackStatus',
        );
        return fallbackStatus;
      } on Exception {
        return PermissionStatus.denied;
      }
    }
  }

  /// Check current notification permission status.
  Future<PermissionStatus> checkNotificationPermission() async {
    try {
      return await Permission.notification.status;
    } on Exception {
      return PermissionStatus.denied;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Open the app settings page (for when permissions are permanently denied).
  Future<bool> openSettings() => openAppSettings();
}
