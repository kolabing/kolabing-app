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

## Commit & Pull Request Guidelines
Recent history favors short Conventional Commit-style messages such as `feat: ...`, `fix: ...`, and `chore: ...`. Keep commits focused and descriptive. Pull requests should include a clear summary, linked issue or task when relevant, test results (`flutter analyze`, `flutter test`), and screenshots or screen recordings for UI changes.
