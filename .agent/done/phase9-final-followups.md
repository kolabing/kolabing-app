# Phase 9 — Final follow-ups (C9 wiring + recipient routing + H3 reader + C7 + C10)

## Status
- Created: 2026-05-21 14:15
- Completed: 2026-05-21 15:30

## Description
After backend deployed the 2026-05-21 contract updates and Phase 8 wired the
new endpoints, five FE-only follow-ups remained. This phase ships all of them.

## Per-task deliverables

### 9.1 — C9 Discover→community tap routing
- `lib/features/business/screens/explore_screen.dart` — `_onCardTap` now
  passes `onViewCreatorProfile` to the detail sheet, routing to
  `/profile/{creatorProfile.id}` when the viewer chooses to view the
  community's public profile.
- `lib/widgets/explore_detail_sheet.dart` — adds optional
  `onViewCreatorProfile` callback. When provided, renders a secondary
  "View creator profile" text button below the primary Apply CTA.

### 9.2 — `recipient_community_id` pre-selection
- `lib/config/routes/routes.dart` — `kolabNew` builder reads the
  `recipient_community_id` query param and passes it to
  `IntentSelectionScreen`.
- `lib/features/kolab/screens/intent_selection_screen.dart` — converted to
  ConsumerStatefulWidget. `initState` stashes the recipient id on the form
  provider so downstream steps see it.
- `lib/features/kolab/providers/kolab_form_provider.dart` — new
  `recipientCommunityId` on KolabFormState + `setRecipientCommunityId`
  notifier method. `selectIntent` preserves the id across intent reset.
  `saveAndPublish` passes it to the service.
- `lib/features/kolab/services/kolab_service.dart` — `publish()` accepts
  `recipientCommunityId` and sends it as `{ "recipient_community_id": ... }`
  body to `POST /kolabs/{id}/publish`.

### 9.3 — H3 reader-side
- `lib/features/opportunity/models/opportunity.dart` — new fields
  `offerHeadline`, `baseOffer`, `negotiationTriggers` parsed from API.
  Adds local `NegotiationTrigger` class with the same shape as the
  kolab.dart writer-side one.
- `lib/features/business/screens/community_offer_detail_screen.dart` —
  renders three new sections:
  - H2 offer-headline pill right below the title.
  - "THE OFFER" card with `base_offer` text (public, every viewer).
  - "EXTRA TERMS UNLOCKED" card when `negotiation_triggers` is non-empty
    (backend gates this — present means the viewer has applied).

### 9.4 — C7 reuse venue photos
- `lib/features/kolab/screens/business/media_screen.dart` — reads the
  business profile's `primaryVenue.photos` via `profileProvider`. When the
  user is on the venue promotion flow AND there are venue photos AND there
  is room (<5 media items), surfaces a "USE VENUE PHOTOS (n)" outlined
  button. Tapping it adds all unused venue photo URLs to `kolab.media` as
  `KolabMedia(type: 'image')`, skipping any already-added duplicates.

### 9.5 — C10 Google Photos preview fix
- `lib/utils/image_picker_normalize.dart` — new utility
  `normalizePickedImage(XFile)`. Reads bytes via the XFile API (which
  handles iOS content URIs / asset identifiers) and writes them to a
  `Directory.systemTemp` file. Returns the original path if `File()` can
  already open it.
- `lib/features/kolab/screens/business/media_screen.dart`,
  `lib/features/kolab/screens/community/photo_screen.dart`,
  `lib/features/kolab/screens/business/past_events_screen.dart` — each
  picker call now goes through `normalizePickedImage` before upload, so
  the local file path used for upload + preview is always readable.

## Cross-cutting
- Resolved an ambiguous `NegotiationTrigger` import in
  `kolab_form_provider.dart` by hiding the opportunity-side class on that
  import (both files now legitimately ship the same shape — writers use
  kolab.dart, readers use opportunity.dart).
- Added 3 new backend tickets to the addendum of
  `.agent/documentations/backend-tickets-from-bug-list-2026-05-21.md`:
  BE-017 (publish accepts recipient_community_id), BE-018 (application
  detail returns gated negotiation_triggers), BE-019 (community public
  profile JSON shape — documentation).

## Verification
- `flutter analyze lib`: 0 errors.
- `flutter test`: **+107 -3**, same as before Phase 9 (the 3 failures are
  pre-existing welcome_screen + explore_screen tests confirmed against
  master via `git stash`).
- Manual smoke (deferred to next QA): tap community card in Explore → see
  "View creator profile" link → tap → public profile loads → "Send Kolab
  proposal" → create flow → publish → backend sees the
  recipient_community_id in the body.
