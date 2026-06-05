# Feature spec — Chat (app + backend) — NF-CHAT

> **Repos:** `kolabing-app` (Flutter) + `kolabing-v2` (Laravel/Sanctum, Postgres).
> **Goal:** a role-shaped chat surface. Builds on NF-6 (Community Members + tiers,
> shipped) and depends on a new **event RSVP/signup** model (see §6). Hand this to
> the agent owning both repos. Read `docs/ROLES-AND-PERMISSIONS.md` first.

## 0. Context (verified current state)
- Chat **today** is bound to an accepted application → active collaboration
  (business↔community). Attendees have no chat. There is **no** general chat model.
- NF-6 is live: `communities`, `community_tiers` (incl. `permissions.chat_channels`
  JSON), `community_members` (roster, `tier`, `can_manage`), `events.community_id`.
- `events` have check-in (QR) but **no advance RSVP/signup** — that's net-new (§6).
- Push (FCM) is live and should carry new-message / @mention notifications.

## 1. Role-shaped behaviour (the product)
| Role | Chat surface | What shows |
|---|---|---|
| **Business** | Single **active-chats** list | Only collaboration threads with **≥1 message from either side** (`last_message_at != null`). A match alone never clutters the inbox. |
| **Community (leader / can_manage)** | **Main chat** (default) + up to **5 custom chats** + **event chats** | One `main` chat auto-created with the community. Leader may create up to **5** `custom` chats (6th → `chat_limit_reached`). **Event chats**: a chat tied to an event where **only members who signed up (RSVP'd) can join/talk** (§6). The existing **Kolab** (collaboration) chats stay separate, as today. |
| **Attendee (Community Member)** | Tier-filtered list | The `main` chat + any `custom` chats their **tier** grants (`community_tiers.permissions.chat_channels`) + **event chats they RSVP'd to**. |

## 2. Data model (backend, new tables)
```
chat_threads
  id uuid PK
  type            enum  collaboration | community_main | community_custom | event
  community_id    FK communities      NULL   (community_* + event types)
  collaboration_id FK collaborations  NULL   (collaboration type)
  event_id        FK events           NULL   (event type)
  name            string NULL                (custom/event display name; main = community name)
  created_by      FK profiles
  last_message_at timestamp NULL             (drives the business "active" filter + sort)
  created_at / updated_at
  -- exactly one of community_id / collaboration_id is set; event_id only with community_id

chat_messages
  id uuid PK
  thread_id   FK chat_threads (cascade)
  sender_profile_id FK profiles
  body        text
  created_at
  index (thread_id, created_at)

chat_thread_reads            -- per-member unread tracking
  thread_id FK chat_threads
  profile_id FK profiles
  last_read_at timestamp NULL
  UNIQUE (thread_id, profile_id)
```
**Access is derived, not a membership table** (keeps it in sync with the roster/tiers):
- `community_main` → any active `community_members` row for that community.
- `community_custom` → members whose `tier.permissions.chat_channels` contains the
  thread (key the chat by a slug stored in `name`/a `slug` column and match it).
- `event` → members with a `signup`/RSVP for that event (§6).
- `collaboration` → the two collaboration participants (as today).

## 3. Endpoints (`routes/api.php`, `auth:sanctum`)
- `GET /chats` — threads visible to the viewer, role-scoped + sorted by
  `last_message_at desc`. **Business: only `last_message_at != null`.**
- `POST /communities/{community}/chats` — create a `custom` chat (owner/`can_manage`).
  **Enforce ≤5 custom cap** → `422 chat_limit_reached`.
- `POST /events/{event}/chat` — create the `event` chat (owner/`can_manage`).
- `GET /chats/{thread}/messages?page=` — paginated, newest-last; access-checked.
- `POST /chats/{thread}/messages` — send; sets `last_message_at = now()`; fires
  push to other thread members (+ @mention). Access-checked.
- `POST /chats/{thread}/read` — set the viewer's `last_read_at`.
- `GET /chats/unread-count` — total unread across visible threads (feeds the badge).

**Policy:** posting/reading requires the derived access in §2. **Never** gate chat on
the business subscription paywall, and **never** let a free business be blocked from a
collaboration chat they're a participant in (ROLES §2.8/§6).

## 4. Resource shapes (match these in the app)
```json
// ChatThread
{ "id","type","name","community_id","collaboration_id","event_id",
  "last_message_at","unread_count","participant_summary":[{"name","avatar_url"}],
  "created_at" }
// ChatMessage
{ "id","thread_id","sender":{"profile_id","name","avatar_url"},"body","created_at","is_mine" }
```

## 5. App side (`kolabing-app`)
- **Entry point:** an **inbox icon in `KolabingAppBar`** (top-right) with an unread
  badge from a `chatsUnreadProvider` — NOT a 6th bottom-nav tab (community is already
  at 5). Shown for business + community + attendee (not for unmatched/anon).
- **`ChatsScreen`** — role-shaped per §1: business = flat active list; community =
  sections (Main · Custom · Events · Kolabs); attendee = tier-filtered list.
- **`ChatThreadScreen`** — message list + composer, GroupMe/iMessage style (see the
  design mockups: bubbles, @mentions, reactions later). Mark-read on open.
- **Models/services/providers:** `ChatThread`, `ChatMessage`; `ChatService`
  (mirrors `CommunityService` conventions); providers for threads / messages /
  unread. Reuse `community_tiers.permissions.chat_channels` (already on
  `CommunityTier.TierPermissions`) for attendee gating.
- **Realtime v1:** poll on open + FCM push for new messages/@mentions; websockets/
  pusher can come later.
- ⚠️ **Apply the AsyncNotifier refresh pattern from
  `2026-06-04-tier-instant-refresh-bug.md`** for the thread/message lists — do NOT
  repeat the `FutureProvider + invalidate` approach (it doesn't refresh reliably here).

## 6. Hard dependency — event RSVP/signup (net-new, shared with the events vision)
Event chats and the "only signed-up people" gate require a **signup/RSVP** concept,
which does not exist (only on-site QR check-in does). Minimum:
```
event_signups  (event_id FK events, profile_id FK profiles, status[going|maybe|declined],
                created_at, UNIQUE(event_id, profile_id))
```
+ `POST /events/{event}/signups` (RSVP), `GET /events/{event}/signups`. This is the
same RSVP piece the community-events→Kolab feature needs — **build it once, both use it.**

## 7. Phasing (each shippable alone)
1. **Business active-chats** — wrap the existing collaboration chat: add
   `chat_threads`/`chat_messages` (or reuse the current chat tables) + the
   `last_message_at != null` filter + the app-bar inbox. Smallest.
2. **Community main + custom (≤5)** — uses the NF-6 roster; attendee tier-gating via
   `permissions.chat_channels`.
3. **Event chats** — after the RSVP model (§6) ships.

## 8. Acceptance
1. Business inbox lists only collaboration chats with ≥1 message; empty otherwise.
2. A community auto-gets one `main` chat; leader creates up to 5 custom (6th → `chat_limit_reached`).
3. An attendee sees main + only the custom chats their tier grants; not others.
4. Event chat is joinable only by RSVP'd members; non-signups are denied.
5. Sending a message updates `last_message_at`, pushes to other members, bumps unread.
6. No chat path touches the business paywall; collaboration chat works for free businesses.
