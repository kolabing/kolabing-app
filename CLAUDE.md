# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## CONTRIBUTOR ROUTING — Volkan → Reverb real-time ticket

If the current user is **Volkan** — they introduce themselves as Volkan, the git
user / commit author is Volkan (volkanoluc@gmail.com), or they ask about
**Reverb, WebSockets, real-time chat, broadcasting, or live messages** — then
BEFORE anything else, read and surface
[`docs/tickets/2026-06-05-reverb-realtime-chat-VOLKAN.md`](docs/tickets/2026-06-05-reverb-realtime-chat-VOLKAN.md)
and orient the conversation around it: it is his assigned task (turning on
real-time chat — ops daemons + Flutter Echo client). Lead with a short summary of
where that ticket stands and what's next, then help with it.

---

## MUST FOLLOW — Ticket → Branch → Description BEFORE any development (every task)

No code is written until a tracked ticket and a dedicated branch exist. For **every**
piece of work (feature, fix, refactor, chore), do these IN ORDER before touching code:

1. **Open a GitHub Projects ticket FIRST.** Create a GitHub issue and add it to the
   **Kolabing Engineering** project board (`gh project item-add 3 --owner kolabing --url <issue-url>`).
   Use the repo `kolabing/kolabing-app`.
2. **Write the task description in the ticket** — goal, current state, the concrete
   work items (checklist), and acceptance criteria. A ticket with an empty body is not
   ready to start. (See issue #14 "Integrate Sentry…" for the expected shape.)
3. **Open a dedicated branch** off up-to-date `master`, named for the work
   (`feat/…`, `fix/…`, `refactor/…`, `chore/…`) — never commit straight to `master`
   (it is protected; see the PR rule below).
4. **Only then start development.** When done, open a PR using the mandatory template
   and link it to the ticket (`Closes #<n>`).

If the user asks to "just fix/add X" without a ticket, create the ticket + branch
first (it's cheap), then proceed — do not skip this. Keep this rule in sync with the
AGENTS.md workflow section.

---

## MUST FOLLOW — i18n is mandatory for EVERY new widget (no literal user-facing strings)

This app is fully localized via gen-l10n (`l10n.yaml`, `lib/l10n/app_{en,es,ca}.arb`,
`AppLocalizations.of(context)`). A new screen/widget is **NOT done** until its strings
exist in all three ARBs. Whenever you design or add ANY user-facing text:

1. **Never hardcode** a user-facing string in a `.dart` file (no `Text('Create event')`,
   no literal `labelText:`/`hintText:`/`SnackBar(content: Text('...'))`/dialog titles).
2. Add the key to `lib/l10n/app_en.arb`, then `app_es.arb` (**es = European/Castilian
   Spanish**: *Aforo* not *Capacidad* for venue cap, *Local/Lugar*, *Vídeos*) and
   `app_ca.arb` (**Catalan**), then run `flutter gen-l10n`.
3. Render via `AppLocalizations.of(context).<key>` (commonly aliased `l10n`). For
   counts/placeholders use ARB `placeholders` (ICU), not string interpolation.
4. **Only** exceptions: brand names ("Kolabing"), dynamic backend error text passed
   through, and pure symbols/emoji.

If you catch a literal while editing a file, fix it in passing. Do not add new debt.

---

## MUST FOLLOW — Pull Request template is mandatory (every PR)

Every PR MUST use [`.github/pull_request_template.md`](.github/pull_request_template.md)
and **fill in every section** — a PR with empty sections is not ready for review and
must not be merged. `master` is protected: changes land through PRs, and only
`olucvolkan` can merge.

Hard rules when you open a PR (or write its body):
1. **Fill all sections.** If one truly does not apply, write `N/A` with a one-line
   reason — never delete the heading.
2. **Screenshots are mandatory for ANY design/UI change.** Include before/after,
   ideally both iOS and Android. A UI-touching PR without a screenshot must not be
   merged. Only tick the "no UI/design change" box when there is genuinely no visual
   change.
3. **"How to test" must be reproducible** — affected role (Business/Community/
   Attendee), test account/data, numbered steps, expected result.
4. **State production needs** explicitly (env/secret, backend deploy/migration, new
   App Store/Play Store build, feature flag, third-party setup) or write "Nothing extra".
5. Tick the **Definition of Done**: `flutter analyze` clean, `dart format` applied,
   tested on iOS AND Android, i18n added in all three ARBs, no hardcoded values,
   `BACKLOG.md` updated.

Keep this section, `.github/pull_request_template.md`, and the AGENTS.md PR section in
sync — if you change one, change the others.

---

## MUST READ — Backend schema (before any data/model/API/DB change)

Read [`docs/BACKEND-SCHEMA.md`](docs/BACKEND-SCHEMA.md) before changing anything that
touches data, models, API payloads, JSON keys, or the database. It documents the
**real production Postgres schema** (Laravel backend, db `main`). Hard rules:
- **Never invent columns, tables, or enum values** — if it's not in that doc (or the
  live schema), it does not exist. Verify before relying on a field.
- **Never hardcode** IDs, emails, city/category names, or sample records in app code;
  fetch from the API. Identity lives in `profiles` (+ `business_profiles` /
  `community_profiles`), NOT the `users` table.
- Lifecycle: `collab_opportunities → applications → collaborations` (+ reviews /
  feedback). `GET /collaborations` is viewer-scoped. The business paywall is
  backend-enforced; never bypass it client-side.

---

## MUST READ — Backlog (every session, before anything else)

At the START of every session, read [`BACKLOG.md`](BACKLOG.md) and list its current
contents back to the user (the three sections: New Features, Incomplete Features,
Fixes). It is the single source of truth for outstanding work. You MUST keep it in
sync as you work, following its "Maintenance rules":
- A New Feature you begin → move to **Incomplete Features**.
- An Incomplete Feature verified working end-to-end → remove it.
- A bug you detect → add to **Fixes** immediately; once the fix is **confirmed**
  (tested, not just written), strike it through with the date, then remove later.
- Update the `Last updated:` date whenever you edit it.

---

## MUST READ — Roles & Permissions (before planning OR executing changes)

Before planning or writing any code that touches **user roles, permissions, the paywall, the Explore feed, profiles, onboarding, or the create/apply flows**, read BOTH (kept in sync with the backend repo `kolabing-v2`):
1. [`docs/ROLES-AND-PERMISSIONS.md`](docs/ROLES-AND-PERMISSIONS.md) — the authoritative *what*: exactly what Business and Community users can see and do.
2. [`docs/ROLES-BACKEND-DB-MAP.md`](docs/ROLES-BACKEND-DB-MAP.md) — the authoritative *where*: how each rule maps to backend code + DB tables/columns, and every known role-handling mistake.

Non-negotiable: **Communities are 100% free and are NEVER paywalled or blocked.** The paywall is Business-only, on exactly two actions (create a collaboration, apply to a Kolab). A free business gets a **blur** of the community's name+logo on Explore, never a hard block. "Opportunity" (community-created) and "collaboration" (business-created) are distinct — never merge them. Most regressions come from applying one role's rules to the other; if a fix seems to contradict these docs, STOP and ask before changing role behaviour.

---

## MUST READ — Architecture grounding (before planning OR executing ANY change)

Ground every change in the REAL architecture and intended UX. Do NOT rely on
memory or on this file's prose summaries — verify against the listed source. When
prose and code disagree, the **code wins** — and fix the prose.

### Authoritative sources (read the one(s) relevant to your change)
1. Roles / permissions / paywall / Explore / onboarding / create-apply →
   `docs/ROLES-AND-PERMISSIONS.md` + `docs/ROLES-BACKEND-DB-MAP.md` (mandatory above).
2. Backend / API contract → `lib/config/constants/api.dart` (the ONE base URL) and
   `api_integration_documentations/docs/MOBILE_APP_INTEGRATION_GUIDE.md` +
   `MOBILE_API_DOCUMENTATION.md`. Per-feature contracts: `.agent/documentations/api-*.md`, `docs/api/`.
3. User journey / feature behaviour → there is NO single journey doc. Reconstruct
   from the feature's own folder under `lib/features/<feature>/` (models = the state
   machine, services = the endpoints), then the matching plan/spec in `docs/plans/`,
   `docs/superpowers/{plans,specs}/`, `.agent/documentations/`. For the kolab
   lifecycle: `lib/features/application/models/application.dart`,
   `lib/features/collaboration/models/collaboration.dart`,
   `.agent/documentations/api-collaboration-detail-spec.md`, `CHANGELOG.md`.

### The backend is Laravel, NOT Supabase
- Laravel REST API secured by **Sanctum Bearer tokens**. Build every URL from
  `ApiConfig.baseUrl`; every service uses `package:http` with
  `'Authorization': 'Bearer $token'` (token from `AuthService.getToken()`).
- `supabase_flutter` is in pubspec but UNUSED — never add Supabase client/RLS/realtime
  code. If a task seems to need Supabase, STOP; it belongs as a Laravel endpoint.

### Do NOT hardcode — checklist (verify before committing)
- [ ] No hardcoded base URLs/hosts — derive from `ApiConfig.baseUrl`. (Only external
      deep links like instagram/tiktok/apple may be literal.)
- [ ] No hardcoded IDs/emails/names/sample records in production paths. (Known
      offender: mock data in
      `lib/features/collaboration/providers/collaboration_detail_provider.dart` —
      never extend the mock pattern; fetch from the API.)
- [ ] No hardcoded city/category/business-type/community-type lists — fetch from
      `/cities`, `/business-types`, `/community-types`, etc. **See
      [`docs/CANONICAL-LISTS.md`](docs/CANONICAL-LISTS.md)** for the authoritative
      endpoint+provider per taxonomy. `_mock*` fallbacks stay behind an
      off-by-default flag and must never shadow a successful API call.
      ⚠️ **`enum CommunityType {greek,fitness,running,business,other}` in
      `community/models/community.dart` is a PLACEHOLDER** — it does NOT match the
      real `/community-types` and collapses unknowns to `other`. Never use it for
      filtering/matching/ranking/interests; use the dynamic `communityTypesProvider`
      (`onboarding/models/community_type.dart`, a different `CommunityType`).
- [ ] No invented role logic — role rules come ONLY from the two ROLES docs.
- [ ] No magic status/type strings — reuse the enums (`ApplicationStatus`,
      `CollaborationStatus`, `UserType`) and their `fromString`/`toApiValue` mappers;
      match the backend's snake_case wire values exactly. (Status/role enums are
      stable wire contracts; user-pickable TAXONOMIES are not — see canonical lists.)
- [ ] Design tokens come from `lib/config/theme/` + `lib/config/constants/` — never
      raw hex or magic numbers.

### Verify paths/symbols exist before relying on them
Parts of the docs are stale. Before citing a file, route, endpoint or symbol, confirm
it exists in the current tree. Known stale refs: the `.agent/{todo,inprogress,sop}/`
folders below do NOT exist (only `documentations/`, `done/`, `task/`); dependency
versions in prose may lag `pubspec.yaml`.

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
- **State Management:** Riverpod 3.x (`flutter_riverpod ^3.2.0` — verify in `pubspec.yaml`)
- **Backend:** Laravel REST API + Sanctum Bearer tokens. Base URL is the single
  source of truth in `lib/config/constants/api.dart` (`ApiConfig.baseUrl`,
  currently `https://kolabing.com/api/v1`). NOT Supabase — `supabase_flutter` is
  listed in pubspec but is UNUSED; do not write Supabase client/query/auth code.
- **Navigation:** GoRouter `^17.0.1` (flat `GoRoute`s, not `StatefulShellRoute`;
  the bottom nav is an `IndexedStack` inside each role's main screen)
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

2. **Bottom nav:** Both roles have the SAME 4 tabs — Home, Explore, My Kolabs, Profile (only the My Kolabs icon differs: briefcase for business, star for community). The former standalone "Applications" tab was merged into My Kolabs, which is a 4-sub-tab hub (`MyKolabsHubScreen`): **Offers** (role-specific list) · **Requests** (the absorbed Applications screen, embedded) · **Active** (scheduled/in-progress collaborations) · **Finished** (completed/cancelled). Nav is an `IndexedStack` in `business_main_screen.dart` / `community_main_screen.dart`; the legacy `/business/applications` & `/community/applications` routes still resolve (they open My Kolabs with the Requests sub-tab preselected).

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