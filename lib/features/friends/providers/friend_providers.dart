import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/friend.dart';
import '../services/friend_service.dart';

/// DI for [FriendService].
final friendServiceProvider = Provider<FriendService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return FriendService(authService: authService);
});

// =============================================================================
// One Notifier holds the three friend lists (accepted + requests + suggested).
//
// Like the community surface, the friends views live inside a kept-alive role
// stack, so we set `state` directly after each mutation (an unconditional emit)
// rather than relying on `ref.invalidate` of a kept-alive FutureProvider.
// =============================================================================

/// State for the friends surface: accepted list, requests inbox, suggestions.
class FriendsState {
  const FriendsState({
    required this.friends,
    required this.requests,
    required this.suggested,
  });

  final AsyncValue<List<Friend>> friends;
  final AsyncValue<FriendRequests> requests;
  final AsyncValue<List<Friend>> suggested;

  static const initial = FriendsState(
    friends: AsyncLoading<List<Friend>>(),
    requests: AsyncLoading<FriendRequests>(),
    suggested: AsyncLoading<List<Friend>>(),
  );

  FriendsState copyWith({
    AsyncValue<List<Friend>>? friends,
    AsyncValue<FriendRequests>? requests,
    AsyncValue<List<Friend>>? suggested,
  }) => FriendsState(
    friends: friends ?? this.friends,
    requests: requests ?? this.requests,
    suggested: suggested ?? this.suggested,
  );
}

class FriendsNotifier extends Notifier<FriendsState> {
  FriendService get _svc => ref.read(friendServiceProvider);

  @override
  FriendsState build() {
    Future.microtask(loadAll);
    return FriendsState.initial;
  }

  /// Load all three lists in parallel, then emit once.
  ///
  /// We deliberately do NOT call the three `reload*` helpers concurrently here:
  /// each does a read-modify-write of `state`, so running them at the same time
  /// races (a lost update would drop one field back to loading). Instead we
  /// await all three fetches in parallel and apply a single atomic state write.
  Future<void> loadAll() async {
    state = FriendsState.initial;
    final friends = AsyncValue.guard(() => _svc.getFriends());
    final requests = AsyncValue.guard(() => _svc.getRequests());
    final suggested = AsyncValue.guard(() => _svc.getSuggested());
    state = FriendsState(
      friends: await friends,
      requests: await requests,
      suggested: await suggested,
    );
  }

  Future<void> reloadFriends() async {
    state = state.copyWith(friends: const AsyncLoading<List<Friend>>());
    state = state.copyWith(
      friends: await AsyncValue.guard(() => _svc.getFriends()),
    );
  }

  Future<void> reloadRequests() async {
    state = state.copyWith(requests: const AsyncLoading<FriendRequests>());
    state = state.copyWith(
      requests: await AsyncValue.guard(() => _svc.getRequests()),
    );
  }

  Future<void> reloadSuggested() async {
    state = state.copyWith(suggested: const AsyncLoading<List<Friend>>());
    state = state.copyWith(
      suggested: await AsyncValue.guard(() => _svc.getSuggested()),
    );
  }

  /// Send a friend request to [profileId], then refresh (the candidate leaves
  /// suggestions and appears in the sent-requests bucket). [loadAll] applies one
  /// atomic state write, avoiding the read-modify-write race of concurrent
  /// per-field reloads.
  Future<void> sendRequest(String profileId) async {
    await _svc.sendRequest(profileId);
    await loadAll();
  }

  /// Accept an incoming request: the person moves into the accepted list.
  Future<void> acceptRequest(String friendshipId) async {
    await _svc.acceptRequest(friendshipId);
    await loadAll();
  }

  Future<void> declineRequest(String friendshipId) async {
    await _svc.declineRequest(friendshipId);
    await loadAll();
  }

  Future<void> unfriend(String profileId) async {
    await _svc.unfriend(profileId);
    await loadAll();
  }

  Future<void> block(String profileId) async {
    await _svc.block(profileId);
    await loadAll();
  }
}

/// The friends surface state (accepted + requests + suggested).
final friendsProvider = NotifierProvider<FriendsNotifier, FriendsState>(
  FriendsNotifier.new,
);

// =============================================================================
// Per-profile relationship state — drives [FriendActionButton].
// =============================================================================

/// The current user's relationship to one other profile, derived from the
/// loaded friends + requests state. Used by [FriendActionButton] so the button
/// reflects (and stays in sync with) the rest of the friends surface.
enum FriendRelationship {
  /// Not connected — show "Add".
  none,

  /// I sent a pending request — show "Pending" (cancellable).
  requestSent,

  /// They sent me a pending request — show "Respond" (accept/decline).
  requestReceived,

  /// Accepted — show "Friends ▾" (unfriend / block).
  friends,

  /// I blocked them — show "Blocked" (unblock).
  blocked,
}

/// Resolve the relationship to [profileId] from the current [friendsProvider]
/// snapshot. Returns [FriendRelationship.none] until the data is loaded.
final friendRelationshipProvider = Provider.family<FriendRelationship, String>((
  ref,
  profileId,
) {
  final s = ref.watch(friendsProvider);

  final friends = s.friends.value;
  if (friends != null && friends.any((f) => f.profileId == profileId)) {
    return FriendRelationship.friends;
  }

  final requests = s.requests.value;
  if (requests != null) {
    if (requests.incoming.any((f) => f.profileId == profileId)) {
      return FriendRelationship.requestReceived;
    }
    if (requests.sent.any((f) => f.profileId == profileId)) {
      return FriendRelationship.requestSent;
    }
  }

  return FriendRelationship.none;
});

/// The incoming friendship row id for [profileId], if any — needed to
/// accept/decline directly from a profile header.
final incomingFriendshipIdProvider = Provider.family<String?, String>((
  ref,
  profileId,
) {
  final requests = ref.watch(friendsProvider).requests.value;
  if (requests == null) {
    return null;
  }
  for (final f in requests.incoming) {
    if (f.profileId == profileId) {
      return f.friendshipId;
    }
  }
  return null;
});
