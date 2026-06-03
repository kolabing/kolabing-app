# Explore Tab Redesign Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the full-screen swipe PageView with a scrollable discovery feed showing 2–3 cards simultaneously, preserving all existing providers, filters, detail sheets, and backend contracts.

**Architecture:** A new `DiscoveryFeedScreen` replaces `ExploreScreen`'s `_buildCardPageView` with a `SliverList` of compact `DiscoveryFeedCard` widgets. The screen shell, providers, filters, quick-chips, and detail sheets are reused without modification. `ExploreSwipeCard` is retired.

**Tech Stack:** Flutter, Riverpod 2.4, GoRouter 13, Shimmer, Lucide Icons, Google Fonts (Rubik / Open Sans / DM Sans)

---

## 1. Current Architecture Audit

### What Exists Today

```
lib/
├── features/
│   ├── business/
│   │   └── screens/explore_screen.dart          ← SINGLE ExploreScreen for BOTH user types
│   └── discovery/
│       ├── models/
│       │   ├── discovery_filters.dart            ← DiscoveryFilters, DiscoveryFeed enum
│       │   └── discovery_item.dart               ← DiscoveryItem, DiscoveryMatch, DiscoveryCreatorProfile
│       ├── providers/
│       │   └── discovery_provider.dart           ← discoveryFiltersProvider, discoveryListProvider
│       ├── services/
│       │   └── discovery_service.dart            ← HTTP layer (unchanged)
│       └── widgets/
│           └── discovery_quick_filters.dart      ← DiscoveryQuickFilters + DiscoveryFilterPresets
└── widgets/
    ├── explore_swipe_card.dart                   ← RETIRE: full-bleed PageView card
    ├── explore_detail_sheet.dart                 ← KEEP: modal detail sheet (unchanged)
    └── explore_filter_sheet.dart                 ← KEEP: filter bottom sheet (unchanged)
```

**Navigation entry points:**
- `BusinessMainScreen` (tab index 1) → `ExploreScreen(detailRoutePrefix: '/business/explore/offer')`
- `CommunityMainScreen` (tab index 1) → `ExploreScreen(lockedCreatorType: 'business')` (same widget, different config)

### What Should Remain Untouched
| Artifact | Reason |
|---|---|
| `discoveryListProvider` | Pagination, auth guard, filter reactivity — all correct |
| `discoveryFiltersProvider` | Full filter state management — no changes needed |
| `DiscoveryFilters` model | 17 filter fields, all used |
| `DiscoveryItem` model | Rich data model — the new card reads from it |
| `DiscoveryService` | HTTP layer, backend contract |
| `ExploreDetailSheet` | Full detail view — unchanged |
| `ExploreFilterSheet` | Advanced filter sheet — unchanged |
| `DiscoveryQuickFilters` | Quick-chip row — kept, possibly enhanced |
| `_FeedToggle` | Recommended/All segmented control — kept |
| Business/community paywall logic | `hideCreatorIdentity`, `canApply`, `onSubscribe` — preserved |

### What Changes
| Artifact | Change |
|---|---|
| `ExploreScreen._buildCardPageView` | Replaced with `_buildFeedList` using `SliverList` |
| `ExploreSwipeCard` | Retired; replaced by `DiscoveryFeedCard` |
| `ExploreScreen._buildTopBar` | Extended: adds persistent result count |
| Screen loading shimmer | Updated: shows 3 skeleton cards instead of 1 full-screen shimmer |

---

## 2. New Explore Information Architecture

```
ExploreScreen (shell — unchanged)
├── Zone A: Top Bar (fixed)
│   ├── Left: "Explore" label  ·  Right: result count ("42 matches")
│   └── Right: NotificationBell
│
├── Zone B: Feed Toggle (sticky)
│   └── [Recommended] [All]  segmented control
│
├── Zone C: Quick Filters (sticky, scrollable horizontal)
│   ├── [City chip]
│   ├── [Collab Type chip]       ← community viewer
│   │   or [Need chip]           ← business viewer
│   ├── [Offer Type chip]        ← community viewer
│   │   or [Community Type chip] ← business viewer
│   └── [More Filters ↓]         → opens ExploreFilterSheet (existing)
│
└── Zone D: Discovery Feed (scrollable)
    ├── Section Header: "Matched for you"  (Recommended feed only, when items > 0)
    │   └── DiscoveryFeedCard × (up to 5 recommended items)
    ├── Divider / Section Header: "All opportunities"  (when both sections coexist)
    │   └── DiscoveryFeedCard × N  (lazy-loaded, paginated)
    └── Load-more spinner (existing loadMore() logic, unchanged)
```

**Section logic:**
- In `Recommended` feed: show both sections if recommendations exist; show only "All" if not.
- In `All` feed: single flat list, no section headers.
- Section headers are light typographic labels, not heavy visual blocks.

---

## 3. Card System Proposal

### Card Philosophy

Kolabing is editorial and human. Cards must feel like a curated magazine spread — not a CRM row. The guiding principle: **a photo on every card, but photo is atmosphere not hero**.

### Card Sizes

#### Standard Card (primary)
Used for the majority of the feed.

```
┌──────────────────────────────────────────────────────┐
│  ┌────────┐  Creator Name                  [85% ▲]  │  ← 52dp top section
│  │  64dp  │  Opportunity Title (1–2 lines)  [♡]     │
│  │ avatar │                                          │
│  └────────┘                                          │
├──────────────────────────────────────────────────────┤
│  ════════════════════ 100dp photo strip ═══════════  │  ← aspect ratio ~3.5:1
│  (cover photo or gradient fallback with category bg) │
│  ════════════════════════════════════════════════════│
├──────────────────────────────────────────────────────┤
│  📍 Barcelona  ·  📅 Jun 12–20              [Apply]  │  ← 48dp action row
│  [Venue chip]  [Social Media chip]                   │
└──────────────────────────────────────────────────────┘
Total card height: ~200–220dp
Card margin: 12dp horizontal, 6dp vertical
Card border radius: 16dp (KolabingRadius.xl)
```

**Information hierarchy:**
1. Creator name + avatar (identity, trust anchor)
2. Title (what the collab is about)
3. Photo strip (atmosphere, category feel)
4. City + date (logistics triage)
5. Chips (2 max: most relevant offer/need types)
6. Match score badge (only on Recommended feed)
7. CTA button (Apply / View)

#### Featured Card (optional, top of Recommended section only)
Taller. Hero photo. For top 1–3 recommended items only.

```
┌──────────────────────────────────────────────────────┐
│  ════════════════ 180dp hero photo ══════════════════ │
│  [dark gradient overlay at bottom]                    │
│  Creator Name  ·  Opportunity Title         [88% ▲]  │  overlaid white text
│  ════════════════════════════════════════════════════ │
├──────────────────────────────────────────────────────┤
│  📍 Barcelona  ·  📅 Jun 12–20   [Venue] [Social]    │
│                                            [Apply →]  │
└──────────────────────────────────────────────────────┘
Total height: ~300–320dp
```

Featured cards use `isFeatured: item.match != null && index < 3`.

#### Skeleton / Loading Card
Same dimensions as Standard Card, filled with shimmer blocks.

```
┌──────────────────────────────────────────────────────┐
│  [○ 48dp shimmer]  [████ 120dp shimmer]    [░░░░░]   │
│                    [████████ 180dp shimmer]           │
├──────────────────────────────────────────────────────┤
│  [░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░]  │
├──────────────────────────────────────────────────────┤
│  [░░░░░░░░]  [░░░░░░░]       [░░░░░░░░]   [░░░░░░]   │
└──────────────────────────────────────────────────────┘
```
Show 3 skeleton cards during initial load.

### Blurred Identity in List Context
For a free business viewing a community item: avatar area shows lock icon + "Subscribe to reveal" label. No blur on a 64dp avatar (too small to be legible). The detail sheet continues to use the existing blur treatment.

### Card Metadata by User Type

| Field | Community viewer sees | Business viewer sees |
|---|---|---|
| Creator name | Business name | Community name (or blurred) |
| Primary chip | Business offer type (Venue, Food…) | Community need type (Promo, Content…) |
| Secondary chip | Collab type (Venue Promotion…) | Community type (Sports, Food…) |
| Match score | % match | % match |
| CTA | "Apply" | "View" (free) / "Apply" (subscribed) |

---

## 4. User Journey Analysis

### Community User Journey

**Goal:** Find a business offering something useful (venue, product, sponsorship) to promote the community's events.

**Current pain points:**
- Serial browsing makes it slow to find something geographically relevant.
- Must swipe through all items before comparing two.
- No way to shortlist for later discussion with organizers.

**New journey:**
1. Open Explore → sees 2–3 cards immediately.
2. Scans creator name + offer type chips in ~1 second per card.
3. Taps quick chip [Barcelona] → feed narrows to local businesses.
4. Scrolls down → sees "Recommended" section (businesses that match their community profile).
5. Taps a card → detail sheet opens → taps Apply → done.

**Recommendation signal** for community users: match is driven by `communityTypes` overlap + `offerTypes` the community is interested in + city match.

### Business User Journey

**Goal:** Find communities to co-promote events. This is lead generation — they browse many, shortlist a few, and reach out.

**Current pain points:**
- One card at a time is extremely slow for lead generation.
- Can't compare two communities without perfect memory.
- Blurred identity on free tier disrupts the browsing experience.

**New journey:**
1. Open Explore → sees 2–3 community cards.
2. Scans community name (or lock icon if unsubscribed), collab type, audience size.
3. For free users: lock icon on 1–2 cards creates curiosity, not frustration (they can still read title, city, chips).
4. Taps quick chip [Sports] → narrows to sports communities.
5. Taps a card → detail sheet opens → either applies (subscribed) or gets paywall CTA.

**Recommendation signal** for business users: match driven by `needTypes` + `communityTypes` + city + audience size band.

### How the Journeys Differ

| Dimension | Community | Business |
|---|---|---|
| Browse style | Selective (fewer, higher intent) | Scanning (many, lower commitment per item) |
| Primary filter | City + offer type | City + community type / need |
| CTA urgency | High (wants to apply fast) | Lower (wants to shortlist first) |
| Subscription gate | None | Blurs identity on community cards |
| Recommendation basis | Business offer match | Community profile match |

**Design implication:** Both user types benefit from the list view, but the business user benefits more — lead generation is a scanning task by nature.

---

## 5. Migration Plan

### Phase 0: Groundwork (no visible change)
- Create `lib/widgets/discovery_feed_card.dart` — new compact card widget
- Create `lib/widgets/discovery_feed_card_featured.dart` — hero variant
- Create `lib/widgets/discovery_feed_card_skeleton.dart` — shimmer skeleton
- No changes to `ExploreScreen` yet

### Phase 1: Feed View (additive, behind a toggle)
- Add `_ExploreViewMode { feed, cards }` enum to `ExploreScreen`
- Add a small layout toggle icon (grid icon ↔ cards icon) to the top bar
- Default to `feed` for new installs / new sessions; persist via shared prefs
- `_buildCardPageView` unchanged (still accessible in `cards` mode)
- `_buildFeedList` new — renders `SliverList` of `DiscoveryFeedCard`

This gives users and the team a direct A/B comparison without any forced migration.

### Phase 2: Default Flip
- Change the persisted default from `cards` to `feed`
- Existing users who haven't toggled see the feed on next session
- Keep the toggle button available

### Phase 3: Retire Cards Mode
- Remove `_ExploreViewMode` toggle and `_buildCardPageView`
- Remove `ExploreSwipeCard` widget
- Remove `PageController` from `ExploreScreen`

### What Can Be Reused
| Widget | Reuse plan |
|---|---|
| `ExploreDetailSheet` | Used unchanged — tapping any card opens it |
| `ExploreFilterSheet` | Used unchanged |
| `DiscoveryQuickFilters` | Used unchanged, sits above feed |
| `_FeedToggle` | Used unchanged |
| `_buildTopBar` | Kept, add result count text |
| `_buildEmptyState` | Used unchanged |
| `_buildErrorState` | Used unchanged |
| `BlurredIdentity` | Replaced with lock icon in card header (list context) |
| `MatchBreakdown` | Available in detail sheet — not shown on list card |

### What Gets Retired
| Widget | Reason |
|---|---|
| `ExploreSwipeCard` | Replaced by `DiscoveryFeedCard` |
| `PageController` in `ExploreScreen` | Only needed for PageView |
| Full-screen shimmer in `_buildLoadingState` | Replaced by 3x skeleton cards |

---

## 6. Technical Impact Analysis

### Files — Classified by Risk

#### HIGH Risk (core logic changes)

| File | Change | Risk Reason |
|---|---|---|
| `lib/features/business/screens/explore_screen.dart` | Replace `_buildCardPageView` + `_buildLoadingState`, add view-mode toggle | Core screen; shared by both user types; paywall/subscription logic lives here |

#### MEDIUM Risk (new widgets consuming existing data)

| File | Change | Risk Reason |
|---|---|---|
| `lib/widgets/discovery_feed_card.dart` | NEW — reads `DiscoveryItem`, `hideCreatorIdentity`, calls `onTap` | Must correctly handle all card variants (business offer / community request / featured) |
| `lib/widgets/discovery_feed_card_featured.dart` | NEW — hero variant for top recommended items | Image loading, overlay gradient, blurred identity interaction |
| `lib/widgets/discovery_feed_card_skeleton.dart` | NEW — shimmer skeleton | Low risk but needs correct shimmer pattern |

#### LOW Risk (minor additions to stable files)

| File | Change | Risk Reason |
|---|---|---|
| `lib/features/discovery/widgets/discovery_quick_filters.dart` | Possible: add result count display above chips | Additive only |
| `lib/features/business/screens/explore_screen.dart` | `_buildTopBar` — add result count `Text` | Simple UI addition |

#### NO CHANGE (explicitly preserved)

| File | Reason |
|---|---|
| `lib/features/discovery/providers/discovery_provider.dart` | No changes — `loadMore`, `refresh`, `build` all correct |
| `lib/features/discovery/models/discovery_filters.dart` | No changes |
| `lib/features/discovery/models/discovery_item.dart` | No changes |
| `lib/features/discovery/services/discovery_service.dart` | No changes |
| `lib/widgets/explore_detail_sheet.dart` | No changes |
| `lib/widgets/explore_filter_sheet.dart` | No changes |
| `lib/features/business/screens/business_main_screen.dart` | No changes |
| `lib/features/community/screens/community_main_screen.dart` | No changes |
| `lib/features/application/widgets/apply_modal.dart` | No changes |
| `lib/features/application/widgets/apply_success_sheet.dart` | No changes |
| `lib/features/subscription/widgets/subscription_paywall.dart` | No changes |
| All routes in `lib/config/routes/` | No changes |

### Interactions to Verify After Implementation

| Interaction | Test scenario |
|---|---|
| Paywall gate | Free business taps a community card → detail sheet → Apply → paywall appears |
| Blurred identity | Free business sees lock icon on community cards; subscribed business sees avatar |
| Pagination | Scroll to bottom of feed → `loadMore()` fires → new cards appear |
| Filter reactivity | Apply city filter → feed refreshes → result count updates |
| Feed toggle | Switch Recommended ↔ All → feed refreshes → section headers appear/disappear |
| Detail sheet | Tap any card → sheet opens with correct `opportunity` data |
| Apply flow | Submit application → success sheet → navigate to Applications tab |
| Empty state | All filters active, no results → empty state widget renders |
| Error state | Network failure → error widget with retry renders |
| Community user | Community user sees correct chip labels (offer types, not need types) |
| Business user | Business user sees correct chip labels (need types, community types) |

---

## Visual Reference Wireframes

### Standard Feed View (community user)

```
╔═══════════════════════════════════════════════╗
║  Explore                           34 matches 🔔 ║  ← Zone A
╠═══════════════════════════════════════════════╣
║  [Recommended ●]  [All]                       ║  ← Zone B
╠═══════════════════════════════════════════════╣
║  [Barcelona ×]  [Venue Promo]  [Food & Drink] ↔ ║ ← Zone C
╠═══════════════════════════════════════════════╣
║  — Matched for you ———————————————————        ║  ← Section header
║ ┌─────────────────────────────────────────┐   ║
║ │ [Logo] Cervecería Moritz    [88% match] │   ║
║ │        Summer Terrace Collab     [♡]    │   ║
║ │ ░░░░░░░░░░░ photo strip ░░░░░░░░░░░░░░ │   ║  ← 3:1 photo
║ │ 📍 Gracia · Jun 1–30  [Venue] [Drinks]  │   ║
║ │                              [Apply →]  │   ║
║ └─────────────────────────────────────────┘   ║
║ ┌─────────────────────────────────────────┐   ║
║ │ [Logo] Loewe x Concept Store [72% match]│   ║  ← 2nd card partially visible
║ │        Pop-up Night Partnership   [♡]   │   ║
║ │ ░░░░░░░░░░░ photo strip ░░░░░░░░░░░░░░ │   ║
║ └─────────────────────────────────────────┘   ║  ← cut off = "more below" signal
╚═══════════════════════════════════════════════╝
```

### Standard Feed View (business user, free tier)

```
╔═══════════════════════════════════════════════╗
║  Explore                           18 matches 🔔 ║
╠═══════════════════════════════════════════════╣
║  [Recommended ●]  [All]                       ║
╠═══════════════════════════════════════════════╣
║  [Madrid ×]  [Sports]  [+ Filters]           ↔ ║
╠═══════════════════════════════════════════════╣
║  — Matched for you ———————————————————        ║
║ ┌─────────────────────────────────────────┐   ║
║ │ [Logo] Running Club Madrid   [91% match]│   ║
║ │        Spring Race Sponsorship    [♡]   │   ║
║ │ ░░░░░░░░░░░ photo strip ░░░░░░░░░░░░░░ │   ║
║ │ 📍 Madrid · May 10–Jun 5  [Promotion]   │   ║
║ │                              [View →]   │   ║
║ └─────────────────────────────────────────┘   ║
║ ┌─────────────────────────────────────────┐   ║
║ │ [🔒] ▓▓▓▓▓▓▓▓▓▓▓          [85% match]  │   ║  ← locked community identity
║ │        Festival Partnership       [♡]   │   ║
║ │ ░░░░░░░░░░░ photo strip ░░░░░░░░░░░░░░ │   ║
║ │ 📍 Madrid · Jun 15–Jul 1  [Festival]    │   ║
║ │            Subscribe to reveal [View →] │   ║
║ └─────────────────────────────────────────┘   ║
╚═══════════════════════════════════════════════╝
```

### Loading State (3 skeleton cards)

```
║ ┌─────────────────────────────────────────┐   ║
║ │ [○ shimmer]  [████████ shimmer]         │   ║
║ │ [░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░] │   ║
║ │ [░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░] │   ║  ← shimmer strip
║ │ [░░░░░░░░░░░] [░░░░░░░░]   [░░░░░░░░]  │   ║
║ └─────────────────────────────────────────┘   ║
(× 3)
```

---

## Open Design Decisions

The following are NOT answered in this plan and require product/design sign-off before implementation:

1. **Bookmark / save feature** — Does a shortlist tab exist? Where? This plan does not implement bookmarks.
2. **Featured card** — Is the hero variant wanted, or should all cards be the same height? Recommendation: implement standard card only in Phase 1.
3. **Result count placement** — In top bar only, or also updated dynamically in the filter chip bar?
4. **Exact card photo dimensions** — 3:1 strip is a proposal; confirm aspect ratio with design.
5. **Section header style** — Simple label or yellow accent strip? Keep it typographic to avoid dashboard feel.
