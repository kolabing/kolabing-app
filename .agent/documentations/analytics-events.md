# Analytics — PostHog event taxonomy (curated)

**Added:** 2026-06-06 · **SDK:** `posthog_flutter ^5.26.0` · **Project:** PostHog EU
cloud, "Default project" (195047), org "Kolabıng".

## Approach
- **Curated events only.** No autocapture (we don't wrap the tree in
  `PostHogWidget`/`PostHogObserver`), `sessionReplay = false`, `surveys = false`,
  `personProfiles = identifiedOnly`. We fire a small, intentional set of
  business-critical events.
- **Identify by backend user id + role props.** On login / session-restore we
  `identify(user.id)` with person properties `user_type`, `has_subscription`,
  `city`. **No email/name** is sent. `reset()` on logout / session clear.
- **Fail-safe.** `AnalyticsService` never throws and is a silent no-op before
  `init()` (so unit tests, which never init the SDK, are unaffected).

## Where it lives
- Config (write-only `phc_` key + EU host): `lib/config/constants/analytics.dart`
- Service + event-name constants: `lib/services/analytics/analytics_service.dart`
  (`AnalyticsService.instance`, `AnalyticsEvents`)
- Init: `lib/main.dart` (`AnalyticsService.instance.init()` before `runApp`)
- Identify/reset/login/signup: `lib/features/auth/providers/auth_provider.dart`

## Events (19) and their seams

| Event | Properties | Fired at (post-API-success) |
|---|---|---|
| `identify` (+ person props) | `user_type`, `has_subscription`, `city` | `auth_provider._syncPushIdentity` (all logins + session restore) |
| `reset` | — | `auth_provider.logout` + session-clear |
| `user_signed_up` | `user_type` | `auth_provider.onRegistered` |
| `user_logged_in` | `method` (email/google/apple) | each `signIn*` in `auth_provider` |
| `kolab_created` | `kolab_id` | `kolab_service._create` |
| `kolab_published` | `kolab_id`, `is_direct` | `kolab_service._publish` *(business paywall KPI)* |
| `application_submitted` | `opportunity_id` | `application_service.submitApplication` *(business paywall KPI)* |
| `application_accepted` | `application_id` | `application_service._acceptApplication` |
| `application_declined` | `application_id` | `application_service.declineApplication` |
| `collaboration_completed` | `collaboration_id` | `collaboration_detail_provider._markCompleted` |
| `feedback_submitted` | `collaboration_id`, `rating` | `kolab_completion_sheet._onSubmitFeedback` |
| `community_created` | `community_id`, `type` | `community_service.createCommunity` |
| `community_joined` | `community_id` | `community_service.joinCommunity` |
| `tier_created` | `community_id` | `community_service.createTier` |
| `event_created` | `event_id`, `mode` (upcoming/showcase), `is_recurring` | `event_service.createUpcomingEvent` / `_createEvent` |
| `event_signup` | `event_id` | `event_service.signup` *(RSVP)* |
| `event_checked_in` | — | `checkin_service.checkIn` *(QR gamification)* |
| `message_sent` | `context` (application/thread) | `application_service.sendMessage` + `chat_service.sendMessage` |
| `subscription_started` | `product_id` | `iap_service._handlePurchaseUpdate` (purchased only, not restored) *(revenue KPI)* |

## Suggested funnels (build in PostHog once events ingest)
- **Business activation:** `user_signed_up` → `kolab_published` → `application_accepted` → `collaboration_completed`.
- **Business monetization:** `kolab_published` (paywall hit) → `subscription_started`.
- **Community/event:** `community_created` → `event_created` → `event_signup` → `event_checked_in`.

## Verify
Events appear under PostHog → Activity (live) once the app runs on a device/sim
and a user performs these actions. (Not yet verified live — pending a device run.)
