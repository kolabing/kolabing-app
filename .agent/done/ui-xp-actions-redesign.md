# Task: ui-xp-actions-redesign

## Status
- Created: 2026-06-10 00:00
- Started: 2026-06-10 00:00
- Completed: 2026-06-10 00:00

## UI Requirements
Redesign the "Today's XP Missions" section because these actions are repeatable, not
completed once.

- Rename section to "XP ACTIONS" with subtitle "Earn points every time you contribute."
- Remove the "1 of 4 done" counter and the "✓ Done" status pill — actions can be repeated
  (post a review, complete a Kolab, share content, refer a community).
- Replace the stack of separate cards with a single white card containing compact,
  tappable rows separated by hairline dividers.
- Each row: pastel icon tile (smaller, dark simple icon) + title + short description +
  "+N XP" pill.
- If an action was recently completed, show a subtle "Earned" hint under the pill without
  disabling the row (still tappable/repeatable).

## Design Specifications

### Layout
- Section header: "XP ACTIONS" (label-large, letter-spacing 1.0) + subtitle (12px,
  textTertiary).
- Single white (`Colors.white`) card, `KolabingRadius.borderRadiusMd`, `c.hairline`
  border, rows separated by 1px `Divider` in `c.hairline`.
- Row: 36x36 pastel icon tile (radius 10), title (13px/700), description (11px,
  textTertiary, single line ellipsis), trailing column with "+N XP" pill and optional
  "Earned" hint (10px, textTertiary).

### Colors & Typography
- Icon tiles reuse existing pastel accents: `categoryMintBg`, `amberChipContainer`,
  `categoryLavenderBg`, `categoryRedBg`.
- XP pill: `categoryLavenderBg` background / `categoryLavenderText` text, pill radius 20.

### Animations
- None added; rows wrapped in `InkWell` for tap feedback (ripple).

### Responsive Behavior
- Row text uses `Expanded` + ellipsis on description to handle narrow screens.

### Accessibility
- Whole row is tappable (`InkWell` with `onTap` callback hook), min content height keeps
  touch target reasonable within compact layout.

## Implementation

### Widget Structure
- `XpMissionsSection` (Column: header texts + white card with `EarnXpActionCard` rows and
  dividers).
- `EarnXpActionCard` (now a tappable row instead of a bordered standalone card); replaced
  `isDone` with `recentlyEarned` and dropped the green "✓ Done" badge in favor of an
  always-shown "+N XP" pill plus optional subtle "Earned" label.

### Files Created
- (none — existing files modified)

### Files Modified
- `lib/features/dashboard/widgets/xp_missions_section.dart`
- `lib/features/dashboard/widgets/earn_xp_action_card.dart`

### Usage Example
```dart
const XpMissionsSection()
```

## Notes
- Post a review reward updated to +10 XP per spec (was +20 in the old preview data).
- `dart analyze` clean on both modified files.
- `onTap` wiring left as a hook (no-op) — actual navigation/action handlers are an API
  integration concern, out of scope for this UI-only task.
