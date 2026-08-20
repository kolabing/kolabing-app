import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../services/permission_service.dart';

/// Whether the OS notification permission is currently granted.
///
/// The notification settings screen reads this so its push toggles describe
/// reality: while iOS is suppressing every push, a switch showing "on" is both
/// untrue and — per Apple guideline 4.5.4 — a rejection ("the toggle in the app
/// settings was pre-set to enable notifications").
///
/// Invalidate after raising the system prompt to re-read the decision.
final pushPermissionGrantedProvider = FutureProvider<bool>((ref) async {
  final status = await PermissionService.instance.checkNotificationPermission();
  return status.isGranted;
});
