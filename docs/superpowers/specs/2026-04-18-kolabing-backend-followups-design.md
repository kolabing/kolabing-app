# Kolabing Backend Follow-Ups Design

## Goal

Define the backend changes still needed so the Flutter client fixes can behave as intended in production without brittle client-side workarounds.

## Scope

### 1. Kolab / Opportunity media ingestion

Problem:

- The Flutter client now allows users to pick kolab images in the legacy opportunity flows.
- Depending on the current API implementation, `offer_photo` may still be treated as a plain URL instead of an uploaded image payload.

Backend requirement:

- Accept one of these safely on create/update:
  - `offer_photo` as a data URI (`data:image/jpeg;base64,...`)
  - or a multipart upload / pre-signed upload flow that returns a URL
- Persist the uploaded image and return a stable public URL in the response.

Recommended contract:

- Request:
  - keep accepting `offer_photo` for backward compatibility
- Response:
  - always normalize to a URL in `offer_photo`

Why:

- This keeps the current client fix working while avoiding permanent base64 payload storage.

### 2. Active cities for onboarding and creation

Problem:

- Current city lists are broad and product wants only active markets such as Barcelona, Madrid, and Valencia plus an “Other / Suggest a city” path.

Backend requirement:

- Add an `active_cities` concept or filtered endpoint.
- Return only launch markets for the default selector.
- Support a separate suggestion field or endpoint for non-active markets.

Recommended contract:

- `GET /api/v1/cities?active_only=1`
- Response items:
  - `id`
  - `name`
  - `country`
  - `is_active`

Optional:

- `POST /api/v1/city-suggestions`

### 3. Explore result-count masking

Problem:

- Product wants marketplace size hidden until counts are sufficiently large.

Backend requirement:

- Either return a display-safe count policy field or let the client know whether the real total may be shown.

Recommended contract:

- Explore list responses include:
  - `total`
  - `display_total`
  - `can_show_total`

Example:

- If total is below threshold:
  - `display_total: null`
  - `can_show_total: false`
- If total is above threshold:
  - `display_total: 57`
  - `can_show_total: true`

### 4. Past event video support

Problem:

- Current event flow supports only photo uploads.
- Product requested video uploads for past events.

Backend requirement:

- Accept mixed media on events or explicitly reject unsupported video types.

Recommended contract:

- Either:
  - add `media[]` with `{ url, type }` where `type in [photo, video]`
- Or:
  - keep `photos[]` only and document that video is unsupported

Why:

- The client should not expose video upload until the server has a stable contract and storage path.

## Implementation Notes

- Keep backward compatibility where possible for existing `/opportunities` consumers.
- Normalize all media fields in responses to URLs, not base64 strings.
- Prefer explicit capability support over implicit client guessing.
