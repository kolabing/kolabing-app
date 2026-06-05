# Backend — Chat Phase 2: community chats + generic thread messages (NF-CHAT)

> ✅ **DONE 2026-06-04** in `kolabing-v2` (282 tests green). Auto main chat on community create
> (+backfill); `POST /communities/{id}/chats` (≤5 → `chat_limit_reached`); `GET/POST /chats/{thread}/messages`
> + `POST /chats/{thread}/read`; `ChatMessageResource` gains `thread_id`; tier-gated visibility via
> `permissions.chat_channels`. Acceptance 1–4 covered by `CommunityChatTest`. Event chats = Phase 3 (needs RSVP).

> **Target repo:** `kolabing-v2`. Builds on shipped Phase 1 (`chat_threads`,
> `ChatThreadType`, `ChatThreadResource`, `GET /chats`, `/chats/unread-count`,
> application-backed messages). The **app side is already built** against the
> contract below (branch `community-member-flow`) — it currently 404s because
> these routes aren't deployed.
> Verified gap: `POST /communities/{id}/chats` → 404 on production.

## Scope
Generalise chat beyond collaboration: a community's **main** chat (auto) +
**up to 5 custom** chats, with **tier-gated** access for members. Messages for
these non-application threads need generic per-thread endpoints.

## 1. Auto main chat
- Every community has exactly one `community_main` thread (the backfill migration
  `2026_06_04_000004_backfill_chat_threads` may already seed existing ones — make
  sure `POST /communities` also creates it for new communities).

## 2. Create custom chat
`POST /communities/{community}/chats` (auth; owner OR `can_manage` member)
- Body: `{ "name": "Socials" }`
- Enforce **≤ 5** `community_custom` per community → `422 { "error": "chat_limit_reached" }`.
- Returns a **`ChatThreadResource`** (201). The app shows the upsell on
  `chat_limit_reached` and reloads the list on success.

## 3. Generic thread messages (non-application threads)
The existing `applications/{application}/messages` stays for collaboration
threads. Add a thread-keyed surface for `community_main` / `community_custom`
(and later `event`):
- `GET /chats/{thread}/messages?page=` — newest-last; access-checked (see §5).
- `POST /chats/{thread}/messages` — body `{ "content": "..." }` (the app also
  accepts `body`; please standardise on `content`). Sets `last_message_at = now()`,
  broadcasts `NewChatMessage`, bumps unread.
- `POST /chats/{thread}/read` — set the viewer's read pointer for that thread.
- **Reuse `ChatMessageResource`** (the app already parses `content` / `is_own` /
  `sender_profile`); add a `thread_id` field to it (the app reads `thread_id`,
  falling back to `application_id`).

## 4. Surface community threads in the inbox
Extend `ChatService::visibleThreads` so `GET /chats` also returns the viewer's
`community_main` + `community_custom` threads (today it's collaboration-only):
- **Leader / can_manage:** all of the community's chats.
- **Attendee (member):** the `main` chat + the `custom` chats their **tier grants**
  via `community_tiers.permissions.chat_channels` (match the chat by a slug/key).
- Business active-filter (`last_message_at != null`) stays for collaboration only.

## 5. Access policy
- `community_main` → any active `community_members` row for that community.
- `community_custom` → members whose tier `permissions.chat_channels` includes it.
- Mutations (create/delete chat) → owner / `can_manage`.
- Never gate chat on the business subscription paywall.

## App contract (already implemented — match these)
- `ChatThreadResource` unchanged (the app reads `id,type,name,application_id,
  community_id,collaboration_id,event_id,last_message_at,unread_count,
  participant_summary,created_at`).
- Custom-chat create: `POST /communities/{id}/chats {name}` → `ChatThreadResource`;
  cap → `error: chat_limit_reached`.
- Messages: `GET/POST /chats/{thread}/messages`, `POST /chats/{thread}/read`;
  `ChatMessageResource` + `thread_id`.

## Acceptance
1. New community auto-gets a `main` chat; leader creates ≤5 custom (6th → `chat_limit_reached`).
2. `GET /chats` returns community threads for leader (all) and attendee (main +
   tier-granted), in addition to collaboration threads.
3. Generic message send/list/read work for community threads; `last_message_at`
   updates; `NewChatMessage` broadcasts.
4. Tier without a channel in `chat_channels` cannot see/post that custom chat.

## Phase 3 (separate, RSVP-gated)
`event` chats — `POST /events/{event}/chat`, joinable only by RSVP'd members.
Depends on the event signup/RSVP model (shared with the events→Kolab feature).
App already has `createEventChat`.
