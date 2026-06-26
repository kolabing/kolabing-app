# Design: Default Cover Fallback for Business Kolab Photo Step

Date: 2026-06-26

## Problem

The Media step in the venue/product Kolab creation flow (`lib/features/kolab/screens/business/media_screen.dart`) hard-blocks "Next" when a business has no photo and no existing profile/venue photos to reuse. This feels like a forced upload. We want businesses to be able to publish with a Kolabing default cover instead, scoped to exactly 2 types for now (product, venue), matching `IntentType.productPromotion` / `IntentType.venuePromotion`. Each type has 2 photo variants, picked at random when chosen, for visual variety.

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

**Update (2026-06-26): 2 variants per type were provided, not 1.** Real photos were placed at `assets/images/defaults/product_cover_1.png`, `product_cover_2.png`, `venue_1.png`, `venue_2.png` (note the inconsistent venue filenames — no `_cover` infix; constants below match what's actually on disk rather than renaming files). Since there are 2 options per intent type, we pick one at random when the business taps "Use default cover", so not every product/venue Kolab on Explore looks identical. The pick happens once, at tap time — it is not re-randomized on rebuild (the chosen URL is just a normal `KolabMedia` entry in `kolab.media` after that).

`lib/features/kolab/constants/default_covers.dart`:

```dart
const _productDefaultCoverPaths = [
  '/storage/default-kolab-covers/product_cover_1.png',
  '/storage/default-kolab-covers/product_cover_2.png',
];
const _venueDefaultCoverPaths = [
  '/storage/default-kolab-covers/venue_1.png',
  '/storage/default-kolab-covers/venue_2.png',
];

final _random = Random();

String pickDefaultCoverPathFor(IntentType intent) {
  final paths = intent == IntentType.venuePromotion ? _venueDefaultCoverPaths : _productDefaultCoverPaths;
  return paths[_random.nextInt(paths.length)];
}

bool isDefaultCoverUrl(String url) =>
    _productDefaultCoverPaths.any(url.endsWith) || _venueDefaultCoverPaths.any(url.endsWith);
```

`KolabMedia.fromJson` sets `isDefaultCover: isDefaultCoverUrl(url)`.

## UI changes (`media_screen.dart`)

Copy:
- Title: "ADD PHOTOS" (kept, existing style) — subtitle changes to: "Kolabs need a cover image. You can upload your own or use a Kolabing default."
- Keep the existing standing tip container, but only show it once a choice has been made (media non-empty) — soft encouragement, not a precondition.

When `kolab.media.isEmpty` (no choice made yet — applies only to `venuePromotion`/`productPromotion`; `communitySeeking` is untouched, its media step has no validation):

Two equal-weight choice cards replace today's single "Use business photo or choose existing" button:

1. **Upload my photo** (icon: camera/upload) — helper: "Best if you have a real product, venue, food, or event image." Taps into existing `_pickAndUploadPhoto()`.
2. **Use default cover** (icon: image/sparkles) — helper: "We'll use a designed Kolabing cover for this type of Kolab." Tapping calls a new `notifier.useDefaultCover(intentType)` which pushes `KolabMedia(url: normalizeRemoteMediaUrl(pickDefaultCoverPathFor(intent)), type: 'image', sortOrder: 0, isDefaultCover: true)` — no network call, no loading state.

Below both cards, small text: "You can replace it later with your own photo." The existing gallery/venue "choose existing photo" CTA (`_selectExistingPhotos`) is demoted to a small text link under the two cards (only shown when `showReuseCta` is true, same condition as today).

Once `kolab.media` is non-empty (default chosen or real photo uploaded), show the grid as today (`_PhotoGrid`). `_PhotoSlot` gets a small "Default" pill badge (top-left, subtle) when `photos[i].isDefaultCover` is true, so it's clear to the business that this is a placeholder.

**Auto-replace on real upload:** in `_pickAndUploadPhoto()`, before calling `notifier.addMedia(...)`, if the only existing media entry `isDefaultCover`, remove it first (`notifier.removeMedia(0)`) so the new real photo takes its place at `sortOrder: 0` rather than appending — keeps the "replace it later" promise literal instead of leaving two photos.

## Validation (`kolab_form_provider.dart`)

No change needed. `kolab.media.isEmpty` becomes `false` the instant a default cover is selected (it's a real entry in `kolab.media`), so the existing checks at lines 838-844 (venue) and 914-920 (product) already pass. `_hasUsableDefaultPhoto` (gallery/venue reuse fallback) is untouched and still works as today's secondary grace path.

## Assets — superseded: real photos provided instead of illustrations

The original style direction (illustrated/semi-abstract, hand-drawn line art) was the brief, but the assets actually placed at `kolabing-app/assets/images/defaults/` are **real lifestyle photos** — generic, staged community/gathering shots not tied to any specific real venue or product:

- `product_cover_1.png`, `product_cover_2.png` — a group sharing/unboxing food/product items.
- `venue_1.png`, `venue_2.png` — people gathered at an outdoor café-style table.

Per direct product decision, we proceed with these as the actual default covers rather than the illustrated style originally specified — they read as generic "community gathering" stock-style photography rather than a specific fake business, which is the main thing the original brief was guarding against (a default cover that looks like it depicts *this* business's real venue/product when it doesn't). The illustrated-style direction is dropped for v1; revisit only if these photos read as misleading in practice.

Files needed in two places (already done on the Flutter side):

1. ✅ `kolabing-app/assets/images/defaults/product_cover_1.png`, `product_cover_2.png`, `venue_1.png`, `venue_2.png` — done, used as instant local preview thumbnails inside the "Use default cover" choice card. Must be declared under `flutter: assets:` in `pubspec.yaml`.
2. ⬜ `kolabing-v2/storage/app/public/default-kolab-covers/product_cover_1.png`, `product_cover_2.png`, `venue_1.png`, `venue_2.png` — still needed, same 4 files copied to the backend's public disk so the submitted `KolabMedia.url` actually resolves at `{APP_URL}/storage/default-kolab-covers/...` (storage symlink already exists, confirmed via the working `category-icons` convention). This is a file copy, not a code change.

Until step 2 is done: the local choice-card preview works fine (it's a bundled asset), but the actual default-cover URL submitted to the API will 404 — same as any missing static asset, not a fabricated domain. The 4 backend files must be in place before this ships to real users.

## Out of scope (explicitly, per product decision)

- No additional fallback types (community perk, event/experience, content/UGC, review/feedback) — only product + venue.
- No change to `communitySeeking` flow.
- No backend code/migration/endpoint changes — purely a static-file drop using the existing public-disk pattern.
