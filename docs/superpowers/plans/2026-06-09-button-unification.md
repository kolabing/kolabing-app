# Button Unification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate every per-screen button shape, color, and font override so all buttons in the Kolabing Flutter app inherit from the global theme — one pill shape, one set of color tokens, one font (Hanken Grotesk w700).

**Architecture:** The global theme (`lib/config/theme/theme.dart`) already sets `StadiumBorder()` + `KolabingTextStyles.button` (Hanken Grotesk w700) + correct token colors on all four button types. The remaining work is purely **deletion of overrides** that fight the theme, plus a CI guardrail that prevents regressions. No new abstractions; no new tokens; the fix for every button violation is to remove the `shape:` parameter and any hardcoded color from `styleFrom(...)`.

**Tech Stack:** Flutter/Dart, `KolabingColors` + `KolabingRadius` tokens, `flutter analyze`, `flutter test`

---

## Current State (as of 2026-06-09)

**Already done (previous run):**
- Theme: `StadiumBorder()`, `KolabingColors.primary/#FFE28C`, `onPrimary/#4C4A44`, `buttonSecondary/#F0EBE1`, `onButtonSecondary/#1C1C16`, `KolabingTextStyles.button` all wired correctly. ✅
- `collaboration_detail_screen.dart`, `kolab_review_sheet.dart`, `stats_screen.dart`, `create_challenge_screen.dart`, `initiate_challenge_screen.dart`, `event_qr_code_screen.dart`, `attendee_profile_screen.dart` — tokenised. ✅

**Remaining violations (all in Phase 4 of the original spec):**

| File | Lines | Widget | Violation |
|------|-------|--------|-----------|
| `onboarding/screens/community/community_final_screen.dart` | ~549 | ElevatedButton | `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))` |
| `onboarding/screens/business/business_final_screen.dart` | ~858 | ElevatedButton | same |
| `onboarding/screens/business/business_step2_screen.dart` | ~612 | ElevatedButton | same |
| `onboarding/screens/community/community_step1_screen.dart` | ~211 | ElevatedButton | same |
| `onboarding/screens/business/business_step5_screen.dart` | ~404, ~560 | ElevatedButton ×2 | same |
| `onboarding/widgets/google_photos_preview_sheet.dart` | ~171 | ElevatedButton | same |
| `onboarding/screens/community/community_step3_screen.dart` | ~257 | ElevatedButton | same |
| `permission/screens/permission_screen.dart` | ~228-234 | ElevatedButton | `foregroundColor: Colors.black` + hardcoded `_yellow` bg + shape override |
| `event/screens/create_event_screen.dart` | ~360 | FilledButton | `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))` |
| `event/widgets/add_event_modal.dart` | ~323, ~606 | ElevatedButton, OutlinedButton | `shape:` override with token value (still overrides theme) |
| `community/screens/create_opportunity_screen.dart` | ~1337, ~1357 | OutlinedButton ×2 | `shape:` override with token value |
| `community/widgets/opportunity_publish_success_dialog.dart` | ~85 | ElevatedButton | `shape:` override with token value |
| `chat/widgets/chat_inbox_button.dart` | ~41 | InkWell | `borderRadius: BorderRadius.circular(10)` |

**SnackBar/Dialog/BottomSheet shapes — out of scope.** The spec targets buttons only. These are UI chrome (SnackBars, Dialogs, ModalBottomSheets) and are intentionally excluded.

---

## File Map

**Modified (Phase 4):**
- `lib/features/onboarding/screens/community/community_final_screen.dart`
- `lib/features/onboarding/screens/business/business_final_screen.dart`
- `lib/features/onboarding/screens/business/business_step2_screen.dart`
- `lib/features/onboarding/screens/community/community_step1_screen.dart`
- `lib/features/onboarding/screens/business/business_step5_screen.dart`
- `lib/features/onboarding/widgets/google_photos_preview_sheet.dart`
- `lib/features/onboarding/screens/community/community_step3_screen.dart`
- `lib/features/permission/screens/permission_screen.dart`
- `lib/features/event/screens/create_event_screen.dart`
- `lib/features/event/widgets/add_event_modal.dart`
- `lib/features/community/screens/create_opportunity_screen.dart`
- `lib/features/community/widgets/opportunity_publish_success_dialog.dart`
- `lib/features/chat/widgets/chat_inbox_button.dart`

**Created (Phase 5):**
- `test/lints/button_style_lint_test.dart` — Dart test that scans lib/ for regressions

---

## Phase 4 — Sweep Remaining Button Violations

**⛔ STOP for review after completing Phase 4 before starting Phase 5.**

### Task 1: Onboarding ElevatedButton shape overrides

**Files:**
- Modify: `lib/features/onboarding/screens/community/community_final_screen.dart`
- Modify: `lib/features/onboarding/screens/business/business_final_screen.dart`
- Modify: `lib/features/onboarding/screens/business/business_step2_screen.dart`
- Modify: `lib/features/onboarding/screens/community/community_step1_screen.dart`
- Modify: `lib/features/onboarding/screens/business/business_step5_screen.dart`
- Modify: `lib/features/onboarding/widgets/google_photos_preview_sheet.dart`
- Modify: `lib/features/onboarding/screens/community/community_step3_screen.dart`

**Rule:** For each file, find the `ElevatedButton.styleFrom(...)` block that contains `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))`. Delete the entire `shape:` parameter (the property name, the value, and the trailing comma). Leave `backgroundColor`, `foregroundColor`, `disabledBackgroundColor`, `disabledForegroundColor`, `elevation` untouched.

**Approx locations (verify before editing — line numbers drift):**
- `community_final_screen.dart` ~line 549: inside `ElevatedButton.styleFrom` inside a `SizedBox` inside a `_buildCompleteSection`-style widget
- `business_final_screen.dart` ~line 858: same pattern
- `business_step2_screen.dart` ~line 612: `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))`
- `community_step1_screen.dart` ~line 211: same
- `business_step5_screen.dart` ~line 404 AND ~line 560: two separate `ElevatedButton.styleFrom` blocks
- `google_photos_preview_sheet.dart` ~line 171: `ElevatedButton.styleFrom` inside a `_buildConfirmButton` or similar
- `community_step3_screen.dart` ~line 257: same pattern

- [ ] **Step 1: Search each file for the violation**

  For each file, run:
  ```bash
  grep -n "shape.*RoundedRectangleBorder\|BorderRadius\.circular(12)" lib/features/onboarding/screens/community/community_final_screen.dart
  grep -n "shape.*RoundedRectangleBorder\|BorderRadius\.circular(12)" lib/features/onboarding/screens/business/business_final_screen.dart
  grep -n "shape.*RoundedRectangleBorder\|BorderRadius\.circular(12)" lib/features/onboarding/screens/business/business_step2_screen.dart
  grep -n "shape.*RoundedRectangleBorder\|BorderRadius\.circular(12)" lib/features/onboarding/screens/community/community_step1_screen.dart
  grep -n "shape.*RoundedRectangleBorder\|BorderRadius\.circular(12)" lib/features/onboarding/screens/business/business_step5_screen.dart
  grep -n "shape.*RoundedRectangleBorder\|BorderRadius\.circular(12)" lib/features/onboarding/widgets/google_photos_preview_sheet.dart
  grep -n "shape.*RoundedRectangleBorder\|BorderRadius\.circular(12)" lib/features/onboarding/screens/community/community_step3_screen.dart
  ```
  
  Note the exact line numbers. Read each hit in context (3 lines above/below) to confirm it's inside an `ElevatedButton.styleFrom(...)`, not a SnackBar/Dialog.

- [ ] **Step 2: Delete the shape: parameter in each file**

  In each file, for each confirmed `ElevatedButton.styleFrom` shape violation, remove the block:
  ```dart
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  ```
  or the single-line form:
  ```dart
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ```
  
  The `styleFrom` must remain valid Dart — check that removing the line doesn't leave a dangling comma issue (trailing commas after the last param are fine in Dart; it's a missing comma on the preceding line that would break).

- [ ] **Step 3: Verify with analyze**

  ```bash
  flutter analyze lib/features/onboarding/ 2>&1 | grep -E "^  error|^  warning"
  ```
  Expected: zero errors, zero warnings.

- [ ] **Step 4: Commit**

  ```bash
  git add lib/features/onboarding/
  git commit -m "refactor(onboarding): remove ElevatedButton shape overrides, inherit theme StadiumBorder"
  ```

---

### Task 2: Permission screen — hardcoded colors + shape override

**Files:**
- Modify: `lib/features/permission/screens/permission_screen.dart`

**Context:** Around line 228 there is an `ElevatedButton.styleFrom(...)` with:
- `backgroundColor: _yellow` (a file-local `const Color _yellow = Color(0xFFFFE28C)` — correct value but not a token reference)
- `foregroundColor: Colors.black` (raw color, not a token)
- `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))` (shape override)

**Fix:**
1. Remove `backgroundColor: _yellow` — the theme already sets `backgroundColor: KolabingColors.primary` for ElevatedButton
2. Remove `foregroundColor: Colors.black` — the theme already sets `foregroundColor: KolabingColors.onPrimary` (#4C4A44)
3. Remove `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))` — theme gives StadiumBorder
4. Check if `_yellow` is used anywhere else in the file. If it becomes unused, delete the `const Color _yellow` declaration.

- [ ] **Step 1: Read the violation in context**

  ```bash
  grep -n "_yellow\|Colors\.black\|foregroundColor\|backgroundColor\|shape.*Rounded" lib/features/permission/screens/permission_screen.dart
  ```

- [ ] **Step 2: Remove the three style properties from styleFrom**

  Before (approximate):
  ```dart
  style: ElevatedButton.styleFrom(
    backgroundColor: _yellow,
    foregroundColor: Colors.black,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  ```

  After:
  ```dart
  style: ElevatedButton.styleFrom(
    elevation: 0,
  ),
  ```

  (Keep `elevation: 0` only if there's a reason to suppress shadow on this specific button. If other ElevatedButtons in the screen don't need it, remove it too — the theme already sets `elevation: 0`.)

- [ ] **Step 3: Remove unused `_yellow` declaration if now unreferenced**

  ```bash
  grep -n "_yellow" lib/features/permission/screens/permission_screen.dart
  ```
  If no remaining references, delete the `const Color _yellow = ...` line.

- [ ] **Step 4: Analyze**

  ```bash
  flutter analyze lib/features/permission/ 2>&1 | grep -E "^  error|^  warning"
  ```
  Expected: zero errors, zero warnings.

- [ ] **Step 5: Commit**

  ```bash
  git add lib/features/permission/
  git commit -m "refactor(permission): replace hardcoded button colors with theme tokens, remove shape override"
  ```

---

### Task 3: Event screens — remove button shape overrides

**Files:**
- Modify: `lib/features/event/screens/create_event_screen.dart`
- Modify: `lib/features/event/widgets/add_event_modal.dart`

**Violations:**
- `create_event_screen.dart` ~line 360: `FilledButton.styleFrom` with `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))` → delete shape param
- `add_event_modal.dart` ~line 323: `ElevatedButton.styleFrom` with `shape: RoundedRectangleBorder(borderRadius: KolabingRadius.borderRadiusMd)` → delete shape param (already uses token but still overrides theme StadiumBorder)
- `add_event_modal.dart` ~line 606: `OutlinedButton.styleFrom` with `shape: RoundedRectangleBorder(borderRadius: KolabingRadius.borderRadiusMd)` → delete shape param

- [ ] **Step 1: Locate exact lines**

  ```bash
  grep -n "shape.*RoundedRectangleBorder\|shape.*BorderRadius" lib/features/event/screens/create_event_screen.dart lib/features/event/widgets/add_event_modal.dart
  ```

- [ ] **Step 2: Delete the shape: params**

  In `create_event_screen.dart`, remove:
  ```dart
  shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12)),
  ```

  In `add_event_modal.dart` (two locations), remove:
  ```dart
  shape: RoundedRectangleBorder(
    borderRadius: KolabingRadius.borderRadiusMd,
  ),
  ```

- [ ] **Step 3: Analyze**

  ```bash
  flutter analyze lib/features/event/ 2>&1 | grep -E "^  error|^  warning"
  ```
  Expected: zero errors, zero warnings.

- [ ] **Step 4: Commit**

  ```bash
  git add lib/features/event/
  git commit -m "refactor(event): remove button shape overrides, inherit theme StadiumBorder"
  ```

---

### Task 4: Community screens — remove button shape overrides

**Files:**
- Modify: `lib/features/community/screens/create_opportunity_screen.dart`
- Modify: `lib/features/community/widgets/opportunity_publish_success_dialog.dart`

**Violations:**
- `create_opportunity_screen.dart` ~lines 1337, 1357: Two `OutlinedButton.styleFrom` blocks each have `shape: RoundedRectangleBorder(borderRadius: KolabingRadius.borderRadiusMd)` → delete both shape params
- `opportunity_publish_success_dialog.dart` ~line 85: `ElevatedButton.styleFrom` with `shape: RoundedRectangleBorder(borderRadius: KolabingRadius.borderRadiusMd)` → delete shape param

- [ ] **Step 1: Locate exact lines**

  ```bash
  grep -n "shape.*RoundedRectangleBorder\|shape.*BorderRadius" lib/features/community/screens/create_opportunity_screen.dart lib/features/community/widgets/opportunity_publish_success_dialog.dart
  ```

- [ ] **Step 2: Delete the shape: params (3 locations)**

  In `create_opportunity_screen.dart`, remove both instances of:
  ```dart
  shape: RoundedRectangleBorder(
    borderRadius: KolabingRadius.borderRadiusMd,
  ),
  ```

  In `opportunity_publish_success_dialog.dart`, remove:
  ```dart
  shape: RoundedRectangleBorder(
    borderRadius: KolabingRadius.borderRadiusMd,
  ),
  ```

- [ ] **Step 3: Analyze**

  ```bash
  flutter analyze lib/features/community/ 2>&1 | grep -E "^  error|^  warning"
  ```
  Expected: zero errors, zero warnings.

- [ ] **Step 4: Commit**

  ```bash
  git add lib/features/community/
  git commit -m "refactor(community): remove OutlinedButton/ElevatedButton shape overrides, inherit theme StadiumBorder"
  ```

---

### Task 5: chat_inbox_button — fix InkWell border radius

**Files:**
- Modify: `lib/features/chat/widgets/chat_inbox_button.dart`

**Context:** Around line 41, there is an InkWell (or Material+InkWell) with `borderRadius: BorderRadius.circular(10)`. This is a custom button-like widget. The spec says custom GestureDetector/Container buttons should use StadiumBorder + tokens.

**Fix:** Replace `BorderRadius.circular(10)` on the InkWell with `KolabingRadius.borderRadiusRound` (pill, 9999px) if the container is pill-shaped, or with `KolabingRadius.borderRadiusMd` if it is a card-style chip. Read the widget to determine which is correct.

- [ ] **Step 1: Read the widget**

  ```bash
  cat lib/features/chat/widgets/chat_inbox_button.dart
  ```
  Determine: is the outer Container pill-shaped (height ≈ width, or `StadiumBorder` clip)? If so, use `KolabingRadius.borderRadiusRound`. If it's a pill button, use `KolabingRadius.borderRadiusRound`. If it's a smaller action chip, use `KolabingRadius.borderRadiusMd`.

- [ ] **Step 2: Check import**

  ```bash
  grep -n "radius" lib/features/chat/widgets/chat_inbox_button.dart
  ```
  If `lib/config/constants/radius.dart` is not imported, add:
  ```dart
  import '../../../config/constants/radius.dart';
  ```
  (Adjust relative path if the file is nested differently — check sibling imports.)

- [ ] **Step 3: Replace the value**

  Replace:
  ```dart
  borderRadius: BorderRadius.circular(10),
  ```
  With (pill button):
  ```dart
  borderRadius: KolabingRadius.borderRadiusRound,
  ```
  Or if the button is card-style:
  ```dart
  borderRadius: KolabingRadius.borderRadiusMd,
  ```

- [ ] **Step 4: Analyze**

  ```bash
  flutter analyze lib/features/chat/ 2>&1 | grep -E "^  error|^  warning"
  ```

- [ ] **Step 5: Commit**

  ```bash
  git add lib/features/chat/
  git commit -m "refactor(chat): replace hardcoded InkWell border-radius with KolabingRadius token"
  ```

---

### Task 6: Phase 4 final verify + count

After the above 5 tasks:

- [ ] **Step 1: Run full-app analyze**

  ```bash
  flutter analyze lib/ 2>&1 | grep -E "^  error|^  warning" | head -20
  ```
  Expected: zero errors, zero warnings introduced.

- [ ] **Step 2: Count remaining button shape literals (must be 0)**

  ```bash
  grep -rn "shape.*RoundedRectangleBorder\|shape.*BorderRadius\.circular" lib/features/ \
    --include="*.dart" \
    | grep -v "SnackBar\|showDialog\|AlertDialog\|showModalBottomSheet\|Dialog(\|BottomSheet\|//.*shape" \
    | grep -v "glass_button\|kolabing_fab"
  ```
  Expected: empty output (no more ElevatedButton/OutlinedButton/FilledButton shape overrides).

- [ ] **Step 3: Count hardcoded button colors (must be 0)**

  ```bash
  grep -rn "foregroundColor.*Colors\.\|backgroundColor.*Colors\." lib/features/ \
    --include="*.dart" \
    | grep -i "styleFrom\|ButtonStyle" \
    | grep -v "glass_button\|kolabing_fab\|//.*color"
  ```
  Expected: empty output.

- [ ] **Step 4: Commit the counts to the task file or annotate the PR**

  Record:
  - Removed button shape overrides this phase: (count from tasks 1-5)
  - Remaining raw shape literals on buttons: 0
  - Remaining hardcoded button colors: 0

---

## ⛔ STOP HERE — Review Phase 4 before continuing to Phase 5

Present the diff and counts to the user. Wait for approval before starting Phase 5.

---

## Phase 5 — Guardrail Lint

### Task 7: CI guardrail — Dart test that fails on regressions

**Files:**
- Create: `test/lints/button_style_lint_test.dart`

**Purpose:** A `flutter test` test that scans `lib/` for the three forbidden patterns on buttons. It runs in CI and fails the build if a regression is introduced.

**What it checks:**
1. `shape:` param with a raw `BorderRadius.circular(<digit>)` literal on a button (`ElevatedButton.styleFrom`, `FilledButton.styleFrom`, `OutlinedButton.styleFrom`, `TextButton.styleFrom`, `ButtonStyle(`)
2. `foregroundColor:` or `backgroundColor:` referencing `Colors.black`, `Colors.brown`, or a raw hex `Color(0xFF...)` inside a button style call
3. Anton / display font inside a button child text (`fontFamily.*[Aa]nton` inside a `Text(` widget that is a direct child of a button)

**Whitelist:** `glass_button.dart` and `kolabing_fab.dart` are excluded from all checks.

- [ ] **Step 1: Create the test file**

  Create `test/lints/button_style_lint_test.dart`:

  ```dart
  import 'dart:io';
  import 'package:test/test.dart';

  void main() {
    const libDir = 'lib';
    const whitelist = {'glass_button.dart', 'kolabing_fab.dart'};

    List<File> dartFiles() => Directory(libDir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !whitelist.any((w) => f.path.endsWith(w)))
        .toList();

    // -------------------------------------------------------------------------
    // Rule 1: No raw BorderRadius.circular(<int>) on button shape: params
    // -------------------------------------------------------------------------
    test('no raw integer radius literals in button shape: params', () {
      // Pattern: shape: ...RoundedRectangleBorder(borderRadius: BorderRadius.circular(<digit>
      // We look for the shape: line in the context of a button styleFrom or ButtonStyle.
      // We scan each file for the pattern and fail on any match outside SnackBar/Dialog context.
      final violations = <String>[];

      final shapePattern = RegExp(
        r'shape:\s*(?:const\s*)?RoundedRectangleBorder\(\s*borderRadius:\s*BorderRadius\.circular\(\d',
      );
      // Lines that are clearly SnackBar/Dialog shapes (not button shapes):
      final snackbarContext = RegExp(
        r'SnackBar|AlertDialog|showDialog|showModalBottomSheet|BottomSheet',
      );

      for (final file in dartFiles()) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (shapePattern.hasMatch(line)) {
            // Check 3 lines above for SnackBar/Dialog context
            final context = lines
                .sublist((i - 3).clamp(0, lines.length), i + 1)
                .join(' ');
            if (!snackbarContext.hasMatch(context)) {
              violations.add('${file.path}:${i + 1}: ${line.trim()}');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Button shape overrides with raw integer literals found.\n'
            'Delete the shape: param — buttons inherit StadiumBorder from theme.\n'
            'Violations:\n${violations.join('\n')}',
      );
    });

    // -------------------------------------------------------------------------
    // Rule 2: No hardcoded colors on button foreground/background
    // -------------------------------------------------------------------------
    test('no hardcoded colors on button foregroundColor/backgroundColor', () {
      final violations = <String>[];

      // Colors.black, Colors.brown, or Color(0xFF...) as a literal
      final hardcodedColor = RegExp(
        r'(?:foregroundColor|backgroundColor):\s*(?:Colors\.(?:black|brown)|Color\(0xFF[0-9A-Fa-f]{6}\))',
      );
      final buttonContext = RegExp(
        r'styleFrom|ButtonStyle|ElevatedButton|FilledButton|OutlinedButton|TextButton',
      );

      for (final file in dartFiles()) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (hardcodedColor.hasMatch(line)) {
            final context = lines
                .sublist((i - 5).clamp(0, lines.length), i + 1)
                .join(' ');
            if (buttonContext.hasMatch(context)) {
              violations.add('${file.path}:${i + 1}: ${line.trim()}');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Hardcoded colors on button fg/bg found.\n'
            'Use KolabingColors tokens (e.g. KolabingColors.onPrimary) instead.\n'
            'Violations:\n${violations.join('\n')}',
      );
    });

    // -------------------------------------------------------------------------
    // Rule 3: No Anton/display font on button labels
    // -------------------------------------------------------------------------
    test('no Anton/display font inside button label Text widgets', () {
      final violations = <String>[];

      final antonPattern = RegExp(r'[Aa]nton|fontDisplay|fontPageTitle');
      final buttonContext = RegExp(
        r'ElevatedButton|FilledButton|OutlinedButton|TextButton|child:\s*Text',
      );

      for (final file in dartFiles()) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (antonPattern.hasMatch(line)) {
            // Check 10 lines above for button context
            final context = lines
                .sublist((i - 10).clamp(0, lines.length), i + 1)
                .join(' ');
            if (buttonContext.hasMatch(context)) {
              violations.add('${file.path}:${i + 1}: ${line.trim()}');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Anton/display font found in button label context.\n'
            'Button labels must use KolabingTextStyles.button (Hanken Grotesk w700).\n'
            'Violations:\n${violations.join('\n')}',
      );
    });
  }
  ```

- [ ] **Step 2: Run the test to confirm it passes (all violations already fixed)**

  ```bash
  flutter test test/lints/button_style_lint_test.dart --reporter=expanded
  ```
  Expected: `All tests passed!`

  If any test fails, fix the remaining violations it identifies before proceeding.

- [ ] **Step 3: Commit**

  ```bash
  git add test/lints/button_style_lint_test.dart
  git commit -m "test(lints): add button style guardrail — fails on raw radius, hardcoded colors, Anton on buttons"
  ```

---

### Task 8: Phase 5 final verify

- [ ] **Step 1: Run full test suite to ensure no regressions**

  ```bash
  flutter test 2>&1 | tail -5
  ```
  Expected: all tests pass.

- [ ] **Step 2: Run full analyze**

  ```bash
  flutter analyze lib/ 2>&1 | grep -E "^  error|^  warning" | head -20
  ```
  Expected: zero errors introduced.

- [ ] **Step 3: Final token-adoption count**

  ```bash
  # Should be 0
  grep -rn "shape.*RoundedRectangleBorder.*BorderRadius\.circular([0-9]" lib/features/ --include="*.dart" \
    | grep -v "SnackBar\|Dialog\|BottomSheet\|glass_button\|kolabing_fab" | wc -l

  # Should be 0
  grep -rn "foregroundColor.*Colors\.black\|backgroundColor.*Colors\.black" lib/features/ --include="*.dart" \
    | grep -v "glass_button\|kolabing_fab" | wc -l
  ```
  Both must be `0`.

---

## Success Criteria

| Metric | Before | After |
|--------|--------|-------|
| Button shape overrides with raw literals | 9 (onboarding) + 3 (event/community) + 1 (permission) + 1 (chat) = 14 | 0 |
| Hardcoded colors on button fg/bg | 2 (permission) | 0 |
| Anton on button labels | 0 | 0 (already clean) |
| CI guardrail test | absent | ✅ in `test/lints/` |
| Whitelisted files touched | — | 0 (glass_button + kolabing_fab untouched) |

---

## What is Out of Scope

- **SnackBar `shape:`** — intentionally left as-is; SnackBars are not buttons
- **Dialog/AlertDialog/ModalBottomSheet `shape:`** — UI chrome, not buttons
- **`Container`/`BoxDecoration` radius** — visual decoration, not button shape
- **`ClipRRect` radius** — clipping, not button shape
- **Input borders** — not buttons
- **`glass_button.dart`** — whitelisted by spec
- **`kolabing_fab.dart`** — whitelisted by spec
