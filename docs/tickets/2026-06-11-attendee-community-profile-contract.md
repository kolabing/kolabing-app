# Attendee community profile + join requests (shared contract)

> Backend (`kolabing-v2`) + app (`kolabing-app`). Daniel 2026-06-11, for release.
> When an attendee opens a community (e.g. from an event's host-community link), they
> must see a **community-shaped** profile (events + join), NOT the business view
> (Past Kolabs + Send-Kolab), and NOT mock data.

## Bug to fix (app)
The community link in `event_detail_screen.dart` (`_buildPartnerChild` →
`context.push('/profile/$communityId')`) opens `PublicProfileScreen`, whose
`getPublicProfile(profileId)` expects a PROFILE id, gets a COMMUNITY id, and
falls back to **mock "Kolabing Community / Istanbul / Past Kolabs"**. Must open a
**community-keyed** profile via `GET /communities/{id}` instead.

## App — attendee community profile screen
A new (or branched) screen keyed by **community id** (`GET /communities/{id}` for the
real community + `GET /events?community_id={id}` for upcoming events):
- **Header**: cover/brand band, avatar, **real** name · type (17-slug label) · city,
  member count.
- **About** (description).
- **UPCOMING EVENTS** section (replaces Past Kolabs): the next few events as cards →
  tap a card → event detail (RSVP). A **"See all →"** action → opens the community's
  **events sub-tab inside the community detail** screen (route to the member/community
  detail on the Events tab; reuse it).
- Social links (if present).
- **Sticky bottom CTA, state-aware**:
  - not a member + `join_policy=open` → **"Join community"** → `POST /communities/{id}/join` → becomes member ("✓ Joined").
  - not a member + `join_policy=invite_only` → **"Request to join"** → `POST /communities/{id}/join-requests` (new, below); after sending → "Requested" (pending).
  - already a member → **"Open community"** → the community detail (member view).
- Branch by viewer: a **business** viewer keeps the existing Send-Kolab / business
  flow (don't break it); attendee/community viewer gets this. Reuse event cards +
  `CommunityService.joinCommunity`.

## Backend — invite-only join requests (NEW)
`invite_only` communities currently just reject self-join. Add a request flow:
- Migration: `community_join_requests` (id, community_id, profile_id, status
  `pending|approved|declined`, timestamps; unique pending per (community, profile)).
- `POST /communities/{id}/join-requests` — an attendee requests to join an
  invite_only community (open communities → just join directly, return a hint or
  409/422 `already_open`). Idempotent on an existing pending request.
- `GET /communities/{id}/join-requests` — leader/manager lists pending requests.
- `POST /join-requests/{id}/approve` — leader approves → creates the
  `CommunityMember` (default tier) + notifies the requester. `decline` → marks
  declined + notifies.
- Expose the viewer's request state on `GET /communities/{id}` (e.g.
  `my_join_request_status`: null|pending|approved|declined) + `join_policy` +
  `is_member` so the app can pick the CTA without extra calls.
- Notifications: requester on approve/decline; leader on new request (reuse the
  notification system; pick sensible types).

## Rules
- i18n en/es/ca for new strings; design tokens only; self-gate new params. App 0
  analyze errors; backend filtered tests green (full suite OOMs at 128MB). Community
  types = 17-slug `/community-types`, never the placeholder enum.
