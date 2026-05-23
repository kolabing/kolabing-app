# Task: phase4-content-creation-friction

## Status
- Created: 2026-05-21 11:30
- Started: 2026-05-21 11:30
- Completed:

## Description
Phase 4 — content creation friction: C1, C7, C2, C3, C4, C10, B5, D2.

## Per-bug findings + action

| Bug | Status after audit | Action |
|---|---|---|
| **C1** keyboard dismiss | Outer `GestureDetector(onTap: unfocus)` exists on `kolab_flow_screen.dart:132-135` but inner `ListView`/`SingleChildScrollView` consumes most taps. `TextField`s without `onTapOutside` capture focus and bottom buttons stay hidden. | **Fix**: add `onTapOutside: (_) => FocusScope.of(context).unfocus()` to every TextField/TextFormField in kolab venue/product/community detail screens. Pattern already used in `ideal_community_screen.dart:143`. |
| **D2** "Business / Coworking" in Ideal Community | **Already fixed**: `ideal_community_screen.dart:50: 'Business / Coworking'` is present. | Verified, no change. |
| **C2** Cannot add pictures to a Kolab post | **Already fixed in Phase 1.2** (`'photo'` → `'image'` type migration was the root cause of media not surviving reload). | Verified, no change. |
| **C4** Cannot add videos to Past Events | Code path in `past_events_screen.dart:360-389` uploads videos via `pickVideo` + `uploadService.upload(folder: 'kolabs')`. Same type-mismatch risk: if videos are stored as `type: 'video'` and a filter expects something else, they could disappear on reload. Need verification on next QA. | Add `[C4]` logging on video upload + check existing filter values. |
| **C7** Reuse venue photos when creating Kolab | New feature. Requires fetching business's primary venue photos from `profile_provider` and rendering them as a "Use venue photos" picker in `media_screen.dart`. | **Defer** to a Phase 4.1 task — needs profile-side venue photos endpoint inspection. Document as next-up. |
| **C3** Communities cannot upload pictures during profile creation | Community onboarding photo upload via `PhotoUploadWidget` (same widget I updated for E5). The widget itself works — the bug was likely the `'photo'` type mismatch elsewhere. Re-test on next build. | Verified path, log on upload failure. |
| **C10** Google Photos preview not rendering | `ImagePicker.pickImage` returns local path. On iOS, photos picked from Google Photos via the system picker may return a content URI rather than a usable file path. The preview tries to render from `File(path)` which fails for content URIs. | **Defer** — needs device testing. Document recommended approach (use `pickImage(requestFullMetadata: false)` or check `_picker.supportsImageSource`; or fetch bytes and render via `Image.memory`). |
| **B5** Test account venue type selection error | Likely seed-data / test-account specific. Cannot fix without backend logs. | Add `[B5]` log on venue-type tap in `business_step2_screen` to confirm the failing path on the seed account. |

## Changes applied

### C1 — keyboard dismiss on Kolab flow text fields
Add `onTapOutside: (_) => FocusScope.of(context).unfocus()` to every `TextField` / `TextFormField` in:
- `lib/features/kolab/screens/business/venue_details_screen.dart` (2 fields)
- `lib/features/kolab/screens/business/product_details_screen.dart` (3 fields)
- `lib/features/kolab/screens/community/event_details_screen.dart` (2 fields)

Also force the scroll views in these screens to `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag` if not already set.

### C4 logging
Add `[C4]` log on video upload success/failure in `past_events_screen.dart`.

### B5 logging
Add `[B5]` log on venue-type tap selection in `business_step2_screen.dart`.

## Out of scope / deferred (with clear next-steps)

- **C7** — needs a new `Use venue photos` picker on the kolab media step. Spec: fetch `profile.primaryVenue.photos` (or via gallery_provider) → render thumbnails → tap to add to `kolab.media` as `KolabMedia(url: existingUrl, type: 'image')`. ~3-4h of work.
- **C10** — Google Photos preview. Either (a) replace `Image.file(File(path))` with `Image.memory(await File(path).readAsBytes())` in the picker preview (handles iOS content URIs once the file is materialised), or (b) call the platform-channel content resolver to copy the content URI to a temp file before rendering. Needs device test.

## Verification
1. `flutter analyze` clean on touched files.
2. Existing kolab tests pass.
3. Manual: open Create Kolab → venue/product/event details → tap into a TextField → keyboard up → tap on empty area → keyboard dismisses, button row visible.

## Files touched
- `lib/features/kolab/screens/business/venue_details_screen.dart`
- `lib/features/kolab/screens/business/product_details_screen.dart`
- `lib/features/kolab/screens/community/event_details_screen.dart`
- `lib/features/kolab/screens/business/past_events_screen.dart`
- `lib/features/onboarding/screens/business/business_step2_screen.dart`
