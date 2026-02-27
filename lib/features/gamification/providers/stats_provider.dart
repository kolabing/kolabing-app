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
final myStatsProvider = FutureProvider<GamificationStats>((ref) async {
  final service = ref.watch(statsServiceProvider);
  return service.getMyStats();
});

// =============================================================================
// Game Card Provider
// =============================================================================

/// Provider for user's public game card
final gameCardProvider =
    FutureProvider.family<GameCard, String>((ref, profileId) async {
  final service = ref.watch(statsServiceProvider);
  return service.getGameCard(profileId);
});
