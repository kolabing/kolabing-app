# Attendee onboarding + universal @handle + add-by-identifier + interest ranking — shared contract

> Authoritative contract for the build. Backend (`kolabing-v2`) and app
> (`kolabing-app`) are built against THIS doc. App self-gates every new endpoint
> (treat 404 as "feature off"). **Taxonomies are dynamic** — interests come from
> `GET /community-types`, NEVER the placeholder `enum CommunityType` (see
> `docs/CANONICAL-LISTS.md`).

## 1. Identity — `@handle` (universal: attendees + leaders + businesses)
- Column **`profiles.handle`** — unique, nullable, stored lowercase; format
  `^[a-z0-9_]{3,20}$`. Set at onboarding, editable in Edit Profile.
- `GET /handle/available?handle=<h>` → `{available: bool, suggestions: [..]}`
  (suggest from name on collision). Server enforces uniqueness on write.
- Exposed as `handle` on `UserResource` (`/me/profile`) + `PublicProfileResource`.

## 2. Interests — dynamic, from `/community-types`
- Column **`profiles.interests`** — JSON array of **community-type SLUGS** (the
  values `GET /community-types` returns). Set at onboarding, editable.
- Exposed as `interests` on `UserResource`.

## 3. Onboarding submit (authenticated, after register)
- `PUT /onboarding/attendee` — body:
  `{ name, handle, city_id?, interests: [slug], community_ids: [uuid], photo? }`
  (photo as data-URI like community onboarding). Validates handle uniqueness +
  format; stores name/handle/city_id/interests on `profiles`; uploads photo to
  `profiles.avatar_url`; **auto-joins** each open community in `community_ids`
  (ignore invite-only silently). Returns the updated user. Re-runnable.

## 4. Lookup — ONE endpoint, reused by friends + member-add
- `GET /profiles/lookup?q=<email-or-@handle>` (auth) → the matched profile's
  **public card** `{ id, name, handle, avatar_url, user_type, friend_status }`,
  or 404. Resolves an exact email OR exact handle (strip a leading `@`). No PII
  beyond the public card.

## 5. Friends add-by-identifier (attendee)
- App: a search screen (from the profile Friends widget + the Friends list) →
  `GET /profiles/lookup` → result card → `POST /friends/{id}` (existing). Handle
  `friend_status` (already-friends/pending/self).

## 6. Community member add-by-identifier (leader)
- **Extend the existing invite-by-email** (`docs/tickets/2026-06-04-community-invite-by-email-backend.md`)
  / the member-add path to accept a **handle OR email**. Do NOT build a parallel
  endpoint — add handle resolution to the existing one. App: the leader roster's
  "add/invite member" accepts email or @handle.

## 7. Discover interest ranking
- `GET /communities/discover` (already shipped, featured-first): when the viewer
  has stored `interests` and no explicit `?type`, rank **interest-match first**
  (community's `community_type`/type slug ∈ viewer interests), then featured, then
  member_count. Keep the `?type=` override. Optionally return `matched` per row so
  the app can show a "✓ Running" hint and a **For You** section.

## 8. App surfaces
- **Onboarding flow** (reuse `onboardingProvider` infra): after attendee register →
  4 steps — **You** (name + @handle [live availability] + photo) · **City**
  (`/cities`) · **Interests** (multi-select from `/community-types`) · **Join**
  (discover, interest-ranked) → `PUT /onboarding/attendee` → home. Each step
  skippable except name+handle.
- **Edit Profile**: add the **@handle** field (with availability check) alongside
  name/city/photo.
- **Friends**: add-by-email/@handle search (§5).
- **Leader**: add member by email/@handle (§6).

## Rules
- Dynamic taxonomies only (interests ← `/community-types`). i18n en/es/ca for all
  new strings. Design tokens only. Self-gate every new endpoint. 0 analyze errors;
  backend filtered tests green (full suite OOMs at 128MB).
