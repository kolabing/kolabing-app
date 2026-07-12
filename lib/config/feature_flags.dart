/// Central place for temporary, compile-time feature toggles.
///
/// Keep these short-lived: a flag here means a feature is intentionally hidden
/// while it is being finished. Flip back to `true` (and eventually delete the
/// flag) once the feature is ready to ship.
library;

/// Hides the in-app gamification surface that is not ready for users yet:
/// the challenge-selection setup + QR check-in card on the collaboration detail
/// screen, and the "Scan Check-Ins" action on the event hub. Set to `true` to
/// bring the attendee-facing check-in / challenge flow back.
const bool kGamificationSetupEnabled = false;
