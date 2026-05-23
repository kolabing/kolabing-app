# Task: phase1-2-fix-paywall-and-image-url

## Status
- Created: 2026-05-18 14:55
- Started: 2026-05-18 14:55
- Completed:

## Description
- **B1** (2026-04-28, NOT FIXED): Unsubscribed business taps PUBLISH → kolab stays as draft, no paywall, no warning. Paywall widget exists and IS wired in `kolab_flow_screen.dart:72-83` via `requiresSubscription` state listener — wiring works only if backend returns 402 or `requires_subscription: true`.
- **B7** (2026-05-17): Publish errors with an "image URL" message.

## Root cause analysis

### B7 — Bug found (high confidence)
- Upload code stores media as `KolabMedia(type: 'photo', ...)` (lib/features/kolab/screens/business/media_screen.dart:66, lib/features/kolab/screens/community/photo_screen.dart:48).
- `KolabMedia.fromJson` defaults `type` to `'image'` (lib/features/kolab/models/kolab.dart:78) — i.e. **the value frontend writes is not the value frontend reads from the API**.
- When kolab is sent to backend with `media[].type = 'photo'`, validation likely rejects it ("must be image/video"). The error references `media.0.url` since URL is the first field on the object, hence Daniel's "image URL" wording.
- Side effect: the media-screen filter `kolab.media.where((m) => m.type == 'photo')` (media_screen.dart:58) breaks on edit/reload — after reloading a draft, media comes back as `type: 'image'`, so the filter returns empty and the user sees an empty photos slot.

### B1 — Hardening needed
- Backend may be silently keeping the kolab as draft on publish without 402. Add a client-side post-publish status check: if `published.status != 'published'`, treat as subscription block and surface paywall.
- Add comprehensive `[B1B7]` logging to capture exact server responses on next QA pass.

## Changes applied

### B7: standardize media type to `'image'`
- `lib/features/kolab/screens/business/media_screen.dart` — `KolabMedia(type: 'photo' → 'image')` and filter `where(type=='photo' → 'image')`.
- `lib/features/kolab/screens/community/photo_screen.dart` — same.
- `lib/features/kolab/models/kolab.dart` — no change (default `'image'` already correct).

### B1: post-publish status guard + logging
- `lib/features/kolab/providers/kolab_form_provider.dart` — after `_service.publish()` returns, check `published.status`. If not `'published'`, set `requiresSubscription: true` to trigger the existing paywall flow. Log every step with `[B1B7]`.

## Verification
1. Run `flutter analyze` on touched files — must pass.
2. Manual: create a kolab with photos, save, reload — photos still show.
3. Manual: tap PUBLISH on unsubscribed account → paywall appears (current code path) OR silent-draft path → paywall appears (new guard).
4. Manual: tap PUBLISH on subscribed account → kolab transitions to `'published'` status.

## Files touched
- `lib/features/kolab/screens/business/media_screen.dart`
- `lib/features/kolab/screens/community/photo_screen.dart`
- `lib/features/kolab/providers/kolab_form_provider.dart`

## Notes
- The 'photo' vs 'image' bug also explains why "communities cannot upload pictures during community profile creation" (C3) and "cannot add pictures to a collaboration" (C2) might appear broken on reload — flagged for Phase 4 audit.
- If the next QA still fails on publish with subscribed account, the next suspect is `KolabMedia.sortOrder` formatting or a backend-only field validation.
