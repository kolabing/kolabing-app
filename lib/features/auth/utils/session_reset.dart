import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/application_provider.dart';
import '../../business/providers/profile_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../discovery/providers/discovery_provider.dart';
import '../../kolab/providers/my_kolabs_provider.dart';
import '../../notification/providers/notification_provider.dart';
import '../../opportunity/providers/opportunity_provider.dart';
import '../../profile/providers/public_profile_provider.dart';

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
/// Note: `*.family` and `autoDispose` providers (chat data, application detail,
/// public profile by id, unread-count) are auto-disposed when their last
/// listener detaches on navigation away, but we invalidate them defensively
/// here too in case a listener is still attached at logout time.
void invalidateUserScopedProviders(Ref ref) {
  // Home / Dashboard
  ref.invalidate(dashboardProvider);

  // Explore / discovery feed (role-scoped). This was the missing reset that
  // caused Explore to keep showing the previous account's role feed.
  ref.invalidate(discoveryListProvider);
  ref.invalidate(discoveryFiltersProvider);

  // Applications + chat
  ref.invalidate(myApplicationsProvider);
  ref.invalidate(receivedApplicationsProvider);
  ref.invalidate(chatMessagesProvider);
  ref.invalidate(unreadMessagesCountProvider);

  // Posts owned by the user (both parallel post systems)
  ref.invalidate(opportunityListProvider);
  ref.invalidate(opportunityFiltersProvider);
  ref.invalidate(myOpportunitiesProvider);
  ref.invalidate(myOpportunitiesStatusProvider);
  ref.invalidate(myKolabsProvider);
  ref.invalidate(myKolabsStatusProvider);

  // Notifications
  ref.invalidate(notificationProvider);

  // Public profile previews keyed by id (family)
  ref.invalidate(publicProfileProvider);

  // Settings / account profile (logo, subscription, prefs)
  ref.invalidate(profileProvider);
}
