# Task: phase1-1-fix-business-signup-account-creation

## Status
- Created: 2026-05-18 14:30
- Started: 2026-05-18 14:30
- Completed:

## Description
B6 (2026-05-17): Business sign-up cannot complete account creation. Failure point unknown — Daniel asked to "capture exact screen + error string on next test." Top-of-funnel blocker.

## Root cause investigation (codebase audit)

Flow audited end-to-end:
- `BusinessFinalScreen` (lib/features/onboarding/screens/business/business_final_screen.dart) collects email/password/confirm/referral — **structurally complete**, has password field (so E3 isn't here).
- `_handleSubmit` → `OnboardingNotifier.completeWithEmail` (lib/features/onboarding/providers/onboarding_provider.dart:554) → `AuthService.registerBusiness` (lib/features/auth/services/auth_service.dart:183) → `POST /api/v1/auth/register/business` with payload from `OnboardingData.toBusinessPayload()` (lib/features/onboarding/models/onboarding_state.dart:344).
- On success: `_saveAuthData` → `checkAuthStatus` → `OnboardingResult(success:true)` → `_finishOnboardingSuccess` → `context.go(/permissions?destination=/business)` or `/business`.
- Routes (lib/config/routes/routes.dart:371-396): `step1` and `step3` and `step4` are all redirects to step2/step5. Real flow: step5 → step2 → final.

No structural bug found in code path. **Real failure is almost certainly a backend validation error** that the user can't read because:
1. `_showErrorSnackBar` uses a 4-second SnackBar with no scroll, no copy — server error like "primary_venue.photos.0 must be a valid url" disappears before user reads it.
2. `result.displayError` returns only `error.message` (top-level) — does NOT include `error.errors` field-level details from 422 responses unless the field matches `email`/`password`/`referral_code`.
3. Photo payload (`payloadValue`) sends 3 different shapes (data URI / Google resource_name / remote URL) — if backend rejects one shape, the user sees nothing.

## Changes applied

### 1. Persistent error banner instead of snackbar
File: `lib/features/onboarding/screens/business/business_final_screen.dart`
- Added `_apiErrorBanner` state, shown above form when API rejects with non-field-mapped error.
- Banner shows: server message + `allErrorMessages` (every field error joined) + a "Copy details" button for QA.
- Banner persists until user taps Dismiss or retries.

### 2. Comprehensive debug logging
File: `lib/features/onboarding/screens/business/business_final_screen.dart` + `lib/features/onboarding/providers/onboarding_provider.dart`
- Each step of `_handleSubmit` and `completeWithEmail` logs with `[B6]` prefix.
- Logs include: request URL, payload keys, payload size, response status, full response body (truncated), exception type & message.

### 3. Payload-shape audit logged
File: `lib/features/onboarding/models/onboarding_state.dart`
- When building `primary_venue.photos`, log the photo source mix (upload/googleImported/hosted counts) so we know which shape the failing payload uses.

## Why not "fix the backend issue directly"
Without the exact server error string, picking a fix is guessing. The diagnostic improvements turn the next QA pass into a definitive root-cause capture. Once Daniel re-tests and shares the banner contents, the actual fix is a one-liner (rename a field, add a missing required, drop a bad photo shape, etc.).

## Verification plan for next QA
1. Re-test business sign-up on iOS sim or device with current build.
2. When account creation fails, screenshot the persistent error banner (no longer disappears in 4s).
3. Tap "Copy details" — paste contents back to the team.
4. Filter terminal logs for `[B6]` — captures every step of the request lifecycle.

## Related agents
- @flutter-expert (this task)

## Files touched
- `lib/features/onboarding/screens/business/business_final_screen.dart`
- `lib/features/onboarding/providers/onboarding_provider.dart`
- `lib/features/onboarding/models/onboarding_state.dart`

## Notes
- Same diagnostic pattern should be applied to community sign-up (mirror flow at `community_final_screen.dart`) — flagged for Phase 2.
- The 422 field-error mapping currently only surfaces `email`, `password`, `referral_code`. If server reports errors on `primary_venue.photos` or `business_type`, they're lost. The new banner closes that gap by also showing `allErrorMessages`.
