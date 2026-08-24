# One event page — design

**Date:** 2026-08-24
**Status:** approved (Volkan, 2026-08-24)
**Repo:** kolabing-app (Flutter). No backend change.

## Problem

The event page an attendee lands on from the feed (`EventDetailScreen`) shows
three facts — *Kolab with*, *Event Date*, *Attendees* — and then two slabs. The
biggest, greenest control on the screen is `Going ✓ · tap to leave`, whose only
function is to **undo** the RSVP, and it sits where the thumb lands. There is no
way to show a ticket at a door, nothing about the event beyond its date, and no
way to reach the community that runs it.

Meanwhile a *second* event page exists — `EventHubScreen`, opened from the
community timeline and the community hub — carrying check-in, the leader's door
QR, the attendee list and photo upload. Two screens for one event have drifted
apart before: it already produced the report *"I can't find the event QR code"*.

## Decisions taken

| Question | Decision |
|---|---|
| Event description | **No new column.** `GET /events/{id}` already returns far more than the page renders; surface that instead. |
| Which screen | **`EventDetailScreen` becomes the one event page.** `EventHubScreen`'s entry points are repointed at it and the hub is deleted once its parts are ported. |
| "My QR code" | **Two actions, not one.** *My ticket* (what you show at a door) and *Check in* (what you do once inside) are different things and get different buttons. |

## What the server already sends, and the app drops

`EventResource` returns `ends_at`, `address` **and** `location`,
`location_lat/lng`, `city_name`, `capacity`, `tier_gate`, `visibility`,
`series_id`, `occurrence_index`, `community_name`, `community_type`,
`host_profile_id`, `photos`, a leader-only `checkin` block (`code`, `qr_svg`,
`checked_in_count`, `expires_at`) and `my_signup` (`status`,
`waitlist_position`). The Flutter `Event` model parses about half of it.

Tickets are fully built server-side and entirely absent from the app:

- `GET /me/tickets` → the holder's wallet.
- `GET /tickets/{code}` → one ticket: `code`, inline `qr_svg`, `holder_name`,
  `used_at`, and a nested `event`.
- `POST /tickets/{code}/admit` → the host's door, authorised on the scanner.

Community socials exist as `community_profiles.instagram / tiktok / website`,
exposed through `PublicProfileResource` and already modelled in the app as
`PublicProfile` behind `publicProfileProvider(profileId)`. Three networks — that
is all the column set holds.

## The page

One scroll, plus a sticky action bar. Same section vocabulary as the Luma-style
community pages (`community_page_sections.dart`) so the two surfaces read as one
app.

```
┌────────────────────────────────┐
│ ▓▓ photo carousel ▓▓  ‹  ⇪  ⋯ │  hero: photos, else brand gradient
├────────────────────────────────┤
│ [QA] Gamification Test Run     │
│ 📅 Mon 24 Aug · 18:00–20:00    │  ends_at — never shown before
│ 📍 Eixample 46 · Barcelona  →  │  address + city, tap = directions
│ (🌐 Public) (↻ Weekly · #3)    │  visibility + series chips
├────────────────────────────────┤
│ ◆ [QA] Eixample Runners     ›  │  host card → community page
│   Running club · 3 members     │
│   Seeded by kolabing:seed-…    │  community about = event context
│   ⌾ instagram  ♪ tiktok  🌐    │  real links, url_launcher
├────────────────────────────────┤
│ DETAILS                        │
│ 👥 12 going · 20 cap · 8 left  │
│ ⏳ You're #2 on the waitlist   │  only when waitlisted
│ 🔒 Members only / Tier-gated   │  visibility in words
├────────────────────────────────┤
│ ATTENDEES        ●●●●● +7      │  leader: full list + admitted
├────────────────────────────────┤
│ PHOTOS  ▢ ▢ ▢                  │  leader: + add
├────────────────────────────────┤
│ 💬 Event chat               ›  │
│ ⚔ Choose a challenge        ›  │  when checked in
└────────────────────────────────┘
│ [ My ticket ]  [ Check in ]    │  ← sticky, never scrolls away
└────────────────────────────────┘
```

### The action bar is the core change

`Going ✓ · tap to leave` becomes a small text row under the title. The bar
carries what the reader actually needs, by state:

| State | Sticky bar |
|---|---|
| Not going | `I'm going` (filled) |
| Full, not going | `Join waitlist` |
| Going | **`My ticket`** (filled) + `Check in` (outlined) |
| Checked in | `My ticket` + `Choose a challenge` |
| Leader | `Show door QR` (filled) + `Attendees · 4 admitted` |
| Read-only / past | nothing — the bar collapses |

### My ticket

A sheet: the QR at the largest size the screen allows (rendered from the API's
`qr_svg` via `flutter_svg`, no local QR generation so the code can never
disagree with the server), the code in monospace beneath it, the holder's name,
and an `Admitted 18:04` state when `used_at` is set. No ticket for this event →
the button is absent, not disabled-with-a-mystery.

## Components

New `lib/features/event/widgets/event_page_sections.dart`:

- `EventPhotoHero` — carousel with page dots, brand gradient fallback, back +
  share + optional `⋯`.
- `EventTitleBlock` — name, when-line, where-line (tappable → maps), chips.
- `EventHostCard` — community identity, about, socials row, `›` to the community.
- `EventDetailsSection` — capacity/going/spots, waitlist position, visibility in
  words, recurring info.
- `EventActionBar` — the state machine above.
- `EventNavRow`, `EventSectionLabel` — shared with the community vocabulary.

New ticket feature:

- `lib/features/event/models/event_ticket.dart`
- `lib/features/event/services/ticket_service.dart` — `GET /me/tickets`
- `lib/features/event/providers/ticket_provider.dart` —
  `myTicketForEventProvider(eventId)`, which reads the wallet and picks the
  ticket whose `event.id` matches. One call, no new endpoint.
- `lib/features/event/widgets/my_ticket_sheet.dart`

`Event` gains `endsAt`, `address`, `cityName`, `communityName`, `tierGate` —
parsing fields the server already sends.

## Deletions

`event_hub_screen.dart` goes. Ported first: check-in, door QR, the attendee
list, photo upload, chat, extend-series, delete. Its two call sites
(`community_detail_screen.dart`, `community_hub_screen.dart`) push
`EventDetailScreen` instead.

## Testing

`test/features/event/widgets/event_page_sections_test.dart`:

1. The action bar renders the right controls for each of the six states.
2. The title block lays out at phone width with no overflow, and the name keeps
   real width (the FX-48 class of collapse).
3. The details section words a full event, an unlimited one, and a waitlisted
   viewer correctly.
4. The ticket sheet shows the QR, the code and the admitted state.

Plus the existing suite: `flutter analyze` clean, and the 10 known failures
unchanged by name.

## Accepted costs

- The community's about text is the same paragraph on every event of that
  community — useful once, wallpaper thereafter. This is the honest price of
  skipping a real `description` column.
- Deleting the hub moves the leader's photo-upload and extend-series one tap
  deeper, into `⋯`.
- Only three social networks, because that is all `community_profiles` stores.
