# Task: phase2-fix-signup-completability

## Status
- Created: 2026-05-21 10:30
- Started: 2026-05-21 10:30
- Completed:

## Description
Phase 2 — sign-up completability (E2, E3, E5, C6, E1).

## Audit findings

After reading the current codebase:

### Already fixed in earlier work (verified, not re-implemented)
- **E2** (App opens directly into Register): `splash_screen.dart` → `splashStateProvider.initialize()` returns `KolabingRoutes.welcome` when no auth token. `welcome_screen.dart:160,165` exposes **both** `userTypeSelection` (Register) and `login` (Login) CTAs. The done-folder tasks `redesign-splash-auth-flow.md` and `welcome-screen-v3-three-audience.md` implemented this. Verified.
- **E3** (Password field missing on Create Account): Both `business_final_screen.dart` and `community_final_screen.dart` have Email + Password + Confirm Password + (optional Referral) fields with validators (`_validateEmail`, `_validatePassword`, `_validateConfirmPassword`). Daniel's report is from a build that predates `redesign-splash-auth-flow.md`. Verified.
- **E1** (Merge venue + business signup): `routes.dart:371-395` shows business onboarding step1/step3/step4 are all redirects. Real wizard is `step5` (Google Places venue picker) → `step2` (business+venue identity merged) → `final` (email/password). No separate "venue sign-up". Verified.

### Real work in this task

#### E5 — "Add photo" → "Add logo" on business onboarding Step 2

**Root cause**: `lib/features/onboarding/widgets/photo_upload_widget.dart:279` hardcodes the label `'Add photo (optional)'`. The widget is used in `business_step2_screen.dart:310` (business logo) and elsewhere.

**Fix**: Add `addLabel` parameter to `PhotoUploadWidget` (default `'Add photo (optional)'`). Pass `'Add logo (optional)'` from business step 2.

#### C6 — Full street address (scope shift)

Daniel's C6 report describes the **Kolab venue promotion review card** showing only "Barcelona, Spain · Barcelona" with no street line. This is NOT the business signup (signup already uses Google Places `formattedAddress` — verified `business_step5_screen.dart:42,86`).

The actual bug is in the **Kolab venue promotion flow**:
- `kolab.venueAddress` (`venue_details_screen.dart:142`) appears to be a free-text inheritance from the business profile that loses the `formatted_address` from Google Places.

**Recommendation**: Move C6 to Phase 4 (content creation friction) where the Kolab promotion flow lives. Not blocking signup completability.

## Changes applied

### E5 fix
- `lib/features/onboarding/widgets/photo_upload_widget.dart`:
  - Add optional `addLabel` parameter (defaults to current copy).
  - Render `widget.addLabel` when no photo selected.
- `lib/features/onboarding/screens/business/business_step2_screen.dart`:
  - Pass `addLabel: 'Add logo (optional)'` to `PhotoUploadWidget` (this slot is the business brand logo, not a venue photo — Daniel's complaint).
- Community step 2 (if it uses the same widget) keeps the default `'Add photo (optional)'` for community photo upload.

## Verification
1. `flutter analyze` clean on touched files.
2. Existing onboarding tests pass.
3. Manual: business onboarding step 2 → empty photo slot shows "Add logo (optional)"; community onboarding step 2 → empty slot still says "Add photo (optional)".

## Files touched
- `lib/features/onboarding/widgets/photo_upload_widget.dart`
- `lib/features/onboarding/screens/business/business_step2_screen.dart`

## Notes
- C6 is real but lives in Kolab venue promotion, not signup. Adding to Phase 4 task: audit `kolab.venueAddress` inheritance from `OnboardingData.location.formattedAddress` and ensure the full street appears in the promotion review card.
- E2/E3/E1 should be re-verified by Daniel against the next build (the code is correct now, but his last QA was on an older build). The acceptance criterion is just "freshly built app behaves correctly."
