# Release fixes — event visibility + discover + city persistence + chat name (shared contract)

> Backend (`kolabing-v2`) + app (`kolabing-app`) build against this. Community types
> = the unified 17-slug `/community-types` (`communityTypesProvider`), NEVER the
> placeholder enum. App self-gates new params. Daniel 2026-06-11, for release.

## 1. Event visibility (NEW) — public / members / tier
- **Backend:** add `events.visibility` enum **`public | members | tier`** (guarded
  migration; default existing rows to **`members`** so nothing silently becomes
  public). `tier` reuses the existing `tier_gate` (allowed tier ids). Accept
  `visibility` (+ `tier_gate` when tier) on **POST/PUT /events**; expose
  `visibility` on `EventResource`. Eligibility/RSVP rules unchanged for
  members/tier; `public` = visible to everyone (no membership needed to *see* it
  in discover; signup rules TBD-keep-current).
- **App:** the community **create/edit event form** gets a **Visibility** selector:
  **Public** · **Members** · **Specific tier** (tiers from `communityTiersProvider`).
  Public events auto-appear in city discover (below).

## 2. Discover events — show PUBLIC city events, future-inclusive + date ranges
- **Backend `GET /events/discover`:** return ONLY `visibility = public` events for
  the `city_id`, **including future events** (this is the bug — currently nothing
  shows). Expand the date filter param `date` to:
  **`today` | `week` (this week, Mon–Sun) | `weekend` (this week's Sat–Sun) |
  `month` (this calendar month) | `upcoming` (default, all future)**. Keep `type`
  (host community_type) + `city_id`. Verify the city join (events→community→
  community_profiles.city_id).
- **App home feed:** the **Today** chip becomes a **date selector** with
  **Today / This week / This weekend / This month** (→ `date` param; default
  "upcoming"). Public city events (incl. future) render. Empty/loading/error kept.

## 3. City persistence (BUG — re-asked every login)
- **App:** when the user picks a city on the home, **persist it to the profile**
  via `PUT /me/profile` `{city_id}` (so it's remembered). On home load, default the
  city to `user.cityId`/`cityName` (already on UserModel). No more re-asking.
  *(Backend already stores `profiles.city_id`; no backend change needed.)*

## 4. Chat sender name (BUG — can't see who messaged)
- **App:** in the chat thread, render the **sender's name** on **incoming** message
  bubbles (community/event/group chats with multiple participants). The message
  model carries the sender (name/avatar) — show the name above the bubble (skip for
  your own messages and for 1:1 where it's obvious). If the name is missing, fall
  back to the participant/handle, never "Unknown".

## Rules
- i18n en/es/ca for new strings; design tokens only; self-gate new endpoint params.
  0 analyze errors; backend filtered tests green (full suite OOMs at 128MB).

---

## ADDENDUM (2026-06-11) — why discover is still empty + the real mechanism

Two blockers found via the prod API (events are public but discover returns 0):
1. **`is_active` gate**: community upcoming events are created `is_active=false`
   (`EventService::buildUpcoming` never sets it), but discover requires
   `is_active=true` → **no upcoming event is ever discoverable**. The gate suited the
   old geo "active now" path, not "upcoming events in my city".
2. **No event city**: events have no `city_id`; city is derived ONLY from the host
   community's `community_profiles.city_id`, but leader-created communities (e.g. Real
   Run Club, `type=other`) have `community_profile_id=null` → no city → never matched.

### Fix (backend)
- Add **`events.city_id`** (nullable FK `cities`) + **`event_series.city_id`**. This
  is the EVENT's city (where it happens), picked at creation. Series propagates to
  occurrences.
- Discover city filter = **event's effective city**: `events.city_id` if set, else
  fall back to the host community's `community_profiles.city_id`. Expose
  **`city_name`** on the event resource.
- **Relax the `is_active` gate** for the public/city discover path: show **upcoming
  (date ≥ today) PUBLIC events** regardless of `is_active`. (Keep `is_active` for the
  geo "active now" path if it matters there.)
- Create/update event + series accept `city_id`.

### Fix (app)
- Create/edit event form: a **city picker** for the event's city (reuse
  `citiesProvider`), sent as `city_id`. Default to the community's / user's city.
- **Date filter UI: ONE dropdown chip** (tap → menu: Today / This week / This
  weekend / This month / Upcoming), styled like the city chip — NOT separate chips.
