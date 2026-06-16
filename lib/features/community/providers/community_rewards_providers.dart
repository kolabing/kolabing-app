import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/community_rewards.dart';
import '../services/community_rewards_service.dart';

/// Hard ceiling for a Rewards-tab read. Whatever hangs underneath (token read,
/// a socket that never returns, a route that doesn't respond), the section
/// resolves to its empty state instead of spinning forever.
const Duration _kRewardsReadTimeout = Duration(seconds: 12);

/// DI for [CommunityRewardsService].
final communityRewardsServiceProvider =
    Provider<CommunityRewardsService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return CommunityRewardsService(authService: authService);
});

// =============================================================================
// Member view — the rewards hub. A Notifier (not FutureProvider) so `reload()`
// sets state directly: the community widgets live in the role IndexedStack and
// are kept alive, where a plain `invalidate` does NOT reliably recompute a
// kept-alive FutureProvider (documented in community_providers.dart). Keyed per
// communityId. A null value = endpoint not deployed yet (self-gated).
// =============================================================================

class CommunityRewardsHubNotifier
    extends Notifier<AsyncValue<CommunityRewardsHub?>> {
  CommunityRewardsHubNotifier(this.communityId);

  final String communityId;

  @override
  AsyncValue<CommunityRewardsHub?> build() {
    Future.microtask(reload);
    return const AsyncLoading();
  }

  // Re-entrancy guard — see CommunityRewardsAdminNotifier.reloadAll. build() and
  // the screen's initState both trigger a reload; only one runs at a time.
  bool _reloading = false;

  Future<void> reload() async {
    if (_reloading) {
      debugPrint('🎯 RewardsHub($communityId) reload SKIP (in-flight)');
      return;
    }
    _reloading = true;
    debugPrint('🎯 RewardsHub($communityId) reload START');
    state = const AsyncLoading();
    try {
      state = await AsyncValue.guard(
          () => ref
              .read(communityRewardsServiceProvider)
              .getRewardsHub(communityId)
              .timeout(_kRewardsReadTimeout, onTimeout: () => null));
    } finally {
      _reloading = false;
    }
    debugPrint(
        '🎯 RewardsHub($communityId) reload END -> ${state.runtimeType} hasValue=${state.hasValue} value=${state.asData?.value == null ? "null(coming-soon)" : "hub"} err=${state.error}');
  }
}

final communityRewardsHubProvider = NotifierProvider.family<
    CommunityRewardsHubNotifier, AsyncValue<CommunityRewardsHub?>, String>(
  CommunityRewardsHubNotifier.new,
);

// =============================================================================
// Leader view — goals / rewards / badges CRUD lists. One Notifier per community
// holds all three; each list self-gates to [] when the route isn't deployed.
// =============================================================================

class CommunityRewardsAdminState {
  const CommunityRewardsAdminState({
    required this.goals,
    required this.rewards,
    required this.badges,
  });

  final AsyncValue<List<CommunityGoal>> goals;
  final AsyncValue<List<CommunityReward>> rewards;
  final AsyncValue<List<CommunityBadge>> badges;

  static const initial = CommunityRewardsAdminState(
    goals: AsyncLoading<List<CommunityGoal>>(),
    rewards: AsyncLoading<List<CommunityReward>>(),
    badges: AsyncLoading<List<CommunityBadge>>(),
  );

  CommunityRewardsAdminState copyWith({
    AsyncValue<List<CommunityGoal>>? goals,
    AsyncValue<List<CommunityReward>>? rewards,
    AsyncValue<List<CommunityBadge>>? badges,
  }) =>
      CommunityRewardsAdminState(
        goals: goals ?? this.goals,
        rewards: rewards ?? this.rewards,
        badges: badges ?? this.badges,
      );
}

class CommunityRewardsAdminNotifier
    extends Notifier<CommunityRewardsAdminState> {
  CommunityRewardsAdminNotifier(this.communityId);

  final String communityId;

  CommunityRewardsService get _svc =>
      ref.read(communityRewardsServiceProvider);

  @override
  CommunityRewardsAdminState build() {
    Future.microtask(reloadAll);
    return CommunityRewardsAdminState.initial;
  }

  // Re-entrancy guard. build() schedules reloadAll AND the screen's initState
  // calls it on open; running both concurrently makes the three per-field
  // `state = state.copyWith(...)` writes interleave and clobber each other (a
  // late "set Loading" lands after a "set Data"), which left goals/rewards stuck
  // on AsyncLoading forever — the infinite Rewards-tab spinner. Only one full
  // reload runs at a time.
  bool _reloadingAll = false;

  Future<void> reloadAll() async {
    if (_reloadingAll) {
      debugPrint('🎯 RewardsAdmin($communityId) reloadAll SKIP (in-flight)');
      return;
    }
    _reloadingAll = true;
    debugPrint('🎯 RewardsAdmin($communityId) reloadAll START');
    try {
      await Future.wait([reloadGoals(), reloadRewards(), reloadBadges()]);
    } finally {
      _reloadingAll = false;
    }
    debugPrint(
        '🎯 RewardsAdmin($communityId) reloadAll END -> goals=${state.goals.runtimeType} rewards=${state.rewards.runtimeType} badges=${state.badges.runtimeType}');
  }

  Future<void> reloadGoals() async {
    state = state.copyWith(goals: const AsyncLoading());
    state = state.copyWith(
        goals: await AsyncValue.guard(() => _svc
            .getGoals(communityId)
            .timeout(_kRewardsReadTimeout,
                onTimeout: () => const <CommunityGoal>[])));
  }

  Future<void> reloadRewards() async {
    state = state.copyWith(rewards: const AsyncLoading());
    state = state.copyWith(
        rewards: await AsyncValue.guard(() => _svc
            .getRewards(communityId)
            .timeout(_kRewardsReadTimeout,
                onTimeout: () => const <CommunityReward>[])));
  }

  Future<void> reloadBadges() async {
    state = state.copyWith(badges: const AsyncLoading());
    state = state.copyWith(
        badges: await AsyncValue.guard(() => _svc
            .getBadges(communityId)
            .timeout(_kRewardsReadTimeout,
                onTimeout: () => const <CommunityBadge>[])));
  }
}

final communityRewardsAdminProvider = NotifierProvider.family<
    CommunityRewardsAdminNotifier, CommunityRewardsAdminState, String>(
  CommunityRewardsAdminNotifier.new,
);
