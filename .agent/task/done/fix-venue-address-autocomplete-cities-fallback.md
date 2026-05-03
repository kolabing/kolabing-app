# Fix: Venue address autocomplete only suggests cities

## Status
- Created: 2026-05-03 15:45
- Started: 2026-05-03 15:45
- Completed: 2026-05-03 15:55

## Issue Description
On the business onboarding "Where is your venue?" step, the autocomplete shows
only cities (Sevilla, Malaga, Barcelona…) instead of street-level addresses.

User-supplied logs:
```
🌍 Cities parsed count: 11
🌍 Cities loaded successfully: 11 cities
🌍 Cities API Response Body: {"success":true,"data":[{"id":"…","name":"Sevilla","country":"Spain"}, …]}
```

The user wants detailed venue address suggestions.

## Root Cause
`OnboardingService.searchPlaces()` first tries `GET /places/autocomplete`, but
that backend endpoint is not implemented yet, so the request fails. The code
then **falls back to `getCities()`** and maps each city to a
`PlaceSuggestion`, which is what the user is seeing — that fallback is doing
the wrong thing.

Relevant code:
- `lib/features/onboarding/services/onboarding_service.dart:188-235`
  (`searchPlaces`, including the cities fallback)

## Affected Files
- `lib/features/onboarding/services/onboarding_service.dart` — replace cities
  fallback with OpenStreetMap Nominatim search

## Fix Approach
1. Keep the existing backend `/places/autocomplete` attempt — when the backend
   ships, it'll seamlessly take over.
2. On failure or empty result, fall back to **OpenStreetMap Nominatim**
   (`https://nominatim.openstreetmap.org/search`) — free, no API key, returns
   street-level results worldwide.
3. Drop the city fallback so users no longer see city-only suggestions.

Nominatim usage: include a descriptive `User-Agent`, `format=jsonv2`,
`addressdetails=1`, `limit=10`. We map each result into `PlaceSuggestion`
using `display_name` for `formattedAddress`, the road/city as title/subtitle,
and `lat`/`lon` for coordinates.

## Fix Applied
- `OnboardingService.searchPlaces` still tries `GET /places/autocomplete`
  first; on failure or empty result it now calls a new
  `_searchNominatim(query)` helper instead of the cities list.
- `_searchNominatim` hits `https://nominatim.openstreetmap.org/search` with
  `format=jsonv2&addressdetails=1&limit=10` and a descriptive `User-Agent`,
  and maps each hit through `_nominatimToSuggestion` into `PlaceSuggestion`
  (street + house number as title, neighbourhood/city/country as subtitle,
  full `display_name` as `formattedAddress`, lat/lon preserved, place id
  prefixed with `osm:`).
- Exposed `PlaceSuggestion.tryParseDouble` (was private `_parseDouble`) so
  the Nominatim adapter can share the same lenient numeric parser.

## Testing
- [x] `dart analyze` on the touched files: no errors or warnings.
- [x] Backend `/places/autocomplete` integration still in place — when it
      ships it takes precedence over Nominatim.
- [x] Selected `PlaceSuggestion` still flows through `updateLocation`,
      preserving `formatted_address`, `latitude`, `longitude`, and `city`
      for the `primary_venue.*` payload (note: `cityId` is now null for
      Nominatim hits, which is fine — backend should resolve city by
      coordinates or fall back to `city` name from the payload).

## Notes
For production we should switch to a paid Places provider (Google, Mapbox,
Geoapify) or proxy through our own backend; Nominatim has a 1 req/sec usage
policy and requires attribution. This is acceptable for the current onboarding
volume.
