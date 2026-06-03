# Task: Google Photos Preview Sheet

## Status
- Created: 2026-05-21
- Started: 2026-05-21
- Completed: 2026-05-21

## Description
When a business selects a venue from Google during onboarding step 1, every Google photo is silently imported into `venuePhotos` before the user sees them. Add a modal bottom sheet that previews the imported photos and lets the user remove individual ones before they land in onboarding state. Per-photo remove already exists later in the flow, but users want the review moment *before* import.

## Related API Endpoints
- N/A (client-side only; uses photos already returned by existing `getPlaceDetails`)

## Assigned Agents
- [x] @ui-designer
- [x] @flutter-expert

## Progress

### UX Design
**Status:** Done
- User flow: select venue → `getPlaceDetails` returns → if photos.isNotEmpty, show bottom sheet → user toggles photos → confirm with selection → `applyPlaceImport` with filtered list → navigate to step 2.
- UI:
  - Drag handle, header `Review photos from Google`, sub `Tap any photo to remove it before we add them to your venue.`
  - 3-column grid of photo tiles. Kept: normal preview + green check chip top-right. Removed: dimmed + red X chip, tap to bring back.
  - Footer primary button: `ADD N PHOTOS` (N = kept count). When N == 0 → label becomes `SKIP PHOTOS`.
  - Dismiss / drag-down = treat as "Add N photos" with current state (safer default — keep import going).
- States: loading not needed (data already in memory). Empty photos → sheet skipped entirely. Error → not applicable.

### Flutter Implementation
**Status:** Done
- New widget: `lib/features/onboarding/widgets/google_photos_preview_sheet.dart`
  - Static `show(...)` returns `Future<Set<String>>` of kept `resourceName`s (or all if dismissed).
- `applyPlaceImport` accepts optional `photoOverride: List<ImportedGooglePhoto>?` (when non-null, replaces `placeImport.primaryVenue.photos` for the photo-mapping step only).
- `business_step5_screen.dart::_handlePlaceSelected` shows the sheet between `getPlaceDetails` and `applyPlaceImport` when photos are present.

## Notes
- Reused existing `KolabingColors`, `GoogleFonts.rubik/openSans/dmSans`, and `Image.network` patterns from `venue_photo_manager.dart`.
- The sheet is non-blocking-cancelable: swiping it down keeps the user's current selection (defaulting to "keep all") so we never throw away the rest of the import (name, address, hours) just because the user dismissed.
