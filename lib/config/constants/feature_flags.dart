/// Compile-time feature flags.
///
/// Flip [attendeeAppleSignupEnabled] to `true` only after the backend
/// `POST /auth/apple` accepts and honors `user_type` (see kolabing-v2 ticket
/// 2026-06-11-attendee-apple-social-usertype). Until then, a new Apple user
/// would be created with the backend's default type, so the Apple button stays
/// hidden on the attendee surface.
abstract final class FeatureFlags {
  const FeatureFlags._();

  /// Whether the Apple sign-in button is shown on the attendee register screen.
  ///
  /// ON: App Store Guideline 4.8 requires offering Sign in with Apple wherever
  /// Google sign-in is offered. NOTE: a brand-new Apple attendee is created with
  /// the correct role only once backend `/auth/apple` honors `user_type`
  /// (kolabing-v2 PR #24); until then a new Apple signup may get the backend's
  /// default role. Existing Apple users are unaffected.
  static const bool attendeeAppleSignupEnabled = true;

  /// MASTER SWITCH for the attendee / member layer (event discovery, check-ins,
  /// rewards, gamification, the joinable-community / member surfaces).
  ///
  /// The app ships with ONLY the Business and Community (partner) experiences.
  /// While this is `false`:
  ///   - the attendee sign-up card is disabled and shows a "Coming soon" badge,
  ///   - existing attendee accounts are signed out on login (they cannot enter),
  ///   - every attendee / member route resolves to a "Coming soon" placeholder,
  ///   - the Community nav tab (rewards/members/events) shows "Coming soon".
  ///
  /// ALL member code is kept (gated, not deleted). Flipping this to `true`
  /// restores the full member layer with NO other change.
  static const bool attendeeEnabled = false;
}
