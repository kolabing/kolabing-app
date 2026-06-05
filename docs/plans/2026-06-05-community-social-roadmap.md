# Kolabing — Community / Social Fixes & Backlog Roadmap

**Date:** 2026-06-05
**App branch:** `community-member-fixes` (kolabing-app)
**Backend branch:** `community-chat-fixes` (kolabing-v2)
**Status:** Plan locked. Implementation starts at Batch 1.

This is a multi-batch program covering the chat-management fixes, public events,
the maintainer operator panel, and the Flaire-inspired social backlog. Each batch
is a shippable unit. `[BE]` = kolabing-v2 (Laravel), `[APP]` = kolabing-app (Flutter).

---

## Locked decisions

1. **Soft-delete chats** = `community_custom` + `event` threads only. `community_main`
   and `collaboration` threads are structural and NOT deletable. Recoverable by admin.
2. **Join / leave / ban:**
   - Members **join** a chat only when it's available to them (an `is_open` custom
     chat, or one their tier grants). 
   - There is **no per-chat "leave"** — leaving a chat = leaving the community entirely
     (which removes them from all of that community's chats).
   - Admin (owner / `can_manage`) can **remove a member from a chat = BAN**.
   - Re-join is allowed **unless banned**.
3. **Events visibility:** `public` (any attendee may join directly, shows in attendee
   discovery) or `members_only` (must join the community first).
4. **Two "admin" scopes:** the in-app **community leader** (owner / `can_manage`) manages
   *their own* community's chats; the **Kolabing maintainer** (`/admin/*` operator panel)
   sees *all* communities/businesses and their chats and can moderate.
5. **Friends "Suggested":** co-attendance signal = **≥ 3 shared events attended**.

---

## Ship order

```
 1 -> 2     in-app chat management (active pain, fully specced)
 7          maintainer operator panel (reuses Batch 1 data + soft-delete/ban)
 3          public events + attendee discovery
 4, 5, 6    Flaire social (attendee profile, friends, community profile)
```

---

## Batch 1 — Chat management : BACKEND  `[kolabing-v2]`

Schema:
- `chat_threads.deleted_at` (soft delete; SoftDeletes on the model).
- `chat_threads.is_open` bool default false (open vs tier-gated custom chats).
- `chat_thread_participants` (id, thread_id, profile_id, state `joined|banned`,
  joined_at, banned_at, banned_by). UNIQUE(thread_id, profile_id).

Endpoints (all `auth:sanctum`, under the existing chat group):
- `DELETE /chats/{thread}` — owner/`can_manage`; only `custom`+`event`; soft delete.
- `PATCH /chats/{thread}` — rename (name) a custom chat; owner/`can_manage`.
- `POST /chats/{thread}/join` — eligible member joins an `is_open` (or tier-granted) chat;
  rejected if banned; writes a `joined` participant row.
- `POST /chats/{thread}/members/{profile}/remove` — owner/`can_manage`; writes/sets
  `banned` → removes access and blocks re-join.

Service / access changes (`ChatService::canAccessThread`, `visibleThreads`):
- Exclude `deleted_at` threads everywhere.
- A `banned` participant is denied regardless of tier/role.
- `is_open` custom chat: any active member may join (and is then a `joined` participant).
- Leaving the community (status → removed) already cascades; ensure it also drops chat
  access (it does via membership checks) and is reflected in lists.
- `ChatThreadResource` adds `event_id` + `event {id,name,date}` for the app deep-link,
  and `can_manage` / `is_member` / `is_open` flags for the UI.

Docs: update `ROLES-AND-PERMISSIONS.md` (§9 chat rules) + `ROLES-BACKEND-DB-MAP.md`
(§12 chat tables/endpoints), bump dates, mirror to kolabing-app. Tests cover delete
scope, rename authz, join eligibility, ban + re-join block, leave-community cascade.

## Batch 2 — Chat management : APP  `[kolabing-app]`

- Chats tab (`chats_screen.dart`): owner/`can_manage` get **create / rename / delete**
  inline (reuse the create sheet from the community hub) — not only the community profile.
- "Chats you can join" section + **Join** button for `is_open` chats.
- Admin: **remove / ban** a member from a chat (from the thread's participant list).
- Event chat (`chat_thread_screen.dart`): **info icon** in the header → Event detail
  (via `event_id`).
- Delete-chat action + confirm (soft, recoverable).

## Batch 3 — Public events + attendee discovery  `[BE + APP]`

- `[BE]` `events.visibility` enum `public | members_only`.
- `[BE]` Attendee discovery feed returns `public` events; RSVP rules: public → any
  attendee may join; members_only → must be (or become) a community member first.
- `[BE]` Tests + ROLES docs.
- `[APP]` Create/Edit event visibility toggle; Attendee Explore public-events feed
  with the two join paths (direct vs "Join community to RSVP").

## Batch 4 — Attendee profile + events attended (Flaire)  `[BE + APP]`

- `[BE]` Attendee public-profile endpoint: name, avatar, level/points, badges,
  communities (+ tier), `events_attended` count + history (from `event_checkins`/signups),
  friends count.
- `[APP]` Attendee profile screen (self + public view); events-attended list; badges grid.

## Batch 5 — Friends system (Flaire)  `[BE + APP]`

- `[BE]` `friendships` (requester_profile_id, addressee_profile_id, status
  `pending|accepted|blocked`, timestamps). UNIQUE pair.
- `[BE]` Endpoints: request / accept / decline / remove / block / list.
- `[BE]` **Suggested** = profiles sharing **≥ 3 attended events** (co-attendance),
  not already friends/blocked.
- `[APP]` Friends list, requests inbox (incoming/sent), add-friend on any attendee
  profile header (Add / Pending / Friends▾), Suggested row.

## Batch 6 — Community profile improvements (Flaire)  `[BE + APP]`

All blocks are in scope; addressed in this dependency order:

```
 6a  Header + Join CTA      (identity; uses existing community fields + cover/bio)
 6b  Upcoming events        (events feature exists)
 6c  Tiers preview          (tiers exist)
 6d  Members grid           (roster exists)
 6e  Your tier + chapter rank   (member view; leaderboard exists)
 6f  Chats list (member view)   (DEPENDS on Batch 1/2)
 6g  Gallery                (profile gallery support)
```

- `[BE]` add any missing backing fields (cover_url, bio if absent) + a single
  community-profile aggregate endpoint feeding 6a–6g.
- `[APP]` public vs member variants of the profile (public → Join CTA; member →
  your-tier/rank, chats, hub entry).

## Batch 7 — Maintainer operator panel  `[kolabing-v2, /admin/* Blade]`

- Communities index: every community public profile (name, owner, type, members,
  #tiers, #chats).
- Community detail → all chats within (main/custom/event) + msg counts, last activity,
  participant counts; drill into a thread → read transcript (operator view).
- Business index → business detail → active chats (collaboration threads).
- Moderation inline (soft-delete chat / ban member) reusing Batch 1.
- maintainer-only authz + tests + ROLES/DB-MAP (§9) updates.

---

## Data model (chat, after Batch 1)

```
 communities ─1:N─ chat_threads ─1:N─ chat_messages
      │                 │  │
      │                 │  └─1:N─ chat_thread_participants (profile, state: joined|banned)
      │   type: community_main | community_custom | event | collaboration
      │   +is_open  +deleted_at  +slug +name +event_id +last_message_at
      └─1:N─ community_members (status, tier, can_manage)
```
