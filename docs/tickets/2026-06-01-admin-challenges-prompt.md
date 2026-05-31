# PROMPT — Admin: manage gamification challenges (+ role-based defaults)

Hand this to the **admin-dashboard / backend agent** (`kolabing-v2`). Self-contained.

## Context — what the app already relies on (verified live 2026-06-01)
Kolabing has a working gamification "challenges" system used inside a collaboration
(the **Gamification Setup** card on the kolab detail screen):
- `GET /api/v1/challenges/system` → 200, ~48 real challenges. Each item:
  `{ id, name, description, difficulty (easy|medium|hard), points, is_system,
  category (e.g. "barcelona_vibe"), event_id, created_at, updated_at }`.
- `PUT /api/v1/collaborations/{id}/challenges` (body `{ selected_challenge_ids: [] }`)
  saves which system challenges apply to a collaboration; `POST` creates a custom
  one. (Both return 422 to empty/unauth — i.e. they exist.)
- DB: `challenges` (catalogue; `is_system`, `category`, `event_id`, `difficulty`,
  `points`) and `collaboration_challenges` (pivot: which challenges a collaboration
  selected). The app now reads `/challenges/system` for the selectable pool (it
  previously shipped hardcoded mock challenges — removed 2026-05-31).
- There is **no admin surface for challenges** — the catalogue can only be changed
  directly in the DB today.

## Goal
Add an admin CRUD for the challenge catalogue, and a way to define which challenges
are **default** for a collaboration based on the **business type** and/or
**community type** of its participants — so new collaborations start pre-populated
with sensible challenges instead of an empty/manual list.

## Build (matches the existing admin architecture)
Server-rendered **Blade + AdminLTE** inside Laravel 12, under `/admin/*`, behind
the `auth:admin + maintainer` guard; logic in a service under `app/Services/Admin/`;
validation via FormRequests; **no JS chart/JS framework** (vanilla forms — CSP is
strict, `script-src 'self' 'unsafe-inline'` + Tailwind CDN only).

1. **Challenge catalogue CRUD** — `app/Http/Controllers/Admin/ChallengeController.php`
   + views under `resources/views/admin/challenges/`:
   - `GET /admin/challenges` — list with filters (category, difficulty, is_system).
   - `create / edit / destroy` — fields `name, description, difficulty, points,
     category, is_system`. Only `is_system=true` rows are global; custom
     (collaboration-scoped) ones stay out of the global pool.
   - Sidebar entry under a new **"GAMIFICATION"** header in `config/adminlte.php`.

2. **Role-based default mapping** — new table + admin UI:
   - Migration `challenge_defaults`: `id`, `challenge_id` → challenges,
     `applies_to` enum `business_type|community_type`, `type_value` varchar (e.g.
     `coworking` / `run_club`), `position` int, timestamps; unique
     `(challenge_id, applies_to, type_value)`.
   - `GET /admin/challenges/defaults` — matrix: rows = business_types +
     community_types (from existing `business_types` / `community_types` lookups),
     columns = system-challenge checkboxes; saving writes `challenge_defaults`.
   - `app/Services/Admin/ChallengeDefaultsService.php` to read/write.

3. **Apply defaults when a collaboration forms** — in `CollaborationService`
   (where a collaboration is created on application-accept): seed
   `collaboration_challenges` from `challenge_defaults` matching the business's
   `business_type` and the community's `community_type`. Idempotent; participants
   can still add/remove later via `PUT /collaborations/{id}/challenges`.

4. **(Optional) expose defaults to the app** — add
   `?applies_to=business_type:coworking` filtering to `GET /challenges/system` so
   the app can highlight defaults. Not required for v1.

## Acceptance
- Maintainers can add/edit/remove system challenges from `/admin/challenges`
  (403 for non-maintainers; 302 to login when unauthenticated).
- Maintainers can set default challenges per business type and per community type.
- A new collaboration between e.g. a `coworking` business and a `run_club`
  community is pre-seeded with those types' defaults in `collaboration_challenges`.
- No CSP carve-outs; no JS lib added; tests cover route gating + defaults-seeding.

## Guardrails
- Don't break `GET /challenges/system` (the app depends on its exact shape above).
- Reuse `business_types` / `community_types` lookups; don't hardcode type lists.
- `challenges.category` is a free-ish slug (`barcelona_vibe`, …) — keep it a
  controlled vocabulary if you add a picker.
