import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key for storing whether the permission screen has been shown
const String _permissionScreenShownKey = 'permission_screen_shown';

/// Service for managing app permissions (location & notifications).
class PermissionService {
  const PermissionService._();

  /// Singleton instance
  static const PermissionService instance = PermissionService._();

  // ---------------------------------------------------------------------------
  // Permission Screen Gate
  // ---------------------------------------------------------------------------

  /// Whether the permission screen has already been shown to the user.
  Future<bool> hasShownPermissionScreen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_permissionScreenShownKey) ?? false;
    } on Exception {
      return false;
    }
  }

  /// Mark the permission screen as shown.
  Future<void> markPermissionScreenShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_permissionScreenShownKey, true);
    } on Exception {
      // Silently fail
    }
  }

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
