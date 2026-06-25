# Design: Default Cover Fallback for Business Kolab Photo Step

Date: 2026-06-26

## Problem

The Media step in the venue/product Kolab creation flow (`lib/features/kolab/screens/business/media_screen.dart`) hard-blocks "Next" when a business has no photo and no existing profile/venue photos to reuse. This feels like a forced upload. We want businesses to be able to publish with a Kolabing-designed default cover instead, scoped to exactly 2 types for now (product, venue), matching `IntentType.productPromotion` / `IntentType.venuePromotion`.

## Constraint: no fake/broken URLs

Backend (`CreateKolabRequest`/`UpdateKolabRequest`) validates `media.*.url` with Laravel's `url` rule only — no domain restriction, no reachability check, and Explore/Review/Admin hot-link the stored URL directly (`KolabResource`). A made-up CDN URL would pass validation but render as a broken image everywhere. So default cover URLs must be real and resolvable from day one.

**Resolution:** reuse the existing `Icon` model's public-disk pattern (`app/Models/Icon.php`): `Storage::disk('public')->url('category-icons/'.$filename)`, i.e. files dropped under `storage/app/public/...` in kolabing-v2, served via the existing storage symlink at `{APP_URL}/storage/...`. We apply the same pattern to a new directory, `default-kolab-covers/`, with two files: `product_cover.png`, `venue_cover.png`. No new backend code/model/endpoint is needed — only the two static files need to be placed in `kolabing-v2/storage/app/public/default-kolab-covers/`.

On the Flutter side, the relative path `/storage/default-kolab-covers/product_cover.png` is resolved to an absolute URL via the existing `normalizeRemoteMediaUrl()` (`lib/utils/remote_media_url.dart`), which already powers every other relative media path in this app (`KolabMedia.fromJson` calls it on `url`). This is the same mechanism, not a new one — so the URL stored in `kolab.media` and submitted to the API is always a real, absolute, working URL once the two files exist on the backend disk. Until the files are uploaded, the URL 404s like any missing asset would — same failure mode as a missing category icon, not a fabricated domain.

## Data model changes (Flutter, `lib/features/kolab/models/kolab.dart`)

Add one field to `KolabMedia`:

```dart
class KolabMedia {
  const KolabMedia({required this.url, required this.type, this.sortOrder = 0, this.isDefaultCover = false});
  final bool isDefaultCover; // not serialized to API — local-only UI flag
}
```

`toJson()` / `fromJson()` are unchanged (the backend doesn't need to know — it's just a URL). `isDefaultCover` is purely a client-side UI hint (for the "Default" badge and the auto-replace-on-upload behavior described below) and is recomputed from the URL on `fromJson` by checking against the two known constants, so it survives a round-trip without a new wire field.

## New constants (Flutter)

`lib/features/kolab/constants/default_covers.dart`:

```dart
const _productDefaultCoverPath = '/storage/default-kolab-covers/product_cover.png';
const _venueDefaultCoverPath = '/storage/default-kolab-covers/venue_cover.png';

String defaultCoverPathFor(IntentType intent) =>
    intent == IntentType.venuePromotion ? _venueDefaultCoverPath : _productDefaultCoverPath;

bool isDefaultCoverUrl(String url) =>
    url.endsWith(_productDefaultCoverPath) || url.endsWith(_venueDefaultCoverPath);
```

`KolabMedia.fromJson` sets `isDefaultCover: isDefaultCoverUrl(url)`.

## UI changes (`media_screen.dart`)

Copy:
- Title: "ADD PHOTOS" (kept, existing style) — subtitle changes to: "Kolabs need a cover image. You can upload your own or use a Kolabing default."
- Keep the existing standing tip container, but only show it once a choice has been made (media non-empty) — soft encouragement, not a precondition.

When `kolab.media.isEmpty` (no choice made yet — applies only to `venuePromotion`/`productPromotion`; `communitySeeking` is untouched, its media step has no validation):

Two equal-weight choice cards replace today's single "Use business photo or choose existing" button:

1. **Upload my photo** (icon: camera/upload) — helper: "Best if you have a real product, venue, food, or event image." Taps into existing `_pickAndUploadPhoto()`.
2. **Use default cover** (icon: image/sparkles) — helper: "We'll use a designed Kolabing cover for this type of Kolab." Tapping calls a new `notifier.useDefaultCover(intentType)` which pushes `KolabMedia(url: normalizeRemoteMediaUrl(defaultCoverPathFor(intent)), type: 'image', sortOrder: 0, isDefaultCover: true)` — no network call, no loading state.

Below both cards, small text: "You can replace it later with your own photo." The existing gallery/venue "choose existing photo" CTA (`_selectExistingPhotos`) is demoted to a small text link under the two cards (only shown when `showReuseCta` is true, same condition as today).

Once `kolab.media` is non-empty (default chosen or real photo uploaded), show the grid as today (`_PhotoGrid`). `_PhotoSlot` gets a small "Default" pill badge (top-left, subtle) when `photos[i].isDefaultCover` is true, so it's clear to the business that this is a placeholder.

**Auto-replace on real upload:** in `_pickAndUploadPhoto()`, before calling `notifier.addMedia(...)`, if the only existing media entry `isDefaultCover`, remove it first (`notifier.removeMedia(0)`) so the new real photo takes its place at `sortOrder: 0` rather than appending — keeps the "replace it later" promise literal instead of leaving two photos.

## Validation (`kolab_form_provider.dart`)

No change needed. `kolab.media.isEmpty` becomes `false` the instant a default cover is selected (it's a real entry in `kolab.media`), so the existing checks at lines 838-844 (venue) and 914-920 (product) already pass. `_hasUsableDefaultPhoto` (gallery/venue reuse fallback) is untouched and still works as today's secondary grace path.

## Assets — what's needed before this ships to production

Two files need to be generated and placed by the user (not part of this implementation):

1. `kolabing-app/assets/images/defaults/product_cover.png` — local bundled copy, used only as an instant preview thumbnail inside the "Use default cover" choice card (avoids a network round-trip just to show the picker UI). Declared in `pubspec.yaml` assets.
2. `kolabing-app/assets/images/defaults/venue_cover.png` — same, for venue.
3. `kolabing-v2/storage/app/public/default-kolab-covers/product_cover.png` — the production-serving copy (should be the same artwork as #1), reachable at `{APP_URL}/storage/default-kolab-covers/product_cover.png` once placed (storage symlink already exists, confirmed via the working `category-icons` convention).
4. `kolabing-v2/storage/app/public/default-kolab-covers/venue_cover.png` — same, for venue.

Until these files exist: the local choice-card preview falls back to a simple icon+label placeholder via `Image.asset(...).errorBuilder` (dev safety net only, never submitted to the API), and the actual submitted default-cover URL will 404 if a business picks it before the backend file is in place — same as any missing static asset, not a fabricated domain. This is acceptable for development; the two backend files must be in place before this ships to any real users.

### Image generation prompts (style: Kolabing-branded illustrated/semi-abstract, NOT realistic stock photo, NOT emoji, NOT cartoon)

**Product cover:** "Flat illustrated cover image, warm cream/yellow background (#FFF8E7-ish), black hand-drawn line art style, a simple illustrated table with a product box being unboxed/sampled, small hands reaching toward it, tiny doodle accents (stars, a small speech bubble, a heart) in Kolabing yellow (#FFD861), subtle paper texture, no text, modern friendly premium feel, square or 4:3 aspect ratio, community/product-sampling theme."

**Venue cover:** "Flat illustrated cover image, warm cream/yellow background (#FFF8E7-ish), black hand-drawn line art style, a cozy illustrated café/community table scene with a few simple chairs, a plant, and people gathering, small doodle accents in Kolabing yellow (#FFD861), subtle paper texture, no text, modern friendly premium feel, square or 4:3 aspect ratio, local-venue-gathering theme, not based on any real café."

## Out of scope (explicitly, per product decision)

- No additional fallback types (community perk, event/experience, content/UGC, review/feedback) — only product + venue.
- No change to `communitySeeking` flow.
- No backend code/migration/endpoint changes — purely a static-file drop using the existing public-disk pattern.
