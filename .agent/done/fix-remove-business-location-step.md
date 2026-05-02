# Fix: Remove "Where are you located?" screen from business onboarding

## Status
- Created: 2026-05-02
- Started: 2026-05-02
- Completed: 2026-05-02

## Issue Description
Business onboarding starts with a "Where are you located?" location picker screen
that we no longer need. Make business onboarding start similarly to community —
go straight into venue/profile details.

## Root Cause
N/A — product decision. The screen was an unnecessary first step before the
venue type/capacity step.

## Affected Files
- `lib/config/routes/routes.dart` — step1 route now redirects to step2; removed import
- `lib/features/onboarding/screens/business/business_screens.dart` — removed step1 export
- `lib/features/onboarding/screens/business/business_step1_screen.dart` — **deleted**
- `lib/features/onboarding/screens/business/business_step2_screen.dart` — `currentStep: 1, totalSteps: 3`
- `lib/features/onboarding/screens/business/business_step3_screen.dart` — `currentStep: 2, totalSteps: 3`
- `lib/features/onboarding/screens/business/business_step4_screen.dart` — `currentStep: 3, totalSteps: 3`
- `lib/features/onboarding/screens/business/business_final_screen.dart` — Edit redirects to step2
- `lib/features/auth/screens/user_type_selection_screen.dart` — pushes step2 for business
- `lib/features/auth/utils/auth_navigation.dart` — `resolveAuthDestination` returns step2
- `lib/features/auth/providers/auth_state_provider.dart` — splash check uses step2
- `lib/features/kolab/screens/business/venue_details_screen.dart` — "Complete onboarding" redirect goes to step2

## Fix Applied
- Deleted `business_step1_screen.dart` entirely.
- Re-numbered remaining business onboarding step indicators from 4 steps → 3 steps.
- Replaced every callsite that pushed/redirected to `step1` with `step2`.
- Kept the `/onboarding/business/step1` URL alive as a `redirect` route to step2 so
  any cached deeplinks survive the change.

## Testing
- [x] `dart analyze lib/` — 0 errors
- [x] No orphan references to BusinessStep1Screen, business_step1, or step1 path remain
- [x] Step indicators show 1/3, 2/3, 3/3 across the three remaining steps

## Notes
The location data was previously written to onboarding state on step1. After this
change, location is no longer captured at onboarding time. If the backend requires
a location at registration, capture it elsewhere (e.g. inside the venue card or
as part of the step2 venue address field). This was not part of the product ask.
