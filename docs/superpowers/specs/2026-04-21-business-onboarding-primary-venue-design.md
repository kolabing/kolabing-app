# Business Onboarding Primary Venue Design

## Goal

Redesign business onboarding so the app asks for business and primary venue information once, stores it as the business profile source of truth, and removes duplicated venue questions from the `Promote Venue` Kolab flow.

This design starts with location first, using Google Maps autocomplete, then collects venue details and reusable venue media. Future venue-promotion Kolabs should reuse that saved profile instead of asking the same questions again.

## Product Direction

### Core rule

Business users should not repeatedly enter venue identity data when creating a Kolab.

### What becomes onboarding-owned

Business onboarding becomes the owner of:

- business display/profile data
- primary venue location
- primary venue identity
- primary venue metadata
- reusable venue gallery

### What remains Kolab-owned

Venue-promotion Kolab creation remains responsible only for campaign-specific data:

- listing title
- campaign description
- what the business is offering
- ideal communities
- expectations from the community
- past collaborations
- campaign availability

## Current Problem

Today, the business onboarding flow and the venue-promotion Kolab flow are separated in a way that creates duplicate data entry and contract drift.

Current duplication and gaps:

- onboarding stores business basics such as name, type, city, socials
- venue-promotion Kolab asks again for city/address/venue info
- venue-promotion Kolab currently needs data the backend expects as required fields, but the flow is not consistently structured around those requirements
- the business location step currently uses a city list instead of precise place selection
- the app lacks a clear single source of truth for a business’s primary venue

This makes the user experience repetitive and increases API mismatch risk.

## Target UX

### Business onboarding flow

The business onboarding flow should be restructured into a venue-first profile flow:

1. `Where are you located?`
2. `Tell us about your venue`
3. `Add venue photos`
4. `Business details`
5. `Final review / finish`

### Step 1: Where are you located?

This becomes the first business onboarding step.

Requirements:

- use Google Maps Places autocomplete input
- do not use plain city-only selection as the primary business location input
- user chooses a real place result
- store the selected place details in normalized form

Data captured:

- `place_id`
- `formatted_address`
- `city`
- `country`
- `latitude`
- `longitude`

UX behavior:

- autocomplete should show live place suggestions
- selecting a suggestion fills the field and unlocks continue
- no duplicate follow-up city picker is shown after successful place selection

### Step 2: Tell us about your venue

This step captures the reusable venue profile.

Fields:

- venue name
- venue type
- capacity
- optional venue description or business-about text, depending on final backend field strategy

This is venue identity data, not campaign data.

### Step 3: Add venue photos

This step captures reusable venue gallery images.

Requirements:

- these photos belong to the primary venue profile
- they are separate from campaign-specific Kolab media
- future venue-promotion flows can reuse them by default

### Step 4: Business details

This step collects the remaining business profile fields:

- business type
- phone
- instagram
- website
- optional about text if not already collected in the venue step

### Finish

After onboarding is complete, the business profile is considered ready for venue-based Kolab creation.

## Kolab Flow Changes

### Promote Venue flow

The `Promote Venue` Kolab flow must stop asking for duplicated venue profile fields.

Remove from Kolab venue flow:

- venue name
- venue type
- capacity
- venue address
- venue city selection

Keep in Kolab venue flow:

- listing title
- campaign description
- offering
- ideal communities
- expectations
- past collaborations
- availability

### New create-flow behavior

When a business starts `Promote Venue`:

- load the saved business profile
- load the saved primary venue profile
- attach that profile as the source for venue-related display and submission

If the business has no primary venue profile:

- block normal venue Kolab creation
- redirect the user to complete venue onboarding/profile completion first

### Product promotion flow

This design does not remove product-specific onboarding repetition yet. Product promotion still owns its product details because the request is specifically focused on venue duplication.

If desired later, the same pattern can be extended to a reusable product/service profile.

## Data Ownership

### Single source of truth

The primary venue profile should live in the onboarding/business-profile domain, not inside the Kolab form state.

### Layered architecture

Following the app’s Flutter architecture direction:

- UI layer:
  - onboarding screens
  - venue-profile UI widgets
  - Kolab create screens
- Logic/ViewModel layer:
  - onboarding notifier/viewmodel for venue profile draft state
  - business profile loader used by Kolab prefill
- Data layer:
  - onboarding service/repository for business + primary venue persistence
  - business profile repository as the read source for Kolab flow prefill

### Proposed state shape

`OnboardingData` should be expanded for business users to include a nested primary venue draft.

Suggested model direction:

```dart
class PrimaryVenueProfileDraft {
  final String? placeId;
  final String? formattedAddress;
  final String? city;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? venueName;
  final String? venueType;
  final int? capacity;
  final List<String> venuePhotoUrls;
}
```

`OnboardingData` then becomes:

- business profile fields
- venue profile fields
- step progress

This keeps onboarding as the owner of business profile composition.

## Duplicate Information To Move

The following fields currently duplicated in `Promote Venue` should move to onboarding-owned business profile storage:

- `preferred_city`
- venue address
- venue place selection
- venue name
- venue type
- capacity
- venue photos

The following fields remain in Kolab because they describe the specific listing:

- `title`
- `description`
- `offering`
- `seeking_communities`
- `min_community_size`
- `expects`
- `past_events`
- `availability_mode`
- `availability_start`
- `availability_end`
- `selected_time`
- `recurring_days`

## Screen-Level Refactor Plan

### Existing onboarding business flow

Current business steps roughly map to:

- name/photo
- business type
- city
- social/about

### New onboarding business flow

Refactor to:

1. location autocomplete
2. venue profile
3. venue gallery
4. business details
5. final confirmation

### Existing Kolab venue flow

Current venue Kolab flow includes a full venue details step that duplicates onboarding-owned business profile data.

### New Kolab venue flow

Refactor to:

1. venue profile summary/read-only card or no venue-details step at all
2. campaign media if still needed separately
3. offering
4. ideal communities
5. past collaborations
6. availability
7. review

Recommended implementation detail:

- replace the current editable venue-details step with a read-only `Primary Venue` summary card
- include an `Edit venue profile` action that routes to the onboarding/profile editor, not inline Kolab editing

## Google Maps Autocomplete Requirements

### Client-side

Add a Google Maps Places autocomplete integration for the onboarding location step.

Client requirements:

- query suggestions as the user types
- show formatted prediction list
- fetch place details after selection
- normalize and save the selected place payload into onboarding state

### Saved fields

At minimum save:

- Google place id
- full formatted address
- city/locality
- country
- coordinates

### Why this matters

This allows:

- better matching of businesses and communities by location
- future map/search features
- stronger backend identity for primary venue

## Backend Contract Changes

The backend currently treats Kolab venue fields as request-time fields. To support this redesign, business onboarding/profile APIs must become capable of storing a primary venue profile.

### Business onboarding request changes

Business onboarding payload should support:

- `place_id`
- `formatted_address`
- `city`
- `country`
- `latitude`
- `longitude`
- `venue_name`
- `venue_type`
- `capacity`
- `venue_photos`

Suggested request shape:

```json
{
  "name": "Cafe Montjuic",
  "business_type": "cafe",
  "phone_number": "+34123456789",
  "instagram": "cafemontjuic",
  "website": "https://cafemontjuic.com",
  "about": "Rooftop cafe for community events.",
  "primary_venue": {
    "place_id": "google-place-id",
    "formatted_address": "Carrer de Montjuic 42, Barcelona, Spain",
    "city": "Barcelona",
    "country": "Spain",
    "latitude": 41.37,
    "longitude": 2.17,
    "venue_name": "Cafe Montjuic",
    "venue_type": "cafe",
    "capacity": 80,
    "venue_photos": [
      "https://storage.kolabing.com/venues/1.jpg"
    ]
  }
}
```

### Business onboarding response changes

Business profile responses should return a normalized `primary_venue` object:

```json
{
  "data": {
    "id": "profile-id",
    "name": "Cafe Montjuic",
    "business_type": "cafe",
    "phone_number": "+34123456789",
    "instagram": "cafemontjuic",
    "website": "https://cafemontjuic.com",
    "about": "Rooftop cafe for community events.",
    "primary_venue": {
      "id": "venue-id",
      "place_id": "google-place-id",
      "formatted_address": "Carrer de Montjuic 42, Barcelona, Spain",
      "city": "Barcelona",
      "country": "Spain",
      "latitude": 41.37,
      "longitude": 2.17,
      "venue_name": "Cafe Montjuic",
      "venue_type": "cafe",
      "capacity": 80,
      "venue_photos": [
        "https://storage.kolabing.com/venues/1.jpg"
      ]
    }
  }
}
```

### Kolab create contract changes

For `venue_promotion`, the backend should not require duplicate venue fields if a primary venue already exists.

Preferred backend options:

1. `primary_venue_id`
- Kolab payload explicitly references an existing saved venue profile

2. automatic inheritance
- backend derives the primary venue from the authenticated business profile if no explicit override is sent

Recommended option:

- support `primary_venue_id`
- allow server-side fallback to the authenticated business’s default venue

Suggested create request:

```json
{
  "intent_type": "venue_promotion",
  "primary_venue_id": "venue-id",
  "title": "Cafe Montjuic - Community Events Welcome",
  "description": "Host your next community event with us.",
  "offering": ["venue", "food_drink", "discount"],
  "seeking_communities": ["Fitness", "Sports"],
  "min_community_size": 50,
  "expects": ["social_media"],
  "availability_mode": "recurring",
  "availability_start": "2026-05-01",
  "availability_end": "2026-06-30",
  "selected_time": "10:00",
  "recurring_days": [6, 7]
}
```

### Validation changes needed server-side

For `venue_promotion`, adjust validation rules so these become unnecessary when `primary_venue_id` or stored profile inheritance is present:

- `preferred_city`
- `venue_name`
- `venue_type`
- `capacity`
- `venue_address`

If backend wants snapshotting for historical integrity, it can still copy venue data into the created Kolab record internally while not forcing the client to send duplicates.

## Migration / Compatibility Notes

### Existing users

Business users who completed old onboarding will not automatically have a valid primary venue profile.

Required behavior:

- if they start `Promote Venue` without a primary venue profile, redirect them into a venue-profile completion flow
- do not silently create incomplete venue profiles from partial legacy onboarding city-only data

### Existing Kolab drafts

Existing drafts may still contain venue fields directly. The app should continue reading them, but new creation should shift to profile-based venue data.

## Error Handling

### Onboarding location errors

- failed autocomplete fetch: show retryable inline state
- failed place-details fetch: show inline error and keep user on location step
- invalid place selection: do not allow continue

### Missing profile for Kolab creation

- if no `primary_venue` exists, show a clear CTA:
  - `Complete your venue profile first`

### Partial backend support

If backend support is not yet implemented:

- keep the spec-complete client architecture ready behind a thin service abstraction
- document the temporary fallback path clearly
- do not hardcode fake Google-place values into production payloads

## Testing Strategy

### Unit tests

- onboarding draft model serialization
- place selection mapping into onboarding state
- business profile repository mapping
- Kolab prefill from primary venue profile

### Widget tests

- onboarding location step:
  - can select a place
  - continue enables only after valid selection
- venue details step:
  - required fields validate correctly
- Kolab venue flow:
  - duplicated venue inputs are absent
  - primary venue summary is shown
  - create flow blocks when no venue profile exists

### Integration tests

- business onboarding saves primary venue
- `Promote Venue` opens with saved venue profile
- venue Kolab publish works without re-entering venue identity fields

## Implementation Notes

### Recommended order

1. extend onboarding data model and service contracts
2. build location autocomplete step
3. refactor business onboarding step order
4. add primary venue persistence/repository
5. refactor venue Kolab flow to consume profile data
6. add backend integration documentation and contract notes

### Explicit non-goals for this first pass

- multi-venue management
- full product-profile reuse
- backend implementation itself

## Summary

This redesign moves business venue identity into onboarding, makes Google Maps autocomplete the first business-location interaction, removes duplicated venue questions from venue-promotion Kolab creation, and introduces a proper business-profile-to-Kolab data boundary.

That gives the product the intended behavior:

- ask once
- save once
- reuse later
- stop re-asking for the same venue data during Kolab creation
