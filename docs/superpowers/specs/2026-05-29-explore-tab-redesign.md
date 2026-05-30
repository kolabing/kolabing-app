# Explore Tab UX Audit & Redesign Plan
**Date:** 2026-05-29  
**Status:** Audit complete — awaiting design approval before implementation planning

---

## Current State Summary

The Explore tab is a full-screen vertical `PageView` — one opportunity card per "page". Each card is a full-bleed image with a gradient overlay and an information panel docked to the bottom. Tapping opens a modal bottom sheet with full detail. Navigation is swipe-up (vertical scroll).

**Shared component:** `ExploreScreen` is reused by both business and community shells via `lockedCreatorType` / `detailRoutePrefix` parameters.

**Filters:** A floating search/filter bar opens a modal bottom sheet. There are also quick-filter chips pinned below the Recommended/All toggle.

---

## Problems Found

### P1 — One-at-a-time browsing forces serial discovery

**Problem:** The PageView model shows exactly one card before the user must swipe. There is no spatial awareness of what is ahead, behind, or beside the current item. Users cannot scan.

**Why it matters:** Collaboration discovery is a matching task, not a passive entertainment task. Users are not looking for something to entertain them; they are looking for the right partner. They need to compare, jump back, and shortlist. Serial navigation makes this impossible. A user who swiped past something interesting must swipe backwards through the entire stack to find it again — and there is no "go back" button.

**Better pattern:** A scrollable list (or grid) that lets users scan 4–8 items at once and keeps previous items accessible.

---

### P2 — No persistent shortlist or save mechanism

**Problem:** There is no way to save, bookmark, or queue an interesting opportunity. Once swiped past, it is effectively gone unless the user scrolls all the way back.

**Why it matters:** Both user types (community and business) are likely making decisions that require coordination with someone else — a business owner consulting with their marketing team, or a community leader checking availability with organizers. The current model assumes a solo, instant decision. Real purchase/application decisions are rarely that.

**Better pattern:** A "save for later" / bookmark action surfaced directly on each card, with a saved list accessible from the tab or profile.

---

### P3 — Cognitive load mismatch: too much visual noise, too little useful signal

**Problem:** The card UI layers: hero image, gradient overlay, blurred identity treatment, type badge, match score with breakdown bars, yellow headline banner, meta chips, availability row, creator name, location — all simultaneously. On a small screen this creates visual competition between elements.

**Why it matters:** When everything shouts, nothing communicates. Users in discovery mode need to make a quick "is this worth reading more?" decision. That decision requires 2–3 pieces of data (who, what, where), not 8–10. The rest should live inside the detail sheet.

**Better pattern:** A list card with a clear visual hierarchy: creator identity → collab title → 2–3 key signals (city, audience size, offer type) → match score. The detail sheet handles everything else.

---

### P4 — No comparison ability

**Problem:** Users cannot compare two opportunities side by side or even keep one in peripheral vision while viewing another.

**Why it matters:** A community leader evaluating whether to collaborate with Brand A vs Brand B needs to hold both in mind simultaneously. The serial model forces a lossy mental representation.

**Better pattern:** A scrollable list preserves all options in spatial memory. An optional side-by-side view or detailed overlay that lets users pin cards to compare is a further improvement, but a list alone is already a major step forward.

---

### P5 — Poor scalability at volume

**Problem:** A vertical PageView works acceptably with 10–20 items. With 100+ items (as the platform grows), navigation becomes unusable: the user has no sense of where they are in the stack, no way to jump to a section, and infinite swipe-to-end is punishing.

**Why it matters:** The product is presumably meant to grow. Designing for 20 items today creates a migration cost later. A scrollable list handles 5 or 500 items equally well.

**Better pattern:** Lazy-loading scrollable list with section anchors (e.g., "Recommended" section, then "All") or pagination controls.

---

### P6 — Filters are buried and their effect is invisible

**Problem:** Applying filters requires two steps: tap the search bar → open a full-height bottom sheet → configure → close. The result is visible only in the compact filter label. The user cannot see "here is what changed" — they must scroll the updated card stack.

**Why it matters:** When filters are hard to access and their effect is invisible, users don't use them. Without filters, users swipe through irrelevant items and churn. This is a retention risk.

**Better pattern:** Inline quick-filter chips (you already have these, but they are truncated and the full filter sheet is still a two-step journey) with a live count of results shown before closing the sheet. Consider bringing city and collab-type filters to the surface.

---

### P7 — Business-side and community-side have inverted discovery needs that the current layout ignores

**Problem:** A business user is browsing communities to find a partnership. A community user is browsing business opportunities to apply for sponsorship. These are structurally different tasks: the business user is lead-generating (browsing many, shortlisting a few); the community user is applying (fewer options, higher intent per item).

**Why it matters:** The current layout treats both users identically. Business users may need higher-density browsing (grid or list). Community users may need richer per-item detail on the card itself to decide whether to apply.

**Better pattern:** Differentiated card density or layout per user type is an option, though it increases complexity. At minimum, the primary call-to-action language and card hierarchy should differ between the two roles.

---

### P8 — No "distance to goal" feedback

**Problem:** The user has no idea how many opportunities are in the feed, how many match their filters, or where they are in the list. The loading state (single full-screen shimmer) gives no indication of incoming content count.

**Why it matters:** Without progress indicators, users don't know whether to keep scrolling or whether they've exhausted the feed. This is a major driver of premature churn ("I've seen everything" when they haven't).

**Better pattern:** Show result count near the filter bar (you partially do this in the filter label, but it is only visible when filters are active). Show a subtle "X of Y" position indicator in a scrollable list.

---

## UX Recommendations

### R1 — Replace PageView with a scrollable card list

Replace the full-screen `PageView` with a `ListView` or `CustomScrollView` of compact opportunity cards. Each card should occupy approximately 30–40% of the screen height (roughly 200–240dp on a standard phone), allowing 2–3 cards to be visible at once.

This single change resolves P1, P2 (partial), P4, P5, and P8.

### R2 — Establish a strict 3-tier information hierarchy per card

**Tier 1 (always visible on card):** Creator name + avatar, opportunity title, city, match score.  
**Tier 2 (visible on card, smaller):** 1–2 key signals (offer type, audience size or collab type). Availability date range.  
**Tier 3 (detail sheet only):** Full description, all meta chips, past events, deliverables, full match breakdown.

This resolves P3.

### R3 — Add a "Save" action to each card

A bookmark icon in the card header saves the opportunity to a private shortlist. The shortlist is accessible from the Explore tab header or the profile tab. No navigation required.

This resolves P2.

### R4 — Surface result count persistently

Show the result count ("42 opportunities") in the screen header, updating in real time as filters change. Do not hide it behind the filter label.

This partially resolves P6 and P8.

### R5 — Promote 2 highest-signal quick filters to inline chips above the list

City and collab type (or offer type for community users) are the two highest-value filters. Surface them as tappable chips above the card list. The full filter sheet remains available for advanced filtering but should not be the only entry point.

This resolves P6.

### R6 — Add a sticky "Recommended" section header above the rest

If the Recommended feed has items, render them as a labeled section at the top ("Matched for you · 12"), followed by a labeled "All opportunities" section. This makes the two-feed toggle visual without requiring the user to switch modes.

---

## New Information Architecture

```
Explore Tab
├── Screen header
│   ├── "Explore" title
│   ├── Result count (always visible)
│   └── Notification bell
├── Feed context bar
│   ├── Recommended / All toggle (segmented control)
│   └── Inline quick filters: [City] [Collab type] [+ Filters]
├── Card list (scrollable, lazy-loaded)
│   ├── Section: "Matched for you" (if Recommended feed + has items)
│   │   └── OpportunityCard × N
│   └── Section: "All opportunities" (or just the list in All mode)
│       └── OpportunityCard × N
└── Each OpportunityCard (self-contained row/card)
    ├── Left: Creator avatar (48dp)
    ├── Body: Creator name, opportunity title, city · date range
    ├── Key signal row: 1–2 chips (offer type, audience size)
    ├── Right: Match score badge (if present), Bookmark icon
    └── onTap → ExploreDetailSheet (unchanged)
```

---

## Recommended Screen Structure

### Zone 1 — Screen Header (fixed)
- Title "Explore" (left-aligned, Rubik bold)
- Result count label (e.g., "34 matches") in secondary text
- Notification bell (right)

### Zone 2 — Filter Bar (sticky, scrolls with first few items then pins)
- Recommended / All segmented control
- Horizontal scroll of quick-filter chips:
  - [City: Madrid ×] or [City +]
  - [Collab type] multi-select chip
  - [More filters] → opens existing ExploreFilterSheet

### Zone 3 — Card List (scrollable)
- `SliverList` of `OpportunityCard` widgets
- Section header dividers if in Recommended mode with mixed results
- Load-more spinner at bottom (existing `loadMore` logic retained)

### OpportunityCard anatomy (per card)
```
┌──────────────────────────────────────────┐
│ [Avatar]  Creator Name          [Match%] │
│           Opportunity Title     [Bookmark]│
│           📍 City  ·  📅 May 30 - Jun 15 │
│           [Offer chip] [Audience chip]   │
└──────────────────────────────────────────┘
```
Height: ~100–120dp. No hero image on the card itself (image in detail sheet).

**Optional enhancement:** A "featured" card format (taller, with hero image) for the top 1–3 Recommended matches only. This gives the recommendation algorithm a visual premium slot.

---

## Migration Strategy

### Phase 1 — Parallel layouts (low risk)
Add a layout toggle (List / Card) somewhere in the filter bar or screen header. The existing `PageView` is the "Card" mode; the new `ListView` is "List" mode. Default new users to List mode. Existing users see both options. This allows side-by-side comparison without destroying the current experience.

**Risk:** Added UI complexity. Acceptable as a transitional state.

### Phase 2 — Default flip
After validating that list mode engagement is equal or better (apply rate, time-on-tab, return visits), flip the default to List for all users. Keep Card as a secondary option.

### Phase 3 — Remove Card mode
Remove the PageView once metrics confirm list mode is the preferred experience. The `ExploreSwipeCard` widget can be retired or repurposed as the "featured" card variant.

**Code note:** The `ExploreScreen` architecture (providers, filters, detail sheet) is sound and reusable. The migration is a presentation-layer change only — `discoveryListProvider`, `discoveryFiltersProvider`, and `ExploreDetailSheet` are unchanged.

---

## Risks and Tradeoffs

### Risk 1 — Loss of immersive aesthetic
The current full-bleed card is visually striking. A compact list looks more utilitarian. This may reduce the "premium feel" of the app.

**Mitigation:** Invest in card micro-design (clean typography, subtle shadows, strong avatar treatment). The featured card slot for top recommendations preserves visual richness at the top of the screen.

### Risk 2 — Reduced per-opportunity attention
In a list, users may skim past opportunities they would have engaged with in the full-screen format.

**Mitigation:** This is the same tradeoff made by every job board, marketplace, and B2B directory that outperformed "swipe" formats. Efficient scanning increases apply rate even if per-card attention decreases, because users reach relevant items faster.

### Risk 3 — Business vs. community user divergence
The current `ExploreScreen` handles both user types via flags. Adding per-role layout differences (e.g., different card layouts) increases widget complexity.

**Mitigation:** Keep a single `OpportunityCard` widget with a `userType` parameter that adjusts which fields are in the key signal row. Do not fork the entire screen.

### Risk 4 — The blurred-identity paywall mechanic is harder to communicate in a list card
The current full-bleed blur on a large image is visually striking and clearly communicates "this is locked". A small blurred avatar in a list card is ambiguous.

**Mitigation:** In the list card, replace the blurred avatar with a lock icon + "Subscribe to reveal" label in the creator name area. The mystery-identity signal is preserved without requiring a full-screen blur.

### Risk 5 — Recommendation signal dilution
The current model makes the Recommended/All toggle feel meaningful because both are full-screen experiences. In a single list view with section headers, the "recommended" section may feel like just a few items at the top rather than a curated experience.

**Mitigation:** Make the "Matched for you" section header visually distinct (yellow accent, match percentage) and limit it to the top 5–8 matches rather than surfacing all of them. Quality over quantity.

---

## Decision Not Made Here

The audit intentionally leaves open:
- Exact card dimensions and visual design
- Whether to add a horizontal "featured" carousel above the list
- Whether the Saved list lives in Explore or Profile
- Exact color/typography treatment of section headers

These are screen design decisions to be resolved in the design phase.
