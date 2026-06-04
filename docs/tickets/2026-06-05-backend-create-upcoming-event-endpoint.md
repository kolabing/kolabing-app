# Backend — Create UPCOMING events (the missing Phase-3 create path)

> **Target repo:** `kolabing-v2`. Phase-3 (PR #18 / commit `78fafaf`) is **deployed**
> (migrations `event_signups` + `add_phase3_columns_to_events` are Ran on prod). The
> sign-up/waitlist/event-chat/Reverb/filter layers all work. **Gap:** there is still
> **no way to create an *upcoming* event** — `POST /events` (`StoreEventRequest`) is the
> old past-showcase endpoint, so upcoming community events can only be inserted via
> tinker/SQL today.

## The problem (verified on prod)
`app/Http/Requests/Api/V1/StoreEventRequest::rules()` enforces:
- `date` → `before_or_equal:today` (❌ forbids future dates)
- `photos` → `required|array|min:1` (❌ an upcoming event has no photos yet)
- no `community_id`, no `starts_at`/`ends_at`/`location`/`capacity`/`tier_gate`

So `POST /events` can only create **past** showcase rows. The columns + `GET /events`
filters + `EventResource` already support upcoming events; only **create** is missing.
(Confirmed: a tinker `Event::create([...community_id, starts_at...])` produces a row
that `GET /events?community_id&time=upcoming` returns correctly with `is_upcoming:true`.)

## What to build
Add an **upcoming-event create path** (extend `POST /events`, or a sibling
`POST /communities/{community}/events`). Decisions are already locked (see the Phase-3
ticket): binary going · all-members + optional tier-gate · capacity + waitlist.

### Request (upcoming mode)
| field | rule | notes |
|---|---|---|
| `community_id` | required, exists | the owning community (auth user must be owner / `can_manage`) |
| `name` | required, string, 3–100 | |
| `starts_at` | required, date, **future allowed** | the upcoming gate (drop `before_or_equal:today` for this mode) |
| `ends_at` | nullable, date, after `starts_at` | |
| `location` | nullable, string | venue/address |
| `capacity` | nullable, int, min:1 | null = unlimited |
| `tier_gate` | nullable, json/array | tier keys allowed to sign up (reuse `community_tiers.permissions`); null = all members |
| `collaboration_id` | nullable, exists | optional kolab link (mirrors `collaborations.event_id`) |
| `photos` | **optional** here | required only for retroactive past events |

- **Auth:** owner / `can_manage` of `community_id` (the `CommunityPolicy`).
- **Keep the existing past-showcase create working** (photos + `date<=today`) — branch by
  mode, e.g. `starts_at` present + future ⇒ upcoming; else legacy past. `partner_name`/
  `partner_type` can default from the community when `community_id` is set.
- Optionally auto-create the event chat (or leave it to `POST /events/{id}/chat`).
- Return the **`EventResource`** (with `my_signup`/`going_count`/`capacity`/`starts_at`/
  `is_upcoming`/…), 201.

### Acceptance
1. Leader `POST`s an upcoming event with `community_id` + future `starts_at` (no photos) →
   201, row has `is_upcoming:true`, appears in `GET /events?community_id&time=upcoming`.
2. Tier-gated create → only the named tiers may later sign up (existing signup logic).
3. Retroactive past-event create (photos + past date) **still works** unchanged.
4. Non-owner / non-`can_manage` → 403.

## App dependency
The app's **create-event form** (leader) is blocked on this. Once shipped, the app sends
`POST` with `{community_id, name, starts_at, ends_at?, location?, capacity?, tier_gate?}`.
The app's RSVP UI (`POST`/`DELETE /events/{id}/signup`) and the events list already work
against the deployed backend.
