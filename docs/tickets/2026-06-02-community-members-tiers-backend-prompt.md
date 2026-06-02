# Backend prompt — Community Members + customisable tiers (NF-6, Phase 1)

> **Target repo:** `kolabing-v2` (Laravel + Sanctum, Postgres `main`).
> **App-side plan-of-record:** `kolabing-app/docs/plans/community-members-tiers-phase1.md`.
> **Read first:** both `ROLES-*` docs. This adds a NEW role surface — when done, update `ROLES-AND-PERMISSIONS.md` (§5 matrix + a new §9) and `ROLES-BACKEND-DB-MAP.md`, and bump both dates.
> Paste this to an agent working in `kolabing-v2`.

## Context & locked decisions

Generalise the `attendee` user type into **Community Members** and let a **Community Leader** (the `community` user type) run a membership org with a roster and a per-community, leader-defined **tier system**. Community-agnostic (Greek life, fitness, run clubs, business comms).

- **D1 — tier ⟂ admin:** a tier is the member-facing status ladder. "Can manage" is a **separate `can_manage` boolean** on the membership, granted independently. Do NOT couple the top tier to admin power.
- **D2 — multi-community:** a member belongs to many communities, one tier per community. Tier lives on the membership row.
- **D3 — tier payload:** a tier carries a flexible JSON `permissions` blob (visibility scopes, future chat channels, perks, capabilities). Phase 1 stores + returns it; gating enforcement comes later.
- **D4 — wire value:** `profiles.user_type` stays `attendee`. "Community Member" is an app label only. Do NOT add/rename a user_type enum value.
- **D5 — free vs premium:** **one community free per leader.** Creating a 2nd+ community returns a paywall-style error reserved for **NF-7 Community Premium** (not yet built — for now hard-cap at 1 and return a clear `community_limit_reached` error). This is a NEW gate; **do NOT reuse `Profile::hasActiveSubscription()` / the business paywall** — that gate is business-only (ROLES §6, DB-MAP §3).
- **Join model:** communities have a `join_policy` of `open` (members may self-join AND leader may invite) or `invite_only` (leader/`can_manage` add only). Default `open`.
- **Cash-out:** v1 tiers carry status + non-cash perks only. Do NOT wire tiers into `wallets`/`withdrawal_requests`.

## Migrations (new tables — uuid PKs, match existing profile FK style)

### `communities`
- `id` uuid PK
- `owner_profile_id` FK → `profiles` (the Community Leader; constrain, cascade per repo convention)
- `community_profile_id` FK → `community_profiles` NULL (optional marketplace face)
- `name` string, `slug` string unique, `type` enum/string (`greek|fitness|running|business|other`), `description` text NULL, `avatar_url` string NULL
- `is_primary` bool default true (the free one)
- `join_policy` string (`open|invite_only`) default `open`
- timestamps, soft delete if repo uses it

### `community_tiers`
- `id` uuid PK
- `community_id` FK → `communities` (cascade)
- `name` string, `rank` int (ascending = higher), `color` string NULL
- `assignment_rule` string (`manual|xp_threshold|tenure|events_attended`)
- `threshold` int NULL (XP amount / days / event count, per rule; null for manual)
- `permissions` json NULL (flexible: `{view:[], chat_channels:[], perks:[], capabilities:[]}`)
- `is_default` bool default false (tier new joiners land in; enforce exactly one default per community)
- timestamps

### `community_members`
- `id` uuid PK
- `community_id` FK → `communities` (cascade)
- `profile_id` FK → `profiles` (the member; an attendee account)
- `tier_id` FK → `community_tiers` NULL (null until evaluated/assigned)
- `can_manage` bool default false
- `status` string (`active|inactive|removed`) default `active`
- `joined_at` timestamp, `tier_assigned_at` timestamp NULL
- timestamps
- **UNIQUE (`community_id`, `profile_id`)**

Driver-portable (the repo runs sqlite in tests — avoid raw ALTER COLUMN; use the shadow-column pattern already used in the feedback-gate migration if you must change a column).

## Models / relationships
- `Community` (belongsTo owner `Profile`, optional `CommunityProfile`; hasMany `CommunityTier`, `CommunityMember`).
- `CommunityTier`, `CommunityMember`. Enums as PHP enums where the repo already does (mirror `BadgeMilestoneType` style).

## Endpoints (`routes/api.php`, `auth:sanctum`)
- `POST /communities` — create. **Enforce the 1-community free cap**; 2nd+ → 422 `community_limit_reached`. Auto-create a default tier (`is_default`).
- `GET /me/communities` — communities I own (leader).
- `GET /me/memberships` — communities I'm a member of + my tier in each.
- `GET /communities/{community}` · `PATCH /communities/{community}` (owner/`can_manage`).
- Tiers: `GET /communities/{community}/tiers` · `POST` · `PATCH /tiers/{tier}` · `DELETE /tiers/{tier}` (owner/`can_manage`). Reject deleting the default tier unless another is promoted.
- Roster: `GET /communities/{community}/members` (paginated; include member profile summary + tier) · `POST /communities/{community}/members` (invite/add) · `PATCH .../members/{member}` (set `tier_id` / `can_manage` / `status`) · `DELETE .../members/{member}`.
- Join: `POST /communities/{community}/join` — allowed only if `join_policy = open`; else 403 `invite_only`.

## Policies
- A `CommunityPolicy`: mutate tiers/roster/community requires `owner_profile_id == auth profile` OR a `community_members` row for that auth profile with `can_manage = true` and `status = active`.
- **Never** gate any of this on business subscription.

## Tier auto-assignment job
- Command `app:evaluate-community-tiers` (cron daily) + evaluate-on-event hooks (on check-in / XP award) for the member affected.
- For each member, pick the highest-`rank` tier whose rule is satisfied:
  - `xp_threshold` → member XP (from `point_ledger`/`wallets`) ≥ `threshold`
  - `tenure` → `now - joined_at` ≥ `threshold` days
  - `events_attended` → count of `event_checkins` for events in THIS community ≥ `threshold`
  - `manual` tiers are never auto-applied (leader-set only) and are never auto-overwritten.
- Set `tier_id` + `tier_assigned_at`. Make the threshold source align with NF-5's `GET /gamification/config` rather than hardcoding, if that ships first.

## Resource shape (for the app)
`CommunityResource`: id, owner_profile_id, community_profile_id, name, slug, type, description, avatar_url, is_primary, join_policy, member_count, timestamps.
`CommunityTierResource`: id, community_id, name, rank, color, assignment_rule, threshold, permissions, is_default, timestamps.
`CommunityMemberResource`: id, community_id, profile_id, tier (nested tier or tier_id), can_manage, status, joined_at, tier_assigned_at, + member profile summary (name, avatar_url).

## Acceptance criteria
1. A community user can create exactly ONE community free; the 2nd returns `community_limit_reached` (no business-paywall code path touched).
2. Leader can CRUD tiers (manual/xp/tenure/events) and there is always exactly one default tier.
3. Members can be added (invite) and, when `join_policy=open`, self-join; `invite_only` blocks self-join.
4. `can_manage` is independent of tier; a non-top-tier member with `can_manage` can administer.
5. Auto-assignment promotes by the highest satisfied rule; manual tiers are untouched by the job.
6. Tests cover the cap, the policy, each rule, and the join policy. No attendee/community path ever calls the business paywall gate.
7. ROLES docs updated (matrix + new section) and dated; mirror into the `kolabing-app` copies.
