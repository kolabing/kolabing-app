import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/community.dart';
import '../models/community_join_question.dart';
import '../services/community_service.dart';
import 'community_providers.dart';

/// The set of community ids the viewer follows (#138).
///
/// The app holds this rather than reading `is_following` off each community:
/// the backend deliberately keeps that field off `CommunityResource`, which is
/// serialized in lists where a per-row check would be an N+1. One fetch, then
/// every Follow button answers locally.
///
/// Optimistic on both actions — a follow is a one-tap gesture and must feel
/// instant; the row is put back if the call fails.
class CommunityFollowsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    Future.microtask(reload);
    return const {};
  }

  CommunityService get _service => ref.read(communityServiceProvider);

  bool isFollowing(String communityId) => state.contains(communityId);

  Future<void> reload() async {
    try {
      state = (await _service.myFollowedCommunityIds()).toSet();
    } on CommunityException catch (e) {
      // `request_unavailable` just means the backend is not deployed yet — the
      // Follow button self-gates on it rather than erroring.
      debugPrint('communityFollows: reload skipped (${e.code})');
    } on Object catch (e) {
      debugPrint('communityFollows: reload failed: $e');
    }
  }

  /// Follows, optimistically. Returns false when the call failed and the
  /// optimistic change was rolled back.
  Future<bool> follow(String communityId) async {
    if (state.contains(communityId)) return true;
    state = {...state, communityId};
    try {
      await _service.followCommunity(communityId);
      return true;
    } on Object catch (e) {
      state = state.where((id) => id != communityId).toSet();
      debugPrint('communityFollows: follow failed: $e');
      return false;
    }
  }

  Future<bool> unfollow(String communityId) async {
    if (!state.contains(communityId)) return true;
    state = state.where((id) => id != communityId).toSet();
    try {
      await _service.unfollowCommunity(communityId);
      return true;
    } on Object catch (e) {
      state = {...state, communityId};
      debugPrint('communityFollows: unfollow failed: $e');
      return false;
    }
  }
}

final communityFollowsProvider =
    NotifierProvider<CommunityFollowsNotifier, Set<String>>(
      CommunityFollowsNotifier.new,
    );

/// The communities the viewer follows, whole — name, avatar, type.
///
/// [communityFollowsProvider] holds only ids, because that is all a Follow
/// button needs. The attendee feed needs to *show* what you follow, so this
/// keeps the objects. Watching the id set means the strip gains or loses a tile
/// the moment the viewer taps Follow, without a manual invalidate.
///
/// An undeployed endpoint returns an empty list rather than an error: a missing
/// strip is a smaller lie than an error where a strip should be.
final followedCommunitiesProvider = FutureProvider<List<Community>>((
  ref,
) async {
  ref.watch(communityFollowsProvider);
  try {
    return await ref.read(communityServiceProvider).myFollowedCommunities();
  } on CommunityException catch (e) {
    debugPrint('followedCommunities: unavailable (${e.code})');
    return const [];
  } on Object catch (e) {
    debugPrint('followedCommunities: failed: $e');
    return const [];
  }
});

/// What a community asks before admitting a member.
///
/// An empty list is the normal answer and means "Become a member" can go
/// straight through without a form. `autoDispose` because it is read once when
/// the sheet opens.
final communityJoinQuestionsProvider = FutureProvider.autoDispose
    .family<List<CommunityJoinQuestion>, String>((ref, communityId) async {
      try {
        return await ref
            .read(communityServiceProvider)
            .joinQuestions(communityId);
      } on CommunityException catch (e) {
        // Not deployed yet → behave as "asks nothing", which is the pre-feature
        // behaviour and keeps one-tap membership working.
        if (e.code == 'request_unavailable') return const [];
        rethrow;
      }
    });
