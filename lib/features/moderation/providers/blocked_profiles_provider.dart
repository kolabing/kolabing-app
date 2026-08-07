import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/moderation_service.dart';

/// DI seam for [ModerationService] — override in tests with a fake client.
final moderationServiceProvider = Provider<ModerationService>(
  (ref) => ModerationService(),
);

/// The set of profile IDs the viewer has blocked — the single source of truth
/// for instant client-side content filtering (Explore deck, reviews, chats).
///
/// Loaded from `GET /me/blocks` on first watch (after sign-in). [block]/[unblock]
/// update the set **optimistically** and revert on backend failure, so blocked
/// content disappears immediately (App-Review 1.2 requirement).
///
/// Like the other user-scoped notifiers this is a plain [Notifier] held by
/// always-mounted screens, so it is invalidated on session reset
/// (`invalidateUserScopedProviders`) to prevent one account's block list leaking
/// into the next session.
class BlockedProfilesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    // Kick off the initial load without blocking the first synchronous read
    // (watchers get an empty set immediately, then the loaded set when ready).
    Future.microtask(_load);
    return <String>{};
  }

  ModerationService get _service => ref.read(moderationServiceProvider);

  Future<void> _load() async {
    final ids = await _service.blockedProfileIds();
    if (!ref.mounted) return;
    // Merge rather than overwrite so an optimistic block issued while the load
    // was in flight is not dropped.
    state = {...state, ...ids};
  }

  /// Block [profileId] optimistically, then persist. Reverts on failure.
  Future<void> block(String profileId) async {
    if (profileId.isEmpty || state.contains(profileId)) return;
    state = {...state, profileId};
    try {
      await _service.block(profileId);
    } catch (e) {
      debugPrint('BlockedProfilesNotifier.block revert: $e');
      _removeLocal(profileId);
      rethrow;
    }
  }

  /// Unblock [profileId] optimistically, then persist. Reverts on failure.
  Future<void> unblock(String profileId) async {
    if (!state.contains(profileId)) return;
    _removeLocal(profileId);
    try {
      await _service.unblock(profileId);
    } catch (e) {
      debugPrint('BlockedProfilesNotifier.unblock revert: $e');
      state = {...state, profileId};
      rethrow;
    }
  }

  bool isBlocked(String? profileId) =>
      profileId != null && profileId.isNotEmpty && state.contains(profileId);

  void _removeLocal(String profileId) {
    if (!state.contains(profileId)) return;
    state = {...state}..remove(profileId);
  }
}

final blockedProfilesProvider =
    NotifierProvider<BlockedProfilesNotifier, Set<String>>(
      BlockedProfilesNotifier.new,
    );
