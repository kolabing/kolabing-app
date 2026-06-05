# Backend prompt — Community Members + customisable tiers (NF-6, Phase 1)

> **Target repo:** `kolabing-v2` (Laravel + Sanctum, Postgres `main`).
> **App-side plan-of-record:** `kolabing-app/docs/plans/community-members-tiers-phase1.md`.
> **Read first:** both `ROLES-*` docs. This adds a NEW role surface — when done, update `ROLES-AND-PERMISSIONS.md` (§5 matrix + a new §9) and `ROLES-BACKEND-DB-MAP.md`, and bump both dates.
> Paste this whole file to an agent working in `kolabing-v2`. §0 is the context; §1+ is the spec.

---

## 0. Context — what this feature is, where it lives, and how the app uses it

### 0.1 The feature in one paragraph
Kolabing is a marketplace connecting **businesses** and **communities** for recurring event collaborations, with a gamified **attendee** layer. This feature gives a **Community Leader** the tooling to run a real membership organisation: a **member roster** and a **per-community, leader-defined tier system** (a status ladder like "Exec / Active / Pledge", or "Captain / Regular / Newbie", or "Coach / Member / Trial"). It is **community-agnostic** — Greek life (sororities/fraternities) is the launch inspiration, but it must serve fitness studios, running clubs, and business communities equally. Kolabing ships the *mechanism* (tiers + rules); the leader supplies the *meaning* (names + thresholds).

### 0.2 The platform you are plugging into (verified current state)
- **Auth & roles:** Laravel + Sanctum bearer tokens. `profiles.user_type` is an enum: `business | community | attendee`. Read via `Profile::isBusiness()` / `isCommunity()` / `isAttendee()`. Detail rows: `business_profiles`, `community_profiles`, `attendee_profiles` (each 1:1 with a `profile`).
- **Marketplace lifecycle (do not touch):** `collab_opportunities → applications → collaborations`. The **business paywall** gates exactly two actions (create a collaboration, apply to a kolab) and is enforced as `if ($profile->isBusiness() && ! $profile->hasActiveSubscription())`. It is **business-only** and must never be copied into community/attendee paths.
- **Gamification track is LIVE** (this feature reuses it, does not rebuild it): `attendee_profiles` (`total_points`, `total_events_attended`, …), `wallets`, `point_ledger` (append-only), `challenges` + `challenge_completions`, `badges` + `badge_awards`, `event_checkins`, plus endpoints for check-in (`POST /checkin`), leaderboards (`GET /leaderboard/global`, `GET /events/{event}/leaderboard`), badges, and gamification stats.
- **The gap this fills:** `community_profiles` is a **single account** (1:1 with a profile). There is **no roster, no member↔community link, and no sub-role/tier concept anywhere today.** This feature introduces all three.

### 0.3 Where this surfaces in the app (UI placement & the two roles)
- **Community Leader = the `community` user type.** In the app their shell is `community_main_screen.dart` with a 4-tab bottom nav (Home / Explore / My Kolabs / Profile). This feature **adds a new "Community" tab** = the roster + tier-management surface (create the community, define tiers + rules, invite/approve members, assign/auto-assign tiers, view member activity). The "+ create another community" CTA is where **NF-7 Community Premium** will gate; for now the backend hard-caps at one.
- **Community Member = the `attendee` user type** (relabelled "Community Member" in UI copy only; the wire value stays `attendee`). Their shell is `attendee_main_screen.dart` (Home / Scan / Profile) with the live gamification UI. This feature **adds community context**: which communities they belong to, their **tier in each**, and (later phases) tier-gated content/chat. A **chapter-scoped leaderboard** (the global leaderboard filtered to one community) is part of the member surface.
- **The Greek "exec/active/pledge" tiers from the design mockups are NOT special-cased** — they are simply three tiers a leader configured. The app renders whatever tiers the leader defines, in `rank` order, with their `name`/`color`.

### 0.4 The exact wire shapes the app already expects
The app has scaffolded the Dart models (`kolabing-app/lib/features/community/models/{community,community_tier,community_member}.dart`). Your API Resources must serialise to these shapes **field-for-field** (snake_case keys, these enum string values). Sample payloads:

**Community** (`GET /communities/{id}`, items in `GET /me/communities`):
```json
{
  "id": "uuid", "owner_profile_id": "uuid", "community_profile_id": "uuid|null",
  "name": "Kappa Delta — Beta Chi", "slug": "kd-beta-chi",
  "type": "greek",                       // greek|fitness|running|business|other
  "description": "string|null", "avatar_url": "url|null",
  "is_primary": true,
  "join_policy": "open",                 // open|invite_only
  "member_count": 84,
  "created_at": "ISO8601", "updated_at": "ISO8601"
}
```

**CommunityTier** (`GET /communities/{id}/tiers`):
```json
{
  "id": "uuid", "community_id": "uuid", "name": "Exec", "rank": 3, "color": "#FFD861|null",
  "assignment_rule": "manual",           // manual|xp_threshold|tenure|events_attended
  "threshold": null,                     // int for xp/tenure(days)/events; null for manual
  "permissions": { "view": [], "chat_channels": [], "perks": [], "capabilities": [] },
  "is_default": false,
  "created_at": "ISO8601", "updated_at": "ISO8601"
}
```

**CommunityMember** (`GET /communities/{id}/members`):
```json
{
  "id": "uuid", "community_id": "uuid", "profile_id": "uuid",
  "tier": { /* CommunityTier */ },       // app also accepts flat "tier_id": "uuid|null"
  "can_manage": false,                   // ORTHOGONAL admin flag (see D1)
  "status": "active",                    // active|inactive|removed
  "joined_at": "ISO8601", "tier_assigned_at": "ISO8601|null",
  "profile": { "name": "Brooke M.", "avatar_url": "url|null" },  // app also accepts flat name/avatar_url
  "created_at": "ISO8601", "updated_at": "ISO8601"
}
```
The app parser tolerates both nested (`tier`, `profile`) and flat (`tier_id`, `name`, `avatar_url`) forms; **prefer nested for the roster list** so one call renders fully.

### 0.5 End-to-end journeys (which endpoint each step hits)
1. **Leader creates a community** → `POST /communities` → a default tier is auto-created (`is_default=true`, rule `manual`). A 2nd community → `422 community_limit_reached`.
2. **Leader defines tiers** → `POST /communities/{id}/tiers` (name, rank, color, `assignment_rule`, `threshold`, `permissions`), `PATCH`/`DELETE` to edit.
3. **A person becomes a member** → either the leader invites/adds (`POST /communities/{id}/members`) or, if `join_policy=open`, the member self-joins (`POST /communities/{id}/join`). New members land in the default tier.
4. **Tiers auto-assign** → the nightly job + on-check-in/on-XP hooks promote each member to the highest `rank` tier whose rule is satisfied (manual tiers are leader-only and never auto-touched).
5. **Leader manages the roster** → `GET /communities/{id}/members`, `PATCH /communities/{id}/members/{member}` to set `tier_id` (manual promote), `can_manage`, or `status`.
6. **Member sees their standing** → `GET /me/memberships` returns each community + the member's tier in it; tier `permissions` will (later phases) drive content/chat visibility; the chapter-scoped leaderboard shows their rank within the community.

### 0.6 Reuse vs. net-new (and one linkage you must define)
- **Reuse (no new tables):** `point_ledger`/`wallets` feed the `xp_threshold` rule; `event_checkins` feed the `events_attended` rule; the existing leaderboard controller gains a `community_id` scope param for the chapter leaderboard.
- **⚠️ Linkage you must define — "this community's events":** the `events_attended` rule and the chapter leaderboard both need to know **which events belong to a community.** Today `events` carry a `profile_id` (organiser) but no community link, and a leader may own multiple communities. **Recommended:** add a nullable `events.community_id` FK and scope both the rule and the leaderboard by it. Surface your chosen approach in the PR; do not silently assume "organiser's events = the community's events".
- **Net-new:** the three tables below, their endpoints, `CommunityPolicy`, and the auto-assignment job.

---

## 1. Locked product decisions
- **D1 — tier ⟂ admin:** a tier is the member-facing status ladder. "Can manage" is a **separate `can_manage` boolean** on the membership, granted independently. Do NOT couple the top tier to admin power.
- **D2 — multi-community:** a member belongs to many communities, one tier per community. Tier lives on the membership row.
- **D3 — tier payload:** a tier carries a flexible JSON `permissions` blob (visibility scopes, future chat channels, perks, capabilities). Phase 1 stores + returns it; gating enforcement comes later.
- **D4 — wire value:** `profiles.user_type` stays `attendee`. "Community Member" is an app label only. Do NOT add/rename a user_type enum value.
- **D5 — free vs premium:** **one community free per leader.** Creating a 2nd+ community returns a paywall-style error reserved for **NF-7 Community Premium** (not yet built — for now hard-cap at 1 and return a clear `community_limit_reached` error). This is a NEW gate; **do NOT reuse `Profile::hasActiveSubscription()` / the business paywall** — that gate is business-only (ROLES §6, DB-MAP §3).
- **Join model:** communities have a `join_policy` of `open` (members may self-join AND leader may invite) or `invite_only` (leader/`can_manage` add only). Default `open`.
- **Cash-out:** v1 tiers carry status + non-cash perks only. Do NOT wire tiers into `wallets`/`withdrawal_requests`.

## 2. Migrations (new tables — uuid PKs, match existing profile FK style)

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

(Optional, per §0.6) `events.community_id` FK NULL → `communities`, if you adopt the recommended event-linkage.

Driver-portable (the repo runs sqlite in tests — avoid raw ALTER COLUMN; use the shadow-column pattern from the feedback-gate migration if you must change a column).

## 3. Models / relationships
- `Community` (belongsTo owner `Profile`, optional `CommunityProfile`; hasMany `CommunityTier`, `CommunityMember`).
- `CommunityTier`, `CommunityMember`. Enums as PHP enums where the repo already does (mirror `BadgeMilestoneType` style).

## 4. Endpoints (`routes/api.php`, `auth:sanctum`) — shapes in §0.4
- `POST /communities` — create. **Enforce the 1-community free cap**; 2nd+ → 422 `community_limit_reached`. Auto-create a default tier (`is_default`).
- `GET /me/communities` — communities I own (leader).
- `GET /me/memberships` — communities I'm a member of + my tier in each.
- `GET /communities/{community}` · `PATCH /communities/{community}` (owner/`can_manage`).
- Tiers: `GET /communities/{community}/tiers` · `POST` · `PATCH /tiers/{tier}` · `DELETE /tiers/{tier}` (owner/`can_manage`). Reject deleting the default tier unless another is promoted.
- Roster: `GET /communities/{community}/members` (paginated; nested tier + profile summary) · `POST /communities/{community}/members` (invite/add) · `PATCH .../members/{member}` (set `tier_id` / `can_manage` / `status`) · `DELETE .../members/{member}`.
- Join: `POST /communities/{community}/join` — allowed only if `join_policy = open`; else 403 `invite_only`.
- Leaderboard (reuse): add an optional `community_id` scope to the existing leaderboard endpoint for the chapter-scoped view.

## 5. Policies
- A `CommunityPolicy`: mutate tiers/roster/community requires `owner_profile_id == auth profile` OR a `community_members` row for that auth profile with `can_manage = true` and `status = active`.
- **Never** gate any of this on business subscription.

## 6. Tier auto-assignment job
- Command `app:evaluate-community-tiers` (cron daily) + evaluate-on-event hooks (on check-in / XP award) for the member affected.
- For each member, pick the highest-`rank` tier whose rule is satisfied:
  - `xp_threshold` → member XP (from `point_ledger`/`wallets`) ≥ `threshold`
  - `tenure` → `now - joined_at` ≥ `threshold` days
  - `events_attended` → count of `event_checkins` for events in THIS community (per the §0.6 linkage) ≥ `threshold`
  - `manual` tiers are never auto-applied (leader-set only) and are never auto-overwritten.
- Set `tier_id` + `tier_assigned_at`. Align the XP threshold source with NF-5's `GET /gamification/config` rather than hardcoding, if that ships first.

## 7. Resource shapes — see §0.4 for the canonical JSON the app consumes.

## 8. Acceptance criteria
1. A community user can create exactly ONE community free; the 2nd returns `community_limit_reached` (no business-paywall code path touched).
2. Leader can CRUD tiers (manual/xp/tenure/events) and there is always exactly one default tier.
3. Members can be added (invite) and, when `join_policy=open`, self-join; `invite_only` blocks self-join.
4. `can_manage` is independent of tier; a non-top-tier member with `can_manage` can administer.
5. Auto-assignment promotes by the highest satisfied rule; manual tiers are untouched by the job.
6. The community↔events linkage (§0.6) is implemented and documented; `events_attended` + chapter leaderboard scope by it.
7. API Resources match the §0.4 shapes field-for-field (the app is already coded to them).
8. Tests cover the cap, the policy, each rule, the join policy, and the event linkage. No attendee/community path ever calls the business paywall gate.
9. ROLES docs updated (matrix + new section) and dated; mirror into the `kolabing-app` copies.
