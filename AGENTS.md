# Repository Guidelines

## Project Structure & Module Organization
The main product is a Flutter mobile app. App code lives in `lib/`, with domain areas grouped under `lib/features/` (for example `lib/features/onboarding/`, `lib/features/subscription/`, `lib/features/gamification/`). Shared UI and cross-cutting code live in `lib/widgets/`, `lib/services/`, `lib/utils/`, and `lib/config/`. Static assets are stored in `assets/images/`, `assets/icons/`, and `assets/fonts/`.

Platform folders are `android/` and `ios/`. Tests currently live in `test/`. Supporting product docs live in `docs/` and `api_integration_documentations/`. The `instagram-stories/` directory is a separate Node/Puppeteer helper; treat it as an isolated utility. Avoid editing generated or vendor-managed directories such as `build/`, `.dart_tool/`, `ios/Pods/`, and `instagram-stories/node_modules/`.

## Build, Test, and Development Commands
Run these from the repository root unless noted:

- `flutter pub get` installs Dart and Flutter dependencies.
- `flutter run` launches the mobile app on a connected simulator or device.
- `flutter analyze` runs the strict lint and analyzer rules from `analysis_options.yaml`.
- `flutter test` runs the Flutter test suite in `test/`.
- `dart format lib test` formats app source before opening a PR.
- `flutter build ios` or `flutter build apk` creates production builds.
- `npm install` inside `instagram-stories/` installs Puppeteer for that helper script.

## Coding Style & Naming Conventions
Follow Flutter conventions with 2-space indentation and trailing commas for multiline widgets. This repo uses `flutter_lints` plus additional strict rules: prefer explicit return types for public APIs, single quotes, final locals, and Riverpod-friendly separation of screens, services, models, and providers. Use `snake_case.dart` for files, `PascalCase` for classes/widgets, and suffix feature files clearly, such as `*_screen.dart`, `*_service.dart`, and `*_provider.dart`.

## Testing Guidelines
Use `flutter_test` for widget and unit tests. Name test files `*_test.dart` and keep them under `test/`, mirroring the feature they cover where practical. Add or update tests for new business logic, providers, and reusable widgets. The current suite is minimal, so contributors should strengthen coverage rather than rely on the default smoke test.

## Before Development — Ticket → Branch → Description (mandatory, every task)
No code is written until a tracked ticket and a dedicated branch exist. For **every** task (feature, fix, refactor, chore), in order:

1. **Open a GitHub Projects ticket first** — create a GitHub issue in `kolabing/kolabing-app` and add it to the **Kolabing Engineering** project board (`gh project item-add 3 --owner kolabing --url <issue-url>`).
2. **Write the task description in the ticket** — goal, current state, work-item checklist, acceptance criteria. An empty-body ticket is not ready to start.
3. **Open a dedicated branch** off up-to-date `master` (`feat/…`, `fix/…`, `refactor/…`, `chore/…`). Never commit to protected `master`.
4. **Then start development**, and open a PR linked to the ticket (`Closes #__`).

Keep this rule in sync with the CLAUDE.md "Ticket → Branch → Description" section.

## Commit & Pull Request Guidelines
Recent history favors short Conventional Commit-style messages such as `feat: ...`, `fix: ...`, and `chore: ...`. Keep commits focused and descriptive.

**The PR template is mandatory.** Every PR MUST use `.github/pull_request_template.md` and fill in **every** section — a PR with empty sections is not ready for review and must not be merged. `master` is protected: changes land through PRs and only `olucvolkan` can merge. Required sections:

- **What does this PR do?** — concise bullets of the change.
- **What problem does it solve?** — the bug/need behind it, with linked issue (`Closes #__`).
- **What's needed for production?** — env/secret, backend deploy/migration, new App Store/Play Store build, feature flag, third-party setup, or "Nothing extra".
- **Which branch should be merged** — base branch and any dependencies.
- **How to test this merge** — affected role (Business/Community/Attendee), test account/data, numbered steps, expected result, so a reviewer can reproduce it.
- **Screenshots / screen recording** — **MANDATORY for ANY design/UI change** (before/after, ideally both iOS and Android). A UI-touching PR without a screenshot must not be merged; only tick the "no UI/design change" box when there is genuinely no visual change.
- **Definition of Done** — `flutter analyze` clean, `dart format` applied, tested on iOS AND Android, i18n in all three ARBs, no hardcoded values, `BACKLOG.md` updated.
- **Was AI used?** — which tool and what for; be transparent.

Keep this section, `.github/pull_request_template.md`, and the CLAUDE.md PR section in sync — if you change one, change the others.
