# Change Note — My Kolabs merge, Kolab rename, Active/Finished wiring

**Date:** 2026-05-31 · **Branch:** `feat/app-redesign`

Summary of the work done in this session.

## 1. Navigation merge (5 → 4 tabs)
- Bottom nav reduced from 5 to **4 tabs** for both roles: Home · Explore · My Kolabs · Profile. The standalone **Applications** tab was removed.
- New hub [`lib/features/kolab/screens/my_kolabs_hub_screen.dart`](../lib/features/kolab/screens/my_kolabs_hub_screen.dart) hosts 4 internal tabs: **OFFERS · REQUESTS · ACTIVE · FINISHED** (yellow indicator, charcoal labels, per spec).
  - **Offers** = the existing role-specific list (`MyKollabsScreen` for business / `MyOpportunitiesScreen` for community), reused via a new `embedded` flag so there's no duplicate header/Scaffold.
  - **Requests** = the former Applications screen embedded (`ApplicationsScreen(embedded: true)`), keeping its SENT/RECEIVED sub-tabs.
  - **Active / Finished** = real collaboration lists (see §3).
- `business_main_screen.dart` / `community_main_screen.dart`: `IndexedStack` now has 4 children; the create-FAB shows on Home/Explore (and inside the Offers sub-tab), hidden on My Kolabs container + Profile.
- Legacy routes kept alive: `/business/applications` & `/community/applications` now open My Kolabs with the **Requests** sub-tab preselected (`initialTab: 2, initialKolabsSubTab: 1`). `applications_screen.dart` marked `@deprecated` (not deleted), per the handoff.

## 2. "Collab" → "Kolab" rename (visible text only)
- 61 user-facing strings across 33 files: `Collaboration(s)`→`Kolab(s)`, `COLLABORATION`→`KOLAB`, etc.
- **Deliberately NOT changed** (backend contracts): API paths like `/collaborations/{id}`, JSON keys (`would_collaborate_again`, `collab_opportunity`), notification type ids (`collab_day_reminder`), and all Dart identifiers/routes/file names. Changing those would break the Laravel API contract.

## 3. Active & Finished tabs wired to real data (no hardcoding)
- Confirmed live base URL: **`https://kolabing.com/api/v1`** (the `api.` variant is unreachable).
- Discovered the list endpoint by probing with a real token: **`GET /collaborations`** (returns the viewer's collaborations; `?status=` accepts a single value only, so we fetch unfiltered and partition client-side).
- New [`lib/features/collaboration/providers/collaborations_list_provider.dart`](../lib/features/collaboration/providers/collaborations_list_provider.dart): `collaborationsListProvider` + derived `activeCollaborationsProvider` (scheduled / active / pending_confirmation) and `finishedCollaborationsProvider` (completed / cancelled). Reuses the existing `normalizeCollaborationResponse` mapper (renamed from the private `_normalize…`) so list items map to the same `Collaboration` model as the detail screen.
- New [`lib/features/collaboration/widgets/collaborations_list_tab.dart`](../lib/features/collaboration/widgets/collaborations_list_tab.dart): cards (partner names, date/time, status badge), loading/error/empty states, pull-to-refresh, tap → `/collaboration/{id}`.
- Matches the intended lifecycle: **accepted (both sides) → Active; completed or cancelled → Finished.**

## 4. Requests bug fix (FX-1)
- Accepted applications are now filtered out of both Requests sub-lists (Sent + Received) — they graduate to Active. (`applications_screen.dart`.)

## 5. CLAUDE.md corrected (from architecture audit)
- Backend fixed: **Laravel REST + Sanctum**, not Supabase. Riverpod 3.x, GoRouter 17. Nav corrected to 4 tabs. Added a "MUST READ — Architecture grounding" section (authoritative sources, do-not-hardcode checklist, verify-paths-exist rule) and a "MUST READ — Backlog" section.

## 6. New BACKLOG.md
- Three sections (New Features / Incomplete Features / Fixes) with maintenance rules; CLAUDE.md now requires reading it each session. Seeded with the three new features (community member update, map update, geolock check-in).

## Status / still open
- **Verified:** `flutter analyze` clean on all touched files; app builds for the iOS simulator.
- **Pending:** on-device visual QA of the hub (simulator boot has been flaky this session); seeding 6 test kolabs (both logins now work — Eixample46 business + Real Run Club community).
