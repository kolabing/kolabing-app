# Dev/Prod Environment Separation via Flutter Flavors — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `dev` and `prod` as separate, side-by-side-installable apps (two TestFlight apps), each pinned to its own backend, driven by the Flutter build flavor.

**Architecture:** A single `lib/config/environment.dart` resolves the environment from Flutter's compile-time `appFlavor` constant. Because `appFlavor` is `const`, every per-env value (`apiBaseUrl`, `broadcastAuth`, `shareHost`, `sentryEnvironment`) is also a `const` — so `ApiConfig.baseUrl` stays `const` and the ~15 `const String _baseUrl = ApiConfig.baseUrl;` call-sites compile unchanged. A `--dart-define` escape hatch still wins for local backends. Native flavors (iOS build configs + schemes, Android product flavors) give the two builds distinct bundle IDs and per-flavor Firebase config.

**Tech Stack:** Flutter 3.38, Dart `String.fromEnvironment`/`appFlavor`, Xcode build configurations + schemes, Android Gradle (Kotlin DSL) product flavors, PostHog (`posthog_flutter ^5.26.0`), Sentry (`sentry_flutter ^9.22.0`).

**Ticket:** [#17](https://github.com/kolabing/kolabing-app/issues/17) · **Branch:** `feat/env-dev-prod-flavors` · **Spec:** `docs/superpowers/specs/2026-06-18-dev-prod-flavors-design.md`

---

## File Structure

- **Create** `lib/config/environment.dart` — the env resolver + all per-env constants. Single responsibility: "what environment am I, and what are its hosts."
- **Create** `test/config/environment_test.dart` — tests the pure flavor→env mapping.
- **Modify** `lib/config/constants/api.dart` — `baseUrl` reads `Environment.apiBaseUrl` (dart-define override preserved).
- **Modify** `lib/config/constants/sentry.dart` — `environment` reads `Environment.sentryEnvironment`.
- **Modify** `lib/config/constants/realtime.dart` — `authEndpoint` reads `Environment.broadcastAuth`.
- **Modify** `lib/features/opportunity/utils/opportunity_share.dart` — share host from env.
- **Modify** `lib/features/gamification/screens/attendee_main_screen.dart` — QR/share host from env.
- **Modify** `lib/services/analytics/analytics_service.dart` — register `environment` PostHog super-property.
- **Modify** `android/app/build.gradle.kts` — `env` flavor dimension + `dev`/`prod` product flavors.
- **Create** `android/app/src/dev/google-services.json`, `android/app/src/prod/google-services.json` — per-flavor Firebase config (downloaded from console — see appendix).
- **Modify** iOS `Runner.xcodeproj` (build configs, schemes, xcconfig, bundle IDs) + per-flavor `GoogleService-Info.plist`.
- **Modify** `BACKLOG.md`.

---

### Task 1: Environment resolver

**Files:**
- Create: `lib/config/environment.dart`
- Test: `test/config/environment_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/config/environment_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kolabing_app/config/environment.dart';

void main() {
  group('Environment.resolveFlavor', () {
    test('prod flavor resolves to prod', () {
      expect(Environment.resolveFlavor('prod'), AppEnvironment.prod);
    });
    test('dev flavor resolves to dev', () {
      expect(Environment.resolveFlavor('dev'), AppEnvironment.dev);
    });
    test('null (no flavor) defaults to dev', () {
      expect(Environment.resolveFlavor(null), AppEnvironment.dev);
    });
    test('unknown flavor defaults to dev', () {
      expect(Environment.resolveFlavor('staging'), AppEnvironment.dev);
    });
    test('prod uses kolabing.com REST base', () {
      expect(Environment.apiBaseUrlFor(AppEnvironment.prod),
          'https://kolabing.com/api/v1');
    });
    test('dev uses the laravel.cloud REST base', () {
      expect(Environment.apiBaseUrlFor(AppEnvironment.dev),
          'https://kolabing-v2-development-uhzrzd.laravel.cloud/api/v1');
    });
  });
}
```

> The package name in the import is `kolabing_app` — confirm against `name:` in `pubspec.yaml` and fix the import if it differs.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/config/environment_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:kolabing_app/config/environment.dart'`.

- [ ] **Step 3: Write the implementation**

```dart
// lib/config/environment.dart
import 'package:flutter/foundation.dart' show appFlavor;

/// The two shipped environments. Selected by the Flutter build flavor
/// (`--flavor dev|prod`); a flavorless `flutter run` is treated as [dev].
enum AppEnvironment { dev, prod }

/// Single source of truth for environment-dependent hosts.
///
/// [current] is a compile-time constant derived from Flutter's `appFlavor`,
/// so every value below stays `const` (keeps `ApiConfig.baseUrl` const).
class Environment {
  Environment._();

  static const String _devBase =
      'https://kolabing-v2-development-uhzrzd.laravel.cloud';
  static const String _prodBase = 'https://kolabing.com';

  /// Resolved once from the build flavor. Unknown / absent flavor => dev.
  static const AppEnvironment current =
      appFlavor == 'prod' ? AppEnvironment.prod : AppEnvironment.dev;

  static const bool isProd = current == AppEnvironment.prod;

  /// REST base URL (`…/api/v1`).
  static const String apiBaseUrl =
      isProd ? '$_prodBase/api/v1' : '$_devBase/api/v1';

  /// Laravel broadcasting auth route (app-root, not under /api/v1).
  static const String broadcastAuth =
      isProd ? '$_prodBase/broadcasting/auth' : '$_devBase/broadcasting/auth';

  /// Reverb WebSocket host. Kept on the prod host until a dev Reverb daemon
  /// exists; realtime is gated off on an empty app key regardless.
  static const String reverbHost = 'ws.kolabing.com';

  /// Host for user-facing share / QR deep links (no scheme).
  static const String shareHost =
      isProd ? 'kolabing.com' : 'kolabing-v2-development-uhzrzd.laravel.cloud';

  /// Sentry `environment` tag.
  static const String sentryEnvironment = isProd ? 'production' : 'development';

  /// Human label (e.g. for diagnostics).
  static const String label = isProd ? 'Kolabing' : 'Kolabing Dev';

  // --- Pure, testable mirrors of the const logic above. ---
  // Keep [resolveFlavor]/[apiBaseUrlFor] in sync with [current]/[apiBaseUrl];
  // the const fields can't call methods, so the one-liners are duplicated.

  /// Maps a raw flavor string to an [AppEnvironment]. Anything other than
  /// `'prod'` is dev.
  static AppEnvironment resolveFlavor(String? flavor) =>
      flavor == 'prod' ? AppEnvironment.prod : AppEnvironment.dev;

  static String apiBaseUrlFor(AppEnvironment env) =>
      env == AppEnvironment.prod ? '$_prodBase/api/v1' : '$_devBase/api/v1';
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/config/environment_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/config/environment.dart test/config/environment_test.dart
git commit -m "feat(config): add Environment resolver for dev/prod flavors (#17)"
```

---

### Task 2: Route REST base URL through Environment

**Files:**
- Modify: `lib/config/constants/api.dart`

- [ ] **Step 1: Replace the body of `ApiConfig`**

```dart
// lib/config/constants/api.dart
import '../environment.dart';

/// API configuration constants.
class ApiConfig {
  ApiConfig._();

  /// The single source of truth for the API base URL.
  ///
  /// Resolution order:
  /// 1. `--dart-define=KOLABING_API_BASE_URL=…` (local backend override), else
  /// 2. the URL for the active build flavor ([Environment.apiBaseUrl]).
  ///
  /// Stays `const` so existing `const String _baseUrl = ApiConfig.baseUrl;`
  /// call-sites keep compiling.
  static const String baseUrl = bool.hasEnvironment('KOLABING_API_BASE_URL')
      ? String.fromEnvironment('KOLABING_API_BASE_URL')
      : Environment.apiBaseUrl;
}
```

- [ ] **Step 2: Verify it compiles (const call-sites unbroken)**

Run: `flutter analyze lib/config/constants/api.dart lib/features/opportunity/services/opportunity_service.dart`
Expected: No errors (no "const initializer" complaints at the `const String _baseUrl = ApiConfig.baseUrl;` sites).

- [ ] **Step 3: Commit**

```bash
git add lib/config/constants/api.dart
git commit -m "feat(config): derive ApiConfig.baseUrl from build flavor (#17)"
```

---

### Task 3: Route Sentry environment through flavor

**Files:**
- Modify: `lib/config/constants/sentry.dart:30-34` (the `environment` field)

- [ ] **Step 1: Replace the `environment` constant**

Replace:

```dart
  static const String environment = String.fromEnvironment(
    'SENTRY_ENVIRONMENT',
    defaultValue: kReleaseMode ? 'production' : 'development',
  );
```

with:

```dart
  static const String environment = bool.hasEnvironment('SENTRY_ENVIRONMENT')
      ? String.fromEnvironment('SENTRY_ENVIRONMENT')
      : Environment.sentryEnvironment;
```

- [ ] **Step 2: Add the import** at the top of `sentry.dart` (after the existing `foundation.dart` import):

```dart
import '../environment.dart';
```

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/config/constants/sentry.dart`
Expected: No errors. (`kReleaseMode` may now be unused — if analyze warns, remove the `foundation.dart` import only if nothing else uses it; `tracesSampleRate` still uses `kReleaseMode`, so keep it.)

- [ ] **Step 4: Commit**

```bash
git add lib/config/constants/sentry.dart
git commit -m "feat(observability): set Sentry environment from build flavor (#17)"
```

---

### Task 4: Route realtime broadcast auth through Environment

**Files:**
- Modify: `lib/config/constants/realtime.dart` (`authEndpoint`)

- [ ] **Step 1: Add import** at the top:

```dart
import '../environment.dart';
```

- [ ] **Step 2: Replace** the `authEndpoint` declaration:

Replace:

```dart
  static const String authEndpoint = 'https://kolabing.com/broadcasting/auth';
```

with:

```dart
  static const String authEndpoint = Environment.broadcastAuth;
```

(Leave `host`/`scheme`/`port` as-is — `host` stays `ws.kolabing.com` per the spec; realtime is dormant until `appKey` is set.)

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/config/constants/realtime.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/config/constants/realtime.dart
git commit -m "feat(realtime): derive broadcasting auth host from flavor (#17)"
```

---

### Task 5: Route share / QR hosts through Environment

**Files:**
- Modify: `lib/features/opportunity/utils/opportunity_share.dart:1`
- Modify: `lib/features/gamification/screens/attendee_main_screen.dart:146`

- [ ] **Step 1: In `opportunity_share.dart`**, add the import at the top and replace the host constant.

Add (top of file):

```dart
import '../../../config/environment.dart';
```

Replace:

```dart
const String _kolabingShareHost = 'kolabing.com';
```

with:

```dart
const String _kolabingShareHost = Environment.shareHost;
```

- [ ] **Step 2: In `attendee_main_screen.dart`**, replace the hardcoded QR URL.

Replace:

```dart
        ? 'https://kolabing.com/u/$payload'
```

with:

```dart
        ? 'https://${Environment.shareHost}/u/$payload'
```

Add the import if not already present (path is from `lib/features/gamification/screens/`):

```dart
import '../../../config/environment.dart';
```

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/features/opportunity/utils/opportunity_share.dart lib/features/gamification/screens/attendee_main_screen.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/opportunity/utils/opportunity_share.dart lib/features/gamification/screens/attendee_main_screen.dart
git commit -m "feat(share): derive share/QR host from build flavor (#17)"
```

---

### Task 6: PostHog `environment` super-property

**Files:**
- Modify: `lib/services/analytics/analytics_service.dart` (inside `init()`, after `await _posthog.setup(config);`)

- [ ] **Step 1: Add the import** at the top of the file:

```dart
import '../../config/environment.dart';
```

- [ ] **Step 2: Register the super-property** immediately after `await _posthog.setup(config);` and before `_enabled = true;`:

```dart
      await _posthog.setup(config);
      // Tag every event with the build environment so dev traffic is
      // filterable from prod in one PostHog project.
      await _posthog.register('environment', Environment.current.name);
      _enabled = true;
```

> `Posthog().register(String key, Object value)` sets a super-property persisted across events (posthog_flutter 5.x). If `register` is not found on the installed version, fall back to passing `'environment'` in each `capture` call's properties — but verify the method first with `flutter pub deps` / the package source.

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/services/analytics/analytics_service.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/services/analytics/analytics_service.dart
git commit -m "feat(analytics): tag PostHog events with build environment (#17)"
```

---

### Task 7: Android product flavors

**Files:**
- Modify: `android/app/build.gradle.kts`
- Create: `android/app/src/dev/google-services.json`, `android/app/src/prod/google-services.json` (from Firebase console — appendix)

- [ ] **Step 1: Add the flavor block** inside `android { … }`, right after the `buildTypes { … }` block:

```kotlin
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Kolabing Dev")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Kolabing")
        }
    }
```

- [ ] **Step 2: Use the flavor-provided app name** in `android/app/src/main/AndroidManifest.xml`.

Replace:

```xml
        android:label="Kolabing"
```

with:

```xml
        android:label="@string/app_name"
```

- [ ] **Step 3: Place per-flavor `google-services.json`.**

Download from Firebase (appendix steps F1–F2) and save:
- `android/app/src/prod/google-services.json` — for `com.kolabing.kolabing_app`
- `android/app/src/dev/google-services.json` — for `com.kolabing.kolabing_app.dev`

(Remove the old `android/app/google-services.json` only after both flavor copies exist; the google-services Gradle plugin reads the flavor-specific path first.)

- [ ] **Step 4: Verify both flavors build**

Run: `flutter build apk --flavor dev --debug` then `flutter build apk --flavor prod --debug`
Expected: Both succeed. The dev APK's applicationId is `com.kolabing.kolabing_app.dev`.

- [ ] **Step 5: Verify runtime env wiring**

Run: `flutter run --flavor dev` on an emulator; confirm network calls go to `kolabing-v2-development-uhzrzd.laravel.cloud` (check a request in the debugger / Sentry breadcrumb). Then `flutter run --flavor prod` → `kolabing.com`.

- [ ] **Step 6: Commit**

```bash
git add android/app/build.gradle.kts android/app/src/main/AndroidManifest.xml android/app/src/dev/google-services.json android/app/src/prod/google-services.json
git rm --cached android/app/google-services.json 2>/dev/null || true
git commit -m "feat(android): add dev/prod product flavors with per-flavor Firebase (#17)"
```

---

### Task 8: iOS build configurations, schemes, and bundle IDs

> This is Xcode project surgery. Do it in Xcode (Runner.xcworkspace) so the `.pbxproj` stays valid; verify by building from CLI afterward. Follow the standard Flutter iOS flavor recipe.

**Files:**
- Modify: `ios/Runner.xcodeproj/project.pbxproj` (build configs, bundle IDs)
- Create: `ios/Flutter/dev.xcconfig`, `ios/Flutter/prod.xcconfig` (or per-config bundle ID settings)
- Create/replace: per-flavor `GoogleService-Info.plist`
- Modify: schemes under `ios/Runner.xcodeproj/xcshareddata/xcschemes/`

- [ ] **Step 1: Duplicate build configurations.** In Xcode → Runner project → Info → Configurations, duplicate each of `Debug`/`Release`/`Profile` into `Debug-dev`, `Release-dev`, `Profile-dev`, `Debug-prod`, `Release-prod`, `Profile-prod` (six total). Delete the original three only after the six exist.

- [ ] **Step 2: Set per-config bundle IDs.** For the **Runner** target set `PRODUCT_BUNDLE_IDENTIFIER`:
  - `*-prod` → `com.kolabing.kolabingApp`
  - `*-dev`  → `com.kolabing.kolabingApp.dev`

  For the **rich-push extension** target:
  - `*-prod` → `com.kolabing.kolabingApp.richpushserviceext`
  - `*-dev`  → `com.kolabing.kolabingApp.dev.richpushserviceext`

- [ ] **Step 3: Create two schemes** named exactly `dev` and `prod` (Product → Scheme → Manage Schemes → duplicate `Runner`). Mark them **Shared**. Map each scheme's Run/Test/Profile/Archive actions to the matching `*-dev` / `*-prod` configurations. Scheme names MUST match the `--flavor` value Flutter passes.

- [ ] **Step 4: Per-flavor display name.** Set `CFBundleDisplayName` per config: `Kolabing` for `*-prod`, `Kolabing Dev` for `*-dev` (via a build setting `PRODUCT_DISPLAY_NAME` referenced in `Info.plist`, or set `CFBundleDisplayName` directly per configuration through an xcconfig).

- [ ] **Step 5: Per-flavor `GoogleService-Info.plist`.** Place `ios/Runner/config/dev/GoogleService-Info.plist` and `ios/Runner/config/prod/GoogleService-Info.plist` (from Firebase console, appendix F1–F2). Add a Run Script build phase that copies the right one to `${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist` based on the configuration name, e.g.:

```bash
# Run Script phase, before "Copy Bundle Resources"
if [[ "${CONFIGURATION}" == *"-dev" ]]; then
  cp -f "${SRCROOT}/Runner/config/dev/GoogleService-Info.plist" "${SRCROOT}/Runner/GoogleService-Info.plist"
else
  cp -f "${SRCROOT}/Runner/config/prod/GoogleService-Info.plist" "${SRCROOT}/Runner/GoogleService-Info.plist"
fi
```

- [ ] **Step 6: Verify both flavors build**

Run: `flutter build ios --flavor prod --no-codesign --debug` then `flutter build ios --flavor dev --no-codesign --debug`
Expected: Both succeed. (Codesigned archive needs the provisioning profiles from appendix A1–A4.)

- [ ] **Step 7: Verify runtime env wiring**

Run: `flutter run --flavor dev` on a simulator → calls hit `kolabing-v2-development-uhzrzd.laravel.cloud`; `flutter run --flavor prod` → `kolabing.com`. App shows as `Kolabing Dev` for dev.

- [ ] **Step 8: Commit**

```bash
git add ios/
git commit -m "feat(ios): add dev/prod build configs, schemes, and bundle ids (#17)"
```

---

### Task 9: Backlog + final verification

**Files:**
- Modify: `BACKLOG.md`

- [ ] **Step 1:** Move/record this work in `BACKLOG.md` per its Maintenance rules (it began as work → Incomplete Features; remove once verified end-to-end). Update the `Last updated:` date to 2026-06-18.

- [ ] **Step 2: Full analyze + format**

Run: `flutter analyze` then `dart format lib/ test/`
Expected: analyze clean; format reports only intended changes.

- [ ] **Step 3: Full test run**

Run: `flutter test`
Expected: PASS (including `environment_test.dart`).

- [ ] **Step 4: Commit**

```bash
git add BACKLOG.md
git commit -m "docs: track dev/prod flavor separation in backlog (#17)"
```

- [ ] **Step 5: Open the PR** using `.github/pull_request_template.md`, fill every section, link `Closes #17`. Screenshots: dev vs prod app on the home screen (and the `Kolabing Dev` label). State production needs from the appendix explicitly.

---

## Appendix — Console / Portal checklist (manual, owner-only)

These are **outside the codebase** and gate the actual TestFlight split. Code (Tasks 1–9) can land first; these make the dev app real.

### A. Apple — App Store Connect & signing (creates the second TestFlight app)
- [ ] **A1.** In the Apple Developer portal → Identifiers, register App IDs:
  - `com.kolabing.kolabingApp.dev`
  - `com.kolabing.kolabingApp.dev.richpushserviceext`
  Enable the same capabilities as prod (Push Notifications, App Groups if used by the rich-push ext, etc.).
- [ ] **A2.** App Store Connect → My Apps → **+ New App** for bundle id `com.kolabing.kolabingApp.dev`, name e.g. "Kolabing Dev". This is the separate TestFlight app.
- [ ] **A3.** Create provisioning profiles (or enable automatic signing) for both dev App IDs.
- [ ] **A4.** APNs: ensure the dev App ID is covered by the existing APNs auth key (one key per team covers all app IDs) so push works on the dev build.
- [ ] **A5.** Archive `prod` scheme → upload to the existing app; archive `dev` scheme → upload to the new dev app. Add testers to each app's TestFlight.

### B. Firebase (per-flavor config files)
- [ ] **F1.** Firebase console → Project settings → **Add app** → iOS: register `com.kolabing.kolabingApp.dev`; download its `GoogleService-Info.plist` → Task 8 Step 5 (`config/dev/`). Keep prod's existing plist as `config/prod/`.
- [ ] **F2.** Add app → Android: register `com.kolabing.kolabing_app.dev`; download `google-services.json` → Task 7 Step 3 (`src/dev/`). Existing file → `src/prod/`.
- [ ] **F3.** (If push uses Firebase/OneSignal) mirror the APNs key / FCM sender config for the dev apps in the relevant console.

### C. Backend
- [ ] **D1.** Confirm `https://kolabing-v2-development-uhzrzd.laravel.cloud/api/v1` is reachable and schema-compatible with prod (`docs/BACKEND-SCHEMA.md`).
- [ ] **D2.** Confirm whether the dev backend has a Reverb host. If yes, update `Environment.reverbHost` for dev; if no, leave it (realtime stays dormant on the dev build — already gated on empty `appKey`).
