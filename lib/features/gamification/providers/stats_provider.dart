import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/gamification_stats.dart';
import '../services/stats_service.dart';

/// Provider for StatsService
final statsServiceProvider = Provider<StatsService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return StatsService(authService: authService);
});

// =============================================================================
// My Stats Provider
// =============================================================================

/// Provider for current user's gamification stats
final myStatsProvider = FutureProvider.autoDispose<GamificationStats>((
  ref,
) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated || authState.user == null) {
    return const GamificationStats(
      totalPoints: 0,
      totalChallengesCompleted: 0,
      totalEventsAttended: 0,
      badgesCount: 0,
      rewardsCount: 0,
    );
  }

  final service = ref.watch(statsServiceProvider);
  return service.getMyStats();
});

// =============================================================================
// Game Card Provider
// =============================================================================

/// Provider for user's public game card
final gameCardProvider =
    FutureProvider.autoDispose.family<GameCard, String>((ref, profileId) async {
  final service = ref.watch(statsServiceProvider);
  return service.getGameCard(profileId);
});
