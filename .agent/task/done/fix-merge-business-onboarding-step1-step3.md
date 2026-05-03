# Fix: Merge business onboarding step 1 and step 3

## Status
- Created: 2026-05-03 15:20
- Started: 2026-05-03 15:20
- Completed: 2026-05-03 15:35

## Issue Description
Business onboarding step 1 (venue details: name/type/capacity) and step 3 (business
profile: business name/type/photo/about/contacts) are nearly redundant. Both ask for
"name" and "type" — just labelled differently. The user wants:

1. Merge the two screens into one.
2. The merged screen asks **business name** + **business_type** (primary identifiers).
3. All "other questions" (about, phone, Instagram, website, venue type, capacity)
   live on the same merged screen.
4. The **business photo** should be on this merged screen.

Result: total flow drops from 4 → 3 stepped screens (merged → venue photos → address)
plus the email/password final screen.

## Root Cause
Historical split kept "venue identity" (Step 2 file) separate from "business identity"
(Step 4 file), producing two name fields (`venueName` and `name`) the user perceived
as duplicates. With one shared name, the venue inherits the business name on submit.

## Affected Files
- `lib/features/onboarding/screens/business/business_step2_screen.dart` — rewrite as merged screen
- `lib/features/onboarding/screens/business/business_step3_screen.dart` — header 2/3, continue → step5
- `lib/features/onboarding/screens/business/business_step5_screen.dart` — header 3/3
- `lib/features/onboarding/screens/business/business_step4_screen.dart` — delete
- `lib/features/onboarding/screens/business/business_screens.dart` — remove step4 export
- `lib/features/onboarding/models/onboarding_state.dart` — `isStep2Complete` reflects merged fields; `name` propagates to `venueName`
- `lib/features/onboarding/providers/onboarding_provider.dart` — `updateName` mirrors to `venueName`
- `lib/config/routes/routes.dart` — replace step4 GoRoute with redirect to step3; drop step4 import

## Fix Applied
- Rewrote `business_step2_screen.dart` as the single merged screen: business
  photo, business name, business types (multi-select), venue type, capacity,
  about, phone, Instagram, website. Header shows "Step 1 of 3".
- `OnboardingNotifier.updateName` now mirrors the value into `venueName` for
  business users so `primary_venue.name` stays in sync without a second field.
- `OnboardingData.isStep2Complete` now requires name + business type slugs +
  venue type + capacity. `isStep4Complete` defers to `isStep2Complete` for
  business users (kept for `canProceed`/`isComplete` compatibility).
- Updated venue-photos screen header to "Step 2 of 3" and made it push to
  `/onboarding/business/step5` (skipping the deleted step 4).
- Updated address screen header to "Step 3 of 3".
- Replaced the step-4 GoRoute with a redirect to step 2 and removed the
  step-4 import from routes; deleted `business_step4_screen.dart` and its
  export from `business_screens.dart`.

## Testing
- [x] `dart analyze lib/features/onboarding lib/config/routes/routes.dart` →
      no errors or warnings (info-level lints only).
- [x] Flow now reads: user-type-selection → step2 (merged) → step3 (photos)
      → step5 (address) → final (email/password).
- [x] Step-4 deep links redirect to step 2.
- [x] Business profile photo present on the merged screen via
      `PhotoUploadWidget`.

## Notes
Header step labels become "Step 1/2/3 of 3".
