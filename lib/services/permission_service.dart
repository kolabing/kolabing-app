import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

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
  /// Returns true only when both location and notification permissions are
  /// already granted — i.e. there is nothing left to request.
  Future<bool> hasShownPermissionScreen() async {
    try {
      final locationStatus = await Permission.locationWhenInUse.status;
      final notificationStatus = await Permission.notification.status;
      return locationStatus.isGranted && notificationStatus.isGranted;
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
      final status = await Permission.notification.request();
      debugPrint('[PermissionService] Notification permission: $status');
      return status;
    } on Exception catch (e) {
      debugPrint('[PermissionService] Notification permission error: $e');
      return PermissionStatus.denied;
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
  Future<bool> openSettings() async {
    return openAppSettings();
  }
}
