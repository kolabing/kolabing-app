import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import '../../config/constants/analytics.dart';
import '../../config/environment.dart';
import '../../features/auth/models/user_model.dart';

/// Canonical, hand-picked analytics event names.
///
/// Curated only — we do NOT autocapture. Each constant maps to a single
/// business-critical action instrumented at its post-API-success seam. Keep
/// this list small and intentional; adding noise here costs ingestion + dilutes
/// the funnels. Event names are `snake_case` per PostHog convention.
class AnalyticsEvents {
  const AnalyticsEvents._();

  // ── Lifecycle / auth ──────────────────────────────────────────────
  static const String userSignedUp = 'user_signed_up';
  static const String userLoggedIn = 'user_logged_in';

  // ── Business paywall KPIs ─────────────────────────────────────────
  static const String kolabCreated = 'kolab_created';
  static const String kolabPublished = 'kolab_published';
  static const String applicationSubmitted = 'application_submitted';

  // ── Application → collaboration lifecycle ─────────────────────────
  static const String applicationAccepted = 'application_accepted';
  static const String applicationDeclined = 'application_declined';
  static const String collaborationCompleted = 'collaboration_completed';
  static const String feedbackSubmitted = 'feedback_submitted';

  // ── Community ─────────────────────────────────────────────────────
  static const String communityCreated = 'community_created';
  static const String communityJoined = 'community_joined';
  static const String tierCreated = 'tier_created';

  // ── Events / attendee ─────────────────────────────────────────────
  static const String eventCreated = 'event_created';
  static const String eventSignup = 'event_signup';
  static const String eventCheckedIn = 'event_checked_in';

  // ── Engagement ────────────────────────────────────────────────────
  static const String messageSent = 'message_sent';

  // ── Revenue ───────────────────────────────────────────────────────
  static const String subscriptionStarted = 'subscription_started';
}

/// Thin, fail-safe wrapper around the PostHog SDK.
///
/// Design rules:
/// * **Never throws.** Every call is guarded so an analytics fault can never
///   break a user flow. Calls made before [init] (or in unit tests, where the
///   platform channel is absent) are silent no-ops.
/// * **No PII by choice.** We send the backend user id + role-shaped person
///   properties (`user_type`, `has_subscription`, `city`) — never email/name.
/// * **Curated.** Only [capture] the events declared in [AnalyticsEvents].
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  final Posthog _posthog = Posthog();
  bool _enabled = false;

  /// Initialize the SDK. Call once from `main()` before `runApp`.
  Future<void> init() async {
    if (_enabled) return;
    try {
      final config = PostHogConfig(AnalyticsConfig.apiKey)
        ..host = AnalyticsConfig.host
        // Identify-based product analytics: only create person profiles for
        // users we explicitly identify(). Anonymous events stay event-only.
        ..personProfiles = PostHogPersonProfiles.identifiedOnly
        // App open/close/install/update — cheap, high-signal lifecycle events.
        ..captureApplicationLifecycleEvents = true
        // Curated capture: replay + surveys off, no autocapture wrappers used.
        ..sessionReplay = false
        ..surveys = false
        ..debug = kDebugMode;
      await _posthog.setup(config);
      // Tag every event with the build environment so dev traffic is
      // filterable from prod in one PostHog project.
      await _posthog.register('environment', Environment.current.name);
      _enabled = true;
    } on Object catch (e) {
      debugPrint('[Analytics] init failed: $e');
    }
  }

  /// Associate the current device with a known user and set role properties.
  /// Idempotent — safe to call on every login and on session restore.
  Future<void> identify(UserModel user) async {
    if (!_enabled || user.id.isEmpty) return;
    try {
      await _posthog.identify(
        userId: user.id,
        userProperties: _personProperties(user),
      );
    } on Object catch (e) {
      debugPrint('[Analytics] identify failed: $e');
    }
  }

  /// Clear the identified user. Call on logout / session clear so the next
  /// account doesn't inherit the previous person's distinct id.
  Future<void> reset() async {
    if (!_enabled) return;
    try {
      await _posthog.reset();
    } on Object catch (e) {
      debugPrint('[Analytics] reset failed: $e');
    }
  }

  /// Capture a curated event. [properties] values must be non-null.
  Future<void> capture(
    String event, {
    Map<String, Object>? properties,
  }) async {
    if (!_enabled) return;
    try {
      await _posthog.capture(eventName: event, properties: properties);
    } on Object catch (e) {
      debugPrint('[Analytics] capture "$event" failed: $e');
    }
  }

  Map<String, Object> _personProperties(UserModel user) {
    final props = <String, Object>{
      'user_type': user.userType.toApiValue(),
      'has_subscription':
          user.hasActiveSubscription || (user.subscription?.isActive ?? false),
    };
    final city = _cityOf(user);
    if (city != null && city.isNotEmpty) {
      props['city'] = city;
    }
    return props;
  }

  String? _cityOf(UserModel user) {
    switch (user.userType) {
      case UserType.business:
        return user.businessProfile?.city?.name;
      case UserType.community:
        return user.communityProfile?.city?.name;
      case UserType.attendee:
        return null;
    }
  }
}
