# Community Members + Customisable Tiers — Phase 1 Plan-of-Record

> Branch: `community-member-flow` · Backlog: **NF-6** (with NF-7 Community Premium, NF-8 Enterprise close behind).
> Grounding: `docs/ROLES-AND-PERMISSIONS.md` §5/§7, `docs/ROLES-BACKEND-DB-MAP.md` §11, `docs/BACKEND-SCHEMA.md`.
> Status: **design locked except ONE data-model fork (§3.1).** Backend ticket + app models are written once that fork is confirmed.

## 1. Goal

Generalise the existing `attendee` user type into **Community Members** and give a **Community Leader** (the `community` user type) the tooling to run a real membership organisation: a roster, and a **per-community, leader-defined tier system**. Community-agnostic by design — Greek life (the inspiration), fitness studios, run clubs, and business communities all map onto the same primitive. Kolabing ships the *mechanism*; the leader supplies the *meaning*.

## 2. Locked decisions

| # | Decision | Locked answer |
|---|---|---|
| D1 | Tier vs. admin power | **Orthogonal.** A tier is the customisable, member-facing status ladder. "Can manage this community" is a **separate `can_manage` capability** the leader grants to any member. Greek "exec" simply happens to also hold `can_manage`. |
| D2 | Multi-community | **A member can belong to many communities, holding one independent tier in each.** The tier lives on the *membership*, not the user. |
| D3 | What a tier DOES in v1 | **The full set:** a tier carries (a) a cosmetic identity (name, rank, colour/badge), (b) **content gating**, (c) **chat gating** (designed-for now even though chat itself lands later), and (d) **perks/permissions**. So a tier needs a flexible permission/visibility payload, not just a label. |
| D4 | Backend wire value | `attendee` enum value in `profiles.user_type` is **unchanged**; "Community Member" is a **UI label only** (per the no-rename-backend rule in CLAUDE.md). |
| D5 | Paywall posture | Communities remain **free**. The free tier = **one** community per leader. Creating a 2nd+ community is the **NF-7 Community Premium** gate — a brand-new gate surface, NOT the business paywall (which must never touch community/attendee paths — ROLES §6). |

## 3. Data model

### 3.1 THE ONE OPEN FORK — what is a "community" (the group)?

Today `community_profiles` is a **1:1 detail row on a `profile`** — one account *is* one community, and it is the marketplace identity that posts opportunities. But NF-7 requires **one leader owning multiple communities**, and a community-as-group needs members. Two ways:

- **Option A (recommended): dedicated `communities` table.** A `communities` row is the *group* (owner `profile_id`, name, type, avatar), optionally linked to a `community_profiles` row as its marketplace face. Members join `communities`. Cleanly supports premium (1 profile → N communities) and non-marketplace communities (a run club that never posts a kolab). For v1, auto-create one `communities` row per existing community account.
- **Option B: overload `community_profiles`.** Keep community = profile; "more communities" = let one leader own several `community_profiles`. Breaks the current 1:1 profile model and entangles marketplace identity with membership.

**Recommendation: Option A.** Everything below assumes it. **This is the single thing to confirm before the backend ticket is written.**

### 3.2 New tables (assuming Option A)

```
communities                     -- the group a leader owns
  id (uuid PK)
  owner_profile_id  FK profiles  -- the Community Leader
  community_profile_id FK community_profiles NULL  -- optional marketplace face
  name, slug, type (greek|fitness|running|business|other), description, avatar_url
  is_primary (bool)              -- the free one; gate 2nd+ behind NF-7
  created_at / updated_at

community_tiers                 -- per-community, leader-defined rungs
  id (uuid PK)
  community_id FK communities
  name, rank (int, order), color
  assignment_rule  enum(manual | xp_threshold | tenure | events_attended)
  threshold (int NULL)           -- XP amount / days / event count, per rule
  permissions (json)             -- flexible: visibility scopes, chat channels, perks, capabilities
  is_default (bool)              -- tier new joiners land in
  created_at / updated_at

community_members               -- the member <-> community link; carries the tier
  id (uuid PK)
  community_id FK communities
  profile_id   FK profiles       -- the member (an attendee account)
  tier_id      FK community_tiers NULL  -- null until assigned/evaluated
  can_manage   (bool, default false)    -- D1 orthogonal admin capability
  status       enum(active | inactive | removed)
  joined_at, tier_assigned_at
  UNIQUE (community_id, profile_id)
```

`permissions` as JSON keeps D3 flexible: e.g. `{"view": ["events","minutes"], "chat_channels": ["general","members"], "perks": ["partner_discount"], "capabilities": []}` — so chat-gating and content-gating hook in without a schema change when those surfaces ship.

### 3.3 Tier engine (the actual product)

Each tier has exactly one `assignment_rule`:
- `manual` — leader assigns/promotes by hand (the Greek "exec" case).
- `xp_threshold` — auto when member XP ≥ `threshold` (reuses live `point_ledger`/`wallets`).
- `tenure` — auto after `threshold` days in the community (from `joined_at`).
- `events_attended` — auto after `threshold` check-ins to *this community's* events (reuses live `event_checkins`).

Three of the four already have live backend plumbing. Net-new is only the **evaluation + auto-assignment job** (nightly + on relevant events) and the manual-assign endpoint.

## 4. Endpoints (proposed for the backend ticket)

- Communities: `POST /communities` (create; **gated to 1 free**, 2nd+ → NF-7), `GET /communities/{id}`, `PATCH /communities/{id}`, `GET /me/communities` (as leader), `GET /me/memberships` (as member).
- Tiers: `GET /communities/{id}/tiers`, `POST` / `PATCH` / `DELETE /communities/{id}/tiers/{tier}`.
- Roster: `GET /communities/{id}/members`, `POST /communities/{id}/members` (invite/add), `PATCH /communities/{id}/members/{member}` (set `tier_id` / `can_manage` / `status`), `DELETE`.
- Join: `POST /communities/{id}/join` (member self-join if open) and/or invite acceptance.
- Policies: tier/roster mutations require `owner` OR a member with `can_manage`. **Never** reuse the business-paywall gate.

## 5. App surfaces

- **Community Leader** (`community` user) gets a new **Community** bottom-nav tab (slots into `community_main_screen.dart`'s `IndexedStack`): create/manage the community, roster, define tiers + rules, assign/auto-assign, view member activity. The "+ create another community" CTA is where NF-7 gates.
- **Community Member** (`attendee` user): the existing `attendee_main_screen` (Home / Scan / Profile) gains community context — which communities they're in, their tier in each, tier-gated content. Reuse the live gamification UI (XP/badges/leaderboard/check-in); add a **chapter-scoped** leaderboard (existing leaderboard controller + a `community_id` scope param).
- Relabel "attendee" → "Community Member" in user-facing copy only.

## 6. Reuse vs. net-new

- **Reuse (no new tables):** `point_ledger`, `wallets`, `badges`, `event_checkins`, leaderboard endpoints (add chapter scope), the whole gamification UI.
- **Net-new backend:** `communities`, `community_tiers`, `community_members`, the auto-assignment job, roster/tier endpoints + tier-aware policies.
- **Net-new app:** Community tab + roster/tier-management screens + member-facing tier display; chapter-scoped leaderboard view.
- **Rides on:** NF-5's `GET /gamification/config` (so tier XP thresholds aren't hardcoded) — not a hard blocker for v1 but should align.

## 7. Phasing

1. **P1 — Chapter spine (this plan):** `communities` + `community_tiers` + `community_members`, roster + tier CRUD, the Community tab, manual + auto tier assignment, cosmetic tier display + leaderboard scoping.
2. **P2 — Gating:** wire tier `permissions` to actually hide/show content (the pledge "locked" screens) once there's content to gate.
3. **P3 — Chat:** when/if native chat ships, tier `chat_channels` gates it (decision still open from the earlier pitch — build vs. integrate vs. skip).
4. **NF-7 / NF-8:** Community Premium paywall (multi-community + advanced tooling); Enterprise managed-partnerships.

## 8. Still to confirm before code

1. **§3.1 fork — Option A (`communities` table) vs B (overload `community_profiles`).** Blocks the backend ticket. (Recommend A.)
2. Member join model: open self-join, invite-only, or both?
3. Attendee cash-out (still `[VERIFY]` in ROLES §7.3) — does a member's wallet redeem to cash, or status-only? Affects whether tiers can carry monetary perks in v1.
