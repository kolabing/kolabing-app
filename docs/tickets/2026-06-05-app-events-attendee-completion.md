# App — Events / attendee experience completion (NF-16)

> **Repo:** `kolabing-app` (Flutter), branch off `community-member-flow`. Wires the
> already-deployed Phase-3 backend into the UI. Backend half = the event-photos +
> message-pref ticket (`2026-06-05-backend-event-photos-and-message-pref.md`).
>
> **State today (audited):** RSVP screen + `signup`/`cancel` work; chat inbox (Phase
> 1/2) works; `CreateEventScreen` exists but is a **stub** (name+start+capacity only;
> tier-gate hardcoded "all", no location, no photos). MISSING: attendee list,
> event-chat create/open, photo upload, notification toggle, real-time client.

## API contracts (all live on master unless noted)
```
GET  /events/{id}/signups        → { data: { going:[{id,profile_id,status,waitlist_position,
                                     profile:{id,name,avatar_url}}], waitlist:[…] } }   (leader)
POST /events/{id}/signup         → EventResource (my_signup{status,waitlist_position},
                                     going_count, waitlist_count, capacity)
DELETE /events/{id}/signup       → EventResource
POST /events/{id}/chat           → ChatThreadResource { id, type:"event", event_id, name }  (leader)
POST /events                     → EventResource   (UPCOMING: {community_id,name,starts_at,
                                     ends_at?,location?,capacity?,tier_gate?[]})
POST /events/{id}/photos         → EventResource   (multipart photos[]; NEW — backend ticket)
DELETE /events/{id}/photos/{p}   → 200             (NEW — backend ticket)
GET/PUT /me/notification-preferences  (incl message_notifications — backend ticket)
GET  /communities/{id}/tiers     → tiers (for the tier-gate picker)
```

## B1 — Event detail = management hub  (all endpoints LIVE; highest value)
Leader view: details + gallery, **attendee list** (going + waitlist from `GET /signups`),
**[Open event chat]** (call `ChatService.createEventChat` → push the chat thread screen;
it's idempotent so "create or open"). Member view: RSVP button (going/waitlist via `/signup`),
going/capacity, **[Open event chat]** once going.
```
LEADER                                  MEMBER
┌────────────────────────────┐         ┌────────────────────────────┐
│ ‹  Sat Long Run        ⋯   │         │ ‹  Sat Long Run            │
│ [▢▢▢ photos  + Add]        │         │ [▢▢▢ photos]               │
│ 📅 14 Jun · 📍 Ciutadella  │         │ 👥 12 going · cap 20 (8 left)│
│ 👥 12 going·3 wait·cap20   │         │ [  ✓ I'm going  ]           │
│ [ 💬 Open event chat ]     │         │  full→[Join waitlist #4]    │
│ ATTENDEES  ● Maria ● Joan  │         │ once going:[💬 Open chat]   │
│ WAITLIST   1 Lucia 2 Marc  │         └────────────────────────────┘
└────────────────────────────┘
```

## B2 — Create / Edit event form (replace the stub)
Fields: name · starts_at · ends_at · location · capacity (+ Unlimited toggle) ·
**Who can join: All members / Selected tiers** (multi-select from `GET /communities/{id}/tiers`
→ `tier_gate: [tierId,…]`) · **Photos** (pick from gallery → `POST /events/{id}/photos` after
create, or multipart). Support **edit** of an existing upcoming event.
```
┌──────────────────────────────────┐
│ ‹ New event                  Save │
│ Name [______]  Starts[📅] Ends[📅]│
│ Location[______] Capacity[20]☐Unl │
│ Who can join ◉All ○Tiers▸[Gold]   │
│ Photos [+ Add from gallery] ▢▢    │
└──────────────────────────────────┘
```

## B3 — Notification settings (community/attendee) — quick
A settings screen with toggles bound to `GET/PUT /me/notification-preferences`:
**Messages** (`message_notifications`, default on) · new applications · collaboration
updates · tips. (Today only a business model exists; add the community/attendee screen + entry.)

## B4 — Real-time client (LAST; ops-gated)
Add Laravel-Echo-compatible client (pusher protocol / `web_socket_channel`) configured from
`REVERB_*`; **authorizer sends the Sanctum Bearer token to `/broadcasting/auth`**; subscribe
`private-chat.thread.{id}` on an open thread + inbox; append `message.sent` payload
(`ChatMessageResource`) without refetch; refresh unread badge. **Depends on:** backend PR #21
(`/broadcasting/auth`) merged+deployed **and** the Reverb server + queue worker running (ops).
Build behind a flag; until Reverb is up, the existing poll-on-open keeps working.

## Conventions
Mirror existing services (`ChatService`/`EventService` http+Bearer+`_unwrap`), Notifier
providers with `reload()` (the NF-6 refresh pattern), KolabingColors/Spacing, GoRouter/MaterialPageRoute
as in `chats_screen.dart`. Localize new strings (en/es/ca ARBs) — match master's i18n.

## Acceptance
1. Leader opens an event → sees going + waitlist; taps **Open event chat** → event thread opens & is sendable.
2. Member RSVPs (going/waitlist reflects); once going, can open the event chat.
3. Create form posts an upcoming event with tier-gate + photos; edit works; it appears in the community's upcoming list.
4. Notification settings shows + persists the **Messages** toggle (and others).
5. (B4, when ops ready) a sent message arrives live in a second client without refresh.

## Sequence: B1 + B3 first (pure wiring, live endpoints) → B2 (needs backend photos) → B4 (needs ops).
