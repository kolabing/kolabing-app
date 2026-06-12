# Community gamification — rewards, goals, badges, tiers (shared contract)

> Branch `gamification-members` (already has the night-mode `context.colors` theme).
> Daniel confirmed 2026-06-12. Build P1 (backend) + P2 (app restructure) against this.

## Currencies (locked)
- **XP = GLOBAL.** One balance, drives the app-wide level/tier. Redeemable for
  **Kolabing partner rewards** ("Redeem your XP" — **coming soon**, build the surface
  + a disabled CTA; `partner_rewards` table read-only for now).
- **Points = PER-COMMUNITY.** Earned & spent inside each community. The community
  **leaderboard ranks by points**. Earning a community's points (check-in / goal /
  challenge) ALSO awards global XP (reuse `xp_earn_rules`).

## Tabs (community screen) — Daniel confirmed
**REWARDS** (goals · rewards · badges — NO tiers) · **MEMBERS** (roster grouped by
tier + tier management) · **EVENTS** (event PP + attendee-view). **Chats** is a LINK
to the chat screen, not a tab.

## P1 — Backend (kolabing-v2, theme-agnostic)
Tables (guarded migrations):
- `community_goals` — community_id, title, **earn_type** (`event_check_ins` | `challenge` | `days_in_community`), target (int), reward_points (int), challenge_id (nullable, when earn_type=challenge), is_active.
- `community_rewards` — community_id, title, description, **cost_points** (int), stock (nullable int = ∞), is_active.
- `community_badges` — community_id, title, icon (key), **criteria_type** (`points_threshold` | `event_check_ins` | `days_in_community` | `challenges_completed`), criteria_value (int), challenge_ids (json, when criteria_type=challenges_completed), is_active.
- `community_points` — per (community_id, profile_id) balance + a `community_point_ledger` (entries: source, points, ref). (Per-community leaderboard already keys on community_id; back it with this.)
- `reward_redemptions` — community_id, profile_id, reward_id, points_spent, status, redeemed_at.
- `partner_rewards` — GLOBAL (admin-managed later): title, cost_xp, partner, is_active. Read-only endpoint for now.

Endpoints:
- **Leader CRUD** (manage-gated): `GET/POST /communities/{id}/goals`, `PUT/DELETE /goals/{id}`; same for `/rewards` + `/badges`.
- **Member read**: `GET /communities/{id}/rewards-hub` → `{ my_points, my_tier, goals:[{…progress}], badges:[{…earned}], rewards:[{…affordable}] }`.
- **Redeem**: `POST /communities/{id}/rewards/{rewardId}/redeem` → deduct points, create redemption (guard: enough points + stock).
- **Leaderboard**: extend `GET /communities/{id}/leaderboard` to include per-row **tier** + **badge count** + **points** (it already keys community_id).
- **Personal rewards**: `GET /me/rewards-overview` → `{ xp, partner_rewards:[…], communities:[{community, my_points, rewards:[…]}] }`.
- **Earn wiring**: on event check-in / goal completion / challenge verify → award that community's points (+ global XP via xp_earn_rules). Verify the event types fire.
- Expose `my_points` (+ `my_tier`) on `GET /communities/{id}`.

## P2 — App restructure (gamification-members worktree, context.colors)
- **Community screen** (`community_detail_screen`): tabs become **Rewards · Members · Events**; the old Chats tab → a **"Chats →" header action** that opens the chat screen (community-filtered). Remove the in-place chat tab.
- **Members tab**: roster **grouped by tier** (section headers: tier name · count; member rows show points; mark **★ You** in member view; leader rows editable). A **⚙ Tiers** action opens the **existing tier editor** (relocated here).
- **Rewards tab**: MEMBER = points card + goals(progress) + badges(earned/locked) + rewards(redeem); LEADER = `[+Goal][+Reward][+Badge]` + lists with edit/delete + the three **editor sheets** (criteria pickers per the contract). Self-gate on the new endpoints.
- **Events tab**: cards show the **event profile picture** + visibility badge; a **My-view/Attendee-view toggle** renders the list as an attendee sees it.

## P3 (next) — Personal Rewards Screen + Leaderboard entry + profile entry
- Leaderboard rows (tier·badges·points) → tap **self** → **Personal Rewards Screen**
  (`GET /me/rewards-overview`): top = **Redeem your XP (coming soon)**, then
  per-community reward sections. Attendee profile level/badges row → same screen.

## P4 (next) — Admin web (kolabing-v2, per ROLES §0.1)
All-community + global XP leaderboards, partner-reward catalog CRUD, oversight.

## Rules
i18n en/es/ca; **design tokens via `context.colors`** (night-mode theme — never raw
hex, never static `KolabingColors` in new code); self-gate new endpoints; community
types from `/community-types` only. 0 analyze errors; backend filtered tests green.
