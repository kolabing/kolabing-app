# Kolabing Bug Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore broken auth, publish, draft, search, and media flows with minimal Flutter/client changes, plus document any backend follow-up required.

**Architecture:** Reuse the app's existing Riverpod providers, service classes, and GoRouter routes. Fix bugs at the failing integration boundaries: splash bootstrap to routing, form/provider to opportunity API, and picker UI to platform permission metadata.

**Tech Stack:** Flutter, Riverpod, GoRouter, flutter_secure_storage, image_picker, permission_handler

---

### Task 1: Auth bootstrap and post-login routing

**Files:**
- Modify: `lib/features/auth/screens/splash_screen.dart`
- Modify: `lib/features/auth/providers/auth_state_provider.dart`
- Modify: `lib/features/auth/providers/auth_provider.dart`
- Modify: `lib/config/routes/routes.dart`

- [ ] **Step 1: Route splash through the existing splash initializer**

Use `splashStateProvider.notifier.initialize()` from `SplashScreen` after the animation timing completes, then navigate to the returned route instead of hard-coding `/auth/welcome`.

- [ ] **Step 2: Normalize canonical auth routes**

Keep `/auth/sign-in` as a legacy redirect if needed, but make app-owned navigation use the real login route constant so successful auth never lands on a placeholder path.

- [ ] **Step 3: Keep restored auth state aligned with cached token/user**

When auth status is checked, populate both `user` and `token` from `AuthService` so app state reflects persisted secure-storage data.

- [ ] **Step 4: Re-run auth navigation call sites**

Update any direct string route usage touched by this flow to use the canonical login/dashboard paths already defined in `routes.dart`.

### Task 2: Publish, drafts, and search

**Files:**
- Modify: `lib/features/opportunity/services/opportunity_service.dart`
- Modify: `lib/features/opportunity/providers/opportunity_form_provider.dart`
- Modify: `lib/features/opportunity/providers/opportunity_provider.dart`
- Modify: `lib/features/community/screens/my_opportunities_screen.dart`
- Modify: `lib/features/business/screens/my_kollabs_screen.dart`
- Modify: `lib/features/business/screens/explore_screen.dart`

- [ ] **Step 1: Make draft saves explicit**

Ensure `saveDraft()` sends `OpportunityStatus.draft` both on create and update so draft saves do not accidentally persist a stale published status.

- [ ] **Step 2: Strengthen publish fallback behavior**

Allow `publishOpportunity()` to fall back on status update not only for `403`, but also for common server cases where the dedicated publish endpoint is missing or blocked but inline status update works.

- [ ] **Step 3: Preserve exact backend error messages**

Where provider/UI code currently collapses publish failures to generic copy, surface `ApiException.error.message` so draft/publish failures are diagnosable from the client.

- [ ] **Step 4: Force list refresh after mutating actions**

After publish succeeds, refresh or replace list data so drafts and published tabs immediately reflect the new status.

- [ ] **Step 5: Confirm Explore reacts to search/filter changes**

Keep the current filter sheet, but make sure filter changes reliably trigger a new load instead of leaving Explore in a stale state.

### Task 3: Image upload entry points and permissions

**Files:**
- Modify: `lib/features/onboarding/widgets/photo_upload_widget.dart`
- Modify: `lib/features/community/screens/create_opportunity_screen.dart`
- Modify: `lib/features/business/screens/create_collab_request_screen.dart`
- Modify: `ios/Runner/Info.plist`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Add missing platform permission metadata**

Add iOS photo-library usage strings and Android media-read permissions needed for gallery selection on supported OS versions.

- [ ] **Step 2: Make the business collab upload stub functional**

Replace the no-op upload area with the shared picker flow and store the selected image in the existing opportunity form state.

- [ ] **Step 3: Add the missing community kolab photo control**

Insert the same minimal upload widget into the community creation flow so users can attach a kolab image beyond their profile photo.

- [ ] **Step 4: Improve picker error feedback**

If the picker fails or the user denies access, show actionable snackbar copy instead of silently failing.

### Task 4: UX-level creation-flow fixes

**Files:**
- Modify: `lib/features/community/screens/create_opportunity_screen.dart`
- Modify: `lib/features/business/screens/create_collab_request_screen.dart`
- Modify: `lib/widgets/explore_swipe_card.dart`
- Modify: any directly used event/gallery widget touched by U5/U6 if present

- [ ] **Step 1: Add tap-outside keyboard dismiss**

Wrap the main create-flow bodies so tapping outside form fields calls `FocusScope.of(context).unfocus()`.

- [ ] **Step 2: Hide time picker when date context is missing**

Only render time selection UI when the corresponding availability/date state is valid for that branch of the flow.

- [ ] **Step 3: Reposition carousel dots**

Move swipe-card dot indicators into the image area near the lower edge with better contrast and slightly larger tap-safe visibility.

- [ ] **Step 4: Apply tiny local copy/size fixes where safe**

If the oversized past-event CTA and generic gallery empty-state live in editable client widgets, make copy-only / sizing-only changes without changing behavior.

### Task 5: Onboarding mismatch and backend follow-up capture

**Files:**
- Modify: `lib/features/onboarding/screens/business/business_step2_screen.dart`
- Modify: `docs/superpowers/specs/` follow-up notes if needed

- [ ] **Step 1: Fix the business type selection mismatch**

Because the current onboarding payload is single-select end-to-end, correct the business onboarding copy so it no longer promises unsupported multi-select behavior.

- [ ] **Step 2: Assess event video support honestly**

Verify whether `AddEventModal` and `EventService` support video uploads. If not, do not fake support; document it as a backend/API follow-up item in the final summary.

- [ ] **Step 3: Capture backend-required follow-ups**

List backend-dependent items separately in the final report: curated active cities, result-count masking rules, and event video support if absent.

### Task 6: Verification

**Files:**
- Modify: changed files above

- [ ] **Step 1: Format touched Dart files**

Run: `dart format lib test`

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze`

- [ ] **Step 3: Run tests**

Run: `flutter test`

- [ ] **Step 4: Build app**

Run one concrete proof command for a production-oriented build, preferring Android in this environment:
`flutter build apk`

- [ ] **Step 5: Report evidence and backend gaps**

Summarize what is fixed in the client, what was verified, and which issues still require backend work or API changes.
