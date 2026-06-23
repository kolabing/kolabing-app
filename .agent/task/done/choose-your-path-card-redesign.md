# UI: Choose Your Path card redesign

## Status
- Created: 2026-06-10
- Started: 2026-06-10
- Completed: 2026-06-10

## UI Requirements
Redesign the 3 account-type selection cards on the "Choose Your Path"
screen (`UserTypeSelectionScreen`) so they match the white, softly
elevated card style used by `KolabCardShell` (Explore / My Kolabs):
white surface, 16px radius, soft border + two-layer shadow, refined
icon container, polished typography hierarchy, and a clearer
selected vs. coming-soon state.

## Design Specifications

### Colors & Typography
- Card surface: `Colors.white` (was `context.colors.surface`, which
  equals the warm background color, causing the flat look).
- Border: `#EAE6DE` 1px (matches `KolabCardShell`); selected state
  upgrades to a 1.5px soft yellow accent ring (`softYellowBorder`).
- Shadow: two-layer soft shadow matching `KolabCardShell`
  (`black @ 0.06` blur 16 / offset (0,3) + `black @ 0.03` blur 4 /
  offset (0,1)); coming-soon card uses a lighter single-layer shadow.
- Radius: `KolabingRadius.borderRadiusLg` (16px), consistent with
  Explore/My Kolabs cards.
- Icon container: 44x44 rounded square (`KolabingRadius.sm`, 12px)
  with a soft tinted `softYellow` background; muted alpha for the
  disabled (attendee) card.
- Title: `bodyMedium`, w700, `onSurface` (muted for disabled).
- Subtitle: `bodySmall`, `onSurfaceVariant`, line-height 1.35.
- "COMING SOON" badge: refined pill using `softYellow` fill +
  `softYellowBorder` outline.

### Layout
- Padding increased to 18/20 for more breathing room.
- Icon left, vertically centered; title + subtitle column on the
  right; selected check indicator on the far right.

## Implementation

### Files Changed
- `lib/features/auth/widgets/selection_card.dart`

## Notes
Screen structure (`user_type_selection_screen.dart`) untouched —
only the `SelectionCard` widget styling was updated.
