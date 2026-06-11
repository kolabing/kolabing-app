# Member profile hub + Friends — update plan (NF-13 + NF-17)

> **Trigger:** tapping "View profile" on a community member opens a near-empty
> screen — name renders **"Unknown"**, only an empty "Past Kolabs" card. The
> public-profile stack is built for **business/community** profiles and has no
> concept of a **member** (attendee). This ticket fixes the bug and scopes the
> member social-hub profile + friends graph. Build order (Daniel 2026-06-10):
> **NF-13 social-hub → NF-9 languages → NF-17 friends → NF-14 DMs.**

---

## Root cause of "Unknown"

- App: `roster_screen.dart:357` pushes `/profile/{member.profileId}` →
  `PublicProfileScreen`. The route already accepts an optimistic `creatorProfile`
  via `state.extra` but the roster **passes nothing**, so nothing shows until the
  fetch returns.
- Backend: `GET /profiles/{id}` → `PublicProfileResource:46`
  `'display_name' => $extendedProfile?->name`. `getExtendedProfile()` returns the
  **attendeeProfile**, and `attendee_profiles` has **no `name` column** (only
  `total_points / total_challenges_completed / total_events_attended /
  global_rank`). An attendee's name lives on the base **`profiles`** table, which
  the resource never reads for attendees → `display_name = null` →
  `PublicProfile.fromJson` falls back to `'Unknown'`.
- App: `PublicProfile` model + `PublicProfileScreen` only render
  about / gallery / past **collaborations** / reviews / social links — all empty
  for a member, so the screen is bare.

---

## Phase 0 — make the member profile correct & reachable (small, do first)

**Backend (`kolabing-v2`):**
- `PublicProfileResource`: fall back `display_name` and `avatar_url` to the base
  `profiles` record for attendees (e.g. `$extendedProfile?->name ?? $this->name`,
  and the profile's `avatar_url`). Add `user_type` is already present — verify it
  returns `'attendee'` so the app can branch layout.
- *(Optional, cleaner)* expose a `name` the attendee can set: add `name` to
  `attendee_profiles` + the edit-profile payload (`PUT /me/profile`). Until then
  fall back to `profiles.name`.

**App (`kolabing-app`):**
- `roster_screen.dart`: pass an optimistic `CreatorProfile` (we already have
  `member.memberName` + `member.memberAvatarUrl` at the call site) so the header
  shows the real name instantly:
  `context.push('/profile/${id}', extra: CreatorProfile(...))`.
- `PublicProfileScreen`: when `profile.userType == 'attendee'`, render the
  **member layout** (Phase 1) instead of the collaboration layout. Never show
  "Unknown" — fall back to the optimistic name.

**Acceptance:** tapping a member shows their real name + avatar, no "Unknown",
no empty collaboration sections.

---

## Phase 1 — Member social-hub public profile (NF-13)

A member profile is a **social hub**, not a collaboration résumé. Reuse what the
app already has — `GET /profiles/{id}/game-card` (→ `gameCardProvider(profileId)`,
`GameCard` model) returns: profile {id, avatar, user_type}, stats {total_points,
total_challenges_completed, total_events_attended, global_rank, badges_count,
rewards_count}, recent_badges[].

**App — member layout (`userType == attendee`):**
- **Header:** real photo + (uploadable) cover + name + city. (Cover = NF-13 B-2.)
- **Stat row:** Points/Level · Events attended · Badges · Friends · Communities.
- **Badges:** grid from `recent_badges` / `GET /me/badges` shape (reuse
  `badge_card.dart`).
- **Communities:** the member's communities + tier (reuse `community_members` /
  `myMembershipsProvider` shape, but for the *target* profile — needs a public
  endpoint, see backend gaps).
- **Events attended:** list (needs a backend list endpoint — only a *count*
  exists today).
- **Friends preview:** row of friend avatars + "See all" (Phase 2).

**Backend gaps for Phase 1:**
- A **member public-profile payload** — either extend `game-card` or add
  `GET /profiles/{id}/public` (attendee variant) returning: name, avatar, cover,
  level, points, badges, **events-attended list**, **communities (public)**, and
  `friend_status` (Phase 2). Today: no events-attended list endpoint, no public
  memberships endpoint, no cover field.

---

## Phase 2 — Friends graph (NF-17) — full greenfield

**Backend (none exists — no table/model/route today):**
- `friendships` table: `(requester_profile_id, addressee_profile_id, status)`
  where status ∈ `pending | accepted | blocked`, unique unordered pair, indexed.
- Endpoints: `POST /friends/{profile}` (request) · `POST /friends/{profile}/accept`
  · `/decline` · `DELETE /friends/{profile}` (remove/cancel) ·
  `GET /me/friends` · `GET /me/friend-requests` (incoming + pending count).
- Add `friend_status` (`none|pending_out|pending_in|friends`) + `friends_count`
  to the member public-profile payload.

**App (greenfield — no friends code exists):**
- `friendship.dart` model + `FriendshipService` + providers (friends list,
  pending count).
- Profile header CTA: **Add friend / Pending / Friends ▾** (with Remove).
- **Friends list** screen (self + other), incoming-requests screen w/ badge.
- i18n en/es/ca for all new strings (mandatory).

**Gates NF-14 DMs** (DMs are friend-gated).

---

## @handle (universal user identifier) + add-by-identifier — Phase 2b

**`@handle` is for EVERY user, not just attendees** — attendees, community leaders,
and businesses all get one. It is a **unique username** chosen at **onboarding**
(and editable in Edit Profile). Stored on **`profiles.handle`** (unique, indexed;
validate format + uniqueness server-side, suggest from name on collision).

**One lookup endpoint, reused by two surfaces** — resolve an email **or** `@handle`
to a profile:
- `GET /profiles/lookup?q=<email-or-handle>` (or `POST /friends/by-identifier`) →
  the matched profile + its `friend_status`. Never leak more than the public card.

Reused by:
1. **Friends (attendee):** "Add friend" search by email/@handle → send request
   (`POST /friends/{profile}`). Surfaced from the profile Friends widget + the
   Friends list.
2. **Community member-add (leader):** a leader adds/invites a member to *their*
   community by email **or** @handle — **extends the existing invite-by-email**
   (`docs/tickets/2026-06-04-community-invite-by-email-backend.md`); add handle
   resolution to that path, don't build a parallel one.

**Profile Friends widget:** always visible (even with 0 friends — show a "Find
friends" CTA), with entry to the add-by-identifier search.

---

## Suggested sequencing

1. **Phase 0** now (small; fixes the visible bug). Backend `display_name`
   fallback + app optimistic name + attendee-layout branch.
2. **Phase 1** member hub — app layout against `game-card`, in parallel with the
   backend member-public-profile payload (events-attended list, public
   memberships, cover).
3. **Phase 2** friends — backend `friendships` first, then app.

## BACKLOG cross-refs
- NF-13 (social-hub profile), NF-17 (friends), NF-14 (DMs, friend-gated).
- New **FX**: member "View profile" shows "Unknown" + empty sections (Phase 0).
