import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/badge.dart';
import '../services/badge_service.dart';

/// Provider for BadgeService
final badgeServiceProvider = Provider<BadgeService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return BadgeService(authService: authService);
});

// =============================================================================
// All Badges Provider
// =============================================================================

/// Provider for all system badges
final allBadgesProvider = FutureProvider<BadgesResponse>((ref) async {
  final service = ref.watch(badgeServiceProvider);
  return service.getAllBadges();
});

// =============================================================================
// My Badges Provider
// =============================================================================

/// Provider for user's earned badges
final myBadgesProvider = FutureProvider<MyBadgesResponse>((ref) async {
  final service = ref.watch(badgeServiceProvider);
  return service.getMyBadges();
});
