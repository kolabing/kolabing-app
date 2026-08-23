import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/application_provider.dart';
import '../../business/providers/profile_provider.dart';
import '../../chat/providers/chat_providers.dart';
import '../../community/providers/community_providers.dart';
import '../../discovery/providers/discovery_provider.dart';
import '../../community/providers/community_follow_provider.dart';
import '../../gamification/providers/pending_challenge_provider.dart';
import '../../gamification/providers/active_event_session_provider.dart';
import '../../gamification/providers/badge_provider.dart';
import '../../gamification/providers/checkin_provider.dart';
import '../../gamification/providers/discovery_provider.dart';
import '../../gamification/providers/reward_provider.dart';
import '../../gamification/providers/stats_provider.dart';
import '../../kolab/providers/my_kolabs_provider.dart';
import '../../moderation/providers/blocked_profiles_provider.dart';
import '../../notification/providers/notification_provider.dart';
import '../../opportunity/providers/opportunity_provider.dart';
import '../../profile/providers/gallery_provider.dart';
import '../../profile/providers/public_profile_provider.dart';
import '../../rewards/providers/wallet_provider.dart';

/// Tears down every user-scoped Riverpod provider so that no in-memory state
/// from one account leaks into the next session.
///
/// Why this exists
/// ----------------
/// Most of these providers are plain [NotifierProvider]s (not `autoDispose`),
/// and they are watched by always-mounted tab screens. Their notifier
/// instances therefore survive a logout/login cycle and keep serving the
/// previous account's cached data (e.g. the Explore feed showed the previous
/// role's posts) and stale "session expired" error states, until a full app
/// restart rebuilt the provider container.
///
/// Centralising the invalidation here (and calling it from BOTH logout and a
/// fresh login in [AuthNotifier]) guarantees that every logout path — the
/// profile screens, the router error page, account deletion — and every new
/// login fully rebuilds user-scoped state without an app restart.
///
/// The cached auth token/identity is handled separately by [AuthService]'s
/// shared session-epoch mechanism (rotated on login/logout), so each provider
/// re-fetches with the CURRENT session's token after invalidation. The
/// role-scoped Explore feed therefore re-resolves to the current user's role
/// on the next read.
///
/// Note: `*.family` and `autoDispose` providers (application chat messages,
/// application detail, public profile by id, unread-count) are auto-disposed
/// when their last listener detaches on navigation away, but we invalidate them
/// defensively here too in case a listener is still attached at logout time.
/// The NF-CHAT inbox (`chatThreadsProvider`/`chatUnreadProvider`) and NF-6
/// community providers are plain (non-autoDispose) Notifiers held by
/// always-mounted widgets, so they MUST be invalidated here (see below).
void invalidateUserScopedProviders(Ref ref) {
  // Invalidate each provider INDEPENDENTLY. A cascade
  // (`ref..invalidate()..invalidate()`) aborts on the first throw — and a
  // role-scoped provider that the AuthNotifier ref transitively depends on can
  // throw a debug CircularDependency assertion when invalidated. That abort left
  // every later provider (community management, kolabs, wallet, …) serving the
  // PREVIOUS account's data after an account switch — e.g. a freshly registered
  // community showing "another user's community". Wrap each invalidate so one
  // failure can never short-circuit the rest.
  void inv(void Function() invalidate) {
    try {
      invalidate();
    } on Object catch (e) {
      debugPrint('session_reset: invalidate skipped: $e');
    }
  }

  // NOTE: dashboardProvider is intentionally NOT invalidated here. Like the
  // other AuthScopeGuard notifiers it ref.listen()s authProvider and
  // reloads/clears itself on every auth transition, so it self-heals on login
  // AND logout. Invalidating it from AuthNotifier's own ref (the FX-9
  // post-sign-in path) while it is mounted creates an auth<->dashboard
  // CircularDependencyError — see the regression test "signInWithEmail succeeds
  // while dashboardProvider is mounted".

  // Explore / discovery feed (role-scoped). This was the missing reset that
  // caused Explore to keep showing the previous account's role feed.
  inv(() => ref.invalidate(discoveryListProvider));
  inv(() => ref.invalidate(discoveryFiltersProvider));

  // Applications + chat
  inv(() => ref.invalidate(myApplicationsProvider));
  inv(() => ref.invalidate(receivedApplicationsProvider));
  inv(() => ref.invalidate(chatMessagesProvider));
  inv(() => ref.invalidate(unreadMessagesCountProvider));

  // NF-CHAT inbox (plain Notifiers held by the always-mounted app-bar inbox
  // button — these leaked the previous account's chats across a switch).
  inv(() => ref.invalidate(chatThreadsProvider));
  inv(() => ref.invalidate(chatUnreadProvider));

  // NF-6 community management (leader) + memberships (member)
  inv(() => ref.invalidate(communityManageProvider));
  inv(() => ref.invalidate(myMembershipsProvider));

  // Posts owned by the user (both parallel post systems)
  inv(() => ref.invalidate(opportunityListProvider));
  inv(() => ref.invalidate(opportunityFiltersProvider));
  inv(() => ref.invalidate(myOpportunitiesProvider));
  inv(() => ref.invalidate(myOpportunitiesStatusProvider));
  inv(() => ref.invalidate(myKolabsProvider));
  inv(() => ref.invalidate(myKolabsStatusProvider));

  // Notifications
  inv(() => ref.invalidate(notificationProvider));

  // Wallet / XP / badges
  inv(() => ref.invalidate(walletProvider));
  inv(() => ref.invalidate(discoveryProvider));
  inv(() => ref.invalidate(myStatsProvider));
  inv(() => ref.invalidate(myRewardsProvider));
  inv(() => ref.invalidate(myRewardsPaginatedProvider));
  inv(() => ref.invalidate(allBadgesProvider));
  inv(() => ref.invalidate(myBadgesProvider));
  inv(() => ref.invalidate(spinProvider));
  inv(() => ref.invalidate(redeemQRProvider));
  inv(() => ref.invalidate(confirmRedeemProvider));
  inv(() => ref.invalidate(checkinProvider));

  // Which communities this person follows. Per-account, held in a
  // non-autoDispose Notifier read by always-mounted widgets, so it survives a
  // sign-out unless it is invalidated here: the next account would otherwise
  // see the previous one's Following feed and a live Unfollow on communities
  // they have never heard of.
  inv(() => ref.invalidate(communityFollowsProvider));

  // Any pending challenge request aimed at the previous account.
  inv(() => ref.invalidate(pendingChallengeProvider));

  // The "which event am I at" session is per-account and persisted on disk, so
  // invalidating the notifier is not enough — clear the stored value too, or
  // the next account inherits the previous one's active event.
  inv(() => ref.read(activeEventSessionProvider.notifier).clear());
  inv(() => ref.invalidate(activeEventSessionProvider));

  // Public profile previews keyed by id (family)
  inv(() => ref.invalidate(publicProfileProvider));

  // Settings / account profile (logo, subscription, prefs)
  inv(() => ref.invalidate(profileProvider));
  inv(() => ref.invalidate(galleryProvider));

  // UGC moderation — the viewer's blocked-profile set is per-account and must
  // not leak into the next session (App Review 1.2 client-side filtering).
  inv(() => ref.invalidate(blockedProfilesProvider));
}
