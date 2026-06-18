# Dev/Prod Environment Separation via Flutter Flavors

- **Ticket:** [#17](https://github.com/kolabing/kolabing-app/issues/17)
- **Branch:** `feat/env-dev-prod-flavors`
- **Date:** 2026-06-18
- **Status:** Design — pending user review

> ## ⚠️ Scope update (2026-06-18, during implementation)
>
> After the Dart layer was built, the scope was narrowed based on two decisions:
>
> 1. **Android is dropped** — the app is not shipping on Android, so the Android
>    product-flavor work (original Task 7) is removed entirely.
> 2. **iOS uses "one app, two builds" (Approach A)** — same bundle id
>    (`com.kolabing.kolabingApp`), same Firebase, same App Store Connect app. The
>    two builds differ only by backend, distinguished on TestFlight by tester
>    group. **No new bundle id, no new Firebase app, no new ASC app.**
>
> Because no Xcode schemes/bundle-ids change, the original `--flavor` mechanism
> (which requires fragile Xcode build-config surgery) is replaced by a single
> **`--dart-define=APP_ENV=dev|prod`**. This flips REST URL + realtime/broadcast
> host + share host + Sentry environment + PostHog tag together. With no define,
> the safe default is **prod in release, dev in debug/profile** — so a bare
> release build can never accidentally ship the dev backend. Builds are produced
> via the `Makefile` targets (`make ipa-dev` / `make ipa-prod`).
>
> The "Architecture", "iOS (Xcode)", "Android", and "Infra / production needs"
> sections below describe the original flavor plan and are **superseded** by this
> note for everything except the Dart wiring (which shipped as designed).

## Goal

Ship **development** and **production** as separate, independently distributable
apps so that:

- each build is pinned to its own backend (dev testing never touches prod data),
- both can be installed side-by-side on one device, and
- they appear as **two separate TestFlight apps**.

| Env  | API base URL                                              |
| ---- | --------------------------------------------------------- |
| dev  | `https://kolabing-v2-development-uhzrzd.laravel.cloud/api/v1` |
| prod | `https://kolabing.com/api/v1` (unchanged — `kolabing.com`, no `www`) |

## Decisions (confirmed)

- Separation mechanism: **Flutter flavors + Xcode build configs / Android product flavors**.
- Bare `flutter run` (no flavor) defaults to **dev**.
- All `kolabing.com` hosts become env-aware (REST + realtime + share links).
- PostHog: **single project**, dev/prod distinguished by an `environment`
  **super-property** (not a separate project). Sentry uses its `environment` tag.
- Same app icon for both flavors.

## Current state

- `lib/config/constants/api.dart` — `baseUrl` via `String.fromEnvironment('KOLABING_API_BASE_URL')`, default `https://kolabing.com/api/v1`. This is the single REST source; all services read `ApiConfig.baseUrl`.
- `lib/config/constants/realtime.dart` — hardcoded `host = 'ws.kolabing.com'`, `authEndpoint = 'https://kolabing.com/broadcasting/auth'`. Realtime is dormant until `REVERB_APP_KEY` is set (`isConfigured` gate).
- Share host hardcoded `kolabing.com` in `lib/features/opportunity/utils/opportunity_share.dart` and `lib/features/gamification/screens/attendee_main_screen.dart`.
- `lib/config/constants/sentry.dart` — `environment` via `String.fromEnvironment('SENTRY_ENVIRONMENT')`, default `kReleaseMode ? 'production' : 'development'`.
- `lib/config/constants/analytics.dart` — single PostHog key + EU host.
- No Flutter flavors. iOS bundle id `com.kolabing.kolabingApp` (+ rich-push extension `com.kolabing.kolabingApp.richpushserviceext`). Android `com.kolabing.kolabing_app`. Firebase on both platforms (`GoogleService-Info.plist`, `google-services.json`).

## Architecture

A single runtime resolver derives the environment from the build flavor; every
host-bearing config reads from it. No new state, no provider — a compile-time-ish
constant resolved once.

### New unit: `lib/config/environment.dart`

```dart
enum AppEnvironment { dev, prod }

class Environment {
  // Resolved from the build flavor (package:flutter/foundation `appFlavor`).
  // Null flavor (bare `flutter run`) => dev.
  static final AppEnvironment current = _resolve(appFlavor);

  static AppEnvironment _resolve(String? flavor) =>
      flavor == 'prod' ? AppEnvironment.prod : AppEnvironment.dev;

  // Per-env values:
  static String get apiBaseUrl => ...;       // dev/prod /api/v1
  static String get reverbHost => ...;       // ws host
  static String get broadcastAuth => ...;    // /broadcasting/auth
  static String get shareHost => ...;        // kolabing.com share host
  static String get sentryEnvironment => ...;// 'development' | 'production'
  static String get label => ...;            // 'Kolabing Dev' | 'Kolabing'
}
```

- `_resolve` is a pure function — unit-testable without a running app.
- dev Reverb host: until the dev backend has a Reverb daemon, dev `reverbHost`
  may equal prod or be left blank; realtime stays dormant anyway (gated on empty
  `appKey`), so this is not a blocker.

### Wiring (consumers unchanged in shape, source changes)

| File | Change |
| ---- | ------ |
| `api.dart` | `baseUrl` ← `String.fromEnvironment(override) || Environment.apiBaseUrl`. dart-define override kept for local backend. |
| `realtime.dart` | `host` ← `Environment.reverbHost`; `authEndpoint` ← `Environment.broadcastAuth`. |
| `opportunity_share.dart`, `attendee_main_screen.dart` | share host ← `Environment.shareHost`. |
| `sentry.dart` | `environment` default ← `Environment.sentryEnvironment` (dart-define still overrides). |
| `analytics_service.dart` | after init, `register('environment', Environment.current.name)` super-property. |

### iOS (Xcode)

- Duplicate build configurations into `Debug-dev / Release-dev / Profile-dev` and
  `Debug-prod / Release-prod / Profile-prod` (Flutter flavor convention).
- Two schemes: `dev`, `prod`.
- xcconfig-driven `PRODUCT_BUNDLE_IDENTIFIER`:
  - prod: `com.kolabing.kolabingApp`, dev: `com.kolabing.kolabingApp.dev`
  - rich-push ext: `…richpushserviceext` / `….dev.richpushserviceext`
- Display name: `Kolabing` / `Kolabing Dev`.
- Per-flavor `GoogleService-Info.plist` (a build-phase script copies the right
  file by configuration, or config-specific folders).
- App icon: shared (no dev variant).

### Android

```kotlin
flavorDimensions += "env"
productFlavors {
    create("dev")  { dimension = "env"; applicationIdSuffix = ".dev"
                     resValue("string", "app_name", "Kolabing Dev") }
    create("prod") { dimension = "env"
                     resValue("string", "app_name", "Kolabing") }
}
```

- Per-flavor `google-services.json` under `android/app/src/dev/` and `src/prod/`.
- Manifest `android:label="@string/app_name"`.

## Infra / production needs (outside code)

These must be done for TestFlight to actually split — flag in the PR:

- New **App Store Connect app** for `com.kolabing.kolabingApp.dev` + provisioning
  profile + APNs key. This is what creates the second TestFlight app.
- **Firebase:** register dev iOS + Android apps (the `.dev` bundle ids); download
  the new `GoogleService-Info.plist` / `google-services.json`.
- Confirm the dev backend (`kolabing-v2-development-uhzrzd.laravel.cloud`) is
  reachable and schema-compatible; confirm whether a dev Reverb host exists.

## Testing / Definition of Done

- `flutter run --flavor dev` hits dev backend; `--flavor prod` hits prod; bare
  `flutter run` = dev.
- Both build: `flutter build ipa --flavor prod|dev`, `flutter build apk --flavor dev|prod`.
- Unit test: `Environment._resolve('prod') == prod`, `_resolve('dev') == dev`,
  `_resolve(null) == dev`.
- `flutter analyze` clean; `dart format` applied.
- dev + prod installable side-by-side.
- `BACKLOG.md` updated.

## Out of scope

- Separate Sentry/PostHog projects (using env tag + super-property instead).
- A distinct dev app icon.
- CI/fastlane automation of the two flavor builds (can follow in a later ticket).
