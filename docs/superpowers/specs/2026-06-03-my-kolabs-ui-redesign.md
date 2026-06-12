# My Kolabs UI Redesign — Design Spec

**Last updated:** 2026-06-03  
**Status:** Approved  
**Scope:** UI/styling refactor only — no data logic, routes, providers, or Supabase queries change.

---

## Problem

The My Kolabs section (Offers · Requests · Active · Finished) has three different card styles and two different sub-tab styles that do not share a visual language:

| Section | Sub-tab style | Card style |
|---|---|---|
| Offers | Horizontal scrolling filled yellow pills | Vertical, no image |
| Requests | Full-width underline tab bar | Horizontal, circular avatar left |
| Active | — (no sub-tabs) | Minimal vertical, no image |
| Finished | — (no sub-tabs) | Same as Active |

Category chips inside cards use flat grey/beige fills that clash with the soft pastel chips on the Explore card.

---

## Goal

One coherent design language across all of My Kolabs, matching the warm Kolabing Atmospheric Editorial palette already established in the Explore tab.

---

## New Shared Components

### 1. `MyKolabsSubTabs`

**File:** `lib/features/kolab/widgets/my_kolabs_sub_tabs.dart`

A stateless wrapper around Flutter's `TabBar` using the underline style already present in the Requests tab (Sent/Received). Replaces the pill-style horizontal `ListView` used in Offers.

**Props:**
```dart
const MyKolabsSubTabs({
  required TabController controller,
  required List<String> labels, // e.g. ['PUBLISHED', 'DRAFT']
});
```

**Visual spec:**
- Full-width, one row.
- Background: `KolabingColors.background` (parchment `#FDF9F0`).
- Label style: `KolabingTextStyles.button` · uppercase · `letterSpacing: 0.5`.
- Active label color: `KolabingColors.onSurface` (`#1C1C16`) · `fontWeight: w700`.
- Inactive label color: `KolabingColors.textTertiary` (`#8C8A82`) · `fontWeight: w400`.
- Indicator: `KolabingColors.primary` (`#FFE28C`) · `indicatorWeight: 3`.
- Divider below: `KolabingColors.hairline` (`#EAE3D4`) · height 1.
- No filled background, no pill shape.

**Usage:** Replaces `_buildStatusTabs()` in `MyKollabsScreen` and `MyOpportunitiesScreen`. The existing Requests tab already uses this pattern — the new component extracts it so both share identical markup.

---

### 2. `KolabChip`

**File:** `lib/widgets/kolab_chip.dart`  
_(shared widget, not feature-scoped — also used by Explore cards)_

A small pastel pill for category tags, date ranges, city labels, and meta info. Replaces the flat `_InfoPill` used inside `MyKolabCard` and the grey chips elsewhere.

**Props:**
```dart
const KolabChip({
  required String label,
  KolabChipVariant variant = KolabChipVariant.neutral,
  IconData? icon,
});

enum KolabChipVariant {
  neutral,   // surfaceVariant fill — dates, generic meta
  amber,     // amberChipContainer / amberChipText — city, discount
  sage,      // tertiaryContainer / tertiary — nature, wellness, date ranges
  lavender,  // secondaryContainer / secondary — community, lifestyle
  blueGrey,  // categoryBlueGrey / categoryBlueGreyText — art, music, culture
  peach,     // #FFE9D9 / #B05A2A — food & drink
}
```

**Visual spec:**
- Height: 24–26px.
- Horizontal padding: 8–10px.
- Border radius: `KolabingRadius.borderRadiusRound`.
- Font size: 11px · `fontWeight: w600`.
- Text color: darker version of the fill (see variant map above).
- Icon: optional, 11px, same color as text.

**Category → variant mapping (used by parent to pick the right variant):**

| Category keyword | Variant |
|---|---|
| Food & Drink, Bar, Restaurant, Cafe | `peach` |
| Wellness, Yoga, Health, Fitness, Sports | `sage` |
| Music, Art, Film, Culture, Photo | `blueGrey` |
| Community, Events, Social | `lavender` |
| Discount, Promotion, Offer | `amber` |
| City / map pin, date, meta | `amber` (city) / `sage` (date) / `neutral` (other) |

---

### 3. `KolabStatusBadge`

**File:** `lib/widgets/kolab_status_badge.dart`  
_(shared widget)_

A small pill badge for status labels. Extracts the duplicated `_StatusBadge` classes that currently exist independently in `my_kolab_card.dart`, `my_opportunity_card.dart`, `applications_screen.dart`, and `collaborations_list_tab.dart`.

**Props:**
```dart
const KolabStatusBadge({ required String status });
```

**Status → color mapping:**

| Status string | Background | Text |
|---|---|---|
| `published` | `activeBg` `#D4EDDA` | `activeText` `#155724` |
| `draft` | `completedBg` `#EDEAD0` | `completedText` `#4C4638` |
| `closed` | `completedBg` | `completedText` |
| `completed` | `completedBg` | `completedText` |
| `scheduled` | `secondaryContainer` | `secondary` |
| `in_progress` / `active` | `activeBg` | `activeText` |
| `pending_confirmation` | `pendingBg` | `pendingText` |
| `pending` | `pendingBg` `#FFDDAC` | `pendingText` `#D8910B` |
| `accepted` | `activeBg` | `activeText` |
| `declined` | `errorBg` | `errorText` |
| `withdrawn` | `surfaceVariant` | `textTertiary` |
| `cancelled` | `errorBg` | `errorText` |

**Visual spec:**
- Padding: `horizontal: 9, vertical: 3`.
- Border radius: `KolabingRadius.borderRadiusRound`.
- Font: `KolabingTextStyles.labelSmall` · `fontWeight: w700` · `letterSpacing: 0.4`.

---

### 4. `MyKolabCard` (refactored, same filename)

**File:** `lib/features/kolab/widgets/my_kolab_card.dart`

The existing `MyKolabCard` is Offer/Kolab-specific. It gets refactored to match the new horizontal layout spec and use `KolabChip` + `KolabStatusBadge`. A separate unified card is **not** created — each section's parent passes its own data to the appropriate existing card widget, which is restyled. The four card types remain as separate widgets but now share identical layout structure and sub-components.

**Shared layout structure (applied to all four card widget types):**

```
┌──────────────────────────────────────────┐
│  [StatusBadge]                           │
│  Title (bold, 15px, 1 line ellipsis)     │
│  Subtitle / From: / To: (grey, 12px)     │  [68×68 image]
│  Description (grey, 12px, 2 lines)       │
│  [Chip] [Chip] [Chip]                    │
│  🕐 date · · · · · · · · · [›] or [🔴3] │
│  [ACTION] [ACTION] [ACTION]  ← Offer only│
└──────────────────────────────────────────┘
```

**Container:**
- Background: `Colors.white`.
- Border: `1px solid KolabingColors.hairline` (`#EAE3D4`).
- Border radius: `18px` (uses `KolabingRadius.borderRadiusLg`).
- No box shadow (border replaces shadow).
- Padding: `14px all`.

**Right-side image:**
- Size: 68×68.
- Border radius: 14px.
- `BoxFit.cover`.
- Fallback: `LinearGradient(#FFF4C2 → #FFE28C)` with first initial of title, `fontWeight: w700`, `color: KolabingColors.onYellowButton`.

**Action buttons (Offer cards only):**
- Height: 36px.
- Border radius: `KolabingRadius.borderRadiusSm`.
- Primary (View/Publish): `KolabingColors.primary` fill, `onYellowButton` text.
- Outline (Edit/Close/Share): `hairline` border, `onSurface` text.
- Danger (Delete): `errorBg` border, `error` text.
- Label: uppercase, 11px, `fontWeight: w600`, `letterSpacing: 0.5`.

---

## Files Changed

### New files

| File | Purpose |
|---|---|
| `lib/features/kolab/widgets/my_kolabs_sub_tabs.dart` | Shared sub-tab component |
| `lib/widgets/kolab_chip.dart` | Shared pastel chip |
| `lib/widgets/kolab_status_badge.dart` | Shared status badge |

### Modified files

| File | Change |
|---|---|
| `lib/features/kolab/widgets/my_kolab_card.dart` | Restyle to horizontal layout + square image + KolabChip + KolabStatusBadge |
| `lib/features/community/widgets/my_opportunity_card.dart` | Restyle to match same layout; use `opportunity.offerPhoto` for image |
| `lib/features/application/screens/applications_screen.dart` | Replace `_ApplicationCard` with restyled version; replace circular avatar with `application.opportunity?.offerPhoto`; extract sub-tabs to `MyKolabsSubTabs` |
| `lib/features/collaboration/widgets/collaborations_list_tab.dart` | Replace `_CollaborationCard` with restyled version; use `collaboration.opportunity?.offerPhoto` for image |
| `lib/features/business/screens/my_kollabs_screen.dart` | Replace `_buildStatusTabs()` with `MyKolabsSubTabs` |
| `lib/features/community/screens/my_opportunities_screen.dart` | Replace `_buildStatusTabs()` with `MyKolabsSubTabs` |

---

## Image Data Sources (per card type)

| Card | Image field | Fallback |
|---|---|---|
| Business Kolab (Offers) | `kolab.media.firstOrNull?.url` | Initial from `kolab.title` |
| Community Opportunity (Offers) | `opportunity.offerPhoto` | Initial from `opportunity.title` |
| Application / Request (Sent & Received) | `application.opportunity?.offerPhoto` | Initial from `application.opportunityTitle` |
| Collaboration (Active & Finished) | `collaboration.opportunity?.offerPhoto` | Initial from partner names |

**Breaking change from current:** Request cards currently show a circular profile avatar (applicant or recipient). This is replaced by the opportunity's cover photo. The `applicantAvatar` / `recipientAvatar` fields are no longer used for the card image.

---

## What Does NOT Change

- All providers, notifiers, Supabase queries.
- All navigation and routing.
- All action callbacks (onPublish, onEdit, onClose, onDelete, onShare, onView).
- All empty states and loading shimmer skeletons (shimmer height updated to match new card height ~100px).
- The `MyKolabsHubScreen` top-level tab bar (Offers / Requests / Active / Finished) — already consistent.
- The floating `+` FAB on the Offers tab.
- The `embedded` prop on `MyKollabsScreen` and `MyOpportunitiesScreen`.

---

## Constraints

- No new dependencies.
- All tokens come from `KolabingColors`, `KolabingSpacing`, `KolabingRadius`, `KolabingTextStyles`.
- TypeScript — N/A (Flutter/Dart). All widgets strongly typed.
- No hardcoded hex values outside `KolabingColors`.
