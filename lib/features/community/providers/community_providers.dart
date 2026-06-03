import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/community.dart';
import '../models/community_member.dart';
import '../models/community_tier.dart';
import '../services/community_service.dart';

/// DI for [CommunityService].
final communityServiceProvider = Provider<CommunityService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return CommunityService(authService: authService);
});

// =============================================================================
// Leader-side reads
// =============================================================================

/// Communities the current leader owns (`GET /me/communities`).
///
/// Drives the new Community tab: empty → "create your community" CTA; one →
/// open it; (NF-7) more than one once Premium ships.
final myCommunitiesProvider = FutureProvider<List<Community>>((ref) async {
  return ref.watch(communityServiceProvider).getMyCommunities();
});

/// A single community by id.
final communityProvider =
    FutureProvider.family<Community, String>((ref, id) async {
  return ref.watch(communityServiceProvider).getCommunity(id);
});

/// Tiers for a community, sorted by rank descending (highest standing first).
final communityTiersProvider =
    FutureProvider.family<List<CommunityTier>, String>((ref, communityId) async {
  final tiers = await ref.watch(communityServiceProvider).getTiers(communityId);
  return [...tiers]..sort((a, b) => b.rank.compareTo(a.rank));
});

/// Roster for a community (first page; pagination added with the list UI).
final communityMembersProvider =
    FutureProvider.family<List<CommunityMember>, String>(
        (ref, communityId) async {
  return ref.watch(communityServiceProvider).getMembers(communityId);
});

// =============================================================================
// Member-side reads
// =============================================================================

/// Communities the current member belongs to + their tier in each
/// (`GET /me/memberships`). Drives the Community Member's "my communities" view.
final myMembershipsProvider = FutureProvider<List<CommunityMember>>((ref) async {
  return ref.watch(communityServiceProvider).getMyMemberships();
});
