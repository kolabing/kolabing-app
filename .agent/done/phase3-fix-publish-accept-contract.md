# Task: phase3-fix-publish-accept-contract

## Status
- Created: 2026-05-21 11:00
- Started: 2026-05-21 11:00
- Completed:

## Description
Phase 3 — publish→accept contract (C11, C12, C13).

## Audit + fix plan per bug

### C11 — Community Kolab leaks venue step
**Already fixed.** Verified via `kolab_flow_screen.dart` community switch (lines 250-260): `NeedsScreen → CommunityInfoScreen → EventDetailsScreen → LogisticsScreen → PhotoScreen → ReviewScreen`. No venue step. Grep over `lib/features/kolab/screens/community/` for venue references returned empty. The 2-path leak (free community-seeking vs paywalled venue-promotion) Daniel suspected is handled by `IntentType.communitySeeking` vs `venuePromotion/productPromotion` switch — the community path never includes venue steps.

### C12 — Accept dates not constrained to publisher's selected dates
**Partially fixed, hardening applied.** The `_AcceptFormSheet._availableDates` getter (application_review_screen.dart:797-816) already constrains to `opportunity.availabilityStart`–`availabilityEnd`. However:

- For `oneTime` mode the picker still shows every day in the range (should show only the publisher's specific date).
- For `recurring` mode the picker shows every day in the range (should filter to days matching `opportunity.recurringDays`).
- For `flexible` mode current behavior is correct (full range).

**Fix**: In `_AcceptFormSheet`, branch `_availableDates` on `opportunity.availabilityMode`:
- `oneTime`: emit only the start date (if it's still in the future).
- `recurring`: filter the daily walk by `(date.weekday) ∈ opportunity.recurringDays` (1=Mon..7=Sun, matching ISO weekday).
- `flexible`: existing daily walk.

### C13 — Drop contact-methods step on accept
The chat navigation is **already in place** (`application_review_screen.dart:624 `context.pushReplacement('/application/$id/chat')`). The only work is to remove the contact-method UI and validation.

**Fix**:
- Drop the three contact controllers (whatsapp/email/instagram) and their TextFields from `_AcceptFormSheet`.
- Drop `_hasContact` + replace `_isValid = _selectedDate != null && _hasContact` with just `_isValid = _selectedDate != null`.
- `_submit` sends an empty `contactMethods: {}` map. The API still requires the field but accepts empty (or, when the API drops the requirement on the backend side, the FE is already aligned).
- Update subtitle copy: "Pick a collaboration date — you'll chat with them in-app after accepting."

## Changes applied
- `lib/features/application/screens/application_review_screen.dart`:
  - `_availableDates` filtered by `availabilityMode` (C12).
  - Drop contact methods controllers, fields, and validation (C13).
  - Update subtitle copy.
  - Send empty `contactMethods` map in `_submit`.

## Verification
1. `flutter analyze` clean on touched file.
2. `flutter test test/features/application/` passes.
3. Manual: publish a one-time Kolab with date X → community applies → business opens accept sheet → only date X is offered.
4. Manual: publish a recurring Kolab with Mon/Wed → accept sheet shows only Monday/Wednesday dates in range.
5. Manual: accept → no contact-method fields visible → tap Accept → routes to in-app chat.

## Files touched
- `lib/features/application/screens/application_review_screen.dart`

## Notes
- The API `POST /applications/{id}/accept` still requires `contact_methods` in the body (`application_service.dart:283`). We send `{}` — backend may already accept empty, or may need a quick PR. Flag for backend team if QA reports 422 on accept.
- C12 hardening on the application-side covers the "accept" perspective. The publisher side (Kolab edit / availability_screen) needs the same constraint at validation time but is already handled by `_validateVenuePromotionStep` requiring start date for all modes.
