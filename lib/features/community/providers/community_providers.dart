import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../models/community.dart';
import '../models/community_member.dart';
import '../models/community_membership.dart';
import '../models/community_tier.dart';
import '../services/community_service.dart';

/// DI for [CommunityService].
final communityServiceProvider = Provider<CommunityService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return CommunityService(authService: authService);
});

// =============================================================================
// Leader-side: one Notifier holds the community + its tiers + roster.
//
// Why a Notifier (not FutureProvider.family + invalidate): the community
// widgets live inside the role IndexedStack and are kept alive all session.
// On Riverpod 3.x, neither `ref.invalidate` nor a watched tick reliably forced
// those kept-alive FutureProviders to recompute after a mutation (the list only
// refreshed on a full app restart). A Notifier sets `state` directly, which is
// an unconditional emit → the watching widgets rebuild immediately. This mirrors
// the codebase's existing list notifiers (e.g. MyOpportunitiesNotifier).
// =============================================================================

/// State for the Community Leader's management surface.
class CommunityManageState {
  const CommunityManageState({
    required this.communities,
    required this.tiers,
    required this.members,
  });

  /// Communities the leader owns (free tier = exactly one).
  final AsyncValue<List<Community>> communities;

  /// Tiers of the primary community.
  final AsyncValue<List<CommunityTier>> tiers;

  /// Roster of the primary community.
  final AsyncValue<List<CommunityMember>> members;

  static const initial = CommunityManageState(
    communities: AsyncLoading<List<Community>>(),
    tiers: AsyncLoading<List<CommunityTier>>(),
    members: AsyncLoading<List<CommunityMember>>(),
  );

  /// The leader's first (free) community, or null if none yet.
  Community? get primaryCommunity {
    final list = communities.value;
    return (list != null && list.isNotEmpty) ? list.first : null;
  }

  CommunityManageState copyWith({
    AsyncValue<List<Community>>? communities,
    AsyncValue<List<CommunityTier>>? tiers,
    AsyncValue<List<CommunityMember>>? members,
  }) => CommunityManageState(
    communities: communities ?? this.communities,
    tiers: tiers ?? this.tiers,
    members: members ?? this.members,
  );
}

class CommunityManageNotifier extends Notifier<CommunityManageState> {
  CommunityService get _svc => ref.read(communityServiceProvider);

  @override
  CommunityManageState build() {
    Future.microtask(loadAll);
    return CommunityManageState.initial;
  }

  /// Load the community, then its tiers + roster (sequential to avoid races on
  /// `state`).
  Future<void> loadAll() async {
    final comms = await AsyncValue.guard(() => _svc.getMyCommunities());
    state = state.copyWith(communities: comms);
    if (state.primaryCommunity == null) {
      state = state.copyWith(
        tiers: const AsyncData([]),
        members: const AsyncData([]),
      );
      return;
    }
    await reloadTiers();
    await reloadMembers();
  }

  /// Re-fetch the owned communities (after create). Reloads everything.
  Future<void> reloadCommunities() => loadAll();

  /// Re-fetch the primary community's tiers and emit immediately.
  Future<void> reloadTiers() async {
    final id = state.primaryCommunity?.id;
    if (id == null) return;
    state = state.copyWith(tiers: const AsyncLoading<List<CommunityTier>>());
    state = state.copyWith(
      tiers: await AsyncValue.guard(() async {
        final tiers = await _svc.getTiers(id);
        return [...tiers]..sort((a, b) => b.rank.compareTo(a.rank));
      }),
    );
  }

  /// Re-fetch the primary community's roster and emit immediately.
  Future<void> reloadMembers() async {
    final id = state.primaryCommunity?.id;
    if (id == null) return;
    state = state.copyWith(
      members: const AsyncLoading<List<CommunityMember>>(),
    );
    state = state.copyWith(
      members: await AsyncValue.guard(() => _svc.getMembers(id)),
    );
  }
}

/// The Community Leader's management state (community + tiers + roster).
final communityManageProvider =
    NotifierProvider<CommunityManageNotifier, CommunityManageState>(
      CommunityManageNotifier.new,
    );

// =============================================================================
// Member-side reads (separate concern; loaded fresh each time the view opens).
// =============================================================================

/// Communities the current member belongs to + their tier in each
/// (`GET /me/memberships`). Drives the Community Member's "my communities" view.
class MyMembershipsNotifier
    extends Notifier<AsyncValue<List<CommunityMembership>>> {
  @override
  AsyncValue<List<CommunityMembership>> build() {
    Future.microtask(reload);
    return const AsyncLoading();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(communityServiceProvider).getMyMemberships(),
    );
  }
}

final myMembershipsProvider =
    NotifierProvider<
      MyMembershipsNotifier,
      AsyncValue<List<CommunityMembership>>
    >(MyMembershipsNotifier.new);

/// Discoverable communities the current attendee can join
/// (`GET /communities/discover`), optionally filtered by [CommunityType] wire
/// value. Featured-first ordering comes from the backend. Resolves to an empty
/// list when the endpoint is not deployed yet (404), so the discovery surface
/// shows a friendly "coming soon" state rather than crashing.
final discoverCommunitiesProvider =
    FutureProvider.family<List<Community>, String?>(
      (ref, type) =>
          ref.read(communityServiceProvider).getDiscoverCommunities(type: type),
    );

/// A single community by id (`GET /communities/{id}`), keyed by id. Drives the
/// attendee-facing community profile screen. A Notifier (not FutureProvider) so
/// the join CTA can refresh it directly after a join / request without relying
/// on `ref.invalidate` (the kept-alive recompute caveat documented above).
class CommunityByIdNotifier extends Notifier<AsyncValue<Community>> {
  CommunityByIdNotifier(this.communityId);

  final String communityId;

  @override
  AsyncValue<Community> build() {
    Future.microtask(reload);
    return const AsyncLoading();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(communityServiceProvider).getCommunity(communityId),
    );
  }

  /// Optimistically replace the held community (e.g. after a successful join)
  /// so the CTA flips without a round-trip.
  void setCommunity(Community community) => state = AsyncData(community);
}

final communityByIdProvider =
    NotifierProvider.family<
      CommunityByIdNotifier,
      AsyncValue<Community>,
      String
    >(CommunityByIdNotifier.new);

/// Resolves a raw community-type slug to its human label using the dynamic
/// `/community-types` taxonomy (NEVER the placeholder `CommunityType` enum, per
/// CANONICAL-LISTS). Returns null while the taxonomy is loading or when the slug
/// is unknown, so callers can fall back to a generic label.
final communityTypeLabelProvider = Provider.family<String?, String?>((
  ref,
  slug,
) {
  if (slug == null || slug.isEmpty) return null;
  final types = ref.watch(communityTypesProvider).value;
  if (types == null) return null;
  for (final t in types) {
    if (t.slug == slug) return t.name;
  }
  return null;
});

/// A specific community's tiers (`GET /communities/{id}/tiers`), keyed by id.
/// Used by surfaces that need tiers for a community other than the leader's
/// primary (e.g. the event create/edit tier-gate picker). Highest rank first.
final communityTiersProvider =
    FutureProvider.family<List<CommunityTier>, String>((
      ref,
      communityId,
    ) async {
      final tiers = await ref
          .read(communityServiceProvider)
          .getTiers(communityId);
      return [...tiers]..sort((a, b) => b.rank.compareTo(a.rank));
    });

/// A specific community's roster (`GET /communities/{id}/members`), keyed by id.
/// Used by the community detail Members tab for ANY community the viewer is in
/// (not just the leader's primary — that's [communityManageProvider]). A
/// Notifier so `reload()` sets state directly (kept-alive recompute caveat).
class CommunityMembersByIdNotifier
    extends Notifier<AsyncValue<List<CommunityMember>>> {
  CommunityMembersByIdNotifier(this.communityId);

  final String communityId;

  @override
  AsyncValue<List<CommunityMember>> build() {
    Future.microtask(reload);
    return const AsyncLoading();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(communityServiceProvider).getMembers(communityId),
    );
  }
}

final communityMembersByIdProvider =
    NotifierProvider.family<
      CommunityMembersByIdNotifier,
      AsyncValue<List<CommunityMember>>,
      String
    >(CommunityMembersByIdNotifier.new);
