# Spec: Editorial UI Redesign — Phase 1 (Visual Refinement)

**Date:** 2026-06-01  
**Scope:** Visual design only — no layout surgery, no functional changes, no navigation changes.  
**Goal:** Make the app feel editorial, urban, and premium — closer to the Stitch reference direction — by fixing the specific elements causing a childish/playful look. Phase 2 (layout + editorial composition) is explicitly deferred.

---

## Problem Statement

The current UI has the right design tokens (Anton typeface, parchment background, ink charcoal, soft yellow) but applies them poorly in specific components:

1. **Stat cards use lavender/sage as full card backgrounds** — looks like colored toy blocks, not a data interface.
2. **Hardcoded accent colors** (`#FF9800`, `#4CAF50`, `#9C27B0`, `#2196F3`) on icon circles — random, unrelated to brand.
3. **XP progress card uses lavender as its card background** — gamification has no distinct visual identity.
4. **Explore card match badge is a yellow pill** — feels like a game score, not an editorial stamp.
5. **Explore card chips alternate by index position** — artificial, not semantic.
6. **Section spacing is tight** — hierarchy feels compressed; the premium feeling in reference designs comes from breathing room, not just colors.
7. **Dashboard titles lack presence** — subtitle competes with the title visually.
8. **Referral banner eyebrow uses lavender text** — adds noise to an otherwise quiet card.

---

## Design Direction

**Keep:** Yellow accent, lavender, sage, warm parchment surfaces, Anton display type.  
**Change:** Move lavender/sage from dominant card surfaces → small contained accents (icon circles, chips). Use neutral cream for all card faces.  
**Add:** Mint green (`#7AE7A3`) as a contained gamification sub-identity for the XP layer only.  
**Improve:** Section whitespace (+20–30%), count/label contrast, metadata quietness, title dominance.

---

## Color Token Changes

### File: `lib/config/theme/colors.dart`

**Add three XP gamification tokens:**

```dart
static const Color xpGreen = Color(0xFF7AE7A3);
static const Color xpGreenContainer = Color(0xFFE8F9F1);
static const Color xpGreenOnContainer = Color(0xFF1A6644);
```

**Add two category chip tokens:**

```dart
static const Color categoryBlueGrey = Color(0xFFDDE3EC);
static const Color categoryBlueGreyText = Color(0xFF3D4A5C);
```

No existing tokens are removed or changed. `secondaryContainer` and `tertiaryContainer` retain their values but stop being used as full card backgrounds.

---

## Component Specs

### 1. `DashboardStatCard` — `lib/features/dashboard/widgets/dashboard_stat_card.dart`

**Remove:** `accentColor` parameter and `index` parameter.  
**Add:** `StatCardAccent` enum parameter.

```dart
enum StatCardAccent { pending, accepted, active, completed }
```

Each accent value maps to a fill color and icon color:

| Accent | Circle fill | Icon color |
|---|---|---|
| `pending` | `secondaryContainer` (lavender) | `secondary` |
| `accepted` | `tertiaryContainer` (sage) | `tertiary` |
| `active` | `softYellow` | `onSurface` |
| `completed` | `surfaceContainerHigh` | `onSurfaceVariant` |

**Card structure:**
- Background: `surfaceContainer` — same for all 4, no alternating
- No left border, no top accent bar, no shadow
- `borderRadius: 12`
- Icon circle: `36px`, uses accent fill/icon as above
- Count: Anton `displaySmall`, explicit `fontSize: 36`, `onSurface`
- Label: `labelSmall` uppercased, `textTertiary` — quieter than current
- Subtitle (optional): `captionSecondary`, `onSurfaceVariant`

The `_cardColor` getter and the `index` field are removed entirely.

---

### 2. `CommunityDashboardScreen` — `lib/features/dashboard/screens/community_dashboard_screen.dart`

**Stat card calls updated to use `StatCardAccent`:**

| Card | Accent |
|---|---|
| Pending | `StatCardAccent.pending` |
| Accepted | `StatCardAccent.accepted` |
| Active Kolabs | `StatCardAccent.active` |
| Completed | `StatCardAccent.completed` |

Remove hardcoded `Color(0xFFFF9800)`, `Color(0xFF4CAF50)`, `Color(0xFF9C27B0)`.

**Spacing increases:**
- All `SizedBox(height: KolabingSpacing.lg)` between major sections → `KolabingSpacing.xl`
- The `ListView` padding stays at `KolabingSpacing.md` (do not change outer padding)

**Header refinement:**
- Dashboard title: add `letterSpacing: 1.0` to Anton `headlineLarge` (visual judgment — use 0.5–1.5, pick what doesn't look stretched with Anton at 32px)
- Subtitle `Welcome back, $userName`: change color from `onSurfaceVariant` → `textTertiary` — one step quieter

---

### 3. `BusinessDashboardScreen` — `lib/features/dashboard/screens/business_dashboard_screen.dart`

Same changes as `CommunityDashboardScreen`.

**Stat card calls:**

| Card | Accent |
|---|---|
| Published | `StatCardAccent.active` (yellow — primary action) |
| Pending Applications | `StatCardAccent.pending` |
| Active Kolabs | `StatCardAccent.accepted` (sage — ongoing/growth) |
| Completed | `StatCardAccent.completed` |

Remove hardcoded `Color(0xFFFF9800)`, `Color(0xFF4CAF50)`.

---

### 4. `XpProgressCard` — `lib/features/rewards/widgets/xp_progress_card.dart`

- Card background: `xpGreenContainer`
- Progress bar fill: `xpGreen`
- Progress bar track: `xpGreen.withValues(alpha: 0.2)`
- Level chip fill: `xpGreen.withValues(alpha: 0.15)`
- Level chip icon + text: `xpGreenOnContainer`
- All other text: `onSurface` / `onSurfaceVariant` (unchanged)

Lavender (`secondary`, `secondaryContainer`) removed entirely from this widget.

---

### 5. `ExploreSwipeCard` — `lib/widgets/explore_swipe_card.dart`

#### Match badge
- Background: `inverseSurface` (`#31302B`) — dark ink
- Text: `inverseOnSurface` (`#F4F0E7`) — off-white
- Replaces current yellow pill

#### Category chips
Chips map to category families using a helper method `_chipColors(String label)` that returns a `(Color fill, Color text)` tuple:

| Category keywords | Fill token | Text token |
|---|---|---|
| run, sport, fitness, yoga, paddle | `secondaryContainer` | `secondary` |
| food, coffee, drink, restaurant, bar | `softYellow` | `onPrimary` |
| wellness, nature, eco, health, organic | `tertiaryContainer` | `tertiary` |
| music, art, culture, film, photo | `categoryBlueGrey` | `categoryBlueGreyText` |
| (fallback) | `surfaceContainerHigh` | `onSurfaceVariant` |

Matching is case-insensitive substring. The alternating-color logic (`fills` array by index) is removed.

Chip `borderRadius` → `6` (down from round pill — more editorial).  
Chip font: `11px`, `letterSpacing: 0.3`.

#### Text hierarchy in content section
- Card title: Anton `cardTitleLarge`, `letterSpacing: -0.5` — tighter, more condensed
- Business/community name: `labelLarge`, `onSurface`
- Location / metadata: `captionSecondary`, `textTertiary`
- Content section internal padding: increase from `KolabingSpacing.md` → `KolabingSpacing.lg`

---

### 6. `ReferralBannerCard` — `lib/features/rewards/widgets/referral_banner_card.dart`

- Eyebrow label `'EARN BY SHARING'`: color `secondary` (lavender) → `onSurfaceVariant`

One-line change.

---

## Files Edited

| File | Why |
|---|---|
| `lib/config/theme/colors.dart` | Add XP tokens + category blue-grey tokens |
| `lib/features/dashboard/widgets/dashboard_stat_card.dart` | Neutral card bg, semantic `StatCardAccent` enum, no hardcoded colors |
| `lib/features/dashboard/screens/community_dashboard_screen.dart` | Pass semantic accents, increase section spacing, quieter subtitle |
| `lib/features/dashboard/screens/business_dashboard_screen.dart` | Same as community |
| `lib/features/rewards/widgets/xp_progress_card.dart` | Mint green gamification retheme |
| `lib/widgets/explore_swipe_card.dart` | Dark match badge, category-mapped chips, text hierarchy, content padding |
| `lib/features/rewards/widgets/referral_banner_card.dart` | Eyebrow color fix |

**Not touched:** layouts, navigation, routes, providers, data models, auth, onboarding, kolab flow, application flow, collaboration flow, gamification screens.

---

## Out of Scope (Phase 2)

- Full dashboard layout redesign (editorial composition, horizontal scrollable stat row)
- Explore card polaroid/editorial layout
- Global spacing system refactor
- Bottom navigation visual treatment changes
- App bar redesign
- Onboarding / auth screen changes
