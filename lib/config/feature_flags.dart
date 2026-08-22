/// Central place for temporary, compile-time feature toggles.
///
/// Keep these short-lived: a flag here means a feature is intentionally hidden
/// while it is being finished. Flip back to `true` (and eventually delete the
/// flag) once the feature is ready to ship.
library;

/// Enables the event gamification surfaces: the challenge-selection setup on
/// the collaboration detail screen, the organizer's "Show check-in QR" action
/// and the member's "Check in" button on the event hub.
///
/// Turned on with the QR challenge loop (#132), which made the flow reachable
/// end to end for the first time: the organizer can display a check-in code,
/// the member scans it, scanning another member lists that event's challenges,
/// and the verification QR closes the loop into `point_ledger`.
const bool kGamificationSetupEnabled = true;

/// Hides the **Members** tab on the community detail screen (leaving Rewards +
/// Events) while the member-roster surface is on hold. Set to `true` to bring
/// the Members tab back.
const bool kCommunityMembersTabEnabled = false;

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
