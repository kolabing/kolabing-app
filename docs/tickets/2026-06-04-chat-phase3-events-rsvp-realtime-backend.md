# Backend — Chat Phase 3: event RSVP/sign-up, event chats, real-time (Reverb)

> **Target repo:** `kolabing-v2`. Builds on shipped Phase 1 (inbox, `ChatThreadType`,
> `ChatThreadResource`, `GET /chats`, `/chats/unread-count`) and Phase 2 (community
> main + custom chats, generic `/chats/{thread}/messages`, `ChatMessageResource` +
> `thread_id`). Phase 3 adds the **event sign-up layer** the chat gate needs, the
> **event chat** itself, and **real-time delivery**.
>
> Context: events already exist (`events`, `event_checkins`, `event_photos`,
> `event_rewards`; QR check-in → XP; `collaborations.event_id → events`). Today an
> event is effectively a **past-event showcase** (name, `date`, attendee count,
> photos) with no upcoming/RSVP concept. The app's `POST /events/{id}/chat` 404s
> because **sign-up does not exist yet**. This ticket closes that.

---

## Product decisions (locked with Daniel — build exactly these)
- **Sign-up semantics:** binary **"I'm going"** (join / leave). No Going/Maybe/Can't.
- **Access:** any community member by default; a leader may **optionally tier-gate**
  an event (reuse `community_tiers.permissions`, same pattern as custom chats).
- **Capacity + waitlist:** ship **now**. Events may set a max; when full, new sign-ups
  are **waitlisted** with a position; on a leave/cancel, **auto-promote** the head of
  the waitlist to "going" (and notify).
- **Event chat:** signing up (going) grants access to the event's chat. Waitlisted
  members do **not** get chat access until promoted.

---

## 1. Event lifecycle (reframe)
One event, three states by time + viewer status:

```
UPCOMING ─────────────▶ LIVE ───────────────▶ PAST
sign up / waitlist      QR check-in (exists)   gallery + count (exists)
unlocks event chat      earns XP (exists)      shows in community Details
        [NEW]
```

Only the **UPCOMING / sign-up** layer is new; LIVE (check-in) and PAST (showcase)
already exist and must keep working.

## 2. Schema

### 2.1 New table `event_signups`
| col | type | notes |
|---|---|---|
| `id` | uuid PK | |
| `event_id` | → `events` | |
| `profile_id` | → `profiles` | the member signing up |
| `status` | enum | `going` \| `waitlisted` \| `cancelled` |
| `waitlist_position` | int null | set when `waitlisted`, null otherwise |
| `created_at` / `updated_at` | ts | |

Unique `(event_id, profile_id)` (one row per member; re-join flips `cancelled`→`going`).

### 2.2 New columns on `events`
| col | type | notes |
|---|---|---|
| `community_id` | → `communities` null | explicit owner community (today only `partner`/`collaborations.event_id` imply it) |
| `starts_at` | ts | today there is a single `date`; keep `date` working, add start |
| `ends_at` | ts null | |
| `location` | string/json null | venue / address |
| `capacity` | int null | null = unlimited |
| `tier_gate` | json/string null | optional: which tier(s)/permission key may sign up; null = all members |
| `collaboration_id` | → `collaborations` null | kolab link (mirror of existing `collaborations.event_id`) |

Reuse as-is: `event_checkins` (attendance), `event_photos` (gallery/past), and the
existing `collaborations.event_id` link.

## 3. Sign-up endpoints
- `POST /events/{event}/signup` — auth; community member (tier-gated if `tier_gate` set).
  - If room (`going` count < capacity, or capacity null) → `status=going`.
  - If full → `status=waitlisted` with next `waitlist_position`.
  - Idempotent: a `cancelled` row flips back (re-evaluating capacity).
  - On `going`: **add the member to the event chat** (if the chat exists).
  - Returns the updated event (or signup) with `my_signup` + counts.
- `DELETE /events/{event}/signup` — leave/cancel.
  - Frees a slot → **auto-promote** the head of the waitlist to `going`, add them to
    the chat, and notify them.
  - Remove the leaver from the event chat (or downgrade to read-only — your call;
    app treats "not a participant" as no access).
- `GET /events/{event}/signups` — leader / `can_manage`: list going + waitlist (with
  positions) for roster/management.

### Event resource additions (per viewer)
`my_signup` (`going|waitlisted|cancelled|null` + `waitlist_position`), `going_count`,
`waitlist_count`, `capacity`, `starts_at`/`ends_at`, `location`, `community_id`,
`collaboration_id`, `tier_gate`. Keep existing fields (`date`, `attendee_count`,
photos) for the past-showcase view.

## 4. Event chat (the Phase-3 chat)
- `POST /events/{event}/chat` — auth; leader / `can_manage` of the event's community.
  Creates one `event` `ChatThreadType` thread for the event. Returns a
  **`ChatThreadResource`** (the app already calls this; it 404s today).
- **Access:** only `going` sign-ups (+ leader/can_manage) may see/post. Waitlisted =
  no access until promoted. Enforce on `GET /chats`, `GET/POST /chats/{thread}/messages`,
  `POST /chats/{thread}/read`.
- **Surface in inbox:** extend `GET /chats` so the viewer's event threads (the ones
  they're `going` to) come back alongside community + collaboration threads.
- Reuse the Phase-2 generic message surface (`/chats/{thread}/messages`,
  `ChatMessageResource` + `thread_id`). No new message endpoints.

## 5. Real-time (Laravel Reverb)
Chosen over Pusher for **scale cost** (self-hosted, no per-connection/message billing).

- Stand up **Reverb**; set `BROADCAST_CONNECTION=reverb`.
- Broadcast **`NewChatMessage`** (already dispatched in Phase 2) on a **private
  per-thread channel** `chat.thread.{threadId}` whenever a message is stored
  (community, event, or collaboration thread).
- **Channel authorization** (`routes/channels.php` + `/broadcasting/auth`, Sanctum):
  authorize `chat.thread.{id}` only for a participant of that thread — the SAME
  access rules as §4 / Phase-2 §5 (community membership/tier, event `going`,
  collaboration party). This is the security boundary; do not authorize on
  membership of the community alone for tier/event-gated threads.
- Payload = the `ChatMessageResource` (so the app appends without a refetch).
- Also bump unread + `last_message_at` server-side (already done on send).
- **Optional fast-follow (flag, not v1):** typing indicators / presence on the same
  channel. The app will not depend on them initially.

## 6. Events ↔ Kolabs (sync)
No new plumbing — reuse `collaborations.event_id` (+ new `events.collaboration_id`
mirror). An event is either standalone (partner = community) or kolab-linked (partner =
the business). A kolab-linked event must appear in **both** the community's events list
and the collaboration. The existing `profile_event_picker_sheet` (app) is the attach
point.

## 6.1 Past events = the SAME events (normalize — no separate model)
The existing "past events" showcase (app: `past_events_section`, `past_event_card`,
business `past_events_screen`; today surfaced in the profile) must read the **same
`events` rows in their PAST state** — not a parallel concept. Concretely:
- An event created as *upcoming*, once `ends_at` passes, **is** the past event (with
  its `event_photos` gallery + check-in `attendee_count`). One row, lifecycle by time.
- **Community Details** past events = `events WHERE community_id = {id} AND ends_at < now`
  (+ photos) — this is where the gallery + past events live (per the IA decision).
- **User profile** attended/past = events the viewer checked in to (`event_checkins`)
  or had a past `going` sign-up; this drives the profile "Events" stat.
- So `GET /events` must support filters: `community_id`, `time=upcoming|past`, and
  `attendee=me`. The Events tab (upcoming), the community Details tab (past + gallery),
  and the profile showcase all hit the **same endpoint** with different filters — no
  separate past-events table or route. The single `events` lifecycle feeds every
  surface.
- **KEEP the retroactive past-event flow** (existing `createEvent` / `add_event_modal`):
  a leader can still create an event **directly in the past** — `starts_at`/`ends_at`
  in the past, with photos + attendee count, **no sign-up/RSVP/waitlist**. Sign-up,
  capacity, waitlist and the event chat apply only to **upcoming** events. Creation
  must therefore support both modes: (a) upcoming event (RSVP-enabled) and (b)
  retroactive past event (showcase-only). Do not remove (b).

## 6.2 Cover photo = a gallery image (shared pool, no separate upload)
A cover photo and the gallery are the **same image pool** — a cover is just a
*designated* gallery image, never a separate upload path:
- Setting an event cover → **pick from the event's gallery (`event_photos`)** OR
  **upload new**, and an upload **saves into the gallery** and can be set as cover in
  one step. So `events` carries a `cover_photo_id` → `event_photos` (the chosen
  image), not a standalone `cover_url`.
- Same pattern cross-cuts the **community cover** (Details tab gallery) and the
  **user profile cover** (NF-13): cover = `cover_photo_id` into that entity's gallery;
  uploading adds to the gallery. One uploader, one pool, pick-or-upload everywhere.
- Backend: the photo-upload endpoint(s) return the created gallery row; setting a
  cover is just storing its id. App: a shared "choose from gallery / upload new"
  cover picker.

## 7. App contract (already partly built — match these)
- `POST /events/{id}/chat` → `ChatThreadResource` (app has `ChatService.createEventChat`).
- Event threads come back in `GET /chats` with `type=event`, `event_id`, `name`.
- `event_signups` drives a one-tap **"I'm going"** button; the app reads `my_signup`,
  `going_count`, `capacity`, `waitlist_position`.
- Real-time: app will add a Reverb/Echo client subscribing to `chat.thread.{id}` for
  the open thread + inbox; payload must be a `ChatMessageResource`.

## 8. Acceptance
1. A member can sign up to an upcoming event; over capacity → waitlisted with a
   position; a cancel auto-promotes the next waitlisted member (and notifies them).
2. Tier-gated event: a member whose tier isn't permitted is blocked from signing up.
3. Leader creates the event chat; only `going` members (not waitlisted) see/post it;
   it appears in their `GET /chats`.
4. Sending a message broadcasts `NewChatMessage` over `chat.thread.{id}`; a second
   authenticated client subscribed to that channel receives it in real time without
   polling; a non-participant is refused channel auth.
5. Kolab-linked event shows in both the community events list and the collaboration;
   check-in (existing) and past-showcase (existing) still work.

## 9. Out of scope (separate tickets)
- Member-to-member DMs (the competitor's "Personal Chats") — pending decision.
- Typing/presence (fast-follow on the same Reverb channel).
- Profile redesign (Friends graph, uploadable cover) — separate profile ticket.
