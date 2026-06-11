import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/friendship.dart';
import '../services/friendship_service.dart';

/// Shared [FriendshipService] instance.
final friendshipServiceProvider = Provider<FriendshipService>(
  (ref) => FriendshipService(),
);

/// Accepted friends (`GET /me/friends`). Self-gates: a 404 (feature not
/// deployed) resolves to an empty list instead of an error so the screen
/// shows its empty state rather than crashing.
final friendsProvider = FutureProvider.autoDispose<List<FriendSummary>>(
  (ref) async {
    final service = ref.watch(friendshipServiceProvider);
    try {
      return await service.getFriends();
    } on FriendshipException catch (e) {
      if (e.isFeatureOff) return const <FriendSummary>[];
      rethrow;
    }
  },
);

/// Incoming friend requests + count (`GET /me/friend-requests`). Self-gates the
/// same way: a 404 resolves to [FriendRequests.empty].
final friendRequestsProvider = FutureProvider.autoDispose<FriendRequests>(
  (ref) async {
    final service = ref.watch(friendshipServiceProvider);
    try {
      return await service.getFriendRequests();
    } on FriendshipException catch (e) {
      if (e.isFeatureOff) return const FriendRequests.empty();
      rethrow;
    }
  },
);

/// Just the incoming-request count, for the badge. Returns 0 while loading,
/// on error, or when the feature is off (never throws to the badge widget).
final friendRequestCountProvider = Provider.autoDispose<int>((ref) {
  final async = ref.watch(friendRequestsProvider);
  return async.maybeWhen(data: (r) => r.count, orElse: () => 0);
});
