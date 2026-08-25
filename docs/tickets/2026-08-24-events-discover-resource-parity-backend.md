# Backend ticket — `GET /events/discover` should return `EventResource`

**Repo:** `kolabing-v2`
**Raised by:** app ticket [kolabing-app#161](https://github.com/kolabing/kolabing-app/issues/161) (attendee feed rebuild)
**Date:** 2026-08-24
**Issue:** [kolabing-v2#223](https://github.com/kolabing/kolabing-v2/issues/223)
**Status:** spec ready — not started
**Blocking:** nothing. The app self-gates and ships first.

---

## The problem

`GET /events/discover` returns a bespoke, thin payload:

```
id, name, partner_name, partner_type, date, attendee_count,
location_lat, location_lng, address, photos, distance_km,
created_at, updated_at, community_name, community_type
```

`GET /events` returns `EventResource`, which carries everything a reader needs
to decide whether to go:

```
starts_at, ends_at, location, address, capacity, going_count,
waitlist_count, my_signup, visibility, can_access, city_name,
community_id, host_profile_id, series_id, tier_gate, photos, videos
```

Two endpoints returning the same rows in two shapes forced the app to carry two
models. The attendee feed used the thin one, so the discovery list could not
show **the start time or the venue** — the two facts a reader needs most — and
instead showed three that were noise or wrong:

- **`distance_km` on a city query.** City discovery sends no `lat`/`lng`, so the
  value came back `0` and the app rendered **"0 m"** on every card. A fabricated
  fact, shipped to production.
- **`attendee_count`** — the legacy *showcase* headcount for a past event,
  printed on a future one. `going_count` is the real number and was not sent.
- **`partner_type`**, which reads `community` on essentially every row.

## The change

Return `EventResource` from `/events/discover`, the same as `GET /events`.
Keep the pagination envelope (`{ data: { events, pagination } }`) exactly as it
is — the app parses it unchanged.

Then two rules on the fields that are genuinely discovery-only:

1. **`distance_km` only when it means something.** Include it only when the
   request supplied `lat` and `lng`. On a `city_id` or `following` query, omit
   the key rather than sending `0` — an absent field renders as an absent line,
   a zero renders as "0 m".
2. **Drop `attendee_count` from the discover branch** if that is cheap, or leave
   it; the app no longer reads it on this surface. `going_count` is what it
   shows.

`can_access` and `visibility` matter here even though discovery is public-only
today (see IF-29): they keep the resource honest if the scope ever widens, and
the app already respects both.

## Watch the query count

`EventResource` runs roughly three count queries **per event**
(NF-15 measured `GET /events` at ~150 queries for a 50-row page). Discovery is
a hotter, more public path than `GET /events`, so ship this with
`withCount` / batched grouped counts rather than per-row counts. If that cannot
be done in this pass, cap the discover page size and say so in the PR — do not
let the parity change quietly multiply the query count on the busiest attendee
endpoint.

## Acceptance criteria

- `GET /events/discover` returns items whose shape matches `GET /events` item
  for item, inside the existing `{ data: { events, pagination } }` envelope.
- A `city_id` or `following` query returns **no `distance_km` key at all**; a
  `lat`+`lng` query still returns a real one.
- `starts_at`, `location`, `address`, `capacity`, `going_count`, `my_signup`,
  `visibility` and `can_access` are present and correct for the requesting user.
- The `following=1` branch stays gated to `visibility=public` (the IF-29 fix is
  not regressed).
- Query count per discover page is bounded — no per-row counts. State the
  measured count in the PR.

## App side — already done, no coordination needed

The app parses `/events/discover` with `Event.fromJson`, which requires only
`id`, `name`, `date` and `created_at` — all of which the current thin payload
already sends. So the app ships **before** this ticket and degrades honestly:
rows without `starts_at` show no time line, rows without `location` show no
venue line, and nothing renders a placeholder or a zero. Every field this ticket
adds lights up the row it belongs to with no further app release.
