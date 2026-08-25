# The attendee feed, rebuilt — design

**Date:** 2026-08-24
**Ticket:** [#161](https://github.com/kolabing/kolabing-app/issues/161)
**Approved by:** Volkan, 2026-08-24
**Reference:** Luma's home screen (Your Events / Your Calendars / Picked for You)

---

## The problem

`AttendeeHomeScreen` was 1175 lines and opened with data nobody needed.

1. **The top third duplicated the profile.** Three `StatCard`s — Points,
   Challenges, Events attended — showed the same numbers `AttendeeProfileScreen`
   already renders as flanking stats around the avatar. Two screens, one set of
   numbers, and the events pushed below the fold to make room.

2. **"Welcome back / \<Name\>"** occupied two lines and told the reader
   something they knew.

3. **Every event card carried three fields that were noise or wrong.**
   - **The distance badge.** City discovery sends no `lat`/`lng`, so the backend
     returned `distance_km: 0` and `distanceDisplay` rendered **"0 m"** — on
     every card, always. Not a rounding error: a fabricated fact.
   - **The partner-type badge.** "Community" on essentially every card, because
     essentially every event is community-hosted.
   - **`attendee_count`.** The legacy *showcase* headcount — how many people
     attended a past event — printed next to a people icon on a *future* one.

4. **What matters was missing.** No start time. No venue. No indication that the
   reader had signed up. No sense of whether a place was nearly full.

5. **The page did not know the reader had signed up for anything.** The events
   an attendee opens the app to check were the one thing the home screen could
   not show them.

## The shape

Three sections, ordered by how much the reader already cares about what each
one holds.

| # | Section | Data source | Backend work |
|---|---------|-------------|--------------|
| 1 | **Your events** — up to 3 rows, "View all" → `MyEventsScreen` | `GET /events?attendee=me&time=upcoming` | **None.** Already existed and was already called by the scanner's event picker. |
| 2 | **Communities you follow** — horizontal logo tiles → community page | `GET /me/community-follows` | **None.** The payload has always nested a whole `community` object; the app read the id out of it and discarded the name and the avatar. |
| 3 | **What's on** — city discovery, grouped under date headers, with the city / date / type chips and the All ↔ Following toggle | `GET /events/discover` | Resource parity — [kolabing-v2#223](https://github.com/kolabing/kolabing-v2/issues/223), spec in `docs/tickets/2026-08-24-events-discover-resource-parity-backend.md`. Ships independently. |

Above them, one slim **points strip** (`1,240 points · 8 events` → Rewards)
replaces the three stat cards. Points stay on the feed; they stop owning it.

## The structural move

The feed now speaks `Event`, not `DiscoveredEvent`.

`DiscoveredEvent` carried `date`, `attendee_count`, `location_lat/lng`,
`distance_km` and photos. `Event` carries `starts_at`, `ends_at`, `location`,
`address`, `capacity`, `going_count`, `my_signup`, `visibility`, `can_access`,
`city_name` and the host community. Everything the redesign needs is on the
second model and nothing is on the first.

`Event.fromJson` requires only `id`, `name`, `date` and `created_at` — all of
which `/events/discover` already sends — so the swap parses against today's
backend and gains the richer fields as the resource ships. Anything absent
renders as an absent line, never a placeholder and never a computed zero.

That let the Luma row built for the community pages in IF-31 become the feed's
row too. `CommunityEventTimeline` / `_EventRow` moved to
`lib/features/event/widgets/event_timeline.dart` as `EventTimeline` /
`EventTimelineRow`, gaining three flags:

- `showDay` — "Today, 19:30" for rows that do not sit under a date header.
- `showHost` — the host community's logo and name above the title. On a
  community page the host is the page you are standing on; on a city-wide feed
  it is the most important line on the row.
- `showVisibility` — off wherever every row would read the same. Discovery
  returns only public events; your own sign-ups are not access questions.

The day headers gained "Today" / "Tomorrow" (they read `24 August` before), on
the community pages as well as the feed. A reader scanning for tonight should
not have to work out which date is today.

## What was deleted

- `EventDiscoveryScreen` — 521 lines of the legacy GPS/radius feed, reachable
  from nothing but a barrel export.
- `DiscoveredEventCard`, `DiscoveredEvent`, `DiscoveredEventsResponse`.
- Five orphaned l10n keys (`attendeeHomeWelcomeBack`, `attendeeHomeStat*`,
  `attendeeHomeEventsTitle`) and two more the deleted card owned
  (`eventPartnerBusiness`, `eventPartnerCommunity`) — from all three ARBs.

## New files

| File | Holds |
|---|---|
| `lib/features/event/widgets/event_timeline.dart` | `EventTimeline`, `EventTimelineRow`, `eventDayLabel`, `eventCapacityBadge`, `EventMetaLine`, `EventMiniChip`, `EventVisibilityChip`, `EventThumbPlaceholder` |
| `lib/features/gamification/widgets/attendee_feed_sections.dart` | `FeedSectionHeader`, `AttendeePointsStrip`, `YourEventsSection`, `FollowedCommunitiesStrip` |
| `lib/features/gamification/widgets/attendee_feed_filters.dart` | `FeedScopeToggle`, `FeedCityChip`, `FeedDropdownChip`, `FeedDateRangeSheet`, `FeedCityPickerSheet`, `FeedTypeFilterSheet` (split out of the screen) |
| `lib/features/gamification/providers/my_events_provider.dart` | `myUpcomingEventsProvider` |
| `lib/features/gamification/screens/my_events_screen.dart` | The "View all" screen, route `/my-events` |

`CommunityService.myFollowedCommunities()` and `followedCommunitiesProvider`
are new; `followedCommunitiesProvider` watches `communityFollowsProvider`, so
the strip gains or loses a tile the moment the reader taps Follow.

## Error handling

Each section answers for itself and none can take the page down with it.

- A section with no data renders `SizedBox.shrink()`. An empty "Your events"
  heading would push the part of the page that *does* have something further
  down the screen in order to say so.
- `followedCommunitiesProvider` returns an empty list on an undeployed endpoint
  or any failure — a missing strip is a smaller lie than an error where a strip
  should be.
- `DiscoverEventsResponse.fromJson` skips a malformed row rather than letting it
  empty the whole feed.
- The discovery list keeps its four existing states: no city yet, loading,
  error with retry, and the two distinct Following empty states (follows nobody
  vs followed communities with nothing announced).
- Pull-to-refresh reloads all three sections. They are three answers to "what
  is happening"; refreshing one and leaving the others stale would be arbitrary.

## Testing

`test/features/gamification/widgets/attendee_feed_sections_test.dart` — 8 tests:
the points strip's line and its singular, "Your events" capping at three and
offering the rest (and dropping "View all" when it is showing everything), both
sections rendering nothing when empty, a tile per followed community, and a row
carrying its own day, venue, host and Going chip **while asserting no "0 m" and
no "Community" badge can come back**.

The existing `community_page_sections_test.dart` (day grouping, capacity badge)
was pointed at `EventTimeline` and still passes, which is what makes the move
safe.

## Accepted cost

The discovery list renders inside one `SliverToBoxAdapter`, so its rows are not
lazily built. It is paginated at 10–20 per page and the community pages already
do the same. If a "load more" chain ever makes that felt, `EventTimeline` gains
a sliver variant; building one now would be speculation.
