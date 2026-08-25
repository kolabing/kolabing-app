/// Central place for temporary, compile-time feature toggles.
///
/// Keep these short-lived: a flag here means a feature is intentionally hidden
/// while it is being finished. Flip back to `true` (and eventually delete the
/// flag) once the feature is ready to ship.
library;

/// Hides the **collaboration-detail** gamification block: `_ChallengesSection`
/// and `_QRCodeSection`.
///
/// Still unfinished and deliberately still off. The challenge checkboxes write
/// only to `challengeSelectionProvider`, a global (not `.family`) Notifier that
/// nothing ever POSTs — ticks are discarded on navigation and bleed between
/// collaborations — and "Add custom challenge" only shows a "coming soon"
/// snackbar. The QR card there also pushes a hardcoded English event name.
///
/// This is NOT the flag for the event check-in loop; see
/// [kEventCheckinQrEnabled]. They were one flag until #132, where flipping it
/// for the event loop would have shipped this half too.
const bool kGamificationSetupEnabled = false;

/// Enables the **event** check-in QR loop (#132): the organizer's "Show
/// check-in QR" action and the member's "Check in" button on the event hub.
///
/// On, because #132 made that flow work end to end for the first time — the
/// organizer can display a check-in code, the member scans it, scanning another
/// member lists that event's challenges, and the verification QR closes the
/// loop into `point_ledger`.
const bool kEventCheckinQrEnabled = true;

/// The **Members** tab on the community detail screen (alongside Rewards +
/// Events).
///
/// On for QA of the community-member surfaces (#136). The roster reads
/// `community_members`, which `kolabing:seed-qa-gamification` populates.
const bool kCommunityMembersTabEnabled = true;

/// Whether a new attendee (Community Member) can sign themselves up.
///
/// Closed in `820e3b7` when the attendee track was pulled from launch scope,
/// which also removed the only way to *create* a test attendee — hence this
/// flag rather than another hard-coded `false` (#136).
///
/// ⚠️ **Release decision.** With this on, attendee sign-up is publicly
/// reachable from the user-type selection screen. It was closed deliberately;
/// whether it reopens is a product call, and this flag must be reviewed before
/// any store build. The account type itself has always worked — existing
/// ⚠️ RELEASE CHECK — this and [kCommunityMembersTabEnabled] are BOTH on for QA
/// (kolabing-app#137), not because the tracks are launch-ready. Two independent
/// code reviews flagged the pair as a release risk, and they are right: as
/// committed, an App Store build ships attendee sign-up publicly reachable from
/// the user-type selection screen.
///
/// Left ON deliberately — turning them off would break the QA currently running
/// against the dev API — so this is the reminder rather than the fix. Decide
/// both before `make ipa-prod`, and note that flipping either one is a product
/// call, not a cleanup.
/// attendees can sign in either way.
const bool kAttendeeSignupEnabled = true;

/// Hides the **Location** row on the post-signup permission screen.
///
/// Nothing in the shipped app reads device location: the only caller of
/// `Geolocator.getCurrentPosition` is `EventDiscoveryScreen`, which is not
/// routed. Asking for a permission with no feature behind it is a Guideline
/// 5.1.1 rejection risk, so the ask stays hidden until nearby-kolabs ships.
///
/// Flip to `true` together with: routing the location feature, restoring
/// **Coarse Location** in the App Store Connect privacy labels, and confirming
/// `NSLocationWhenInUseUsageDescription` still describes what the app does.
const bool kLocationPermissionPromptEnabled = false;
