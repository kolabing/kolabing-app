# Typography Migration Handoff — Phase 2

## Context

Kolabing Flutter app at `/Users/macbook/kolabing-app/kolabing-app` (iOS & Android).  
Branch: `feat/app-redesign`

**Goal:** Replace every `GoogleFonts.*()` call across the codebase with `KolabingTextStyles.*` from `lib/config/theme/typography.dart`. Pure style migration — do not touch layout, colors, business logic, navigation, state, or widget structure.

---

## Design System

All tokens are already defined. Never redefine them — only import and reference.

| Class | File |
|---|---|
| `KolabingTextStyles` | `lib/config/theme/typography.dart` |
| `KolabingColors` | `lib/config/theme/colors.dart` |
| `KolabingSpacing` | `lib/config/constants/spacing.dart` |
| `KolabingRadius` | `lib/config/constants/radius.dart` |

### Available (non-deprecated) text styles

| Style | Font | Size |
|---|---|---|
| `displayLarge/Medium/Small` | Anton | 80/48/32px |
| `headlineLarge/Medium` | Anton | 32/24px |
| `bodyLarge/Medium/Small` | Inter | 18/16/14px |
| `labelLarge/Medium/Small` | Hanken Grotesk | 14/12/11px |
| `eyebrow` | Hanken Grotesk | 12px, spaced |
| `cardTitleHero/Large` | Anton | 48/32px |
| `button` | Hanken Grotesk | 14px w600 |
| `captionSecondary` | Inter | 13px |

### Deprecated — do not use in new code

`pageTitle`, `pageTitleSmall`, `titleLarge`, `titleMedium`, `titleSmall`, `headlineSmall`, `buttonSmall`, `chipLabelSmall`, `chipLabelMedium`

---

## Mapping Rules

| Original | Context | Map to |
|---|---|---|
| `GoogleFonts.rubik(fontSize: 18+, fontWeight: w600/w700)` | Screen/card heading | `bodyMedium.copyWith(fontSize: ..., fontWeight: ..., color: ...)` |
| `GoogleFonts.rubik(fontSize: 14–16, fontWeight: w500/w600)` | Body emphasis | `bodySmall.copyWith(fontWeight: ..., color: ...)` |
| `GoogleFonts.rubik(fontSize: 20+)` | Large name / avatar initial | `bodyLarge.copyWith(fontSize: ..., fontWeight: ..., color: ...)` |
| `GoogleFonts.openSans(fontSize: 14)` | Body paragraph | `bodySmall.copyWith(color: ...)` |
| `GoogleFonts.openSans(fontSize: 13)` | Secondary text | `captionSecondary.copyWith(color: ...)` |
| `GoogleFonts.openSans(fontSize: 12 or less)` | Small body | `bodySmall.copyWith(fontSize: 12, color: ...)` |
| `GoogleFonts.openSans(fontSize: 10–11)` | Tiny metadata | `labelSmall.copyWith(fontSize: ..., color: ...)` |
| `GoogleFonts.openSans(color: ...)` in `hintStyle`/`suffixStyle` | Input decoration | `bodyMedium.copyWith(color: ...)` |
| `GoogleFonts.dmSans(fontSize: 12, fontWeight: w700, letterSpacing: 0.5)` | Section eyebrow label | `eyebrow.copyWith(fontWeight: FontWeight.w700, color: ..., letterSpacing: 0.5)` |
| `GoogleFonts.dmSans(fontWeight: w600, letterSpacing: 0.5)` | Button label | `button.copyWith(letterSpacing: 0.5)` |
| `GoogleFonts.dmSans(fontSize: 13, fontWeight: w600)` | Small button / add row | `button.copyWith(fontSize: 13, ...)` |
| `GoogleFonts.dmSans(fontSize: 11–12, fontWeight: w600)` | Chip / badge | `labelSmall.copyWith(fontWeight: FontWeight.w600, color: ...)` |
| `GoogleFonts.dmSans(color: ..., fontWeight: w600)` | TextButton label | `labelLarge.copyWith(color: ...)` |
| `GoogleFonts.darkerGrotesque(fontSize: 16, fontWeight: w700, letterSpacing: 0.5)` | CTA button | `button.copyWith(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)` |
| `GoogleFonts.inter(...)` | Body text | `bodySmall/Medium.copyWith(...)` |
| `GoogleFonts.anton(...)` | Display headline | `displayLarge/Medium` or `headlineLarge.copyWith(...)` |
| `Colors.white` in snackbar `style:` | Snackbar text on dark | `KolabingColors.textOnDark` |

**Always preserve via `.copyWith()`:** `color`, any `fontSize` override, `fontWeight` override, `height`, `letterSpacing`, `decoration`, `decorationColor`, `fontStyle`.

---

## Per-file Process

```
1. grep -n "GoogleFonts\." <file>          # list all call sites with line numbers
2. Read each call in context               # what text it styles, what the widget does
3. Replace each with KolabingTextStyles.*  # using the mapping table above
4. Remove:  import 'package:google_fonts/google_fonts.dart';
5. Add if missing:  import '../../../config/theme/typography.dart';
   (adjust relative depth: ../../ for features/x/screens/, ../../../ for widgets/, etc.)
6. flutter analyze <file>                 # must show 0 errors, 0 warnings
7. Move to next file
```

To find all remaining files with GoogleFonts calls at any time:
```bash
grep -rl "GoogleFonts\." lib/
```

---

## Remaining Files (priority order)

| File | Approx calls | Notes |
|---|---|---|
| `lib/features/application/screens/application_review_screen.dart` | ~20 remaining | Partially done — `google_fonts` import removed, `typography.dart` added. Run grep to see what's left. |
| `lib/features/business/screens/community_offer_detail_screen.dart` | 34 | |
| `lib/widgets/explore_filter_sheet.dart` | ~20 | Shared widget |
| `lib/features/application/screens/chat_screen.dart` | 18 | Real-time screen — touch style only |
| `lib/features/onboarding/screens/community/community_step4_screen.dart` | 18 | |
| `lib/features/auth/screens/forgot_password_screen.dart` | 16 | |
| `lib/features/onboarding/screens/business/business_step2_screen.dart` | 14 | |
| `lib/features/auth/screens/reset_password_screen.dart` | 14 | |
| `lib/features/gamification/screens/reward_detail_screen.dart` | 14 | |
| `lib/features/gamification/screens/initiate_challenge_screen.dart` | 14 | |
| `lib/features/kolab/screens/business/past_events_screen.dart` | 13 | |
| `lib/features/rewards/screens/wallet_screen.dart` | 12 | |
| `lib/features/auth/screens/attendee_register_screen.dart` | 7 | |
| `lib/features/auth/screens/user_type_selection_screen.dart` | 5 | |
| `lib/features/auth/screens/welcome_screen.dart` | remaining | |
| All other files | varies | Run `grep -rl "GoogleFonts\." lib/` to get the full list |

---

## Already Completed

| File | Calls removed |
|---|---|
| `lib/widgets/explore_detail_sheet.dart` | 20 |
| `lib/features/application/widgets/apply_modal.dart` | 30 |
| `lib/features/collaboration/widgets/kolab_completion_sheet.dart` | 12 |
| `lib/features/auth/screens/login_screen.dart` | 11 |
| `lib/features/collaboration/screens/collaboration_detail_screen.dart` | 55 |
| `lib/features/community/screens/create_opportunity_screen.dart` | 42 |
| `lib/features/application/screens/application_review_screen.dart` | ~15 of 35 |

---

## Safety Rules — Never Touch

- Auth providers, Riverpod `ref.watch` / `ref.read`, API calls
- Form validators, route names, navigation callbacks
- `BoxDecoration`, `BorderRadius`, padding, margins, spacing
- `ElevatedButton.styleFrom`, `OutlinedButton.styleFrom`, `TextButton.styleFrom`
- Subscription / Stripe logic, collaboration status transitions, onboarding completion logic
- Chat real-time state

**Only change:** `style:` properties inside `Text(...)`, `TextFormField(style:)`, `InputDecoration(hintStyle:, suffixStyle:, errorStyle:, counterStyle:)`.

---

## Baseline to Maintain

After each file: `flutter analyze <file>` must report **0 errors, 0 warnings**.  
Pre-existing `info` lints (~755 total across the project) are unrelated — ignore them.
