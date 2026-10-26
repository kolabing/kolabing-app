# CLAUDE.md

Guidance for Claude Code in this repository. Templates, command examples and diagrams live in [`docs/CLAUDE-REFERENCE.md`](docs/CLAUDE-REFERENCE.md) (not auto-loaded).

---

## CONTRIBUTOR ROUTING — Volkan → Reverb real-time ticket

Trigger: the user is **Volkan** (introduces himself, or git user / commit author is volkanoluc@gmail.com), OR asks about **Reverb, WebSockets, real-time chat, broadcasting, or live messages**.
- BEFORE anything else, read and surface [`docs/tickets/2026-06-05-reverb-realtime-chat-VOLKAN.md`](docs/tickets/2026-06-05-reverb-realtime-chat-VOLKAN.md). It is his assigned task (turn on real-time chat: ops daemons + Flutter Echo client).
- Lead with a short summary of where the ticket stands and what is next. Then help with it.

---

## MUST FOLLOW — Ticket → Branch → Description BEFORE any development (every task)

No code before a tracked ticket and a dedicated branch exist. For **every** feature, fix, refactor or chore, IN ORDER:
1. **Open a GitHub Projects ticket FIRST.** Create an issue in `kolabing/kolabing-app` and add it to the **Kolabing Engineering** board (`gh project item-add 4 --owner kolabing --url <issue-url>`).
2. **Write the task description in the ticket**: goal, current state, concrete work items (checklist), acceptance criteria. An empty-body ticket is not ready. (Expected shape: issue #14 "Integrate Sentry…".)
3. **Open a dedicated branch** off up-to-date `master` (`feat/…`, `fix/…`, `refactor/…`, `chore/…`). Never commit straight to `master` (protected).
4. **Only then develop.** When done, open a PR with the mandatory template, linked to the ticket (`Closes #<n>`).

If the user says "just fix/add X" without a ticket, create ticket + branch first, then proceed. Do not skip. Keep this rule in sync with the AGENTS.md workflow section.

---

## MUST FOLLOW — i18n is mandatory for EVERY new widget (no literal user-facing strings)

The app is localized via gen-l10n (`l10n.yaml`, `lib/l10n/app_{en,es,ca}.arb`, `AppLocalizations.of(context)`). A new screen/widget is **NOT done** until its strings exist in all three ARBs. For ANY user-facing text:
1. **Never hardcode** a user-facing string in `.dart` (no `Text('Create event')`, literal `labelText:`/`hintText:`/`SnackBar(content: Text('...'))`/dialog titles).
2. Add the key to `lib/l10n/app_en.arb`, then `app_es.arb` (**es = European/Castilian Spanish**: *Aforo* not *Capacidad* for venue cap, *Local/Lugar*, *Vídeos*) and `app_ca.arb` (**Catalan**). Run `flutter gen-l10n`.
3. Render via `AppLocalizations.of(context).<key>` (often aliased `l10n`). Counts/placeholders use ARB `placeholders` (ICU), not string interpolation.
4. **Only** exceptions: brand names ("Kolabing"), dynamic backend error text passed through, pure symbols/emoji.

If you see a literal while editing a file, fix it in passing. Add no new debt.

---

## MUST FOLLOW — Pull Request template is mandatory (every PR)

Every PR MUST use [`.github/pull_request_template.md`](.github/pull_request_template.md) and **fill every section**. A PR with empty sections is not ready for review and must not be merged. `master` is protected: changes land via PRs; only `olucvolkan` can merge.
1. **Fill all sections.** If one truly does not apply, write `N/A` + a one-line reason. Never delete the heading.
2. **Screenshots are mandatory for ANY design/UI change**: before/after, ideally iOS and Android. A UI PR without a screenshot must not be merged. Tick "no UI/design change" only when there is genuinely no visual change.
3. **"How to test" must be reproducible**: affected role (Business/Community/Attendee), test account/data, numbered steps, expected result.
4. **State production needs** (env/secret, backend deploy/migration, new App Store/Play Store build, feature flag, third-party setup) or write "Nothing extra".
5. Tick the **Definition of Done**: `flutter analyze` clean, `dart format` applied, tested on iOS AND Android, i18n in all three ARBs, no hardcoded values, `BACKLOG.md` updated.

Keep this section, `.github/pull_request_template.md` and the AGENTS.md PR section in sync. Change one → change the others.

---

## MUST READ — Backend schema (before any data/model/API/DB change)

Read [`docs/BACKEND-SCHEMA.md`](docs/BACKEND-SCHEMA.md) before changing data, models, API payloads, JSON keys or the database. It documents the **real production Postgres schema** (Laravel backend, db `main`). Hard rules:
- **Never invent columns, tables or enum values.** Not in that doc (or the live schema) = does not exist. Verify before relying on a field.
- **Never hardcode** IDs, emails, city/category names or sample records in app code; fetch from the API. Identity lives in `profiles` (+ `business_profiles` / `community_profiles`), NOT `users`.
- Lifecycle: `collab_opportunities → applications → collaborations` (+ reviews / feedback). `GET /collaborations` is viewer-scoped. The business paywall is backend-enforced; never bypass it client-side.

---

## MUST READ — Backlog (every session, before anything else)

At session START, read [`BACKLOG.md`](BACKLOG.md) and list its contents to the user (New Features, Incomplete Features, Fixes). It is the single source of truth for outstanding work. You MUST keep it in sync per its "Maintenance rules":
- New Feature you begin → move to **Incomplete Features**.
- Incomplete Feature verified working end-to-end → remove it.
- Bug you detect → add to **Fixes** immediately. Once **confirmed** fixed (tested, not just written), strike it through with the date, then remove later.
- Update the `Last updated:` date on every edit.

---

## MUST READ — Roles & Permissions (before planning OR executing changes)

Before planning or coding anything touching **user roles, permissions, the paywall, the Explore feed, profiles, onboarding, or the create/apply flows**, read BOTH (kept in sync with backend repo `kolabing-v2`):
1. [`docs/ROLES-AND-PERMISSIONS.md`](docs/ROLES-AND-PERMISSIONS.md) — authoritative *what* Business and Community users can see and do.
2. [`docs/ROLES-BACKEND-DB-MAP.md`](docs/ROLES-BACKEND-DB-MAP.md) — authoritative *where*: rule → backend code + DB tables/columns, and every known role-handling mistake.

Non-negotiable:
- **Communities are 100% free and are NEVER paywalled or blocked.**
- The paywall is Business-only, on exactly two actions: create a collaboration, apply to a Kolab.
- A free business gets a **blur** of the community's name+logo on Explore, never a hard block.
- "Opportunity" (community-created) and "collaboration" (business-created) are distinct. Never merge them.
- Most regressions come from applying one role's rules to the other. If a fix seems to contradict these docs, STOP and ask before changing role behaviour.

---

## MUST READ — Architecture grounding (before planning OR executing ANY change)

Ground every change in the REAL architecture and intended UX. Do NOT rely on memory or this file's prose; verify against the source. When prose and code disagree, the **code wins**, and fix the prose.

### Authoritative sources (read the relevant one)
1. Roles / permissions / paywall / Explore / onboarding / create-apply → the two ROLES docs (mandatory above).
2. Backend / API contract → `lib/config/constants/api.dart` (the ONE base URL), `api_integration_documentations/docs/MOBILE_APP_INTEGRATION_GUIDE.md` + `MOBILE_API_DOCUMENTATION.md`. Per-feature contracts: `.agent/documentations/api-*.md`, `docs/api/`.
3. User journey / feature behaviour → there is NO single journey doc. Reconstruct from `lib/features/<feature>/` (models = the state machine, services = the endpoints), then the plan/spec in `docs/plans/`, `docs/superpowers/{plans,specs}/`, `.agent/documentations/`. Kolab lifecycle: `lib/features/application/models/application.dart`, `lib/features/collaboration/models/collaboration.dart`, `.agent/documentations/api-collaboration-detail-spec.md`, `CHANGELOG.md`.

### The backend is Laravel, NOT Supabase
- Laravel REST API with **Sanctum Bearer tokens**. Build every URL from `ApiConfig.baseUrl`. Every service uses `package:http` with `'Authorization': 'Bearer $token'` (token from `AuthService.getToken()`).
- `supabase_flutter` is in pubspec but UNUSED. Never add Supabase client/RLS/realtime/query/auth code. If a task seems to need Supabase, STOP: it belongs as a Laravel endpoint.

### Do NOT hardcode — checklist (verify before committing)
- [ ] No hardcoded base URLs/hosts; derive from `ApiConfig.baseUrl`. (Only external deep links like instagram/tiktok/apple may be literal.)
- [ ] No hardcoded IDs/emails/names/sample records in production paths. Known offender: mock data in `lib/features/collaboration/providers/collaboration_detail_provider.dart`. Never extend the mock pattern; fetch from the API.
- [ ] No hardcoded city/category/business-type/community-type lists; fetch from `/cities`, `/business-types`, `/community-types`, etc. See [`docs/CANONICAL-LISTS.md`](docs/CANONICAL-LISTS.md) for the endpoint+provider per taxonomy. `_mock*` fallbacks stay behind an off-by-default flag and must never shadow a successful API call.
- [ ] ⚠️ `enum CommunityType {greek,fitness,running,business,other}` in `community/models/community.dart` is a PLACEHOLDER: it does NOT match real `/community-types` and collapses unknowns to `other`. Never use it for filtering/matching/ranking/interests. Use the dynamic `communityTypesProvider` (`onboarding/models/community_type.dart`, a different `CommunityType`).
- [ ] No invented role logic. Role rules come ONLY from the two ROLES docs.
- [ ] No magic status/type strings. Reuse the enums (`ApplicationStatus`, `CollaborationStatus`, `UserType`) and their `fromString`/`toApiValue` mappers; match the backend's snake_case wire values exactly. (Status/role enums are stable wire contracts; user-pickable TAXONOMIES are not; see canonical lists.)
- [ ] Design tokens come from `lib/config/theme/` + `lib/config/constants/`. Never raw hex or magic numbers.

### Verify paths/symbols exist before relying on them
Parts of the docs are stale. Before citing a file, route, endpoint or symbol, confirm it exists in the current tree. Known stale refs: `.agent/{todo,inprogress,sop}/` do NOT exist (only `documentations/`, `done/`, `task/`); dependency versions in prose may lag `pubspec.yaml`.

---

## 🤖 Agent Workflow System

All development work MUST go through the AI agent task workflow.
- `.agent/` folders: `documentations/` (docs, API specs, design docs), `todo/` (waiting), `inprogress/` (active, max 1), `done/`, `sop/` (SOPs & error logs), `task/` (templates, references), `README.MD` (system docs).
- Lifecycle: `todo/` → `inprogress/` → `done/` (create → execute → complete).
- Agents: `@ui-designer` (UI/UX design, user flows, wireframes, component specs, states); `@flutter-expert` (Flutter implementation, state management, API integration, widgets).

### Slash commands
**IMPORTANT:** All development work MUST use these commands. Do NOT write code without creating a task first. Examples: see reference.
- `/mobile-tasks <api-file>` — main workflow: reads the API integration file, analyzes endpoints, creates all tasks, executes them in order (API Analysis → Task Creation → UX Design → Flutter Implementation → Done).
- `/mobile-feature <description>` — single feature (optional `--api="/path"`).
- `/mobile-fix <description>` — bug fix, minimal changes only.
- `/mobile-refactor <description>` — improve code quality without changing functionality.
- `/mobile-ui <description>` — UI-only, no API integration.

### ⚙️ Command execution rules
1. Always create a task first. No direct code changes without a task file (template: reference).
2. One task at a time: only one task in `inprogress/`.
3. `@ui-designer` designs first, then `@flutter-expert` implements.
4. Update the task file with progress.
5. Move tasks `todo/` → `inprogress/` → `done/`.
6. Log errors to `.agent/sop/`.

---

## 📱 Project Overview

Kolabing is a Flutter mobile app (iOS & Android): a collaboration marketplace connecting businesses with communities for partnership opportunities.

## Build & Development Commands

```bash
flutter pub get
flutter run [-d chrome | -d ios | -d android]
flutter build apk | appbundle | ipa | web      # appbundle = Play Store
flutter test [test/path/file_test.dart]
dart analyze
dart format lib/
dart fix --apply
```

## Tech Stack

- **Framework:** Flutter (Dart).
- **State:** Riverpod 3.x (`flutter_riverpod ^3.2.0`; verify in `pubspec.yaml`).
- **Backend:** Laravel REST API + Sanctum Bearer tokens. Base URL single source of truth: `lib/config/constants/api.dart` (`ApiConfig.baseUrl`, currently `https://kolabing.com/api/v1`). NOT Supabase (see above).
- **Navigation:** GoRouter `^17.0.1`: flat `GoRoute`s, not `StatefulShellRoute`; bottom nav is an `IndexedStack` inside each role's main screen.
- **Forms:** flutter_form_builder + form_builder_validators. **Icons:** Lucide Icons.

## Architecture

- **User types:** Business (post opportunities, browse communities, manage incoming applications); Community (browse opportunities, apply for sponsorships, manage sent applications). Role-based navigation.
- **`lib/` layout:** `main.dart`; `config/theme/` (KolabingColors, KolabingTypography, ThemeData); `config/routes/` (GoRouter); `config/constants/` (KolabingSpacing, KolabingRadius, KolabingLayout); `features/` (auth, onboarding, business, community; full original tree in reference); `widgets/` (reusable buttons, inputs, cards, badges, nav); `services/` (Supabase, notifications); `utils/` (animations, transitions).
- **Routes:** auth screens use dark theme (black background); main app uses light theme. `/auth/*`, `/business/*`, `/community/*`, shared detail `/opportunity/:id`, `/collaboration/:id`, `/application/:id`.

## Design System Reference

Single source of truth: **`lib/config/theme/colors.dart`** (`KolabingColors`) and **`lib/config/theme/typography.dart`** (`KolabingTypography`), NOT prose here or in README.md/DESIGN.md. Code wins. Key values ("Atmospheric Editorial" palette):
- Primary `#FFE28C` (warm yellow). Always dark ink `#19150F` on yellow.
- Background `#FAF5EA` (warm parchment). Surface `#FFFFFF`. Text primary `#1C1C16` (ink `#19150F` on-surface). Success `#56624D`. Error `#BA1A1A`.
- Type via `google_fonts` (no bundled `.ttf`): Display/Headlines **Anton** (uppercase, editorial); Body/Labels/Buttons **Inter**.
- Button 52dp high, radius 12dp. Input 52dp (dark) / variable (light), radius 12dp (dark) / 8dp (light). Card radius 16dp. Touch targets min 48x48dp.

## Key Implementation Notes

1. **Auth state flow:** check onboarding completion → check auth state → route to the dashboard for `user_type`.
2. **Bottom nav:** each role has **5** tabs. Shared first 4: Home, Explore, My Kolabs, Chats. 5th: Business = **Profile**; Community = **Community** (leader's community hub; community/attendee standalone Profile is now a pushed screen). My Kolabs icon: briefcase (business), star (community).
   - The old "Applications" tab is merged into My Kolabs, a 4-sub-tab hub (`MyKolabsHubScreen`): **Offers** (role-specific list) · **Requests** (embedded Applications screen) · **Active** (scheduled/in-progress collaborations) · **Finished** (completed/cancelled).
   - Nav is an `IndexedStack` in `business_main_screen.dart` / `community_main_screen.dart`. Legacy `/business/applications` & `/community/applications` still resolve (open My Kolabs on Requests).
3. **Profile completion:** optional post-registration flow (photo, city, category, social links).
4. **Animations:** default 300ms transitions, 200ms for tabs, shimmer for loading states.
