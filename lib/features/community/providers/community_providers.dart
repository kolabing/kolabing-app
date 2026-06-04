import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
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

/// Refresh signal. Every community read-provider watches this; bumping it
/// (`bumpCommunityRefresh(ref)`) forces them all to refetch and their widgets
/// to rebuild. Used after every mutation because `ref.invalidate` alone did
/// not reliably rebuild the kept-alive (IndexedStack) community widgets.
/// (Riverpod 3.x removed StateProvider, so this is a Notifier.)
class CommunityRefreshTick extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}

final communityRefreshTick =
    NotifierProvider<CommunityRefreshTick, int>(CommunityRefreshTick.new);

/// Call after any community mutation to refresh the visible data.
void bumpCommunityRefresh(WidgetRef ref) =>
    ref.read(communityRefreshTick.notifier).bump();

// =============================================================================
// Leader-side reads
// =============================================================================

/// Communities the current leader owns (`GET /me/communities`).
///
/// Drives the new Community tab: empty → "create your community" CTA; one →
/// open it; (NF-7) more than one once Premium ships.
final myCommunitiesProvider = FutureProvider<List<Community>>((ref) async {
  ref.watch(communityRefreshTick);
  return ref.watch(communityServiceProvider).getMyCommunities();
});

/// A single community by id.
final communityProvider =
    FutureProvider.family<Community, String>((ref, id) async {
  ref.watch(communityRefreshTick);
  return ref.watch(communityServiceProvider).getCommunity(id);
});

/// Tiers for a community, sorted by rank descending (highest standing first).
final communityTiersProvider =
    FutureProvider.family<List<CommunityTier>, String>((ref, communityId) async {
  ref.watch(communityRefreshTick);
  final tiers = await ref.watch(communityServiceProvider).getTiers(communityId);
  return [...tiers]..sort((a, b) => b.rank.compareTo(a.rank));
});

/// Roster for a community (first page; pagination added with the list UI).
final communityMembersProvider =
    FutureProvider.family<List<CommunityMember>, String>(
        (ref, communityId) async {
  ref.watch(communityRefreshTick);
  return ref.watch(communityServiceProvider).getMembers(communityId);
});

// =============================================================================
// Member-side reads
// =============================================================================

/// Communities the current member belongs to + their tier in each
/// (`GET /me/memberships`). Drives the Community Member's "my communities" view.
final myMembershipsProvider =
    FutureProvider<List<CommunityMembership>>((ref) async {
  ref.watch(communityRefreshTick);
  return ref.watch(communityServiceProvider).getMyMemberships();
});
