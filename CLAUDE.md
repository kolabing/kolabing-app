# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## 🤖 Agent Workflow System

This project uses an **AI Agent-powered task management system**. All development work MUST go through the agent workflow.

### Folder Structure

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

### Agents

| Agent | Responsibility |
|-------|----------------|
| `@ui-designer` | UI/UX design, user flows, wireframes, component specs, states |
| `@flutter-expert` | Flutter implementation, state management, API integration, widgets |

---

## 🚀 Slash Commands

**IMPORTANT:** All development work MUST use these commands. Do NOT write code without creating a task first.

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

---

## ⚙️ Command Execution Rules

1. **Always create a task first** - No direct code changes without a task file
2. **One task at a time** - Only one task in `inprogress/` at any time
3. **Follow the agents** - `@ui-designer` designs first, then `@flutter-expert` implements
4. **Document everything** - Update task file with progress
5. **Move tasks properly** - `todo/` → `inprogress/` → `done/`
6. **Log errors** - Any issues go to `.agent/sop/`

### Task File Template

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

---

## 📱 Project Overview

Kolabing is a Flutter mobile application (iOS & Android) that serves as a collaboration marketplace connecting businesses with communities for partnership opportunities.

## Build & Development Commands

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

## Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Riverpod 2.4.0
- **Backend:** Supabase
- **Navigation:** GoRouter 13.0.0
- **Forms:** flutter_form_builder with form_builder_validators
- **Icons:** Lucide Icons

## Architecture

### User Types
Two distinct user flows with role-based navigation:
- **Business Users:** Post opportunities, browse communities, manage incoming applications
- **Community Users:** Browse opportunities, apply for sponsorships, manage sent applications

### Project Structure
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

### Navigation Routes
Auth screens use dark theme (black background). Main app uses light theme.

Key route patterns:
- `/auth/*` - Authentication flows
- `/business/*` - Business user screens
- `/community/*` - Community user screens
- `/opportunity/:id`, `/collaboration/:id`, `/application/:id` - Shared detail screens

## Design System Reference

All design tokens are defined in README.md. Key values:

### Colors
- Primary: `#FFD861` (Yellow) - Always use black text on yellow
- Background: `#F7F8FA` (Light Gray)
- Dark Background: `#000000` (Auth screens only)
- Text Primary: `#232323`
- Success: `#7AE7A3`, Error: `#E14D76`

### Typography
- Display/Headlines: Rubik (bold, uppercase for display)
- Body: Open Sans
- Buttons/Labels: Darker Grotesque (uppercase)

### Component Specs
- Button height: 52dp, radius: 12dp
- Input height: 52dp (dark) / variable (light), radius: 12dp (dark) / 8dp (light)
- Card radius: 16dp
- Touch targets: minimum 48x48dp

## Key Implementation Notes

1. **Auth state flow:** Check onboarding completion → Check auth state → Route to appropriate dashboard based on `user_type`

2. **Bottom nav differs by user type:** Both have 5 tabs but with different middle tabs (Business: "My Offers", Community: "My Opportunities")

3. **Profile completion:** Optional post-registration flow with photo, city, category, social links

4. **Animations:** Default 300ms transitions, 200ms for tabs, use shimmer for loading states

---

## 📋 Quick Reference

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