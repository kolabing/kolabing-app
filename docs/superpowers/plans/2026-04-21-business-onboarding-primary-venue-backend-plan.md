# Business Onboarding Primary Venue Backend Plan

Date: 2026-04-21

## Goal

Make the backend support the new frontend rule:

- business onboarding saves one reusable `primary_venue`
- venue-promotion Kolabs reuse that venue automatically
- the backend stops requiring duplicate venue fields to be typed again on every Kolab create

This plan is the backend implementation sequence for the already-shipped frontend changes.

## Scope

In scope:

- business registration/onboarding payload changes
- business profile response changes
- place autocomplete endpoint
- venue-promotion Kolab create/update changes
- migration handling for existing business accounts

Out of scope:

- community onboarding changes
- product-profile reuse
- admin tooling beyond minimum migration support

## Recommended Rollout Order

### Phase 1: Accept and persist `primary_venue`

Backend should first become tolerant of the new onboarding payload shape, even before the whole venue-promotion refactor is finished.

Tasks:

- update business registration endpoint to accept nested `primary_venue`
- update `PUT/POST /onboarding/business` to accept the same nested `primary_venue`
- persist venue fields to a stable backend data model
- accept both `city_id` and `city_name`
- support `primary_venue.photos[]` as data URIs or convert them during upload/storage

Why first:

- the new mobile onboarding now sends this shape
- without this phase, new business onboarding data is incomplete

### Phase 2: Return `primary_venue` in auth/profile responses

Once the backend stores the venue, it must expose it consistently.

Tasks:

- include `primary_venue` in:
  - registration response user payload
  - login/authenticated user payload
  - any `me` or profile endpoints used by the app
- keep response shape stable across all business-auth hydration points

Why second:

- venue promotion prefill depends on the authenticated business profile including `primary_venue`

### Phase 3: Add place autocomplete endpoint

The frontend is already prepared for a backend place-search endpoint and currently falls back to city search if it is missing.

Tasks:

- add `GET /api/v1/places/autocomplete?query=...`
- proxy Google Places or your chosen geocoding source server-side
- normalize results into the frontend contract
- map returned places to an existing `city_id` when possible

Why third:

- onboarding works today with fallback behavior
- this phase upgrades UX precision rather than unblocking the core data model

### Phase 4: Refactor venue-promotion Kolab create/update rules

This is the behavior change that removes duplicated venue validation from Kolab create.

Tasks:

- stop requiring direct request fields for:
  - `venue_name`
  - `venue_type`
  - `capacity`
  - `venue_address`
  - `preferred_city`
- derive those values from the authenticated business profile’s `primary_venue`
- store a venue snapshot on the Kolab at publish/create time
- keep `title`, `description`, `media`, offering, expectations, and availability validation as required

Why fourth:

- do this only after `primary_venue` storage and read APIs are stable

### Phase 5: Migrate existing businesses

Existing businesses may not have `primary_venue`, and that becomes the main compatibility risk.

Tasks:

- decide whether to:
  - backfill from existing business/venue-like fields
  - or force profile completion before venue promotion
- add a migration or fallback behavior for old accounts
- make sure the app receives a predictable “missing primary venue” state

## Backend Data Model Expectation

Recommended minimum backend ownership:

- `business_profile`
- `primary_venue`

Recommended `primary_venue` fields:

- `id`
- `business_profile_id`
- `name`
- `venue_type`
- `capacity`
- `place_id`
- `formatted_address`
- `city`
- `country`
- `latitude`
- `longitude`
- `photos`
- timestamps

Recommended behavior:

- treat `primary_venue` as the editable source of truth
- treat Kolab venue fields as a snapshot copied from that source when needed

Why snapshot:

- published Kolabs should remain historically accurate even if the business later edits its venue profile

## API Expectations

### 1. Business registration / onboarding

Expected request support:

```json
{
  "name": "Sol Studio",
  "business_type": "cafe",
  "city_id": "optional-city-id",
  "city_name": "Barcelona",
  "about": "Neighborhood hangout for creator events.",
  "phone_number": "+34612345678",
  "instagram": "solstudio",
  "website": "https://solstudio.com",
  "profile_photo": "data:image/jpeg;base64,...",
  "primary_venue": {
    "name": "Sol Studio Rooftop",
    "venue_type": "cafe",
    "capacity": 120,
    "place_id": "google-place-id",
    "formatted_address": "Carrer de Mallorca 1, Barcelona",
    "city": "Barcelona",
    "country": "Spain",
    "latitude": 41.3874,
    "longitude": 2.1686,
    "photos": [
      "data:image/jpeg;base64,..."
    ]
  }
}
```

Expectation:

- backend accepts this shape without requiring old venue fields outside `primary_venue`

### 2. Business profile response

Expectation:

- every business-auth hydration response includes `primary_venue`
- response uses normalized field names, not separate ad hoc variants

### 3. Place autocomplete

Expectation:

- endpoint returns lightweight place suggestions
- query length under 2 characters can safely return an empty `data` array
- `city_id` is optional but should be included whenever a place maps to a known city

### 4. Venue-promotion Kolab create

Expectation:

- request no longer fails because direct venue fields are missing
- backend resolves venue data from `primary_venue`
- backend writes a venue snapshot onto the Kolab record or response payload

## Validation Expectations

### Business onboarding validation

Required:

- `name`
- `business_type`
- `primary_venue.name`
- `primary_venue.venue_type`
- `primary_venue.capacity`
- `primary_venue.formatted_address`
- `primary_venue.city`

Optional:

- `city_id`
- `country`
- `latitude`
- `longitude`
- `phone_number`
- `instagram`
- `website`
- `primary_venue.photos`

### Venue-promotion Kolab validation

Still required:

- `title`
- `description`
- at least one media item
- valid availability

No longer required directly in request:

- `venue_name`
- `venue_type`
- `capacity`
- `venue_address`
- `preferred_city`

## Migration Expectations

I expect one of these 2 strategies:

### Recommended: soft migration with profile completion

- if a business lacks `primary_venue`, return business profile normally with `primary_venue: null`
- block venue-promotion Kolab creation server-side with a clear validation/business-rule error
- app redirects user to finish onboarding/profile

Benefits:

- lowest migration complexity
- safest rollout

Tradeoff:

- existing businesses need one extra setup pass

### Alternative: best-effort backfill

- infer `primary_venue` from existing business city/address/name data
- mark incomplete venue profiles if fields are missing

Benefits:

- smoother for existing accounts

Tradeoff:

- higher risk of dirty/inaccurate venue data

## Error Handling Expectations

Please keep error responses explicit. The mobile app benefits from backend messages like:

- `Primary venue profile is required before creating a venue promotion kolab.`
- `The selected place could not be mapped to a supported city.`
- `Primary venue capacity must be greater than 0.`

Avoid generic validation messages when a business-rule-specific message is possible.

## Acceptance Criteria

Backend is ready when all of the following are true:

1. A new business can register or complete onboarding with a nested `primary_venue`.
2. The authenticated business payload returns `primary_venue`.
3. The place autocomplete endpoint returns normalized suggestions.
4. A venue-promotion Kolab can be created without direct venue fields in the request.
5. Existing businesses without `primary_venue` receive a clear, intentional behavior.

## My Expectations From Backend

These are the concrete expectations I’m building against on the app side:

- stable `primary_venue` response shape everywhere business profile data is returned
- backward-compatible onboarding endpoint rollout before strict Kolab validation changes
- place endpoint normalized by backend, not raw Google payload passthrough
- venue-promotion creation derived from profile data, not duplicated request data
- clear server errors for missing venue profile state

## Recommended Implementation Ticket Split

Ticket 1:

- accept and persist `primary_venue` on business onboarding/register

Ticket 2:

- expose `primary_venue` in business auth/profile responses

Ticket 3:

- add `/places/autocomplete`

Ticket 4:

- refactor `venue_promotion` create/update validation and venue snapshot derivation

Ticket 5:

- migration handling for existing business accounts
