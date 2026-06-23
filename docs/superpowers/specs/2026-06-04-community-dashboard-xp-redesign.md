# Community Dashboard XP Redesign — Design Spec
_Last updated: 2026-06-04_

## Overview

Redesign the Community Dashboard to make XP the primary focal point. Instead of burying XP behind a tappable card, the new layout surfaces XP progress and earning actions directly on the dashboard. The implementation uses a **local preview variant switch** so all three layout options can be compared on localhost before committing to one.

Approved visual direction: **Variant B — Gamified Mission Board**, with the sage-green XP card style, pastel yellow referral card, and warm ink text scale.

---

## Goals

- XP summary visible immediately below the header (above the fold)
- Ways to earn XP visible directly on the dashboard — no tap required
- XP card is non-navigable (no "View progress ›" CTA)
- Stats demoted to a compact horizontal strip
- Badges surfaced on the dashboard
- Referral card restyled as a soft pastel yellow rect (matches XP card shape language)
- Warm ink text scale applied throughout

---

## Visual Style

| Token | Value |
|---|---|
| Headings | `#36322A` warm graphite |
| Body copy | `#5A5345` warm taupe |
| Captions | `#928B7C` soft |
| XP card bg | `#E8EFE0` sage green |
| XP card text | `#3D5229` / `#2E4020` |
| Referral card bg | `#FDF6DC` pastel yellow |
| Referral card border | `#F0E4A0` |
| XP badge | Purple pastel `#EDE8FB` / `#7B5EA7` |
| Done badge | Green pastel `#E8F5EE` / `#2E7D52` |

Typography, spacing, and radius constants follow the existing Kolabing design system (`KolabingColors`, `KolabingSpacing`, `KolabingRadius`).

---

## Dashboard Layout (Approved — Variant B)

```
1. Header (greeting + notification bell)
2. XP Summary Card  ← sage green, non-tappable
3. "Today's XP Missions" section  ← mission cards with icon / title / desc / badge
4. Compact stats strip  ← 4-pill horizontal row
5. Badges row  ← horizontal scroll, earned highlighted / locked greyed
6. Referral card  ← pastel yellow rect
7. Find a Kolab / My Applications CTAs
8. Upcoming Kolabs
```

---

## Preview Variant Switch

A local-only enum inside the dashboard file controls which layout renders:

```dart
enum DashboardPreviewVariant { optionA, optionB, optionC }
const _kDashboardVariant = DashboardPreviewVariant.optionB;
```

All three variants remain selectable by changing `_kDashboardVariant`. The switch does **not** affect production builds — it is a dev-time constant.

---

## New Components

### `CommunityXpSummaryCard`
- **File:** `lib/features/dashboard/widgets/community_xp_summary_card.dart`
- **Props:** `XpModel xp` (from existing wallet provider)
- **Behaviour:** Non-tappable. Displays level chip, big XP number, "To next level" counter, progress bar. No navigation.
- **Style:** Sage green background, warm ink text.

### `EarnXpSection` (Variant A) / `XpMissionsSection` (Variant B)
- **File:** `lib/features/dashboard/widgets/xp_missions_section.dart`
- **Props:** none (actions are static/constant for now)
- **Behaviour:** Renders a list of `EarnXpActionCard` widgets. For Variant B, shows "Today's XP Missions" header with a counter. Done/pending state is hardcoded for preview; real completion state can be wired in a follow-up.
- **Note:** XP actions are currently defined by `PointEventType` enum in `lib/features/rewards/models/ledger_entry.dart`. The section reads from a static local list for the preview.

### `EarnXpActionCard`
- **File:** `lib/features/dashboard/widgets/earn_xp_action_card.dart`
- **Props:** `String icon`, `String title`, `String description`, `int xpReward`, `bool isDone`
- **Behaviour:** Displays pastel icon, title, description, and either a purple XP badge or a green "Done" badge.

### `CommunityStatsStrip`
- **File:** `lib/features/dashboard/widgets/community_stats_strip.dart`
- **Props:** `int pending`, `int accepted`, `int active`, `int completed`
- **Behaviour:** Replaces the existing 2×2 `DashboardStatCard` grid with a single-row 4-pill strip. Reuses existing stat data from the dashboard provider.

### `DashboardBadgesRow`
- **File:** `lib/features/dashboard/widgets/dashboard_badges_row.dart`
- **Props:** `List<Badge> badges` (from existing wallet provider)
- **Behaviour:** Horizontally scrollable row of badge chips. Earned badges have warm yellow tint; locked badges are greyed. Sourced from `WalletNotifier` already used by the wallet screen.

---

## Modified Files

| File | Change |
|---|---|
| `lib/features/dashboard/screens/community_dashboard_screen.dart` | Add variant switch constant; conditionally render variant layouts |
| `lib/features/rewards/widgets/xp_progress_card.dart` | Remove / hide "View progress ›" tap CTA (keep widget intact for wallet screen use) |

---

## What Stays Unchanged

- `WalletScreen` — disconnected from dashboard card tap, not deleted
- All navigation routes
- Backend logic, providers, Supabase calls
- Explore, My Kolabs, Profile, auth screens
- `DashboardStatCard` widget (still used by Variant A/C and business dashboard)

---

## Hardcoded Data (Preview Only)

The following is hardcoded for the preview and flagged for wiring in a follow-up:
- Mission done/pending states (real data: ledger entries from `WalletNotifier`)
- Mission list order (real data: could be driven by `PointEventType`)
- "2 of 4 done" counter (real data: count ledger entries by type)

---

## Out of Scope

- Connecting mission tap actions to real flows
- Persisting variant preference
- Any changes to Explore, auth, navigation, or backend
