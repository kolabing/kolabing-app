import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/leaderboard.dart';
import '../services/leaderboard_service.dart';

/// Provider for LeaderboardService
final leaderboardServiceProvider = Provider<LeaderboardService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return LeaderboardService(authService: authService);
});

// =============================================================================
// Event Leaderboard Provider
// =============================================================================

/// Parameters for event leaderboard
typedef EventLeaderboardParams = ({String eventId, int limit});

/// Provider for event leaderboard
final eventLeaderboardProvider =
    FutureProvider.family<LeaderboardResponse, EventLeaderboardParams>(
        (ref, params) async {
  final service = ref.watch(leaderboardServiceProvider);
  return service.getEventLeaderboard(params.eventId, limit: params.limit);
});

/// Simplified provider for event leaderboard with default limit
final eventLeaderboardSimpleProvider =
    FutureProvider.family<LeaderboardResponse, String>((ref, eventId) async {
  final service = ref.watch(leaderboardServiceProvider);
  return service.getEventLeaderboard(eventId);
});

// =============================================================================
// Global Leaderboard Provider
// =============================================================================

/// Provider for global leaderboard with default limit
final globalLeaderboardProvider =
    FutureProvider<LeaderboardResponse>((ref) async {
  final service = ref.watch(leaderboardServiceProvider);
  return service.getGlobalLeaderboard();
});

/// Provider for global leaderboard with custom limit
final globalLeaderboardWithLimitProvider =
    FutureProvider.family<LeaderboardResponse, int>((ref, limit) async {
  final service = ref.watch(leaderboardServiceProvider);
  return service.getGlobalLeaderboard(limit: limit);
});
