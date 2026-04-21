# Business Onboarding + Primary Venue Backend Changes

Date: 2026-04-21

## Goal

The mobile app now treats business onboarding as the one-time source of truth for the business profile and its primary venue. `Promote Venue` Kolabs should reuse this saved venue instead of asking for the same venue fields again.

## Frontend Changes Already Implemented

- Business onboarding flow order is now:
  - `step1`: choose business location from place autocomplete
  - `step2`: enter primary venue details
  - `step3`: upload reusable venue photos
  - `step4`: finish business profile details
- Venue promotion Kolab creation now:
  - pre-fills venue name, type, capacity, address, and city from the business profile
  - only asks for campaign-specific `title` and `description` on step 0
  - blocks the flow if the business does not have a primary venue profile

## New Backend Contract Required

### 1. Business Registration / Business Onboarding

The app now sends the existing business fields plus a nested `primary_venue` object.

Recommended supported payload shape:

```json
{
  "email": "owner@example.com",
  "password": "secret123",
  "password_confirmation": "secret123",
  "name": "Sol Studio",
  "business_type": "cafe",
  "city_id": "city-uuid-if-known",
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
      "data:image/jpeg;base64,...",
      "data:image/jpeg;base64,..."
    ]
  }
}
```

Notes:

- `city_id` may be absent when the user selected a place that does not map to the current `cities` table yet.
- `city_name` is included as a fallback and should be accepted.
- `primary_venue.photos` currently arrives as data URIs from onboarding.

### 2. Business Profile Response

The authenticated business response should now include:

```json
{
  "business_profile": {
    "id": "profile-id",
    "name": "Sol Studio",
    "about": "Neighborhood hangout for creator events.",
    "business_type": "cafe",
    "city": {
      "id": "city-id",
      "name": "Barcelona",
      "country": "Spain"
    },
    "instagram": "solstudio",
    "website": "https://solstudio.com",
    "profile_photo": "https://...",
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
        "https://..."
      ]
    }
  }
}
```

The app reads this `primary_venue` object to prefill venue promotion Kolabs.

### 3. Place Autocomplete API

The app is prepared for a backend Google Places proxy endpoint:

`GET /api/v1/places/autocomplete?query={search}`

Recommended response:

```json
{
  "data": [
    {
      "place_id": "google-place-id",
      "title": "Sol Studio",
      "subtitle": "Carrer de Mallorca 1, Barcelona, Spain",
      "formatted_address": "Carrer de Mallorca 1, Barcelona",
      "city": "Barcelona",
      "country": "Spain",
      "latitude": 41.3874,
      "longitude": 2.1686,
      "city_id": "optional-existing-city-id"
    }
  ]
}
```

Important:

- `city_id` should be returned when the selected place can be matched to the existing cities table.
- The mobile app currently falls back to local city search if this endpoint is not available.

### 4. Kolab Create / Update for `venue_promotion`

Current frontend behavior:

- `venue_name`
- `venue_type`
- `capacity`
- `venue_address`
- `preferred_city`

are no longer manually asked on the venue promotion form.

Backend expectation should therefore change to one of these options:

1. Recommended: derive venue fields from the authenticated business profile's `primary_venue`.
2. Alternative: accept an explicit `primary_venue_id` on Kolab create and resolve it server-side.

Recommended Kolab payload for venue promotion:

```json
{
  "intent_type": "venue_promotion",
  "title": "Sunset rooftop social for local creators",
  "description": "We want to host an evening meetup for lifestyle and food creators.",
  "media": [
    {
      "url": "https://...",
      "type": "photo",
      "sort_order": 0
    }
  ],
  "offering": ["free_drinks", "venue_space"],
  "seeking_communities": ["food", "lifestyle"],
  "min_community_size": 50,
  "expects": ["social_media"],
  "availability_mode": "specific_dates",
  "availability_start": "2026-05-10",
  "availability_end": "2026-05-12"
}
```

Server-side behavior:

- enrich the saved Kolab with the business profile's primary venue snapshot
- stop validating venue promotion requests as if venue data must always be supplied directly in the request body

## Migration Notes

- Existing business accounts without `primary_venue` will not be able to complete the new venue-promotion flow cleanly.
- Recommended migration options:
  - backfill `primary_venue` for existing businesses where venue-like business data already exists
  - or require those businesses to revisit onboarding/profile edit once

## Validation Notes

- `primary_venue.name`, `primary_venue.venue_type`, `primary_venue.capacity`, `primary_venue.formatted_address`, and `primary_venue.city` should be required for business onboarding completion.
- `venue_promotion` Kolabs should still require `title`, `description`, at least one `media` item, and valid availability.
- `media.*.type` must continue accepting `photo`.
