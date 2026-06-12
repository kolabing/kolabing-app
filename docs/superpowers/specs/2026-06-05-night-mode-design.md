# Night Mode — Design Spec & Coworker Task Brief
**Date:** 2026-06-05  
**Branch:** `feat/night-mode-full-migration`  
**Approach:** ThemeExtension full migration (Approach C)  
**Assignee:** _(coworker)_

---

## Overview

Add a Night (dark) mode to the Kolabing Flutter app. Dark is the **primary** theme — it is the default. Light is an opt-in. Night mode is implemented as a **token set** via Flutter's `ThemeExtension` API so all 144 files that reference `KolabingColors` resolve the correct value at runtime without branching logic.

---

## Architecture Decision

### Why ThemeExtension

- **144 files** currently hardcode `KolabingColors.xxx` directly — no runtime resolution.
- Flutter's `ThemeExtension<T>` lets us register two token sets (light + night) inside `ThemeData`. Widgets call `context.colors.ink` and get the right value automatically.
- A codemod script replaces all `KolabingColors.xxx` references in one pass.
- No `if (isDark)` branching in widgets. No parallel color APIs.

### Call site before/after

```dart
// Before
color: KolabingColors.onSurface

// After
color: context.colors.onSurface
```

---

## Token Map

### New class: `KolabingColorTokens extends ThemeExtension<KolabingColorTokens>`

Every field in `KolabingColors` maps to a token in `KolabingColorTokens`. The light values are identical to the existing `KolabingColors` values. The night values are listed below.

#### Surfaces & Text (Night)

| Token | Night value | Light value (existing) |
|---|---|---|
| `background` | `#0C0C0E` | `#FDF9F0` |
| `surface` | `#0C0C0E` | `#FDF9F0` |
| `surfaceContainer` | `#19191C` | `#F1EEE5` |
| `surfaceContainerLow` | `#141416` | `#F7F3EA` |
| `surfaceContainerHigh` | `#222226` | `#ECE8DF` |
| `surfaceVariant` | `#161618` | `#E6E2D9` |
| `onSurface` | `#F5F5F7` | `#1C1C16` |
| `onSurfaceVariant` | `#A2A2A9` | `#4C4638` |
| `outline` | `#2E2E34` | `#7D7667` |
| `outlineVariant` | `#2A2A2F` | `#CFC6B3` |
| `inverseSurface` | `#F5F5F7` | `#31302B` |
| `inverseOnSurface` | `#0C0C0E` | `#F4F0E7` |
| `hairline` | `#26262B` | `#E8E2D6` |

#### Brand Yellow (Night — soft gold family)

| Token | Night value | Light value |
|---|---|---|
| `primary` | `#FFE28C` | `#FFE28C` _(same)_ |
| `primaryDark` | `#E7CE84` | `#F5D070` |
| `onPrimary` | `#5C4A12` | `#78631A` |
| `softYellow` | `#2C2710` (bg tint) | `#FFF4C2` |
| `softYellowBorder` | `#FFE28C` | `#FFE28C` _(same)_ |
| `navBarBackground` | `#19191C` | `#FFE28C` |
| `charcoal` | `#F5F5F7` | `#1C1C16` |

#### Status / Semantic (Night)

| Token | Night value | Light value |
|---|---|---|
| `error` | `#E14D3D` | `#BA1A1A` |
| `errorBg` | `#371F1B` | `#F8D7DA` |
| `errorText` | `#FBA797` | `#721C24` |
| `pendingBg` | `#36280F` | `#FFDDAC` |
| `pendingText` | `#FBC56F` | `#D8910B` |
| `activeBg` | `#0E3326` | `#D4EDDA` |
| `activeText` | `#6CF2BC` | `#155724` |
| `completedBg` | `#2B2550` | `#EDEA E0` |
| `completedText` | `#D4C6FF` | `#4C4638` |
| `success` | `#6CF2BC` | `#56624D` |
| `info` | `#94CBF7` | `#2196F3` |

#### Navigation (Night)

| Token | Night value | Light value |
|---|---|---|
| `navInactive` | `#6C6C74` | `#7D7667` |
| `navInactiveSubtle` | `#6C6C74` | `#CFC6B3` |

#### XP / Gamification (Night)

| Token | Night value | Light value |
|---|---|---|
| `xpGreen` | `#6CF2BC` | `#7AE7A3` |
| `xpGreenContainer` | `#0E3326` | `#E8F9F1` |
| `xpGreenOnContainer` | `#8CE7C2` | `#1A6644` |

#### Category Chips (Night — vivid glow pairs)

| Token | Night bg | Night label | Light bg | Light label |
|---|---|---|---|---|
| `categoryLavender` | `#2B2550` | `#D4C6FF` | `#E5DCF6` | `#615B71` |
| `categorySage` | `#28361B` | `#CCEC9C` | `#DBE8CD` | `#56624D` |
| `categoryMint` | `#0E3326` | `#6CF2BC` | `#E8F9F1` | `#1A6644` |
| `categoryOrange` | `#36280F` | `#FBC56F` | `#FFDDAC` | `#D8910B` |
| `categoryRed` | `#371F1B` | `#FBA797` | `#F8D7DA` | `#721C24` |
| `categoryBlue` | `#13293F` | `#94CBF7` | `#DDE3EC` | `#3D4A5C` |
| `categoryLocation` | `#2E2A14` | `#FFE28C` | `#FFF4C2` | `#A07010` |

_Note: `categoryBlueGrey` / `categoryBlueGreyText` are replaced by `categoryBlue` pair in the night set but keep light values for light mode._

#### Overlay / Glass (Night — unchanged)

| Token | Value |
|---|---|
| `overlayDark30` | `rgba(0,0,0,0.30)` _(same)_ |
| `overlayDark50` | `rgba(0,0,0,0.50)` _(same)_ |
| `overlayDark60` | `rgba(0,0,0,0.62)` |
| `glassWhite14` | `rgba(255,255,255,0.14)` _(same)_ |
| `glassInk` | `#A2A2A9` (night) / `#57534B` (light) |

#### Amber chips (Night)

| Token | Night value | Light value |
|---|---|---|
| `amberChipContainer` | `#2C2710` | `#FFF0C2` |
| `amberChipText` | `#FFE28C` | `#A07010` |
| `accentOrange` | `#36280F` | `#FFDDAC` |
| `accentOrangeText` | `#FBC56F` | `#D8910B` |

#### Auth / Dark surface (Night)

| Token | Night value | Light value |
|---|---|---|
| `darkSurface` | `#19191C` | `#FFFFFF` |
| `darkBorder` | `#2A2A2F` | `rgba(28,28,22,0.06)` |

#### Borders / Focus (Night)

| Token | Night value | Light value |
|---|---|---|
| `borderFocus` | `#FFE28C` | `#1C1C16` |
| `borderError` | `#E14D3D` | `#BA1A1A` |
| `textTertiary` | `#6C6C74` | `#8C8A82` |
| `textOnDark` | `#F5F5F7` | `#FFFFFF` |

---

## Global Design Rules (apply everywhere in night mode)

1. **All buttons are pills** — `borderRadius: BorderRadius.circular(999)`. Use `StadiumBorder()` or `KolabingRadius.borderRadiusRound`. No rounded-rectangle buttons.
2. **Title text opacity** — large Anton display titles (`displayLarge`, `displayMedium`, heading text like "COMMUNITY DASHBOARD") render at `rgba(245,245,247,0.80)`. Body/label text stays at full `#F5F5F7`. Add a `titleInk` token: Night = `Color(0xCCF5F5F7)`, Light = `Color(0xFF1C1C16)`.
3. **Cards are flat** — `elevation: 0`, `shadowColor: Colors.transparent`, `1px` border (`outlineVariant`), `radius: 16`.
4. **No drop shadows anywhere** on cards in night mode.

---

## Screen-Specific Night Mode Requirements

### Home — Community Dashboard
- Title "COMMUNITY DASHBOARD": Anton, `titleInk` (`rgba(245,245,247,0.80)`), wraps 2 lines.
- Subtitle "Welcome back, …": `onSurfaceVariant` (`#A2A2A9`).
- Header right: bell icon with `#E14D3D` badge count + circular avatar.
- **Level card**: bg `#15271B`, border `1px #21351F`, radius 18.
  - "LEVEL 1" pill: bg `#0F2E1F`, text `#8CE7C2`, shield icon `#8CE7C2`, `white-space: nowrap`.
  - Right: "To next level" `#9BB1A2` / "100" (Anton, `#EAF3EC`) / "XP needed" `#9BB1A2` — `nowrap`.
  - Big XP number (Anton ~58px, `#EAF3EC`) + "XP POINTS" label `#8FB39C`.
  - Progress bar: track `rgba(140,231,194,0.15)`, fill `#6CF2BC`.
- **"TODAY'S XP MISSIONS"** section header + "1 of 4 done" (`#6C6C74`).
- **Mission rows** (flat cards, no shadow):
  - Left icon tile (radius 13): `[tileBg, iconColor]`:
    - Review: `['#0E3326', '#6CF2BC']`
    - Complete: `['#2C2710', '#FFE28C']`
    - Share: `['#2B2550', '#D4C6FF']`
    - Refer: `['#371F25', '#FBA7C0']`
  - Status pills — Done: transparent bg, `1px #2E5A45` border, `#8CE7C2` text + check icon. XP pills: bg `#2B2550`, text `#D4C6FF`.
- **Mini-stats row** (4 flat cards): Anton number (`onSurface`) + label (`navInactive`). Labels: PENDING / ACTIVE / DONE / ACCEPTED.

### Explore
- Title "EXPLORE": Anton, `titleInk`.
- Search bar: pill shape, bg `surfaceVariant` (`#161618`), border `outline` (`#2E2E34`), icon + placeholder `navInactive`.
- Segmented control (Recommended | All): track `surfaceVariant`; active cell `primary` (`#FFE28C`) bg with `onPrimary` (`#5C4A12`) text; inactive transparent with `onSurfaceVariant` text. Pill radius.
- Filter chips: transparent, `1px outline` border, `onSurface` text, sliders icon `navInactive`.
- **Listing card** (flat, radius 16):
  - Photo top, radius top 18.
  - "48% match" badge: `rgba(0,0,0,0.62)` bg + blur, white text.
  - Title: Anton sentence-case, `onSurface`.
  - Subtitle: "Discount · 📍 Barcelona" — `navInactive`.
  - Offer line: `primary` (`#FFE28C`) text + tag icon.
  - Type chips: `surfaceVariant` bg, `onSurfaceVariant` text.
  - Divider: `hairline`.
  - "View Details" + chevron: `onSurface`.

### My Kolabs
- Title "MY KOLABS": Anton, `titleInk`.
- **Primary tabs** (OFFERS / REQUEST / ACTIVE / FINISHED): active = `onSurface` + `3px primary` underline; inactive = `navInactive`. Bottom hairline `hairline`.
- **Sub-tabs** (PUBLISHED / DRAFT): same treatment.
- Count label "3 opportunities": `onSurfaceVariant`.
- **Offer card** (flat, 1px `outlineVariant` border, radius 16):
  - "PUBLISHED" badge: `activeBg`/`activeText` (mint pair).
  - Title: Inter 700, `onSurface`.
  - Chip row: date (sage pair + calendar icon), location (location pair + pin), category (sage or orange pair).
  - Thumbnail: radius 14, top-right float.
- **Action row**:
  - Wide view pill: bg `rgba(255,226,140,0.10)`, border `1px rgba(255,226,140,0.42)`, eye icon `primary` centered.
  - Three 46×46 circular buttons (edit, share, close): bg `surfaceContainer`, border `1px outline`, icon `onSurfaceVariant`.

### Profile
- Title "PROFILE": Anton, `titleInk`. Edit (pencil) icon right.
- **Profile card** (flat, centered):
  - Avatar: circular, `3px primary` ring + bottom-right camera badge (yellow circle, `onPrimary` icon).
  - Name: Inter 800, `onSurface`.
  - Role chip: blue pair (`#13293F` bg, `#94CBF7` label).
  - Level pill: bg `primaryDark` (`#E7CE84`), text `onPrimary` (`#5C4A12`), shield icon. Format: "LVL 1 · New Community · 0 XP".
- **About card** (flat): "ABOUT" label (`onSurfaceVariant`) + paragraph (`onSurfaceVariant`).
- **Gallery card** (flat):
  - Image icon (`primary`) + "Gallery" (Inter 800, `onSurface`) + "2/10" (`navInactive`).
  - "+ Add" pill: bg `primaryDark`, text `onPrimary`.
  - Thumbnails (radius 14) each with circular `rgba(0,0,0,0.55)` close badge top-right.

### Bottom Nav (all screens)
- Bar bg: `surfaceContainer` (`#19191C`).
- Top hairline: `hairline` (`#26262B`).
- Active tab: `onSurface` icon + label + small `primary` underline indicator.
- Inactive: `navInactive` (`#6C6C74`).
- "My Kolabs" star: `#E14D3D` "3" badge.
- FAB: solid `primary` circle, `onPrimary` plus icon, bottom-right above nav.

---

## Implementation Steps

### Step 1 — Set up branch

```bash
git checkout master
git pull origin master
git checkout -b feat/night-mode-full-migration
```

### Step 2 — Create `KolabingColorTokens` ThemeExtension

Create `lib/config/theme/color_tokens.dart`:

```dart
import 'package:flutter/material.dart';

@immutable
class KolabingColorTokens extends ThemeExtension<KolabingColorTokens> {
  const KolabingColorTokens({
    required this.background,
    required this.surface,
    required this.surfaceContainer,
    required this.surfaceContainerLow,
    required this.surfaceContainerHigh,
    required this.surfaceVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.inverseSurface,
    required this.inverseOnSurface,
    required this.hairline,
    required this.primary,
    required this.primaryDark,
    required this.onPrimary,
    required this.softYellow,
    required this.softYellowBorder,
    required this.navBarBackground,
    required this.charcoal,
    required this.titleInk,
    required this.error,
    required this.errorBg,
    required this.errorText,
    required this.pendingBg,
    required this.pendingText,
    required this.activeBg,
    required this.activeText,
    required this.completedBg,
    required this.completedText,
    required this.success,
    required this.info,
    required this.navInactive,
    required this.navInactiveSubtle,
    required this.xpGreen,
    required this.xpGreenContainer,
    required this.xpGreenOnContainer,
    required this.categoryLavenderBg,
    required this.categoryLavenderText,
    required this.categorySageBg,
    required this.categorySageText,
    required this.categoryMintBg,
    required this.categoryMintText,
    required this.categoryOrangeBg,
    required this.categoryOrangeText,
    required this.categoryRedBg,
    required this.categoryRedText,
    required this.categoryBlueBg,
    required this.categoryBlueText,
    required this.categoryLocationBg,
    required this.categoryLocationText,
    required this.overlayDark30,
    required this.overlayDark50,
    required this.overlayDark60,
    required this.glassWhite14,
    required this.glassInk,
    required this.glassDestructiveInk,
    required this.amberChipContainer,
    required this.amberChipText,
    required this.accentOrange,
    required this.accentOrangeText,
    required this.darkSurface,
    required this.darkBorder,
    required this.borderFocus,
    required this.borderError,
    required this.textTertiary,
    required this.textOnDark,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.tertiary,
    required this.tertiaryContainer,
    required this.onAccent,
    required this.softAccent,
    required this.primaryGradient,
  });

  // --- surfaces & text ---
  final Color background;
  final Color surface;
  final Color surfaceContainer;
  final Color surfaceContainerLow;
  final Color surfaceContainerHigh;
  final Color surfaceVariant;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color inverseSurface;
  final Color inverseOnSurface;
  final Color hairline;

  // --- brand yellow ---
  final Color primary;
  final Color primaryDark;
  final Color onPrimary;
  final Color softYellow;
  final Color softYellowBorder;
  final Color navBarBackground;
  final Color charcoal;
  final Color titleInk; // large Anton titles only

  // --- semantic ---
  final Color error;
  final Color errorBg;
  final Color errorText;
  final Color pendingBg;
  final Color pendingText;
  final Color activeBg;
  final Color activeText;
  final Color completedBg;
  final Color completedText;
  final Color success;
  final Color info;

  // --- navigation ---
  final Color navInactive;
  final Color navInactiveSubtle;

  // --- xp / gamification ---
  final Color xpGreen;
  final Color xpGreenContainer;
  final Color xpGreenOnContainer;

  // --- category chip pairs ---
  final Color categoryLavenderBg;
  final Color categoryLavenderText;
  final Color categorySageBg;
  final Color categorySageText;
  final Color categoryMintBg;
  final Color categoryMintText;
  final Color categoryOrangeBg;
  final Color categoryOrangeText;
  final Color categoryRedBg;
  final Color categoryRedText;
  final Color categoryBlueBg;
  final Color categoryBlueText;
  final Color categoryLocationBg;
  final Color categoryLocationText;

  // --- overlay / glass ---
  final Color overlayDark30;
  final Color overlayDark50;
  final Color overlayDark60;
  final Color glassWhite14;
  final Color glassInk;
  final Color glassDestructiveInk;

  // --- amber chips ---
  final Color amberChipContainer;
  final Color amberChipText;
  final Color accentOrange;
  final Color accentOrangeText;

  // --- auth / borders ---
  final Color darkSurface;
  final Color darkBorder;
  final Color borderFocus;
  final Color borderError;
  final Color textTertiary;
  final Color textOnDark;

  // --- secondary / tertiary / legacy ---
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color tertiary;
  final Color tertiaryContainer;
  final Color onAccent;
  final Color softAccent;

  // --- gradient ---
  final LinearGradient primaryGradient;

  // ---------------------------------------------------------------------------
  // Light set (maps 1:1 to existing KolabingColors values)
  // ---------------------------------------------------------------------------
  static const KolabingColorTokens light = KolabingColorTokens(
    background: Color(0xFFFDF9F0),
    surface: Color(0xFFFDF9F0),
    surfaceContainer: Color(0xFFF1EEE5),
    surfaceContainerLow: Color(0xFFF7F3EA),
    surfaceContainerHigh: Color(0xFFECE8DF),
    surfaceVariant: Color(0xFFE6E2D9),
    onSurface: Color(0xFF1C1C16),
    onSurfaceVariant: Color(0xFF4C4638),
    outline: Color(0xFF7D7667),
    outlineVariant: Color(0xFFCFC6B3),
    inverseSurface: Color(0xFF31302B),
    inverseOnSurface: Color(0xFFF4F0E7),
    hairline: Color(0xFFE8E2D6),
    primary: Color(0xFFFFE28C),
    primaryDark: Color(0xFFF5D070),
    onPrimary: Color(0xFF78631A),
    softYellow: Color(0xFFFFF4C2),
    softYellowBorder: Color(0xFFFFE28C),
    navBarBackground: Color(0xFFFFE28C),
    charcoal: Color(0xFF1C1C16),
    titleInk: Color(0xFF1C1C16),
    error: Color(0xFFBA1A1A),
    errorBg: Color(0xFFF8D7DA),
    errorText: Color(0xFF721C24),
    pendingBg: Color(0xFFFFDDAC),
    pendingText: Color(0xFFD8910B),
    activeBg: Color(0xFFD4EDDA),
    activeText: Color(0xFF155724),
    completedBg: Color(0xFFEDEAE0),
    completedText: Color(0xFF4C4638),
    success: Color(0xFF56624D),
    info: Color(0xFF2196F3),
    navInactive: Color(0xFF7D7667),
    navInactiveSubtle: Color(0xFFCFC6B3),
    xpGreen: Color(0xFF7AE7A3),
    xpGreenContainer: Color(0xFFE8F9F1),
    xpGreenOnContainer: Color(0xFF1A6644),
    categoryLavenderBg: Color(0xFFE5DCF6),
    categoryLavenderText: Color(0xFF615B71),
    categorySageBg: Color(0xFFDBE8CD),
    categorySageText: Color(0xFF56624D),
    categoryMintBg: Color(0xFFE8F9F1),
    categoryMintText: Color(0xFF1A6644),
    categoryOrangeBg: Color(0xFFFFDDAC),
    categoryOrangeText: Color(0xFFD8910B),
    categoryRedBg: Color(0xFFF8D7DA),
    categoryRedText: Color(0xFF721C24),
    categoryBlueBg: Color(0xFFDDE3EC),
    categoryBlueText: Color(0xFF3D4A5C),
    categoryLocationBg: Color(0xFFFFF4C2),
    categoryLocationText: Color(0xFFA07010),
    overlayDark30: Color(0x4D000000),
    overlayDark50: Color(0x80000000),
    overlayDark60: Color(0x99000000),
    glassWhite14: Color(0x24FFFFFF),
    glassInk: Color(0xFF57534B),
    glassDestructiveInk: Color(0xFF9B3B3B),
    amberChipContainer: Color(0xFFFFF0C2),
    amberChipText: Color(0xFFA07010),
    accentOrange: Color(0xFFFFDDAC),
    accentOrangeText: Color(0xFFD8910B),
    darkSurface: Color(0xFFFFFFFF),
    darkBorder: Color(0x0F1C1C16),
    borderFocus: Color(0xFF1C1C16),
    borderError: Color(0xFFBA1A1A),
    textTertiary: Color(0xFF8C8A82),
    textOnDark: Color(0xFFFFFFFF),
    secondary: Color(0xFF615B71),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE5DCF6),
    tertiary: Color(0xFF56624D),
    tertiaryContainer: Color(0xFFDBE8CD),
    onAccent: Color(0xFFFFFFFF),
    softAccent: Color(0xFFE5DCF6),
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFE28C), Color(0xFFFFF4C2)],
    ),
  );

  // ---------------------------------------------------------------------------
  // Night set
  // ---------------------------------------------------------------------------
  static const KolabingColorTokens night = KolabingColorTokens(
    background: Color(0xFF0C0C0E),
    surface: Color(0xFF0C0C0E),
    surfaceContainer: Color(0xFF19191C),
    surfaceContainerLow: Color(0xFF141416),
    surfaceContainerHigh: Color(0xFF222226),
    surfaceVariant: Color(0xFF161618),
    onSurface: Color(0xFFF5F5F7),
    onSurfaceVariant: Color(0xFFA2A2A9),
    outline: Color(0xFF2E2E34),
    outlineVariant: Color(0xFF2A2A2F),
    inverseSurface: Color(0xFFF5F5F7),
    inverseOnSurface: Color(0xFF0C0C0E),
    hairline: Color(0xFF26262B),
    primary: Color(0xFFFFE28C),
    primaryDark: Color(0xFFE7CE84),
    onPrimary: Color(0xFF5C4A12),
    softYellow: Color(0xFF2C2710),
    softYellowBorder: Color(0xFFFFE28C),
    navBarBackground: Color(0xFF19191C),
    charcoal: Color(0xFFF5F5F7),
    titleInk: Color(0xCCF5F5F7), // 80% opacity
    error: Color(0xFFE14D3D),
    errorBg: Color(0xFF371F1B),
    errorText: Color(0xFFFBA797),
    pendingBg: Color(0xFF36280F),
    pendingText: Color(0xFFFBC56F),
    activeBg: Color(0xFF0E3326),
    activeText: Color(0xFF6CF2BC),
    completedBg: Color(0xFF2B2550),
    completedText: Color(0xFFD4C6FF),
    success: Color(0xFF6CF2BC),
    info: Color(0xFF94CBF7),
    navInactive: Color(0xFF6C6C74),
    navInactiveSubtle: Color(0xFF6C6C74),
    xpGreen: Color(0xFF6CF2BC),
    xpGreenContainer: Color(0xFF0E3326),
    xpGreenOnContainer: Color(0xFF8CE7C2),
    categoryLavenderBg: Color(0xFF2B2550),
    categoryLavenderText: Color(0xFFD4C6FF),
    categorySageBg: Color(0xFF28361B),
    categorySageText: Color(0xFFCCEC9C),
    categoryMintBg: Color(0xFF0E3326),
    categoryMintText: Color(0xFF6CF2BC),
    categoryOrangeBg: Color(0xFF36280F),
    categoryOrangeText: Color(0xFFFBC56F),
    categoryRedBg: Color(0xFF371F1B),
    categoryRedText: Color(0xFFFBA797),
    categoryBlueBg: Color(0xFF13293F),
    categoryBlueText: Color(0xFF94CBF7),
    categoryLocationBg: Color(0xFF2E2A14),
    categoryLocationText: Color(0xFFFFE28C),
    overlayDark30: Color(0x4D000000),
    overlayDark50: Color(0x80000000),
    overlayDark60: Color(0x9E000000),
    glassWhite14: Color(0x24FFFFFF),
    glassInk: Color(0xFFA2A2A9),
    glassDestructiveInk: Color(0xFFFBA797),
    amberChipContainer: Color(0xFF2C2710),
    amberChipText: Color(0xFFFFE28C),
    accentOrange: Color(0xFF36280F),
    accentOrangeText: Color(0xFFFBC56F),
    darkSurface: Color(0xFF19191C),
    darkBorder: Color(0xFF2A2A2F),
    borderFocus: Color(0xFFFFE28C),
    borderError: Color(0xFFE14D3D),
    textTertiary: Color(0xFF6C6C74),
    textOnDark: Color(0xFFF5F5F7),
    secondary: Color(0xFFD4C6FF),
    onSecondary: Color(0xFF2B2550),
    secondaryContainer: Color(0xFF2B2550),
    tertiary: Color(0xFFCCEC9C),
    tertiaryContainer: Color(0xFF28361B),
    onAccent: Color(0xFF2B2550),
    softAccent: Color(0xFF2B2550),
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFE28C), Color(0xFFE7CE84)],
    ),
  );

  @override
  KolabingColorTokens copyWith({/* all fields optional */}) => this;

  @override
  KolabingColorTokens lerp(KolabingColorTokens? other, double t) {
    if (other is! KolabingColorTokens) return this;
    return KolabingColorTokens(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      // ... lerp every Color field the same way
      // LinearGradient fields: use primaryGradient (no lerp needed for snap transitions)
      primaryGradient: t < 0.5 ? primaryGradient : other.primaryGradient,
      // ... fill in all other fields
    );
  }

  @override
  Object get type => KolabingColorTokens;
}

// BuildContext extension for ergonomic access
extension KolabingColorsX on BuildContext {
  KolabingColorTokens get colors =>
      Theme.of(this).extension<KolabingColorTokens>()!;
}
```

> **Note on `copyWith` and `lerp`:** The snippet above is abbreviated. Fill in all fields — every `Color` field needs a `Color.lerp(...)` line in `lerp`, and `copyWith` needs every field as an optional named parameter. There are ~60 fields total. Use the light set as the template.

### Step 3 — Register in `KolabingTheme`

In `lib/config/theme/theme.dart`, add the extension to both themes:

```dart
// In lightTheme:
extensions: const [KolabingColorTokens.light],

// In darkTheme (replace the body entirely — make it a proper dark theme):
brightness: Brightness.dark,
colorScheme: ColorScheme.dark(
  primary: KolabingColorTokens.night.primary,
  onPrimary: KolabingColorTokens.night.onPrimary,
  surface: KolabingColorTokens.night.surface,
  onSurface: KolabingColorTokens.night.onSurface,
  error: KolabingColorTokens.night.error,
  // ... map the rest
),
scaffoldBackgroundColor: KolabingColorTokens.night.background,
extensions: const [KolabingColorTokens.night],
// ... update appBarTheme, cardTheme, buttonThemes, chipTheme, etc.
//     using KolabingColorTokens.night values (same structure as lightTheme)
```

### Step 4 — Wire `themeProvider` in `main.dart`

```dart
// Change KolabingApp to ConsumerWidget (it may already be one — check)
// Then:
theme: KolabingTheme.lightTheme,
darkTheme: KolabingTheme.darkTheme,
themeMode: ref.watch(themeProvider).themeMode,
// Remove the hardcoded ThemeMode.light
```

Change the default in `theme_provider.dart`:
```dart
const ThemeState({
  this.themeMode = ThemeMode.dark, // was ThemeMode.system
  ...
});
```

### Step 5 — Run the codemod

Create and run `scripts/migrate_colors.sh` from the repo root:

```bash
#!/usr/bin/env bash
# Replaces KolabingColors.xxx with context.colors.xxx in all widget Dart files.
# Run from repo root. Review diff before committing.

set -e
TOKENS=(
  background surface surfaceContainer surfaceContainerLow surfaceContainerHigh
  surfaceVariant onSurface onSurfaceVariant outline outlineVariant
  inverseSurface inverseOnSurface hairline
  primary primaryDark onPrimary softYellow softYellowBorder
  navBarBackground charcoal titleInk
  error errorBg errorText pendingBg pendingText
  activeBg activeText completedBg completedText success info
  navInactive navInactiveSubtle
  xpGreen xpGreenContainer xpGreenOnContainer
  overlayDark30 overlayDark50 overlayDark60 glassWhite14
  glassInk glassDestructiveInk
  amberChipContainer amberChipText accentOrange accentOrangeText
  darkSurface darkBorder borderFocus borderError textTertiary textOnDark
  secondary onSecondary secondaryContainer tertiary tertiaryContainer
  onAccent softAccent
  categoryBlueGrey categoryBlueGreyText
  accentOrange accentOrangeText
  activeBg activeText
)

find lib -name "*.dart" | while read f; do
  for token in "${TOKENS[@]}"; do
    sed -i '' "s/KolabingColors\.$token/context.colors.$token/g" "$f"
  done
done
echo "Done. Run: dart analyze lib/ to find issues."
```

> **Important:** After running the codemod, fix up:
> - Files that are not `Widget` classes (models, services, constants) — revert those to `KolabingColors.xxx` or pass the color in as a parameter.
> - The `KolabingColors` class itself — leave it unchanged (it's the source of the light token values used in `KolabingColorTokens.light`).
> - `primaryGradient` — this is a `LinearGradient`, not a `Color`. Replace `KolabingColors.primaryGradient` with `context.colors.primaryGradient`.
> - Static/const contexts — anywhere the color is used in a `const` expression, you can't use `context`. Pass it as a runtime argument instead.

### Step 6 — Implement the 4 night screens

Using the screen-specific specs above (§ Screen-Specific Night Mode Requirements), update:
- `lib/features/dashboard/screens/community_dashboard_screen.dart` + its widgets
- `lib/features/discovery/screens/` (Explore screen)
- `lib/features/kolab/screens/my_kolabs_hub_screen.dart` + widgets
- `lib/features/community/screens/community_profile_screen.dart` + widgets

All colors now come from `context.colors.xxx`. No hardcoded hex values in widgets.

### Step 7 — Update `KolabingTheme.darkTheme` completely

The `darkTheme` getter currently duplicates the light theme. Replace it fully using `KolabingColorTokens.night` values:
- `appBarTheme` → bg `surfaceContainer`, fg `onSurface`, status bar light icons
- `bottomNavigationBarTheme` → bg `surfaceContainer`, selected `onSurface`, unselected `navInactive`
- `cardTheme` → bg `surfaceContainer`, border `outlineVariant`, no shadow
- `elevatedButtonTheme` → all buttons `StadiumBorder()` (pill), bg `primary`, fg `onPrimary`
- `outlinedButtonTheme` → `StadiumBorder()`, border `outlineVariant`
- `inputDecorationTheme` → fill `surfaceVariant`, border `outline`, focus `borderFocus`
- `chipTheme` → bg `tertiaryContainer`, label `onSurface`, `StadiumBorder`
- `dividerTheme` → `hairline`

### Step 8 — Analyze, test, commit

```bash
dart analyze lib/
flutter test
# Smoke test on simulator:
flutter run -d ios
```

Commit:
```bash
git add -A
git commit -m "feat: add night mode via ThemeExtension full migration

- Add KolabingColorTokens ThemeExtension with light + night token sets
- Migrate all 144 widget files from KolabingColors.xxx to context.colors.xxx
- Wire themeProvider in main.dart (dark is now default)
- Implement night mode for Dashboard, Explore, My Kolabs, Profile screens
- Update KolabingTheme.darkTheme with full night spec"

git push -u origin feat/night-mode-full-migration
```

---

## Acceptance Checks

- [ ] Toggling Night/Light in Settings swaps tokens with no layout shift
- [ ] Light mode unchanged — no regressions on light screens
- [ ] Every button is a pill (`StadiumBorder`) — no rounded-rectangle buttons
- [ ] Large Anton titles render at 80% opacity (`titleInk`), body text is crisp white
- [ ] Cards are flat: no shadows, 1px `outlineVariant` hairline, radius 16
- [ ] Yellow is always `#FFE28C` family — never saturated yellow
- [ ] Category chips: dark tint bg + luminous label — all readable
- [ ] Bottom nav: dark bar, yellow underline on active, faint inactive
- [ ] FAB: solid `#FFE28C` circle with `#5C4A12` plus icon
- [ ] `dart analyze` passes with 0 errors
- [ ] `flutter test` passes

---

## Files Created / Modified

| File | Action |
|---|---|
| `lib/config/theme/color_tokens.dart` | **Create** — KolabingColorTokens ThemeExtension |
| `lib/config/theme/theme.dart` | **Modify** — register extension, rebuild darkTheme |
| `lib/main.dart` | **Modify** — wire themeProvider, add darkTheme |
| `lib/features/settings/providers/theme_provider.dart` | **Modify** — default to ThemeMode.dark |
| `lib/features/dashboard/screens/community_dashboard_screen.dart` + widgets | **Modify** — night tokens |
| `lib/features/discovery/screens/` (Explore) | **Modify** — night tokens |
| `lib/features/kolab/screens/my_kolabs_hub_screen.dart` + widgets | **Modify** — night tokens |
| `lib/features/community/screens/community_profile_screen.dart` + widgets | **Modify** — night tokens |
| `~144 other widget files` | **Modify** — codemod replaces KolabingColors → context.colors |
| `scripts/migrate_colors.sh` | **Create** — codemod script |
