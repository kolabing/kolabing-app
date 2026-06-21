# NF-21 — Attendee gamification hub (make the reward loop visible + earnable)

> Branch `gamification-members` (worktree, off `origin/master`). Daniel 2026-06-11.
> The whole loop is BUILT but orphaned. This is **surfacing + earn-loop wiring**, not
> a backend build — everything below already has a provider + a live endpoint.

## What already exists (reuse, do NOT rebuild)
- **Screens**: `BadgesScreen`, `RewardWalletScreen`, `SpinWheelScreen`, `StatsScreen`,
  `LeaderboardScreen`, `EventChallengesScreen`, `event_qr_code_screen`, `qr_scanner_screen`.
- **Providers**: `badge_provider`, `challenge_provider`, `checkin_provider`,
  `leaderboard_provider`, `reward_provider`, `stats_provider`.
- **Endpoints (live)**: `GET /me/gamification-stats`, `/me/badges`, `/me/rewards`,
  `/me/challenge-completions`, `GET /challenges`, `POST /challenges/initiate`,
  `POST /challenge-completions/{id}/verify`, `POST /checkin`, `/events/{id}/challenges`,
  `/events/{id}/checkins`, `/events/{id}/leaderboard`, `/events/{id}/rewards`,
  `/leaderboard` + `/leaderboard/global`, `/reward-claims`, `GET /gamification/config`.

## The gap (verified)
- Orphaned: `BadgesScreen`/`RewardWalletScreen`/`SpinWheelScreen`/`StatsScreen` are
  referenced only by their own definitions — no nav reaches them.
- Attendee nav = Home·Communities·Chats·Scan; no Rewards surface.
- Home Points/Challenges/Events stats aren't tappable.
- No "+points earned" confirmation on check-in / challenge completion.

## Build plan
### 1. A reachable **Rewards hub** (the home of gamification)
A single `RewardsHubScreen` with a header (level + XP progress + points balance from
`stats_provider` / `GET /me/gamification-stats`) and segmented sections:
- **Missions** — active challenges (`challenge_provider` / `GET /challenges` +
  `/me/challenge-completions`): progress, "Start"/"Submit" → `initiate`/`verify`.
- **Badges** — `BadgesScreen` content (`GET /me/badges`): earned + locked grid.
- **Rewards** — `RewardWalletScreen` + `SpinWheelScreen` (`/me/rewards`, `/reward-claims`).
- **Leaderboard** — `LeaderboardScreen` (`/leaderboard` global + per-community).

### 2. Entry points (discoverability)
- **New `Rewards` bottom-nav tab** for attendees (Home·Communities·**Rewards**·Chats,
  Scan stays the modal action) — the hub's home. *(Alt: no new tab; reach the hub from
  home stats + profile only. Decide in the pitch.)*
- **Home stats tappable** — Points→hub Rewards, Challenges→hub Missions, Events→My Kolabs/events.
- **Home "Missions" preview card** — next 1–2 active challenges + "See all".
- **Profile** — level + badges + points row → hub.

### 3. Earn-loop confirmation (the dopamine)
- **Check-in** (Scan → `POST /checkin`): on success show a "**+X points · checked in!**"
  sheet (+ any badge unlocked). Refresh `stats_provider`/`badge_provider`.
- **Challenge complete** (`verify`): "**+X points**" toast + progress update.
- Verify the backend `xp_earn_rules` event types actually fire for attendee check-in /
  challenge / event-attendance (config from `GET /gamification/config`); if an event
  type is missing, flag it (backend follow-up) — don't fake client-side points.

## Rules
- i18n en/es/ca; design tokens only; reuse the existing screens/providers; self-gate
  any endpoint that 404s. 0 analyze errors. Pitch the IA (esp. the new-tab decision)
  before the full build.
