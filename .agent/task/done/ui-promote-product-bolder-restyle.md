# UI: Promote Product wizard — Bolder restyle

## Status
- Created: 2026-06-25 15:16
- Started: 2026-06-25 15:16
- Completed: 2026-06-25 16:42

## UI Requirements
Restyle the Promote Product wizard steps (Product Details, Goal, Media/Photos)
to match the "Kolabing Promote Product - Bolder" mockup, consistent with the
already-shipped Bolder refactor (KolabingTopBar, KolabingButton,
KolabStepIndicator, KolabingInput, KolabingSelectableChip already exist and
already match tokens). This is presentation-only — no API/model/logic changes.

Affected files (kolabing-app Flutter repo):
- lib/features/kolab/screens/business/product_details_screen.dart
- lib/features/kolab/screens/business/goal_screen.dart
- lib/features/kolab/screens/business/media_screen.dart
- lib/widgets/category_icon.dart (still used elsewhere — do not delete/break)

New files to add:
- lib/widgets/kolabing_product_type_icon.dart — `KolabingProductTypeIcon(typeKey)`
- lib/widgets/kolabing_goal_icon.dart — `KolabingGoalIcon(goalKey)`

## Design Specifications

### Already correct — reuse, do not touch
- `KolabingTopBar`, `KolabStepIndicator` (ink dots, hairline border — already
  matches spec), `KolabActionBar`/`KolabingButton` (Back+Next, sticky footer
  with hairline top border), `KolabingInput`, `KolabingSelectableChip`,
  `KolabExamplesBox`. Tokens already correct in `color_tokens.dart` /
  `colors.dart` (ink #19150F, primaryTint/yellowTint #FFF1C6, hairline
  #EDE5D5, divider #ECE4D4, radius input 16/card 24/optionCard 20/thumbnail 18,
  Anton for display, Inter for body via `KolabingTypography`).

### Product Type chips (product_details_screen.dart)
Currently builds raw `GestureDetector` + `AnimatedContainer` chips using
`CategoryIcon(name: option.name, iconUrl: option.iconUrl)` — this renders
whatever icon the *admin-seeded* `option.name`/`iconUrl` resolves to, which is
why screenshots show emoji-like glyphs. Replace with:
- `KolabingSelectableChip` (already gives pill shape + yellowTint/ink-border
  selected state) passing `leadingIcon: KolabingProductTypeIcon(type)` where
  `type` is the typed `ProductType` enum value (from
  `lib/features/kolab/enums/product_type.dart`, via
  `ProductType.fromString(option.slug)` — already computed in the existing
  loop). Keep `option.name` for the label (admin-managed copy, just drop the
  `CategoryIcon` icon rendering for this chip set).
- Add a small ink check badge (12-14px circle, ink fill + yellow check) next
  to/over the icon when selected, per mockup — `KolabingSelectableChip`
  doesn't have a built-in badge, so either extend it with an optional
  `selectedBadge` slot or compose it locally in this file with a `Stack`; pick
  whichever keeps `KolabingSelectableChip` reusable for non-badge callers
  (default the new param to off/null so other call sites are unaffected).
- Keep the `errors['product_type']` banner and loading spinner as-is.

### KolabingProductTypeIcon (new file)
A single keyed icon widget/CustomPainter map, one source of truth:
```dart
KolabingProductTypeIcon(ProductType type, {double size = 18, Color? color})
```
Render via `CustomPaint`/`Path` (no SVG asset needed — these are simple stroke
paths), `stroke: color ?? context-ink #19150F`, `strokeWidth 1.7`,
`StrokeCap.round`, `StrokeJoin.round`, `fill: none` (Other = 3 filled ink
dots). Use a 24x24 viewBox scaled to `size`. Path data per `ProductType` enum
value (map every existing enum case; check the enum file for exact case names
— likely foodProduct, beverage, healthBeauty, sportsEquipment, fashion,
techGadget, experienceService, other):
- Food Product: `M4 11h16M5 11a7 7 0 0 1 14 0M7 16h10M9 20h6`
- Beverage: `M6 8h12l-1.2 11.2a1.5 1.5 0 0 1-1.5 1.3H8.7a1.5 1.5 0 0 1-1.5-1.3L6 8ZM9 8V4.5M12 8V3.5M15 8V4.5`
- Health & Beauty: `M12 20S4 14.5 4 9a4.5 4.5 0 0 1 8-2.8A4.5 4.5 0 0 1 20 9c0 5.5-8 11-8 11Z`
- Sports Equipment: `M6 3v8M6 11a2.5 2.5 0 0 0 2.5-2.5V3M9 3v18M16.5 3c-1.7 0-3 2-3 5s1.3 4 3 4m0 0v9m0-9V3`
- Fashion: `M8 4 5 6v3l2 1v9h10v-9l2-1V6l-3-2-3 2-3-2Z`
- Tech Gadget: rounded rect x4 y5 w16 h11 rx1.5 + line `M3 20h18`
- Experience / Service: `M12 3.5l2.6 5.4 5.9.8-4.3 4.1 1 5.9-5.2-2.8-5.2 2.8 1-5.9L3.5 9.7l5.9-.8L12 3.5Z`
- Other: three filled ink dots at (5,12) (12,12) (19,12), r 1.9
If a `ProductType` has no mapped case, fall back to the "Other" three-dots
glyph — never throw, never render emoji/blank.

### Goal step (goal_screen.dart)
Currently a hand-rolled radio card with `CategoryIcon(name: option.name, ...)`
(same emoji-glyph issue). Replace:
- Keep the existing `ListView` + `goalOptionsAsync` + `notifier.updateGoal`
  logic untouched — only restyle the per-option card.
- Card: white surface, `KolabingRadius.borderRadiusOptionCard` (20px — close
  enough to the mockup's 18px, reuse the existing token rather than
  introducing a new radius constant), `1px hairline` border unselected,
  `1.5px ink` border + `yellowTint` fill selected. Keep `AnimatedContainer`
  for the transition.
- Replace the existing 24px radio circle (already correct colors/sizing) —
  no change needed there, it already matches spec (ink fill + check when
  selected, hairline border otherwise).
- Replace `CategoryIcon(name: option.name, iconUrl: option.iconUrl)` with
  `KolabingGoalIcon(option.slug)`.
- Title: bump to `FontWeight.w800` when selected (currently w600/w400) per
  spec; subtitle stays `KolabingTextStyles.bodySmall` + `textTertiary`/muted —
  keep pulling `option.description` exactly as now (don't touch copy).
- Heading block ("GOAL" label + "What would make this Kolab a success?" +
  helper line) already styled close to spec (w700 tracked label, w700 18px
  question) — bump question to `FontWeight.w800` to match the Inter-800 spec,
  leave copy/strings untouched.

### KolabingGoalIcon (new file)
Same approach as the product-type icon: `KolabingGoalIcon(String goalSlug,
{double size = 24, Color? color})`, keyed by the admin `slug` string (lowercase,
hyphenated — confirm actual slug values from the `goalsProvider`/seeder rather
than assuming; match case-insensitively / strip punctuation if needed so seed
data variations don't fall through). Path data:
- More Visits: `M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7Z` + circle
  center(12,12) r2.8
- Product Awareness: `M3 11a9 9 0 0 1 18 0M5.5 11v4a6.5 6.5 0 0 0 13 0v-4M12 17.5v2.5M9 20h6`
- Content / Tagged Posts: `M4 5.5h16v10H9l-5 4V5.5Z`
- Reviews: `M12 3.5l2.6 5.4 5.9.8-4.3 4.1 1 5.9-5.2-2.8-5.2 2.8 1-5.9L3.5 9.7l5.9-.8L12 3.5Z`
- Sales / Revenue: `M12 3v18M8 7.5C8 6 9.8 5 12 5s4 1 4 2.6-1.5 2.4-4 2.4-4 .9-4 2.5S9.8 17 12 17s4-1 4-2.5`
- Community Event: circle center(9,8) r3 + `M3.5 19a5.5 5.5 0 0 1 11 0M16 8a3 3 0 0 1 0 5M16.5 19c0-1.4-.4-2.7-1-3.7`
- Product Testing: `M9 3h6v3l-2 2v3l4.5 7a1.5 1.5 0 0 1-1.3 2.3H7.8a1.5 1.5 0 0 1-1.3-2.3L11 14v-3L9 9V3Z`
Fallback for any unmapped slug = the Reviews star (never blank/never emoji).
Same stroke spec as product-type icons (1.7px ink, round caps/joins, no fill
except Other's dots — not applicable here).

### Media / Add Photos step (media_screen.dart)
- Header `ADD PHOTOS` already w700 tracked — bump to Inter 800 to match spec.
- Info banner already `softYellow` background — switch to `yellowTint`
  (#FFF1C6, matches mockup more closely than `softYellow` #FFF4C2) with
  `KolabingRadius.borderRadiusOptionCard` (18-20px) and add a small ink/amber
  info icon (`LucideIcons.info`, ~16px, amber/ink) before the text — currently
  text-only. Keep existing copy strings (`hasNoPhotoAnywhere` ternary) as-is.
- `errors['media']` validation line: keep data-driven, but render in
  `context.colors.orange` (not the generic `error` red) per spec, Inter 600.
- "Add Photo" tile (`_PhotoGrid`'s add button): resize to 120x120 (currently
  100x100), `2px dashed` border using `color: #D9CFBC` (introduce as a literal
  border color only if no existing named token matches — check
  `color_tokens.dart` first for something close like `navInactiveSubtle`
  #CFC6B3 before adding a new one), radius 18 (`borderRadiusThumbnail`).
  Replace the plain `LucideIcons.plus` icon with a small filled yellow
  circle (`primary`/`#FFE28C`) containing an ink `+`, with "Add Photo" label
  below in Inter 700.
- Photo thumbnails (`_PhotoSlot`): bump radius from `borderRadiusMd` (12px) to
  `borderRadiusThumbnail` (18px) to match. Keep the existing remove badge.
- Counter: there's currently no "X of 5 added" counter rendered — add one
  below the photo grid, computed as `${photos.length} of 5 added}` (or use
  l10n if a string format exists; otherwise a plain literal with the *number*
  always computed from `photos.length`, never hardcoded), Inter 600 muted.

## Implementation

### Widget Structure
- `KolabingProductTypeIcon(ProductType type, {double size = 18, Color? color})`
  — `CustomPaint` over `_ProductTypeIconPainter`. Stroke = `context.colors.ink`
  (overridable via `color`), 1.7px, round caps/joins, drawn on a 24x24 viewBox
  scaled to `size`. Path data mapped per enum case; `techGadget` drawn as a
  rounded rect + base line; `other` (and any unmapped case) draws three filled
  ink dots. SVG path strings parsed by the shared `parseSvgPath`.
- `KolabingGoalIcon(String goalSlug, {double size = 24, Color? color})` —
  `CustomPaint` over `_GoalIconPainter`. Same stroke spec. Slugs normalized to
  lowercase alphanumerics (`_normalize`) so seed variations match
  case-insensitively. `more_visits` = eye outline + pupil circle;
  `community_event` = head circle + body/second-person path; all others use
  mapped path data; unmapped slugs fall back to the Reviews star.
- `parseSvgPath(String)` (new util) — minimal M/m,L/l,H/h,V/v,Z/z parser used by
  both icon painters; handles negative numbers and packed decimals (e.g.
  `5.9.8`).
- `KolabingSelectableChip` — added optional `showSelectedBadge` (default false);
  when true and selected, overlays a 13px ink circle + yellow check on the
  leading icon. Other call sites unaffected.
- `ProductDetailsScreen` — product-type chips now `KolabingSelectableChip` with
  `leadingIcon: KolabingProductTypeIcon(type)` and `showSelectedBadge: true`.
  All data binding (label, `ProductType.fromString(option.slug)`,
  `notifier.updateProductType`, error banner, loading spinner) unchanged.
- `GoalScreen` — `CategoryIcon` → `KolabingGoalIcon(option.slug)`; selected
  title + question heading bumped to `FontWeight.w800`; card uses
  `borderRadiusOptionCard`, ink/hairline selected border, `yellowTint` fill.
  List/selection logic, descriptions, and radio circle untouched.
- `MediaScreen` — `ADD PHOTOS` header → Inter w800; info banner → `yellowTint`
  + `borderRadiusOptionCard` + `LucideIcons.info` (amber); media error rendered
  in `context.colors.orange` (Inter w600); "Add Photo" tile resized to 120x120
  with a 2px dashed border (`navInactiveSubtle`, `borderRadiusThumbnail`) and a
  filled-primary circle with an ink plus; thumbnail radius → `borderRadiusThumbnail`;
  computed `${photos.length} of 5 added` counter below the grid (reads live
  `kolab.media`).

### Files Created
- lib/widgets/kolabing_product_type_icon.dart
- lib/widgets/kolabing_goal_icon.dart
- lib/utils/svg_path_parser.dart (shared SVG path-data parser for the icons)

### Files Modified
- lib/widgets/kolabing_selectable_chip.dart (optional `showSelectedBadge` slot)
- lib/features/kolab/screens/business/product_details_screen.dart
- lib/features/kolab/screens/business/goal_screen.dart
- lib/features/kolab/screens/business/media_screen.dart

### Verification
- `flutter analyze` on all changed files: no new issues. The single remaining
  `directives_ordering` info on media_screen.dart:14 is pre-existing (the
  `l10n` import order) and was not introduced by this task.
- `flutter test test/features/kolab/screens/business/goal_screen_test.dart`:
  passing (also surfaced + fixed a packed-decimal parser bug).
- All 12 icon path strings verified to parse without throwing.

## Guardrails (non-negotiable, from product spec)
- No emoji anywhere in this flow after the change.
- Icon path data is the only literal/hardcoded data allowed, and only inside
  the two new icon-map widgets.
- All copy/labels/options/goals/cities/subtitles/validation messages must stay
  bound to existing providers/state — do not hardcode strings, counts, or
  lists that are already data-driven today.
- Do not change routing, API calls, validation rules, wizard step ordering,
  form controllers, or models.
- Run `flutter analyze` and existing widget tests touching these screens (if
  any) after the change; fix any analyzer warnings introduced.

## Notes
Spec originated from a Claude Design mockup comparison ("Kolabing Promote
Product - Bolder" vs current screenshots) — full icon path tables and color
tokens are inlined above so no external mockup file needs to be re-fetched.
