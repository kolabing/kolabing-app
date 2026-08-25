# The community page, second pass — design

**Date:** 2026-08-24
**Status:** approved (Volkan, 2026-08-24)
**Repo:** kolabing-app (Flutter). No backend change.
**Supersedes the layout in:** IF-31 (the first Luma pass, same day)

## Problem

The first pass gave the community page Luma's *shape* — cover band, overlapping
logo, identity, date-grouped events. Held next to Luma's own "The Offline Club |
Barcelona", what it lacks is **substance**, and almost all of it is substance the
backend already sends:

- the cover is a blurred copy of the logo, because nothing looked for a photo;
- there are no photos of the community anywhere;
- the social icons are a `SizedBox.shrink()` seam, though the handles exist;
- points and tier come from a second call, though `GET /communities/{id}` sends
  `my_points` and `my_tier` in the payload the page already has;
- the one chip says the community's type and nothing else;
- a community between events looks dead — `communityPastEventsProvider` exists
  and nothing has ever called it.

## What already exists (verified, not assumed)

| Need | Where it already lives |
|---|---|
| Community photos | `GET /profiles/{id}/gallery`, and `PublicProfile.gallery` rides inside `publicProfileProvider`. Upload/reorder/delete via `me/gallery` is built and shipped. |
| Socials + city | `PublicProfile.instagram / tiktok / website / cityName` on the community owner's profile. |
| Points, tier, manage | `my_points`, `my_tier` (`{id,name,color,rank}`), `my_can_manage` on `CommunityResource` — the app model parses none of them. |
| Past events | `communityPastEventsProvider(communityId)`, already written, never called. |
| Photo viewing | `PhotoViewerDialog.show(photos:, initialIndex:)`, `GalleryPhoto.fromUrl(...)`. |

## Decisions taken

| Question | Decision |
|---|---|
| Where photos come from | **Curated gallery first, event photos as fallback.** The owner's gallery when the leader has one; otherwise photos from the community's own events, so an active community is never photoless. No backend work either way. |
| The chips | **They filter.** Upcoming / Past / Public / Members with real counts, and tapping one filters the timeline. |

## The page

```
┌──────────────────────────────────┐
│ ▓ cover = first real photo ▓ ‹ ⇪⋯│  gallery → event photo → blurred logo → gradient
│ ┏━━━┓                            │
│ ┃LOGO┃                           │
│ ┗━━━┛                            │
│ [QA] Eixample Runners            │
│ Seeded by kolabing:seed-qa…      │  tap to expand
│ 📍 Barcelona · Running club · 3  │  city from the owner profile
│ ⌾ @handle  ♪ @handle  🌐 Website │  the dead seam, wired
├──────────────────────────────────┤
│ ◆ 75 pts · Gold tier          ›  │  my_points / my_tier, no second call
├──────────────────────────────────┤
│ PHOTOS   ▢ ▢ ▢ ▢ ▢               │  tap → PhotoViewerDialog
├──────────────────────────────────┤
│ (Upcoming 3)(Past 7)(Public 2)…  │  counts, and they filter
│                                  │
│ 24 August / Monday               │
│ ▢ [QA] Gamification Test Run     │
│   🕐 18:00 · 📍 Eixample 46      │
│   (Going)(Public)(2 left)        │  NEW capacity badge
├──────────────────────────────────┤
│ GOALS / BADGES / REWARDS         │  unchanged
└──────────────────────────────────┘
```

### Components (added to `community_page_sections.dart`)

- `CommunityCoverHero` gains `coverUrl`: a real photo when there is one, the
  blurred avatar when there isn't, the brand gradient when there is neither.
- `CommunityIdentityBlock` gains a socials row (instagram / tiktok / website,
  each self-gated) — reusing the URL shapes the profile screens already use.
- `CommunityPhotoStrip` — horizontal thumbnails, tap opens `PhotoViewerDialog`.
- `CommunityFilterChips` — selectable chips with counts; selection drives the
  timeline. "Past" swaps the source to `communityPastEventsProvider`.
- `CommunityEventTimeline` rows gain a **capacity badge**: `Full`, `Near
  capacity` (≤20% left), or `N left`. Nothing when the event is uncapped.

### New provider

`communityPhotosProvider` — a `Provider.family` keyed by a
`(communityId, ownerProfileId)` record, returning the curated gallery when it is
non-empty and event photos (newest first, de-duplicated) when it is not.

### Model

`Community` gains `myPoints`, `myTier` (name + colour + rank) and `myCanManage`,
parsed from the payload it already receives.

## Testing

`test/features/community/widgets/community_page_sections_test.dart` grows:

1. the hero prefers a cover photo, and falls back without one;
2. the socials row renders only present handles, and nothing when there are none;
3. filter chips report counts and report their selection;
4. a capped event shows `N left`, a full one shows `Full`, an uncapped one shows
   no badge at all;
5. the photo strip renders the photos it is given.

Plus: `flutter analyze` clean, and the suite's 10 known failures unchanged by
name.

## Accepted costs

- The "curated" gallery belongs to the leader's **profile**, not to the
  community as such: a leader who runs one community sees no difference, and one
  who runs two would see the same photos on both. A real `community_photos`
  table is the fix, and it is deliberately not in this pass.
- Filtering is client-side over what the two providers already loaded, so the
  counts describe what has been fetched, not what exists server-side.
