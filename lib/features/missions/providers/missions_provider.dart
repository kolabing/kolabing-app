import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/mission.dart';
import '../services/missions_service.dart';

/// Provider for [MissionsService].
final missionsServiceProvider = Provider<MissionsService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return MissionsService(authService: authService);
});

/// The signed-in user's missions.
///
/// Exposed as an [AsyncValue] so the screen gets loading / data / error states
/// for free. Refresh via `ref.invalidate(myMissionsProvider)` (used by
/// pull-to-refresh and the error-state retry button).
final myMissionsProvider = FutureProvider<List<Mission>>((ref) async {
  final service = ref.watch(missionsServiceProvider);
  return service.getMyMissions();
});
