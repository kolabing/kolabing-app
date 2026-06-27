# Plan — Saved Kolabs (Recommended | All | Saved)

- **App ticket:** kolabing/kolabing-app#43
- **Backend ticket:** kolabing/kolabing-v2#61 (blocking)
- **Created:** 2026-06-27
- **Backend PR:** kolabing/kolabing-v2#62 (`feat/saved-kolabs-api`) — READY
- **Status:** ✅ App implemented on `feat/saved-kolabs` (against the PR #62 contract). Endpoints confirmed: `POST/DELETE /kolabs/{id}/save`, list `GET /kolabs?saved=1`, `is_saved` on `KolabResource` + `OpportunitySummaryResource`. **Note:** the discovery feed (`/discovery/opportunities` → `DiscoveryOpportunityResource`) does NOT carry `is_saved`, so the Saved tab is fed by `GET /kolabs?saved=1` and a client-side `savedKolabIdsProvider` keeps the deck bookmarks in sync.

---

## 1. Problem

A "Save for later" button exists but does nothing, and there is no place to see saved
kolabs. Make saving real and surface saved items in the Explore feed as a third tab.

**Verified current state**
- `lib/features/profile/screens/public_profile_screen.dart:1188` — `_SendKolabBottomBar`
  "Save for later" button is a **stub**: `onPressed: () => Navigator.of(context).maybePop()`.
- Explore tabs (Recommended | All): `lib/features/business/screens/explore_screen.dart:630-667`
  (`_FeedToggle`), enum `DiscoveryFeed { recommended, all }`
  (`lib/features/discovery/models/discovery_filters.dart`), list via `discoveryListProvider`
  → `DiscoveryService.getOpportunities` → `GET /discovery/opportunities?feed=…`.
- No `is_saved` on `Opportunity` / `DiscoveryItem` / `Kolab`; no saved route/screen.
- Backend: **no** save/unsave/list endpoint, **no** pivot table, **no** `is_saved`.

## 2. Open decision (resolve first)

**What is saved?** Default **(A) kolabs/opportunities** (matches "Recommended | All | Saved"
and the user's wording). Alternative (B) community profiles (where the stub lives). The
backend ticket defaults to (A). If (B) is chosen, the backend pivot keys on `profiles`
instead of `collab_opportunities` and the Saved tab lists communities — same UI pattern.

This plan assumes **(A) kolabs**.

## 3. Backend (kolabing-v2#61) — must land on dev first

1. Migration `saved_kolabs` pivot: `profile_id`, `kolab_id`, `created_at`, `unique(profile_id, kolab_id)`.
2. `Profile::savedKolabs()` belongsToMany.
3. `POST /kolabs/{kolab}/save` (idempotent), `DELETE /kolabs/{kolab}/save`.
4. Saved list: `GET /kolabs?saved=1` (reuse `browse()` — identical shape/paging).
5. `is_saved` (viewer-scoped) on `KolabResource` + `OpportunitySummaryResource`.
6. Tests + deploy to dev.

**App integration contract to confirm when #61 lands:** exact save path, list param
(`?saved=1` vs `/me/saved-kolabs`), and the `is_saved` key name.

## 4. App implementation (after #61 on dev)

Branch: `feat/saved-kolabs` off updated master.

### 4.1 Data layer
- `DiscoveryItem` / `Opportunity`: add `bool isSaved` (parse `is_saved`, default false).
- `DiscoveryFeed`: add `saved`; map to the backend param in `DiscoveryFilters`/service.
- `DiscoveryService`: when `feed == saved`, call the saved list (`GET /discovery/opportunities?feed=saved`
  or `GET /kolabs?saved=1` — match #61). Add `setSaved(id, saved)` →
  `POST`/`DELETE /kolabs/{id}/save`.
- Provider: a `savedKolabsProvider` (or reuse `discoveryListProvider` keyed by feed). A
  small notifier method `toggleSaved(id)` doing optimistic update + revert on error, and
  invalidating the Saved list so it stays in sync.

### 4.2 UI
- `_FeedToggle` (`explore_screen.dart`): 3 segments. Verify the 3-up layout on narrow
  screens (Expanded children already; check label wrapping / use shorter labels).
- Save affordance: bookmark icon (outline/filled) on the opportunity card
  (`lib/features/business/widgets/opportunity_card.dart`) and the swipe card
  (`lib/widgets/explore_swipe_card.dart`); wire the `_SendKolabBottomBar` "Save for later"
  to `toggleSaved` instead of `maybePop` (and only pop after a successful save, or keep
  pop + save — confirm UX).
- Saved tab body: reuse the existing card list; add an **empty state** ("No saved kolabs yet").

### 4.3 i18n (en/es/ca — es Castilian, ca Catalan)
- `exploreFeedSaved`, `savedKolabsEmptyTitle`/`Body`, `kolabSavedToast`/`kolabUnsavedToast`,
  and rename/keep `publicProfileSaveForLater`.

### 4.4 Analytics (optional)
- `kolab_saved` / `kolab_unsaved` via `AnalyticsService`, consistent with the curated set.

## 5. Acceptance
- Save persists to backend; bookmark reflects immediately; survives restart.
- Saved tab lists exactly the viewer's saved kolabs; unsave removes live.
- `flutter analyze` clean, `dart format`, iOS+Android, i18n ×3, BACKLOG updated.

## 6. Sequencing
1. Backend #61 → dev.
2. Confirm contract.
3. App data layer → UI → i18n → tests.
4. PR with screenshots (UI change), `Closes #43`.
