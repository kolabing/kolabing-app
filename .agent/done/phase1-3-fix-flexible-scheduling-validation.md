# Task: phase1-3-fix-flexible-scheduling-validation

## Status
- Created: 2026-05-18 15:15
- Started: 2026-05-18 15:15
- Completed:

## Description
C8: On Create Kolab business flow, picking "Flexible" availability mode lets the user proceed without choosing a start date — but publish requires one. Result: silent block at publish step.

## Root cause
`lib/features/kolab/screens/business/availability_screen.dart:162-191` — for `AvailabilityMode.flexible` the UI shows ONLY an info note (no date pickers).
`lib/features/kolab/providers/kolab_form_provider.dart:722-734` — validator requires `availabilityStart` for all modes including flexible (mode-agnostic check after mode is picked).

Mismatch: validator demands input that UI never collects → silent step-advance, then a publish-time error the user can't act on.

Daniel's preferred fix (Option B): Show DateRangeSection inside flexible mode, treating it as an open window with a required start.

Community side already does this (logistics_screen.dart has date range inputs for flexible + `logistics validation flexible mode requires start and end` test passes).

## Changes applied
- `lib/features/kolab/screens/business/availability_screen.dart`:
  - Move the existing info note (`"Communities will propose a time..."`) so it remains visible
  - Add `_buildDateRangeSection` inside flexible branch with a label tweak ("Window during which you're open") so users understand it's a flexible window, not a fixed range
  - Keep the same `_pickDateRange` widget so date selection logic is shared
- No validator change needed — current validator already requires start for flexible; the fix is exposing the input.

## Verification
1. `flutter analyze` clean on touched file.
2. Existing kolab tests pass (esp. business-side validation in `_validateVenuePromotionStep`).
3. Manual: choose Flexible → see date range input → must select start before "Next" advances.
4. Manual: choose Flexible, leave dates empty, tap Next → inline error appears on the date field (not a silent block).

## Files touched
- `lib/features/kolab/screens/business/availability_screen.dart`
