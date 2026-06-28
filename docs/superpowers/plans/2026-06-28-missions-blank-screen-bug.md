# Missions Blank-Screen Bug — Diagnosis & Fix Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Task 2 onward additionally requires superpowers:systematic-debugging discipline: do not guess-fix before the live repro produces evidence.

**Goal:** Root-cause and fix `kolabing-app#48` (Profile → Missions tap is reported as a blank screen / not navigating), which is currently blocked by `kolabing-app#47` (a local iOS simulator code-signing build failure).

**Architecture:** A prior static read of every checkpoint in the tap → route → provider → render chain found no defect (see "Static findings" below) — so the fix here is procedural: unblock the local build, get a live repro with temporary instrumentation, let the evidence pick the branch, then write the real fix only once the failure point is known. This plan therefore has one "fix the environment" task, one "instrument and reproduce" task, and a decision-tree task whose two pre-written branches cover the most likely outcomes given what's already been ruled out.

**Tech Stack:** Flutter / Riverpod (`kolabing-app`), Laravel 12 (`kolabing-v2`, branch `feat/gamif-mission-phase1`, already merged-ready per `kolabing-v2#63`).

## Global Constraints
- Do not guess-fix: every code change in this plan is gated on a specific piece of live evidence captured in Task 3.
- Remove all temporary `debugPrint` instrumentation before the final commit (Task 5) — it must not ship.
- `flutter analyze lib` → 0 new errors before any commit that changes non-test code.
- If the live repro shows the bug is actually "dev backend doesn't have `/me/missions` deployed" (i.e. not a Flutter bug at all), close `kolabing-app#48` with that finding and do not write a speculative code fix.

## Static findings (already verified, 2026-06-28 — do not re-derive these)
- `lib/features/business/screens/business_profile_screen.dart:1027-1031` and `lib/features/community/screens/community_profile_screen.dart:1018-1022` — the Missions tile is a `_ContactInfoTile(onTap: () => context.push(KolabingRoutes.missions))`. `_ContactInfoTile` (`business_profile_screen.dart:1148-1199`) wraps its `Row` in a real `InkWell(onTap: onTap, ...)` — the tap wiring itself is correct, no swallowed gesture, no overlapping hit-test blocker.
- `lib/config/routes/routes.dart:866-871` — `GoRoute(path: KolabingRoutes.missions, name: 'missions', builder: ... MissionsScreen())` is a flat top-level route with no `redirect:` of its own. The router's only top-level `redirect:` (`routes.dart:375-384`) only matches `state.matchedLocation == '/'` for the password-reset deep link — it cannot intercept `/missions`.
- `lib/features/missions/providers/missions_provider.dart` — `myMissionsProvider` is a plain `FutureProvider<List<Mission>>` that calls `service.getMyMissions()` inside the async body; there is no synchronous throw during provider construction.
- `lib/features/missions/screens/missions_screen.dart` — `MissionsScreen.build()` calls `missionsAsync.when(data:, loading:, error:)` correctly; `_MissionsError` (lines ~300-340) renders a centered icon + message + retry button — it is not visually empty/blank, it's a normal error card.
- `lib/features/missions/services/missions_service.dart:38-39` already logs `🎯 Get My Missions: GET $url` and the response status — no new logging needed there, only at the call sites above it.
- **Conclusion of the static pass:** if the live repro shows the screen really does render nothing (not even the error icon), the bug is upstream of `MissionsScreen.build()` — most likely the `context.push()` call never runs, or runs but the navigator doesn't actually swap screens. If instead the screen does render but shows the error card, the bug is server-side (`kolabing-v2#63` not deployed where the app points), not a Flutter bug.

---

### Task 1: Unblock the local iOS simulator build (resolves `kolabing-app#47`)

**Files:**
- No source changes — this is a local Xcode/derived-data cache fix, not a code change.

**Interfaces:** N/A (environment-only task).

- [ ] **Step 1: Confirm the signing config is consistent (it already is)**

Run:
```bash
grep -n "CODE_SIGN_STYLE\|DEVELOPMENT_TEAM" ios/Runner.xcodeproj/project.pbxproj | sort -u
```
Expected: every line reads `CODE_SIGN_STYLE = Automatic;` and `DEVELOPMENT_TEAM = LPFNQ76GB6;` — including the `richpushserviceext` (OneSignal notification-service extension) target. This confirms the project file itself is *not* misconfigured — the error (`Embedded binary is not signed with the same certificate as the parent app`) is a stale-cache symptom, not a settings mismatch. If any target shows a different team or `CODE_SIGN_STYLE = Manual`, stop here and fix that line first — that would be a real config bug, out of scope for the cache-clear fix below.

- [ ] **Step 2: Clear derived data and CocoaPods caches**

```bash
flutter clean
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
cd ios && rm -rf Pods Podfile.lock && cd ..
flutter pub get
```

- [ ] **Step 3: Rebuild and launch on the simulator**

```bash
flutter run -d "iPhone 16e" --dart-define=KOLABING_API_BASE_URL=http://127.0.0.1:8000/api/v1
```
Expected: build completes and the app launches on the simulator without the `Embedded binary is not signed...` error. (Pod install + Xcode build together typically take 3-5 minutes on a clean cache — this is normal, not a hang.)

- [ ] **Step 4: If Step 3 still fails with the same signing error**

Open `ios/Runner.xcworkspace` in Xcode, select the `richpushserviceext` target → Signing & Capabilities, and re-toggle "Automatically manage signing" off then on (forces Xcode to re-resolve a fresh provisioning profile instead of reusing a stale cached one). Re-run Step 3.

- [ ] **Step 5: Close `kolabing-app#47`**

```bash
gh issue close 47 -R kolabing/kolabing-app -c "Resolved by clearing DerivedData + CocoaPods caches (stale provisioning profile cache, not a project misconfiguration — CODE_SIGN_STYLE/DEVELOPMENT_TEAM were already consistent across all targets). Simulator build now launches; see kolabing-app#48 for the unblocked investigation."
```

---

### Task 2: Stand up the backend + add temporary instrumentation

**Files:**
- Modify (temporarily — reverted in Task 5): `lib/features/business/screens/business_profile_screen.dart:1031`
- Modify (temporarily — reverted in Task 5): `lib/features/community/screens/community_profile_screen.dart:1022`
- Modify (temporarily — reverted in Task 5): `lib/features/missions/screens/missions_screen.dart:27` (top of `build()`)

**Interfaces:** N/A — instrumentation only, no new public API.

- [ ] **Step 1: Start the backend with the gamification branch**

In the `kolabing-v2` checkout:
```bash
cd /Users/macbook/kolabing-app/kolabing-v2
git checkout feat/gamif-mission-phase1
php artisan serve --port=8000 > /tmp/laravel-serve.log 2>&1 &
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/api/v1/cities
```
Expected: `200`. This confirms the server (with `/me/missions` already merged into this branch per `kolabing-v2#63`) is reachable before you touch the Flutter side.

- [ ] **Step 2: Add a tap-fired log at both Missions entry points**

In `lib/features/business/screens/business_profile_screen.dart:1031`, change:
```dart
onTap: () => context.push(KolabingRoutes.missions),
```
to:
```dart
onTap: () {
  debugPrint('🔍 [B3] business profile: Missions tile tapped');
  context.push(KolabingRoutes.missions);
},
```

In `lib/features/community/screens/community_profile_screen.dart:1022`, apply the same change with `'🔍 [B3] community profile: Missions tile tapped'`.

- [ ] **Step 3: Add a build-fired log at the top of `MissionsScreen.build()`**

In `lib/features/missions/screens/missions_screen.dart`, inside `MissionsScreen.build()` (currently starts at line 27 with `final l10n = AppLocalizations.of(context);`), add as the first line:
```dart
debugPrint('🔍 [B3] MissionsScreen.build() called');
```

- [ ] **Step 4: Commit the instrumentation on a throwaway basis**

This is intentionally *not* committed to history — keep it as an uncommitted working-tree change so Task 5's revert is a clean `git checkout -- <files>` rather than a revert commit. Skip `git commit` for this task.

---

### Task 3: Reproduce live and capture the evidence

**Files:** None (this task only produces log output, recorded into the plan/issue, not into code).

**Interfaces:** N/A.

- [ ] **Step 1: Launch the app pointed at the local backend**

```bash
flutter run -d "iPhone 16e" --dart-define=KOLABING_API_BASE_URL=http://127.0.0.1:8000/api/v1 2>&1 | tee /tmp/flutter-b3-repro.log
```

- [ ] **Step 2: Sign in as a business user and navigate to Profile → Missions**

In the running simulator: complete sign-in (Google OAuth), go to the Business Profile tab, tap the "Missions" row.

- [ ] **Step 3: Read the log in order and classify the outcome**

```bash
grep "🔍 \[B3\]\|🎯 Get My Missions" /tmp/flutter-b3-repro.log
```

Classify into exactly one of these three outcomes:

- **Outcome A — no `Missions tile tapped` line at all:** the tap never reached `onTap`. This means something *above* `_ContactInfoTile` (e.g. an overlapping `GestureDetector`/`Hero`/scroll-view drag conflict introduced since the static read) is intercepting the gesture. This was not visible in the static read — it's a layout issue that only shows up live. → go to Task 4, Branch 1.
- **Outcome B — `Missions tile tapped` logs, but no `MissionsScreen.build() called` follows:** `context.push()` ran but the navigator never built the destination screen. → go to Task 4, Branch 2.
- **Outcome C — both logs appear, and `🎯 Get My Missions: GET ...` / `response status: ...` also appear:** navigation and the screen build both work. The bug is not a Flutter defect — it's that the missions list/error renders but looked "blank" because of empty data, OR the original bug report was filed against the dev backend (which doesn't have `/me/missions` yet) and is not reproducible against this local backend at all. → go to Task 4, Branch 3 (no-code-change closure).

- [ ] **Step 4: Save the raw log evidence for the issue comment**

```bash
grep -A2 -B2 "🔍 \[B3\]\|🎯 Get My Missions" /tmp/flutter-b3-repro.log > /tmp/flutter-b3-evidence.txt
```

---

### Task 4: Apply the fix for the observed outcome

**Files:** depends on outcome — see each branch.

**Interfaces:** N/A.

- [ ] **Branch 1 (Outcome A — tap never fires): inspect the widget tree above the tile for a gesture conflict**

Run:
```bash
grep -n "GestureDetector\|onTap\|Dismissible\|Draggable" lib/features/business/screens/business_profile_screen.dart | head -30
```
Look specifically for any ancestor of the Missions `_ContactInfoTile` (between it and the nearest scrollable) that also defines `onTap`/`onPanStart`/similar. If found, the fix is to ensure the ancestor's gesture recognizer doesn't claim the pointer before the `InkWell` does — typically by giving the `InkWell` a `HitTestBehavior.opaque` (it already defaults to this in Material's `InkWell`, so look instead for a `Listener`/`GestureDetector` higher up using `HitTestBehavior.translucent` incorrectly, or an `AbsorbPointer`/`IgnorePointer` left mistakenly active). Write the fix as a one-line change to that ancestor widget's gesture configuration — do not restructure the tile itself, since `_ContactInfoTile` was already verified correct.

- [ ] **Branch 2 (Outcome B — push runs, screen never builds): check for a thrown/swallowed exception during navigation**

Add one more temporary log immediately after the `context.push(KolabingRoutes.missions)` call, wrapped in try/catch:
```dart
try {
  context.push(KolabingRoutes.missions);
  debugPrint('🔍 [B3] context.push(missions) returned normally');
} catch (e, st) {
  debugPrint('🔍 [B3] context.push(missions) threw: $e\n$st');
}
```
Re-run Task 3's Step 1-3. If it throws, the stack trace identifies the exact failure (most likely a `GoRouter` configuration error specific to runtime state, e.g. a missing `Navigator` context from how the profile screen itself is pushed). Fix that specific cause. If it does NOT throw and `MissionsScreen.build()` still never logs, the issue is in how `kolabingNavigatorKey` is wired in `lib/config/routes/routes.dart:363` — check whether the `Navigator` the profile screen lives under matches `kolabingNavigatorKey`'s tree (a mismatched nested `Navigator` would silently no-op a `context.push`).

- [ ] **Branch 3 (Outcome C — both logs fire, no Flutter defect found): close as backend-not-reproducible**

No code change. Run:
```bash
gh issue close 48 -R kolabing/kolabing-app -c "Live repro against a local backend running kolabing-v2's feat/gamif-mission-phase1 (kolabing-v2#63) shows the full tap → navigate → build → fetch chain working correctly (evidence: /tmp/flutter-b3-evidence.txt). The original blank-screen report was against the dev backend, which doesn't have /me/missions deployed yet. Closing — re-open if the bug reproduces again once kolabing-v2#63 is deployed to dev."
```

---

### Task 5: Clean up instrumentation, add a regression test, commit

**Files:**
- Modify: `lib/features/business/screens/business_profile_screen.dart` (revert Task 2's instrumentation)
- Modify: `lib/features/community/screens/community_profile_screen.dart` (revert Task 2's instrumentation)
- Modify: `lib/features/missions/screens/missions_screen.dart` (revert Task 2's instrumentation)
- Modify: whichever file Task 4's branch actually changed
- Test: `test/features/missions/missions_navigation_test.dart` (create)

**Interfaces:**
- Produces: a widget test asserting the Missions tile navigates, guarding against this exact regression.

- [ ] **Step 1: Revert all temporary instrumentation**

```bash
git diff --stat lib/features/business/screens/business_profile_screen.dart lib/features/community/screens/community_profile_screen.dart lib/features/missions/screens/missions_screen.dart
git checkout -- lib/features/business/screens/business_profile_screen.dart lib/features/community/screens/community_profile_screen.dart lib/features/missions/screens/missions_screen.dart
```
This discards the `debugPrint` lines added in Task 2 while keeping any real fix from Task 4 (which you will have made as separate, deliberate edits — re-apply that fix now if this revert removed it too, since Task 4's fix should be made directly on top of clean code once the diagnosis is confirmed, not mixed into the instrumentation diff).

- [ ] **Step 2: Write the failing regression test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kolabing/config/routes/routes.dart';
import 'package:kolabing/features/missions/screens/missions_screen.dart';

void main() {
  testWidgets('tapping the Missions route pushes MissionsScreen', (tester) async {
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.push(KolabingRoutes.missions),
              child: const Text('Go to missions'),
            ),
          ),
        ),
        GoRoute(
          path: KolabingRoutes.missions,
          name: 'missions',
          builder: (context, state) => const MissionsScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.text('Go to missions'));
    await tester.pumpAndSettle();

    expect(find.byType(MissionsScreen), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run the test to verify it passes against the fixed code**

Run: `flutter test test/features/missions/missions_navigation_test.dart`
Expected: PASS. (This test exercises the route wiring in isolation — if Task 4's fix was in the route/navigation layer, this catches a regression; if the fix was in a gesture-conflict ancestor widget specific to the profile screen, additionally note that finding in the commit message since this particular test won't cover an ancestor-widget gesture conflict.)

- [ ] **Step 4: Run `flutter analyze` to confirm no new errors**

Run: `flutter analyze lib`
Expected: 0 new errors introduced by this plan's changes.

- [ ] **Step 5: Commit**

```bash
git add test/features/missions/missions_navigation_test.dart
# plus whichever file(s) Task 4's branch modified
git commit -m "fix(missions): <actual root cause from Task 3/4, not 'fix blank screen'>"
```

- [ ] **Step 6: Update `kolabing-app#48` with the resolution**

```bash
gh issue close 48 -R kolabing/kolabing-app -c "Root-caused and fixed: <one-line actual cause>. See commit <sha>. Regression test added in test/features/missions/missions_navigation_test.dart."
```
(If Task 4 resolved via Branch 3, this step was already done in Task 4 — skip it here.)

---

## Execution Order
Task 1 → Task 2 → Task 3 → Task 4 (exactly one branch, chosen by Task 3's evidence) → Task 5. Do not skip ahead to Task 4 without Task 3's log evidence in hand — that evidence is what selects the branch and is itself the artifact this plan exists to produce.
