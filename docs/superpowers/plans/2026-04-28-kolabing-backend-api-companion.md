# Kolabing Launch Fixes Backend Companion

This file records the backend changes the Flutter launch fixes assume are available.

## B1. Publish subscription gating

- `POST /api/v1/kolabs/{id}/publish` and any legacy publish endpoints should return `402` with a machine-readable body when subscription is required.
- Response shape should include:
  - `message`
  - `requires_subscription: true`
  - optional `code: subscription_required`
- The frontend now treats `402` as a paywall trigger instead of a generic failure.

## B2. Auth restore and refresh

- Successful login must always return a complete user payload with the correct `user_type` and dashboard-routing data.
- Refresh-token support should remain valid for seeded and newly-created accounts.
- If an access token expires, refresh should succeed without forcing a visible logout whenever the refresh token is still valid.

## B3. Kolab drafts and edit loading

- `POST /api/v1/kolabs`
  - Must persist `status: draft` drafts durably.
- `GET /api/v1/kolabs/me`
  - Must include draft, published, and closed kolabs for the authenticated user.
  - Must support optional `status` filtering.
- `GET /api/v1/kolabs/{id}`
  - Must return a complete editable record for reopening a saved kolab.

## B4. Upload auth retry compatibility

- Upload endpoints should support refreshed access tokens cleanly after `401`.
- Seeded test accounts must ship with valid refresh credentials.
- When upload authorization fails because of an expired access token, the backend should allow a refresh-and-retry flow rather than leaving the client in a permanently expired state.

## C2 and C3. Image upload contract

- Kolab post media and community onboarding/profile image uploads should accept the same canonical response shape:
  - `url`
  - `type`
  - optional `thumbnail_url`
- Allowed file-size and mime-type rules should be consistent across profile and kolab uploads.

## C4. Past events video support

- Past event payloads should support mixed media, not just `photos`.
- Recommended backend shape:
  - `past_events[].media[]`
  - each media item contains `url`, `type`, `thumbnail_url?`, `sort_order`
- Accepted video formats and size limits should be documented and enforced consistently.

## C5. Accept kolab/application

- Accept endpoints should be idempotent.
- Successful accept responses should return the updated application/collaboration state immediately so the app can refresh without a second fetch.

## C6. Full venue address capture

- Venue records should store:
  - `formatted_address`
  - `city`
  - `country`
  - `latitude`
  - `longitude`
  - optional `place_id`
- Published kolabs and onboarding payloads should echo those fields back unchanged.

## D1. Multi-category business signup

- Business onboarding/profile update endpoints should accept up to three categories.
- Profile and explore payloads should return categories as an ordered list, not a single string.

## G1. Email banner upload

- Upload `community/kolabing/marketing/brand/logo-wordmark-banner-dark.png` to a stable public URL under `kolabing.com`.
- Share the final CDN URL so Postmark templates can be updated without another app release.
