# Kolabing UI Standardization — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Standardize all Flutter UI components (buttons, cards, chips, inputs, headers, bottom nav) to the "Kolabing App Screens — Bolder" design system before any screen-level redesign begins.

**Architecture:** Centralize design tokens first, then update canonical component files one category at a time. Every existing reusable widget becomes the single source of truth — no new duplicate components. Screens are not touched until all components are stable.

**Tech Stack:** Flutter 3.x, Dart, Google Fonts (Anton + Inter), Lucide Icons, Riverpod

## Global Constraints

- Do NOT edit any screen files until Phase 6 (screen refactors) is explicitly approved.
- Do NOT change routing, state management, API calls, or data models.
- Do NOT create a new widget if a canonical equivalent already exists — update the existing one.
- Font families: Anton (display/major titles only), Inter (body/buttons/chips/inputs/labels). The codebase currently uses "Hanken Grotesk" for labels/buttons — migrate to Inter.
- Primary yellow CTA: `#FFE28C` only. Never `#FFD861` or any other yellow variant.
- Orange: `#FF6114` for status/role/accent labels only — never as a primary CTA.
- Background: warm cream `#FAF5EA`. Cards: white `#FFFFFF`. Never muddy brown, lavender, or random pastels.
- All colors MUST resolve through `context.colors` (the `KolabingColorTokens` ThemeExtension). No `Color(0xFF...)` literals in widget files.
- Run `flutter analyze` after each phase and resolve all warnings before moving on.
- No dark-mode regressions: always test both light and dark in simulator after each phase.

---

## AUDIT SUMMARY

### What already exists (do not recreate)

| File | What it is | Status |
|------|-----------|--------|
| `lib/config/theme/color_tokens.dart` | 89 runtime color tokens, ThemeExtension | ✅ Good — needs value updates |
| `lib/config/theme/colors.dart` | Legacy static color constants | ⚠️ Keep for non-widget contexts, sync values |
| `lib/config/theme/typography.dart` | Font families + text styles | ⚠️ Needs font family swap (Hanken → Inter) + new styles |
| `lib/config/theme/theme.dart` | ThemeData wiring | ⚠️ Needs token value updates |
| `lib/config/constants/spacing.dart` | Semantic spacing values | ✅ Good — no changes needed |
| `lib/config/constants/radius.dart` | Radius tokens | ⚠️ Needs new values (card: 24, option card: 20, pill: 999, input: 16, thumbnail: 18) |
| `lib/config/constants/layout.dart` | Screen padding, nav heights, shadows | ✅ Good — minor updates |
| `lib/widgets/kolabing_button.dart` | Primary/secondary/dark buttons | ⚠️ Canonical — needs color + font fixes |
| `lib/widgets/glass_button.dart` | Soft outline buttons | ⚠️ Keep — migrate colors to tokens |
| `lib/widgets/glass_icon_button.dart` | Circular icon button | ✅ Keep as-is |
| `lib/widgets/cards/kolabing_cards.dart` | PrimaryContentCard, CompactListCard, EmptyStateCard | ⚠️ Canonical — fix hardcoded Colors.white + borders |
| `lib/widgets/kolab_card_shell.dart` | My Kolabs list card | ⚠️ Fix hardcoded border + thumbnail gradient |
| `lib/widgets/kolab_chip.dart` | KolabChip — 6 color variants | ⚠️ Canonical chip — rename variants + fix colors |
| `lib/widgets/kolab_status_badge.dart` | KolabStatusBadge — 12+ status types | ⚠️ Migrate status colors to tokens |
| `lib/widgets/navigation/kolabing_bottom_nav_bar.dart` | KolabingBottomNavBar | ⚠️ Fix active state (no black circle), fix label style |
| `lib/widgets/navigation/kolabing_app_bar.dart` | KolabingAppBar | ⚠️ Extend to support title + back button variants |

### What is MISSING (needs to be created)

| Widget | Where needed |
|--------|-------------|
| `KolabingInput` | Wrapper around TextFormField with centralized decoration |
| `KolabingSelectableChip` | Unselected/selected chip for filter/category choosers (separate from KolabChip status chips) |
| `KolabingIconOptionCard` | Selectable option card for "Venue", "Food & Drink", etc. |
| `KolabingMetadataPill` | Compact tinted pill with icon + label for date/location/attendees |
| `KolabingTopBar` | Screen-level top bar with Anton title, circular back button, optional right action |

---

## Phase 0 — Audit (COMPLETE)

This document is the output of Phase 0. No code changes made.

---

## Phase 1 — Centralize Design Tokens

**Goal:** All color, typography, radius, and shadow values updated to match the bolder design system. No screen changes. Component files may not adopt them yet — that happens in Phases 2–7.

**Risk:** Low. Changes are isolated to config files.

**Files to modify:**
- `lib/config/theme/color_tokens.dart`
- `lib/config/theme/colors.dart`
- `lib/config/theme/typography.dart`
- `lib/config/constants/radius.dart`
- `lib/config/theme/theme.dart`

**Visual result after phase:** Near-zero visible change unless components already use tokens. But foundation is correct for all subsequent phases.

---

### Task 1.1 — Update color tokens

**Files:**
- Modify: `lib/config/theme/color_tokens.dart`
- Modify: `lib/config/theme/colors.dart`

**Interfaces:**
- Produces: `KolabingColorTokens` ThemeExtension with updated surface/brand/semantic values
- Produces: `KolabingColors` static class mirroring key values for non-widget contexts
- Later tasks use: `context.colors.surface`, `context.colors.appBackground`, `context.colors.primary`, `context.colors.hairline`, `context.colors.inkBody`, `context.colors.muted`, `context.colors.orange`, `context.colors.yellowTint`, `context.colors.orangeTint`

- [ ] **Step 1: Read current color_tokens.dart**

```bash
cat lib/config/theme/color_tokens.dart
```

- [ ] **Step 2: Update light theme color values in KolabingColorTokens**

Target values for the light theme (update only these fields — preserve all existing field names):

```dart
// Surfaces
appBackground: const Color(0xFFFAF5EA),   // warm cream (was #F7F8FA or similar)
surface: const Color(0xFFFFFFFF),          // white cards
surfaceVariant: const Color(0xFFF5EFE3),   // input fill (soft cream)
navBarBackground: const Color(0xFFFFFFFF), // white nav

// Brand
primary: const Color(0xFFFFE28C),          // main yellow CTA (was #FFD861)
primaryTint: const Color(0xFFFFF1C6),      // yellow tint for selected chips
amber: const Color(0xFF9A7C28),            // amber text on yellow backgrounds
orange: const Color(0xFFFF6114),           // status/role/accent only
orangeTint: const Color(0xFFFFE7D6),       // orange tint background

// Ink / text
ink: const Color(0xFF19150F),              // darkest text
inkBody: const Color(0xFF3F3A32),          // body text
muted: const Color(0xFF8C8474),            // placeholder / inactive text
navInactive: const Color(0xFFA99E8B),      // nav inactive

// Borders
hairline: const Color(0xFFEDE5D5),         // card/input border (light)
outlineVariant: const Color(0xFFE4DBCB),   // secondary border
divider: const Color(0xFFECE4D4),          // dividers
```

- [ ] **Step 3: Add missing tokens that don't yet exist**

If any of these fields don't exist in `KolabingColorTokens`, add them now:
- `yellowTint` → `const Color(0xFFFFF1C6)`
- `orangeTint` → `const Color(0xFFFFE7D6)`
- `amber` → `const Color(0xFF9A7C28)` (if not present)
- `inkBody` → `const Color(0xFF3F3A32)` (if not present)

Also add the `lerp` and `copyWith` implementations for any new fields following the existing pattern.

- [ ] **Step 4: Sync KolabingColors static class**

In `lib/config/theme/colors.dart`, update static constants to match:
```dart
static const Color appBackground = Color(0xFFFAF5EA);
static const Color primary = Color(0xFFFFE28C);
static const Color primaryTint = Color(0xFFFFF1C6);
static const Color orange = Color(0xFFFF6114);
static const Color orangeTint = Color(0xFFFFE7D6);
static const Color ink = Color(0xFF19150F);
static const Color inkBody = Color(0xFF3F3A32);
static const Color muted = Color(0xFF8C8474);
static const Color hairline = Color(0xFFEDE5D5);
```

- [ ] **Step 5: Run analyze**

```bash
flutter analyze lib/config/theme/
```
Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add lib/config/theme/color_tokens.dart lib/config/theme/colors.dart
git commit -m "chore: update color tokens to bolder design system values"
```

---

### Task 1.2 — Update typography tokens

**Files:**
- Modify: `lib/config/theme/typography.dart`
- Modify: `lib/config/theme/theme.dart`

**Interfaces:**
- Produces: `KolabingTextStyles` with Anton (display only) + Inter (everything else)
- Later tasks use: `KolabingTextStyles.displayTitle`, `KolabingTextStyles.sectionHeader`, `KolabingTextStyles.buttonLabel`, `KolabingTextStyles.chipLabel`, `KolabingTextStyles.bodyMd`, `KolabingTextStyles.bodySm`, `KolabingTextStyles.metaLabel`

- [ ] **Step 1: Read current typography.dart**

```bash
cat lib/config/theme/typography.dart
```

- [ ] **Step 2: Update font families**

Replace `HankenGrotesk` with `Inter` in all text styles except display/title styles:

```dart
// DISPLAY — Anton only (major screen titles, big uppercase headings)
static TextStyle displayTitle = GoogleFonts.anton(
  fontSize: 32,
  fontWeight: FontWeight.w400, // Anton has no weight variants
  letterSpacing: 0.5,
  height: 1.1,
);

static TextStyle sectionHeadingLarge = GoogleFonts.anton(
  fontSize: 22,
  letterSpacing: 0.3,
  height: 1.2,
);

// BODY / UI — Inter for everything else
static TextStyle buttonLabelLg = GoogleFonts.inter(
  fontSize: 16,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.1,
);

static TextStyle buttonLabelMd = GoogleFonts.inter(
  fontSize: 14,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.1,
);

static TextStyle chipLabel = GoogleFonts.inter(
  fontSize: 13,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.1,
);

static TextStyle metaLabel = GoogleFonts.inter(
  fontSize: 11,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.8,
);  // for uppercase section micro-labels

static TextStyle bodyLg = GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
static TextStyle bodyMd = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
static TextStyle bodySm = GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4);

static TextStyle nameBold = GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800);
// Community/business names — NOT Anton — Inter 800
```

Keep all existing style names that are already in use. Add new names above. Do not remove old names yet — wrap in deprecation comments only if replacing them in the same PR.

- [ ] **Step 3: Update ThemeData textTheme references if any use HankenGrotesk**

In `theme.dart`, ensure the `textTheme` uses the updated `KolabingTextStyles` values.

- [ ] **Step 4: Run analyze**

```bash
flutter analyze lib/config/theme/
```
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/config/theme/typography.dart lib/config/theme/theme.dart
git commit -m "chore: migrate typography from Hanken Grotesk to Inter, lock Anton to display only"
```

---

### Task 1.3 — Update radius and shadow tokens

**Files:**
- Modify: `lib/config/constants/radius.dart`
- Modify: `lib/config/constants/layout.dart`

**Interfaces:**
- Produces: `KolabingRadius.card` = 24, `KolabingRadius.optionCard` = 20, `KolabingRadius.input` = 16, `KolabingRadius.thumbnail` = 18, `KolabingRadius.pill` = 999
- Later tasks use these values in component files.

- [ ] **Step 1: Read current radius.dart**

```bash
cat lib/config/constants/radius.dart
cat lib/config/constants/layout.dart
```

- [ ] **Step 2: Update or add radius values**

```dart
// In KolabingRadius:
static const double card = 24;        // main content cards
static const double optionCard = 20;  // selectable option cards (venue, food, etc.)
static const double input = 16;       // text inputs
static const double thumbnail = 18;   // image thumbnails
static const double pill = 999;       // chips, buttons, badges (already exists as `round`)
static const double sm = 8;           // small elements
static const double md = 12;          // medium elements (keep existing)
static const double lg = 16;          // large (keep — but card now uses 24, not lg)
```

Add `BorderRadius` convenience getters for the new values following the existing pattern.

- [ ] **Step 3: Verify existing `round` / `pill` constant**

If `round = 9999` already exists with a `BorderRadius` getter, keep it. Just ensure `pill` is an alias or consolidate.

- [ ] **Step 4: Update shadow constants in layout.dart**

Ensure `KolabingLayout` (or wherever shadows are defined) has:
```dart
static List<BoxShadow> cardShadow = [
  BoxShadow(color: Color(0x0A19150F), blurRadius: 8, offset: Offset(0, 2)),
  BoxShadow(color: Color(0x0619150F), blurRadius: 24, offset: Offset(0, 8)),
];

static List<BoxShadow> buttonShadow = [
  BoxShadow(color: Color(0x26FFE28C), blurRadius: 12, offset: Offset(0, 4)),
];
```

- [ ] **Step 5: Run analyze**

```bash
flutter analyze lib/config/constants/
```

- [ ] **Step 6: Commit**

```bash
git add lib/config/constants/radius.dart lib/config/constants/layout.dart
git commit -m "chore: update radius tokens — card 24, input 16, optionCard 20, thumbnail 18"
```

---

## Phase 2 — Standardize Buttons

**Goal:** All main CTAs use a single consistent style — `#FFE28C` fill, Inter 700, pill radius, 56px height. Secondary buttons: cream fill, soft border, same height. No locally-defined button widgets.

**Risk:** Low-medium. Button files are already centralized; changes are mostly color/font values.

**Files to modify:**
- `lib/widgets/kolabing_button.dart`
- `lib/widgets/glass_button.dart`
- `lib/widgets/primary_button.dart` (re-export file — delete after verifying no imports use it)

**Visual result:** All primary CTAs become `#FFE28C` pill buttons. Secondary buttons become cream/outlined. Glass buttons become token-driven.

**Regressions to check:** Auth screens (login button), onboarding CTAs, apply button on opportunity cards, send button in chat.

---

### Task 2.1 — Fix KolabingButton

**Files:**
- Modify: `lib/widgets/kolabing_button.dart`

- [ ] **Step 1: Read the current file**

```bash
cat lib/widgets/kolabing_button.dart
```

- [ ] **Step 2: Replace all hardcoded Color() literals with context.colors equivalents**

Replace these specific hardcoded values:
- `Color(0xFF19150F)` → `context.colors.ink`
- `Color(0xFFE8E2D6)` → `context.colors.hairline`
- `Color(0xFFFFE28C)` → `context.colors.primary`
- `Colors.white` → `context.colors.surface`

The shadow on primary button should use `KolabingLayout.buttonShadow` (defined in Task 1.3).

- [ ] **Step 3: Update font style**

Replace any `HankenGrotesk` / `Hanken Grotesk` font calls in this file with `KolabingTextStyles.buttonLabelLg` (for default size) and `KolabingTextStyles.buttonLabelMd` (for compact/small). Do not set font family inline.

- [ ] **Step 4: Confirm height constants**

Primary button height must be exactly `56`. Compact: `48`. Small: `44`. Use `KolabingLayout` constants if they exist; otherwise hardcode these three values with inline comments referencing the design spec.

- [ ] **Step 5: Run analyze**

```bash
flutter analyze lib/widgets/kolabing_button.dart
```

- [ ] **Step 6: Hot reload and visually verify in simulator**

Check that the primary CTA button on the login screen still renders correctly, and the secondary variant renders with a cream/white fill and soft border.

- [ ] **Step 7: Commit**

```bash
git add lib/widgets/kolabing_button.dart
git commit -m "feat: migrate KolabingButton colors and font to design tokens"
```

---

### Task 2.2 — Fix GlassButton

**Files:**
- Modify: `lib/widgets/glass_button.dart`

- [ ] **Step 1: Read the current file**

```bash
cat lib/widgets/glass_button.dart
```

- [ ] **Step 2: Migrate all inline colors to context.colors**

GlassButton has three intents: primary (soft yellow), neutral (soft cream), destructive (soft red).

```dart
// primary intent
fill: context.colors.primaryTint       // #FFF1C6
border: context.colors.primary         // #FFE28C
ink: context.colors.amber              // #9A7C28

// neutral intent
fill: context.colors.surfaceVariant    // #F5EFE3
border: context.colors.hairline        // #EDE5D5
ink: context.colors.inkBody            // #3F3A32

// destructive intent
fill: context.colors.errorContainer    // existing token
border: context.colors.error           // existing token
ink: context.colors.onErrorContainer   // existing token
```

- [ ] **Step 3: Update font style to Inter**

```dart
style: KolabingTextStyles.buttonLabelMd,
```

- [ ] **Step 4: Run analyze + visual check**

```bash
flutter analyze lib/widgets/glass_button.dart
```

Check any screen that uses GlassButton still renders correctly.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/glass_button.dart
git commit -m "feat: migrate GlassButton colors to design tokens"
```

---

### Task 2.3 — Delete primary_button.dart re-export

**Files:**
- Delete: `lib/widgets/primary_button.dart`

- [ ] **Step 1: Check for any direct imports of primary_button.dart**

```bash
grep -r "primary_button" lib/ --include="*.dart" -l
```

- [ ] **Step 2: Update any importers to use kolabing_button.dart directly**

For each file found in step 1, replace:
```dart
import 'package:kolabing/widgets/primary_button.dart';
```
with:
```dart
import 'package:kolabing/widgets/kolabing_button.dart';
```

- [ ] **Step 3: Delete the re-export file**

```bash
rm lib/widgets/primary_button.dart
```

- [ ] **Step 4: Run analyze**

```bash
flutter analyze lib/
```
Expected: No errors related to primary_button.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore: remove primary_button.dart re-export, import kolabing_button.dart directly"
```

---

## Phase 3 — Standardize Chips, Pills, and Badges

**Goal:** All chips, status badges, metadata pills, and role pills use consistent token-driven colors with correct selected states. Selectable chips for filters/categories get their own component separate from status chips.

**Risk:** Medium. Chip variants are used across multiple screens. Test each carefully.

**Files to modify / create:**
- `lib/widgets/kolab_chip.dart` — fix variant naming and colors
- `lib/widgets/kolab_status_badge.dart` — migrate colors to tokens
- Create: `lib/widgets/kolabing_selectable_chip.dart` — new chip for filter/category selection
- Create: `lib/widgets/kolabing_metadata_pill.dart` — compact icon + label pill

**Visual result:** Onboarding category chips, filter chips, status badges, and metadata pills become consistent — no lavender, no random pastels, no hardcoded greens.

**Regressions to check:** Onboarding screens with category selection, kolab list cards with status badges, opportunity cards with metadata.

---

### Task 3.1 — Fix KolabChip variant naming and colors

**Files:**
- Modify: `lib/widgets/kolab_chip.dart`

- [ ] **Step 1: Read current file**

```bash
cat lib/widgets/kolab_chip.dart
```

- [ ] **Step 2: Rename confusing variant names**

Current mapping has confusing names (lavender → orange, sage → amber). Fix the enum/string values so names match actual colors. If external code passes variant names as strings, update callers after this task.

New canonical variants:
```dart
enum KolabChipVariant {
  neutral,   // cream fill, muted text
  yellow,    // primaryTint fill, amber text  (was: amber)
  orange,    // orangeTint fill, orange text  (was: lavender — confusingly named)
  green,     // greenTint fill, green text    (was: sage)
  blue,      // blueTint fill, blue text      (was: blueGrey)
  red,       // redTint fill, red text        (was: peach)
}
```

- [ ] **Step 3: Migrate all fill/text colors to context.colors**

```dart
KolabChipVariant.neutral:
  fill: context.colors.surfaceVariant
  text: context.colors.inkBody

KolabChipVariant.yellow:
  fill: context.colors.primaryTint       // #FFF1C6
  text: context.colors.amber             // #9A7C28

KolabChipVariant.orange:
  fill: context.colors.orangeTint        // #FFE7D6
  text: context.colors.orange            // #FF6114

// For green/blue/red, use existing semantic tokens if present, or add them to color_tokens.dart
```

- [ ] **Step 4: Find all callers and update variant strings/enums**

```bash
grep -r "KolabChip\|KolabChipVariant\|\.lavender\|\.sage\|\.blueGrey\|\.peach" lib/ --include="*.dart" -n
```

Update each caller to use the new variant names.

- [ ] **Step 5: Run analyze**

```bash
flutter analyze lib/
```

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/kolab_chip.dart
git commit -m "feat: rename KolabChip variants to match actual colors, migrate to tokens"
```

---

### Task 3.2 — Migrate KolabStatusBadge to tokens

**Files:**
- Modify: `lib/widgets/kolab_status_badge.dart`

- [ ] **Step 1: Read current file**

```bash
cat lib/widgets/kolab_status_badge.dart
```

- [ ] **Step 2: Add status color tokens to color_tokens.dart**

In `lib/config/theme/color_tokens.dart`, add a `statusColors` map or individual fields:

```dart
// Status badge fills (in light theme)
statusPublishedFill: const Color(0xFFFFE7D6),  // orange tint
statusPublishedText: const Color(0xFFFF6114),

statusDraftFill: const Color(0xFFF5EFE3),
statusDraftText: const Color(0xFF8C8474),

statusPendingFill: const Color(0xFFFFF1C6),
statusPendingText: const Color(0xFF9A7C28),

statusAcceptedFill: const Color(0xFFDFF5E9),
statusAcceptedText: const Color(0xFF2D7A4F),

statusDeclinedFill: const Color(0xFFFFE5E9),
statusDeclinedText: const Color(0xFFBA1A1A),
// etc. — one pair per status type
```

- [ ] **Step 3: Replace all hardcoded Color() calls in the badge file with context.colors lookups**

- [ ] **Step 4: Run analyze + visual check**

```bash
flutter analyze lib/widgets/kolab_status_badge.dart
```

Verify status badges on the My Kolabs / Offers screen still show correct colors.

- [ ] **Step 5: Commit**

```bash
git add lib/config/theme/color_tokens.dart lib/widgets/kolab_status_badge.dart
git commit -m "feat: migrate KolabStatusBadge colors to design tokens"
```

---

### Task 3.3 — Create KolabingSelectableChip

**Files:**
- Create: `lib/widgets/kolabing_selectable_chip.dart`

This is a **new component** for filter/category selection UIs (onboarding, find partner filters). It is distinct from `KolabChip` which is used for display-only labels on cards.

**Interfaces:**
- Produces: `KolabingSelectableChip({required String label, required bool selected, required VoidCallback onTap, Widget? leadingIcon})`

- [ ] **Step 1: Create the file**

```dart
import 'package:flutter/material.dart';
import 'package:kolabing/config/theme/color_tokens.dart';
import 'package:kolabing/config/theme/typography.dart';

class KolabingSelectableChip extends StatelessWidget {
  const KolabingSelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leadingIcon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colors.primaryTint : colors.surface,
          border: Border.all(
            color: selected ? colors.ink : colors.hairline,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              leadingIcon!,
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: KolabingTextStyles.chipLabel.copyWith(
                color: selected ? colors.ink : colors.inkBody,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it renders correctly**

Add a temporary use in any onboarding chip selection screen, confirm selected state is `#FFF1C6` with dark border, unselected is white with `#EDE5D5` border.

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/kolabing_selectable_chip.dart
git commit -m "feat: add KolabingSelectableChip with unselected/selected states"
```

---

### Task 3.4 — Create KolabingMetadataPill

**Files:**
- Create: `lib/widgets/kolabing_metadata_pill.dart`

**Interfaces:**
- Produces: `KolabingMetadataPill({required Widget icon, required String label, Color? tintColor})`

- [ ] **Step 1: Create the file**

```dart
import 'package:flutter/material.dart';
import 'package:kolabing/config/theme/color_tokens.dart';
import 'package:kolabing/config/theme/typography.dart';

class KolabingMetadataPill extends StatelessWidget {
  const KolabingMetadataPill({
    super.key,
    required this.icon,
    required this.label,
    this.tintColor,
  });

  final Widget icon;
  final String label;
  final Color? tintColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fill = tintColor ?? colors.surfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTheme(
            data: IconThemeData(color: colors.inkBody, size: 12),
            child: icon,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: KolabingTextStyles.bodySm.copyWith(
              color: colors.inkBody,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/widgets/kolabing_metadata_pill.dart
git commit -m "feat: add KolabingMetadataPill for compact icon+label metadata"
```

---

## Phase 4 — Standardize Cards

**Goal:** All card widgets use `context.colors.surface` for fill, `context.colors.hairline` for border, `KolabingRadius.card` (24) for corners, and `KolabingLayout.cardShadow` for shadow. No hardcoded `Colors.white` or `Color(0xFF...)` literals.

**Risk:** Medium. Cards appear on nearly every screen. Test thoroughly.

**Files to modify:**
- `lib/widgets/cards/kolabing_cards.dart`
- `lib/widgets/kolab_card_shell.dart`
- `lib/widgets/explore_swipe_card.dart`

**Visual result:** All cards become visibly white with a soft cream border, 24px radius corners, and subtle shadow. Dark mode renders correctly.

**Regressions to check:** Community list screen, opportunity detail, My Kolabs screen, Explore swipe screen.

---

### Task 4.1 — Fix kolabing_cards.dart

**Files:**
- Modify: `lib/widgets/cards/kolabing_cards.dart`

- [ ] **Step 1: Read current file**

```bash
cat lib/widgets/cards/kolabing_cards.dart
```

- [ ] **Step 2: Replace all Colors.white and hardcoded border colors**

Find each `Colors.white` → `context.colors.surface`
Find each `Color(0xFF...)` border → `context.colors.hairline`
Find each hardcoded radius number → `KolabingRadius.card` (24)
Find each hardcoded shadow → `KolabingLayout.cardShadow`

- [ ] **Step 3: Ensure CompactListCard uses md radius (12) not card radius (24)**

Compact list cards should keep `KolabingRadius.md` (12) since they are list rows, not standalone content cards.

- [ ] **Step 4: Run analyze + visual check**

```bash
flutter analyze lib/widgets/cards/
```

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/cards/kolabing_cards.dart
git commit -m "feat: migrate kolabing_cards.dart to design tokens — surface color, hairline border, card radius"
```

---

### Task 4.2 — Fix KolabCardShell

**Files:**
- Modify: `lib/widgets/kolab_card_shell.dart`

- [ ] **Step 1: Read current file**

```bash
cat lib/widgets/kolab_card_shell.dart
```

- [ ] **Step 2: Fix all hardcoded colors**

- Border `#EAE6DE` → `context.colors.hairline`
- Thumbnail gradient `#FFF9E6` → `#FFE28C` → use `[context.colors.primaryTint, context.colors.primary]`
- Initials text `#5C4A12` → `context.colors.amber`

- [ ] **Step 3: Update radius**

Card container radius → `KolabingRadius.card` (24)
Thumbnail radius → `KolabingRadius.thumbnail` (18)

- [ ] **Step 4: Run analyze + visual check**

```bash
flutter analyze lib/widgets/kolab_card_shell.dart
```

Verify My Kolabs screen cards still render correctly.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/kolab_card_shell.dart
git commit -m "feat: migrate KolabCardShell border, thumbnail gradient, and radius to tokens"
```

---

### Task 4.3 — Fix ExploreSwipeCard

**Files:**
- Modify: `lib/widgets/explore_swipe_card.dart`

- [ ] **Step 1: Read current file**

```bash
cat lib/widgets/explore_swipe_card.dart
```

- [ ] **Step 2: Fix all hardcoded colors**

- Gradient bg `#EFEDE8` → `context.colors.surfaceVariant`
- Circle border `#DDD8CC` → `context.colors.hairline`
- Match badge bg `#1A1A1A` → `context.colors.ink`

- [ ] **Step 3: Commit**

```bash
git add lib/widgets/explore_swipe_card.dart
git commit -m "feat: migrate ExploreSwipeCard placeholder colors to design tokens"
```

---

### Task 4.4 — Create KolabingIconOptionCard

**Files:**
- Create: `lib/widgets/kolabing_icon_option_card.dart`

Used on screens where users select options like "Venue", "Food & Drink". Has selectable state.

**Interfaces:**
- Produces: `KolabingIconOptionCard({required Widget icon, required String label, required bool selected, required VoidCallback onTap})`

- [ ] **Step 1: Create the file**

```dart
import 'package:flutter/material.dart';
import 'package:kolabing/config/constants/radius.dart';
import 'package:kolabing/config/theme/color_tokens.dart';
import 'package:kolabing/config/theme/typography.dart';

class KolabingIconOptionCard extends StatelessWidget {
  const KolabingIconOptionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: selected ? colors.primaryTint : colors.surface,
          border: Border.all(
            color: selected ? colors.ink : colors.hairline,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(KolabingRadius.optionCard),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme(
              data: IconThemeData(
                color: selected ? colors.ink : colors.inkBody,
                size: 28,
              ),
              child: icon,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: KolabingTextStyles.chipLabel.copyWith(
                color: selected ? colors.ink : colors.inkBody,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (selected) ...[
              const SizedBox(height: 8),
              Icon(Icons.check_circle_rounded, size: 16, color: colors.ink),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/widgets/kolabing_icon_option_card.dart
git commit -m "feat: add KolabingIconOptionCard for selectable option grids"
```

---

## Phase 5 — Standardize Inputs

**Goal:** All text inputs use a single `KolabingInput` wrapper with consistent decoration — white fill, `#EDE5D5` border, 16px radius, Inter placeholder.

**Risk:** Medium. Inputs exist across many forms. Test onboarding flows thoroughly.

**Files to modify / create:**
- Create: `lib/widgets/kolabing_input.dart`
- Modify: `lib/widgets/referral_code_field.dart`
- Screen files with inline TextFormField styling (Phase 5 only touches inputs, not screen layout)

**Visual result:** All inputs look consistent — white, compact, soft-bordered.

**Regressions to check:** Login/register, onboarding profile setup, search bars, kolab creation forms, message input.

---

### Task 5.1 — Create KolabingInput widget

**Files:**
- Create: `lib/widgets/kolabing_input.dart`

**Interfaces:**
- Produces: `KolabingInput({required TextEditingController controller, String? label, String? hint, String? errorText, bool obscureText, TextInputType keyboardType, int? maxLines, Widget? prefix, Widget? suffix, VoidCallback? onTap})`

- [ ] **Step 1: Create the file**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kolabing/config/constants/radius.dart';
import 'package:kolabing/config/theme/color_tokens.dart';
import 'package:kolabing/config/theme/typography.dart';

class KolabingInput extends StatelessWidget {
  const KolabingInput({
    super.key,
    required this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.prefix,
    this.suffix,
    this.onTap,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.textInputAction,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final Widget? prefix;
  final Widget? suffix;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onTap: onTap,
      onChanged: onChanged,
      validator: validator,
      enabled: enabled,
      textInputAction: textInputAction,
      style: KolabingTextStyles.bodyLg.copyWith(color: colors.ink),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefix,
        suffixIcon: suffix,
        filled: true,
        fillColor: colors.surface,
        hintStyle: KolabingTextStyles.bodyLg.copyWith(color: colors.muted),
        labelStyle: KolabingTextStyles.bodySm.copyWith(color: colors.muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KolabingRadius.input),
          borderSide: BorderSide(color: colors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KolabingRadius.input),
          borderSide: BorderSide(color: colors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KolabingRadius.input),
          borderSide: BorderSide(color: colors.ink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KolabingRadius.input),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KolabingRadius.input),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/widgets/kolabing_input.dart
git commit -m "feat: add KolabingInput — centralized text input with token-driven decoration"
```

---

### Task 5.2 — Migrate ReferralCodeField to KolabingInput

**Files:**
- Modify: `lib/widgets/referral_code_field.dart`

- [ ] **Step 1: Read the current file**

```bash
cat lib/widgets/referral_code_field.dart
```

- [ ] **Step 2: Replace inline InputDecoration with KolabingInput**

Wrap the existing TextFormField in KolabingInput or replace with it, passing the custom prefix icon via the `prefix` parameter.

Remove the hardcoded `Color(0xFF...)` border and fill values.

- [ ] **Step 3: Run analyze + visual check**

```bash
flutter analyze lib/widgets/referral_code_field.dart
```

Verify the referral code input still shows the gift card icon prefix and uppercase formatting.

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/referral_code_field.dart
git commit -m "feat: migrate ReferralCodeField to KolabingInput"
```

---

### Task 5.3 — Find and migrate all remaining inline TextFormField decorations

- [ ] **Step 1: Find all inline InputDecoration usages**

```bash
grep -r "InputDecoration\|fillColor\|OutlineInputBorder" lib/features/ --include="*.dart" -l
```

- [ ] **Step 2: For each file found, replace inline decoration with KolabingInput**

For each file:
1. Read the file
2. Identify which TextFormField instances have custom decoration
3. Replace them with `KolabingInput`, passing any custom prefix/suffix/validator
4. Remove the now-unused `InputDecoration` imports if applicable

- [ ] **Step 3: Run analyze**

```bash
flutter analyze lib/
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/
git commit -m "feat: migrate inline TextFormField decorations to KolabingInput across features"
```

---

## Phase 6 — Standardize Headers and Top Navigation

**Goal:** All screens use a consistent top bar with circular back button, Anton uppercase title, and optional right action. Replace ad-hoc AppBar usages with `KolabingTopBar`.

**Risk:** Medium. AppBar changes affect screen layout and safe area. Test carefully on both iOS and Android.

**Files to modify / create:**
- Create: `lib/widgets/kolabing_top_bar.dart`
- Modify: `lib/widgets/navigation/kolabing_app_bar.dart` (extend for title variant)
- Modify: Feature screen files that use ad-hoc headers (scope determined by grep)

**Visual result:** Profile, Find Partner, New Kolab, Chat, and detail screens all have consistent headers.

---

### Task 6.1 — Create KolabingTopBar

**Files:**
- Create: `lib/widgets/kolabing_top_bar.dart`

**Interfaces:**
- Produces: `KolabingTopBar({String? title, bool showBack, VoidCallback? onBack, Widget? trailing})` as a `PreferredSizeWidget`

- [ ] **Step 1: Create the file**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kolabing/config/theme/color_tokens.dart';
import 'package:kolabing/config/theme/typography.dart';

class KolabingTopBar extends StatelessWidget implements PreferredSizeWidget {
  const KolabingTopBar({
    super.key,
    this.title,
    this.showBack = true,
    this.onBack,
    this.trailing,
    this.backgroundColor,
  });

  final String? title;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Color? backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bgColor = backgroundColor ?? colors.appBackground;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
        height: preferredSize.height + MediaQuery.of(context).padding.top,
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        color: bgColor,
        child: Row(
          children: [
            if (showBack)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: _CircularBackButton(
                  onTap: onBack ?? () => Navigator.of(context).pop(),
                  colors: colors,
                ),
              )
            else
              const SizedBox(width: 56),
            Expanded(
              child: title != null
                  ? Text(
                      title!.toUpperCase(),
                      style: KolabingTextStyles.sectionHeadingLarge.copyWith(
                        color: colors.ink,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : const SizedBox.shrink(),
            ),
            SizedBox(
              width: 56,
              child: trailing != null
                  ? Center(child: trailing!)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularBackButton extends StatelessWidget {
  const _CircularBackButton({required this.onTap, required this.colors});
  final VoidCallback onTap;
  final KolabingColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: colors.hairline),
        ),
        child: Icon(Icons.arrow_back_rounded, color: colors.ink, size: 20),
      ),
    );
  }
}
```

- [ ] **Step 2: Find which screens use custom AppBar / back button patterns**

```bash
grep -r "AppBar\|IconButton.*arrow_back\|Navigator.pop" lib/features/ --include="*.dart" -l
```

- [ ] **Step 3: In each screen, replace the custom AppBar with KolabingTopBar**

Only replace ad-hoc implementations. The main `KolabingAppBar` (wordmark version) stays in place for dashboard screens.

- [ ] **Step 4: Run analyze + visual check on all affected screens**

```bash
flutter analyze lib/
```

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/kolabing_top_bar.dart lib/features/
git commit -m "feat: add KolabingTopBar and migrate screen headers"
```

---

## Phase 7 — Standardize Bottom Nav and FAB

**Goal:** Active nav state uses bold label + dark icon only — no filled black circle. FAB becomes `#FFE28C` yellow pill. Labels use Inter 700 below icons.

**Risk:** Low-medium. Single component file, well isolated.

**Files to modify:**
- `lib/widgets/navigation/kolabing_bottom_nav_bar.dart`

**Visual result:** Nav active state is clean (bold text + dark icon), inactive is muted. FAB becomes yellow pill.

---

### Task 7.1 — Update KolabingBottomNavBar active state

- [ ] **Step 1: Read current file**

```bash
cat lib/widgets/navigation/kolabing_bottom_nav_bar.dart
```

- [ ] **Step 2: Remove any filled indicator / background circle from active items**

Find where the active item renders a filled circle or background. Remove the Container/DecoratedBox that creates the black active background. Replace with color-only differentiation.

- [ ] **Step 3: Update label font**

Replace Hanken Grotesk label style with:
```dart
style: KolabingTextStyles.metaLabel.copyWith(
  color: isActive ? context.colors.ink : context.colors.navInactive,
  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
),
```

- [ ] **Step 4: Update icon color**

Active: `context.colors.ink`
Inactive: `context.colors.navInactive`

- [ ] **Step 5: Verify FAB if present**

If a FAB is defined here or nearby, ensure it uses:
```dart
backgroundColor: context.colors.primary,  // #FFE28C
foregroundColor: context.colors.ink,
elevation: 0,
shape: const StadiumBorder(),
```

- [ ] **Step 6: Run analyze + visual check**

```bash
flutter analyze lib/widgets/navigation/
```

Navigate between all 5 tabs and verify active/inactive states.

- [ ] **Step 7: Commit**

```bash
git add lib/widgets/navigation/kolabing_bottom_nav_bar.dart
git commit -m "feat: update bottom nav — remove active indicator circle, bold label + dark icon active state"
```

---

## Phase 8 — Fix Feature-Level Hardcoded Palettes

**Goal:** Remove the isolated color palettes in rewards, gamification, permission, and auth screens. Route all colors through tokens.

**Risk:** Low per file, but many files. Do one file at a time.

**Files to modify:**
- `lib/features/auth/screens/login_screen.dart`
- `lib/features/permission/screens/permission_screen.dart`
- `lib/features/rewards/models/xp_level.dart`
- `lib/features/rewards/widgets/referral_banner_card.dart`
- `lib/features/gamification/widgets/` (each file individually)
- `lib/features/dashboard/widgets/dashboard_badges_row.dart`

For each file:
- [ ] Read the file
- [ ] Find all `Color(0xFF...)` literals
- [ ] Map each to the nearest `context.colors` equivalent (or add a token if missing)
- [ ] Replace and run `flutter analyze`
- [ ] Commit per file

---

## Phase 9 — Screen Refactors

**APPROVAL REQUIRED before starting Phase 9.**

Only begin after Phases 1–8 are complete and you have explicitly approved. At that point, screens will be refactored one by one to use the new components. Scope includes:

- Community Profile screen
- Find Partner — Community Type selection
- Find Partner — Needs / Offer type
- New Kolab — Choose type screen
- Chat screen
- My Kolabs / Offers screen

Each screen refactor is its own PR.

---

## Self-Review Checklist

- [x] All spec token values covered in Phase 1
- [x] All button types covered in Phase 2
- [x] Selectable chips, status badges, and metadata pills covered in Phase 3
- [x] All card types (PrimaryContentCard, CompactListCard, EmptyStateCard, KolabCardShell, ExploreSwipeCard) covered in Phase 4
- [x] Input widget creation + migration covered in Phase 5
- [x] Headers covered in Phase 6
- [x] Bottom nav covered in Phase 7
- [x] Feature-level isolated palettes covered in Phase 8
- [x] Screen refactors gated behind explicit approval in Phase 9
- [x] No duplicate components created where canonical equivalents exist
- [x] HankenGrotesk → Inter migration included
- [x] Anton locked to display-only in typography task
- [x] Orange `#FF6114` usage restricted to status/role only (badges, not CTAs)
- [x] Dark mode regressions called out in every phase

---

## Phased Risk Summary

| Phase | Risk | Can do independently? | Visual change |
|-------|------|----------------------|---------------|
| 1 — Tokens | Low | Yes | Minimal |
| 2 — Buttons | Low-medium | After Phase 1 | All CTAs consistent |
| 3 — Chips/badges | Medium | After Phase 1 | Onboarding + status consistent |
| 4 — Cards | Medium | After Phase 1 | White cards, better radius |
| 5 — Inputs | Medium | After Phase 1 | Inputs consistent |
| 6 — Headers | Medium | After Phase 1 | All screen headers consistent |
| 7 — Bottom nav | Low-medium | After Phase 1 | Active state clean |
| 8 — Feature palettes | Low per file | After Phase 1 | Incremental |
| 9 — Screen refactors | High | APPROVAL REQUIRED | Major visual change |

**Recommended first phase after approval: Phase 1 — Centralize Design Tokens.**
It is fully isolated, low-risk, and unlocks all subsequent phases to use `context.colors` correctly.
