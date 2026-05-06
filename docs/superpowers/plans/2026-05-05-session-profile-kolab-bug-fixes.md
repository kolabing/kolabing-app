# Session, Profile, and Kolab Flow Bug Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stop false session-expiry errors on Home and Applications, make the profile screen render even when secondary profile endpoints fail, and guarantee that community users enter the community kolab flow instead of the business flow.

**Architecture:** Keep changes inside the existing Flutter client layers that already own these behaviors: auth-aware services for retry-on-401, the shared profile Riverpod notifier for staged profile hydration, and the kolab intent-entry screens/providers for community flow gating. Reuse the working token-refresh pattern already present in `ProfileService` instead of introducing a new networking abstraction.

**Tech Stack:** Flutter, Riverpod, GoRouter, flutter_test

---

### Task 1: Session refresh parity for Home and Applications

**Files:**
- Modify: `lib/features/dashboard/services/dashboard_service.dart`
- Modify: `lib/features/application/services/application_service.dart`
- Add/Modify: `test/features/dashboard/services/dashboard_service_test.dart`
- Add/Modify: `test/features/application/services/application_service_test.dart`

- [ ] **Step 1: Write failing dashboard refresh tests**

Cover `DashboardService.getDashboard()` when the first `/me/dashboard` call returns `401` and the retried call after `refreshSession()` returns `200`.

- [ ] **Step 2: Write failing applications refresh tests**

Cover `ApplicationService.getMyApplications()` and `getReceivedApplications()` when the first request returns `401` and the retried request succeeds after `refreshSession()`.

- [ ] **Step 3: Implement minimal retry-on-401 support**

Mirror the existing `ProfileService._sendWithRefresh()` behavior so dashboard and applications reuse refreshed access tokens before surfacing a session-expired error.

- [ ] **Step 4: Re-run the targeted service tests**

Run: `flutter test test/features/dashboard/services/dashboard_service_test.dart test/features/application/services/application_service_test.dart`

### Task 2: Make profile hydration resilient

**Files:**
- Modify: `lib/features/business/providers/profile_provider.dart`
- Add/Modify: `test/features/business/providers/profile_provider_test.dart`

- [ ] **Step 1: Write a failing provider test for partial success**

Make `getProfile()` succeed while `getNotificationPreferences()` fails, and verify that `ProfileNotifier` still exposes the loaded profile instead of leaving the screen empty.

- [ ] **Step 2: Write a failing provider test for optional subscription loading**

For a business profile, make `getSubscription()` fail after `getProfile()` succeeds and verify that profile data still renders while subscription stays nullable.

- [ ] **Step 3: Implement staged state commits**

Persist the main profile into state as soon as `/me/profile` succeeds, then load notification preferences and subscription as follow-up enrichments that may fail without blanking the whole screen.

- [ ] **Step 4: Re-run the targeted provider tests**

Run: `flutter test test/features/business/providers/profile_provider_test.dart`

### Task 3: Lock community users into the correct kolab entry flow

**Files:**
- Modify: `lib/features/kolab/screens/intent_selection_screen.dart`
- Modify: `lib/features/kolab/providers/kolab_form_provider.dart` (only if needed to clear stale intent state)
- Add/Modify: `test/features/kolab/screens/intent_selection_screen_test.dart`
- Add/Modify: `test/features/kolab/providers/kolab_form_provider_test.dart` (only if provider reset logic changes)

- [ ] **Step 1: Keep or extend the failing intent-selection regression**

Verify that a community user does not see or enter the business-only options while profile type is still resolving, and that the community CTA routes into `IntentType.communitySeeking`.

- [ ] **Step 2: Add stale-state protection if needed**

If the investigation confirms prior intent state can leak into a fresh `/kolab/new` visit, reset the kolab form state when the user re-enters the intent picker.

- [ ] **Step 3: Implement only the minimal community-flow fix**

Ensure the community entry path resolves profile type before rendering options and that the first community action always selects `IntentType.communitySeeking`, which avoids venue-only validation paths.

- [ ] **Step 4: Re-run the targeted kolab tests**

Run: `flutter test test/features/kolab/screens/intent_selection_screen_test.dart test/features/kolab/providers/kolab_form_provider_test.dart`

### Task 4: Verification and review

**Files:**
- Modify: changed files above

- [ ] **Step 1: Format touched Dart files**

Run: `dart format` on the touched `lib/` and `test/` files.

- [ ] **Step 2: Run the focused regression suite**

Run:
`flutter test test/features/dashboard/services/dashboard_service_test.dart test/features/application/services/application_service_test.dart test/features/business/providers/profile_provider_test.dart test/features/kolab/screens/intent_selection_screen_test.dart test/features/kolab/providers/kolab_form_provider_test.dart`

- [ ] **Step 3: Run a focused analyzer pass**

Run: `flutter analyze` on the touched files if full-repo analysis is still blocked by unrelated pre-existing failures.

- [ ] **Step 4: Do a code review pass**

Review the final diff for regressions, confirm backend assumptions stayed unchanged, and document any backend follow-up separately only if a client-side fix cannot remove the blocker.
