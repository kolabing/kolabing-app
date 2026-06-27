# UI: My Kolabs filters & card actions — Bolder redesign

## Status
- Created: 2026-06-27 13:52
- Started: 2026-06-27 13:52
- Completed: 2026-06-27 14:03

## UI Requirements
Redesign "My Kolabs" filters (primary OFFERS/REQUEST/ACTIVE/FINISHED tab row +
secondary PUBLISHED/DRAFT row) and per-card action buttons to match the
"Kolabing My Kolabs - Bolder" mockup, consistent with the shipped "Kolabing App
Screens - Bolder" refactor. Presentation-only — no content/logic changes.

Affected files (kolabing-app):
- lib/features/kolab/screens/my_kolabs_hub_screen.dart (primary TabBar)
- lib/features/kolab/widgets/my_kolabs_sub_tabs.dart (secondary tab row)
- lib/features/kolab/widgets/my_kolab_card.dart (card action row)
- lib/widgets/glass_icon_button.dart (replaced by KolabingIconPillButton in
  this flow; left in place since other call sites may still use it)

New files:
- lib/widgets/kolabing_segmented_control.dart
- lib/widgets/kolabing_card_action_bar.dart (KolabingCardActionBar +
  KolabingIconPillButton + shared icon map)

## Design Specifications
See full spec in the originating conversation — primary/secondary segmented
control tokens, card action bar (VIEW pill + 3 icon pills), icon path table.
Reused tokens: bgCream, cardWhite, yellow, yellowTint, orangeTint, orange,
ink, muted, amber, hairline/divider, radiusCard, radiusPill, shadowCard.
New tokens added to color_tokens.dart (none existed at matching hex):
- `mutedFilter` #A29886 (unselected segmented-control label)
- `controlBorder` #EAE0CF (segmented-control track / icon-pill border)
- `pillPressedFill` #F7F1E5 (icon-pill pressed state)
- `iconStroke` #5F5A52 (neutral icon-pill stroke)

## Implementation
### Widget Structure
- `KolabingSegmentedControl<T>` — generic, takes `segments`, `selectedValue`,
  `onChanged`, `style` (primary/secondary visual preset). No tab/segment
  strings are hardcoded by the widget; callers pass their own labels.
- `KolabingCardActionBar` — flex row (VIEW flex 2.1 + up to 3 icon pills flex
  1.25 each, gap 10, height 52).
- `KolabingIconPillButton` — stadium pill, cardWhite/controlBorder/iconStroke,
  pillPressedFill on press, no shadow.
- Shared `KolabingCardActionIcon` path map (view/edit/share/close) drawn via
  the existing `parseSvgPath` util from the Promote Product bolder refactor.

### Files Created
- lib/widgets/kolabing_segmented_control.dart
- lib/widgets/kolabing_card_action_bar.dart

### Files Modified
- lib/config/theme/color_tokens.dart (4 new tokens, light+dark)
- lib/features/kolab/screens/my_kolabs_hub_screen.dart
- lib/features/kolab/widgets/my_kolabs_sub_tabs.dart
- lib/features/kolab/widgets/my_kolab_card.dart

### Verification
- `flutter analyze` on changed files
- existing widget/provider tests touching these screens

## Notes
Spec originated from a Claude Design mockup comparison ("Kolabing My Kolabs -
Bolder" vs current screenshot). Branch: feat/my-kolabs-bolder-redesign (off
master, isolated from the gamification WIP branch in another session).
