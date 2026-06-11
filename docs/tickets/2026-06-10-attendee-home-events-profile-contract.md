# Attendee Home + events discovery + inline profile — shared contract (NF-18, NF-19, FX-21/22/23)

> Backend (`kolabing-v2`) + app (`kolabing-app`) build against this. App self-gates
> new params (ignore gracefully if backend not deployed). **Event "type" = the host
> community's `community_type`** (the unified 17-slug; NEVER the placeholder enum —
> see `docs/CANONICAL-LISTS.md`). Daniel 2026-06-10.

## NF-19 — events discovery by CITY (replace the "No Events Nearby" placeholder)
**Backend** — extend `GET /events/discover` (today it's geo `lat/lng/radius_km`):
- Add params: `city_id` (filter to a city), `date` (`today` | `upcoming`, default upcoming),
  `type` (a host **community_type** slug). Keep the geo params working (back-compat).
- `EventResource` for these cards must expose: `community_name` + `community_type`
  (the host community's name + 17-slug type) so the app can show "Real Run Club ·
  Running" and filter by type. (Verify the event→community join; reuse it.)
- Test: discover by city returns that city's events; `date=today` filters to today;
  `type=run_club` filters to events hosted by run-club-typed communities.

**App** — home "Events" section (replaces the radius placeholder):
- A **city picker** (top-right, dark/readable — FX-21) defaulting to the attendee's
  `user.cityId`/`cityName`; changing it re-queries (browse other cities when traveling).
- **Filter chips**: **Today** (toggle → `date=today`) and **Type ▾** (a sheet of
  community types from `communityTypesProvider` → `type=` slug). FX-21: chips +
  controls use readable contrast (no yellow-on-light).
- The real event list (name, host community + type, date/time) → tap → event detail.
  Loading/empty/error states. Self-gate: if the backend ignores the new params, the
  list still renders (just unfiltered).

## FX-22 — on-brand home stat icons
- Replace the Points/Challenges/Events icons (star/target/calendar) with icons aligned
  to the onboarding/community-type icon set (and the SVG-icon table once it lands).
  Design tokens only.

## FX-23 — persistent "Explore communities" CTA on home
- An always-visible button on the attendee home → `KolabingRoutes.discoverCommunities`
  (the discovery screen already built), not just an empty-state.

## NF-18 — inline profile editing (remove the Edit Profile screen)
- **Tap the avatar** on the attendee profile → change photo (reuse
  `ProfileService.updateProfilePhotoFile` multipart `profile_photo`).
- **Name + @handle editable inline** just below the avatar (tap → inline field;
  @handle uses the existing `handle_field` live availability; save via
  `PUT /me/profile`). No separate screen.
- **Delete** `edit_profile_screen.dart` + `KolabingRoutes.editProfile` + the
  profile "Edit profile" row (city is no longer edited here — it lives in Home's
  city picker per NF-19). Keep Notifications / Language / Log out.

## Rules
- Event type / interests / community types → ALWAYS the dynamic `/community-types`
  (`communityTypesProvider`), never the placeholder enum.
- i18n en/es/ca for every new string. Design tokens only. Self-gate new endpoints.
  0 analyze errors; backend filtered tests green (full suite OOMs at 128MB).
