# CLAUDE.md reference (not auto-loaded)

Templates, examples and diagrams moved out of `CLAUDE.md` to keep the auto-loaded file small. The rules themselves stay in `CLAUDE.md`.

## Agent workflow: folder tree and lifecycle diagram

```
.agent/
├── documentations/   → Project documentation, API specs, design docs
├── todo/             → Tasks waiting to be started
├── inprogress/       → Currently active task (max 1 at a time)
├── done/             → Completed tasks
├── sop/              → Standard Operating Procedures & error logs
├── task/             → Task templates and references
└── README.MD         → Agent system documentation
```

### Task Lifecycle

```
┌────────┐     ┌─────────────┐     ┌────────┐
│  todo/ │ ──▶ │ inprogress/ │ ──▶ │  done/ │
└────────┘     └─────────────┘     └────────┘
  Create          Execute          Complete
```

## Slash command examples

### `/mobile-tasks <api-file>`

Main workflow command. Reads API integration file, analyzes endpoints, creates all tasks, and executes them in order.

```bash
/mobile-tasks .agent/documentations/api-integration.md
```

**Flow:** API Analysis → Task Creation → UX Design → Flutter Implementation → Done

### `/mobile-feature <description>`

Develop a single feature.

```bash
/mobile-feature "User Profile Screen" --api="/users/{id}"
/mobile-feature "Business Dashboard"
```

### `/mobile-fix <description>`

Fix a bug or issue. Minimal changes only.

```bash
/mobile-fix "Bottom navigation not highlighting active tab"
/mobile-fix "Login button not responding"
```

### `/mobile-refactor <description>`

Improve code quality without changing functionality.

```bash
/mobile-refactor "Extract common widgets to shared package"
/mobile-refactor "Migrate to Riverpod 2.0 patterns"
```

### `/mobile-ui <description>`

UI-only tasks without API integration.

```bash
/mobile-ui "Splash screen animation"
/mobile-ui "Onboarding carousel"
/mobile-ui "Custom loading indicators"
```

## Task file template

```markdown
# Task: <feature-name>

## Status
- Created: YYYY-MM-DD HH:MM
- Started: 
- Completed: 

## Description
<what needs to be done>

## Related API Endpoints
- [ ] METHOD /endpoint

## Assigned Agents
- [ ] @ui-designer
- [ ] @flutter-expert

## Progress

### UX Design
**Status:** Pending
- User Flow: 
- UI Components: 
- States: loading, empty, error, success

### Flutter Implementation
**Status:** Pending
- Screens: 
- Widgets: 
- State Management: 

## Notes
```

## Quick reference tables

| Action | Command |
|--------|---------|
| Full workflow from API | `/mobile-tasks <api-file>` |
| Single feature | `/mobile-feature <description>` |
| Bug fix | `/mobile-fix <description>` |
| Refactoring | `/mobile-refactor <description>` |
| UI only work | `/mobile-ui <description>` |

| Folder | Purpose |
|--------|---------|
| `.agent/todo/` | New tasks |
| `.agent/inprogress/` | Active task |
| `.agent/done/` | Completed |
| `.agent/sop/` | Errors & procedures |
| `.agent/documentations/` | API specs, docs |

## Original build commands listing

```bash
# Setup dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Run on specific device
flutter run -d chrome          # Web
flutter run -d ios             # iOS simulator
flutter run -d android         # Android emulator

# Build
flutter build apk              # Android APK
flutter build appbundle        # Android App Bundle (Play Store)
flutter build ipa              # iOS
flutter build web              # Web

# Testing
flutter test                   # Run all tests
flutter test test/path/file_test.dart  # Run single test file

# Code quality
dart analyze                   # Analyze code
dart format lib/               # Format code
dart fix --apply               # Apply automatic fixes
```

## Original lib/ project structure

```
lib/
├── main.dart
├── config/
│   ├── theme/           # KolabingColors, KolabingTypography, ThemeData
│   ├── routes/          # GoRouter configuration
│   └── constants/       # KolabingSpacing, KolabingRadius, KolabingLayout
├── features/
│   ├── auth/            # Sign in, sign up, forgot password
│   ├── onboarding/      # First-launch onboarding screens
│   ├── business/        # Dashboard, browse, offers, applications, profile
│   └── community/       # Dashboard, offers, opportunities, applications, profile
├── widgets/             # Reusable components (buttons, inputs, cards, badges, nav)
├── services/            # Supabase, notifications
└── utils/               # Animations, transitions
```
