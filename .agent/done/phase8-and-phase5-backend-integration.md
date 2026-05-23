# Phase 8 + Phase 5 — Backend Integration & Discovery Features

## Status
- Created: 2026-05-21 15:00
- Completed: 2026-05-21 16:30

## Description
Backend deployed contract updates on 2026-05-21. This task wires the Flutter
client to the new endpoints and ships the remaining discovery/matching
features (H1, H2, H3) that were blocked on PM decisions.

PM decisions captured at start:
- **H3**: base + negotiable (Option B)
- **H4**: backend audited the food-community → coworking 95% anomaly directly
  (no FE work — handled in BE-011)

## Changes shipped

### Phase 8.1 — D3 real backend wiring
File: `lib/features/collaboration/providers/collaboration_detail_provider.dart`
- Replaced the mock `markCollaborationCompleted` with a real
  `POST /api/v1/collaborations/{id}/complete` HTTP call.
- Handles 401 with single-shot token refresh + retry.
- Surfaces `ApiException` so the UI can show the backend's
  `invalid_status_transition` (and other) errors.

### Phase 8.2 — C9 community public profile + Send Kolab CTA
Files:
- `lib/features/profile/services/public_profile_service.dart` — wires
  `GET /api/v1/communities/{id}/public-profile`. Falls back to mock for
  non-community ids (business profile endpoint still TBD).
- `lib/features/profile/screens/public_profile_screen.dart` — adds an
  auth-aware bottom action bar with "Send a Kolab proposal" (primary) and
  "Save for later" (secondary). Visible only when a business is viewing a
  community profile.

### Phase 5.H2 — offer_headline on venue/product kolabs
Files:
- `lib/features/kolab/models/kolab.dart` — adds `offerHeadline` field +
  fromJson + toJson + copyWith.
- `lib/features/kolab/providers/kolab_form_provider.dart` —
  `updateOfferHeadline` + validation on venue/product step 0.
- `lib/features/kolab/screens/business/venue_details_screen.dart` and
  `product_details_screen.dart` — new TextField (50 char cap) with inline
  field error.

### Phase 5.H3 — base_offer + negotiation_triggers
Files:
- `lib/features/kolab/models/kolab.dart` — new `NegotiationTrigger` class +
  `baseOffer` + `negotiationTriggers` on Kolab.
- `lib/features/kolab/providers/kolab_form_provider.dart` —
  `updateBaseOffer` + `updateNegotiationTriggers`.
- `lib/features/kolab/screens/business/offering_screen.dart` — converted to
  `ConsumerStatefulWidget`. New "BASE OFFER" multiline field. New "EXTRA
  TERMS" section with an Add modal that captures
  `{ condition, additional_offer }`. Triggers render as removable cards.

### Phase 5.H1 — match_score + match_breakdown widget
Files:
- `lib/features/discovery/models/discovery_item.dart` — adds
  `DiscoveryMatchSignal` class + `breakdown` field on `DiscoveryMatch`.
  Robust parsing: handles both `match.breakdown` (nested) and
  `match_breakdown` at the item level. Same for `match_score` fallback.
- `lib/widgets/match_breakdown.dart` — new compact `MatchBreakdown` widget
  that renders ordered signals as labeled mini bars. Visual bar = weight ×
  per-signal score, clamped to [0, 1].
- `lib/widgets/explore_swipe_card.dart` — `_buildFitBadge` now stacks
  "% match" + the mini-bars when breakdown is present. Falls back to the
  legacy single pill when backend omits the breakdown (backwards-compat).

## Tests
- All touched files `flutter analyze` clean.
- Kolab suite passes (26/26) with new model fields.
- 2 pre-existing failures persist (welcome_screen cream layout +
  explore_screen "City match") — both unrelated to this work, confirmed on
  master via `git stash` earlier in the session.

## Open items / future work
- **C9 → wire from Discover**: when a business taps a community card in
  Explore, the navigation should land on `/profile/{communityId}`. The
  existing route already exists; just need to confirm the tap handler in
  `explore_screen.dart` routes to the same route for community items.
- **C9 → recipient_community_id pre-selection**: the Send CTA pushes
  `${kolabNew}?recipient_community_id=...`. The Create Kolab intent
  selection / first step needs to read this query param and skip the
  recipient picker (or pre-select). Flagged for a follow-up.
- **H3 triggers UI on detail screen**: when a community views a Kolab they
  have already applied to, surface the `negotiation_triggers` in the
  detail sheet. Currently the writer-side UI is complete; the
  reader-side rendering is a Phase 5.H3.2 task.
