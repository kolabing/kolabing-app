# Collaboration Preview + Past Events Design

**Date:** 2026-05-16  
**Status:** Approved for planning  
**Ticket:** TICKET 3, View Mode for Published Collaborations + Past Events on Business-Facing View

## Goal

Close two trust and workflow gaps on the published collaboration detail experience:

- let a community open its own published collaboration in the exact business-facing layout
- show the publishing community's past events directly on the business-facing collaboration detail screen

The outcome should reduce context switching for businesses and give communities a safe preview of what buyers see before they share or promote a collaboration.

## Scope

This ticket targets the **published, apply-able collaboration/opportunity detail flow**, not the post-acceptance `CollaborationDetailScreen`.

In the current app, the relevant screen is:

- `lib/features/business/screens/community_offer_detail_screen.dart`

That screen is already used as the shared detail surface for:

- business viewers opening a community-published offer
- community viewers opening the equivalent detail route from the shared router

The accepted collaboration screen under `lib/features/collaboration/screens/collaboration_detail_screen.dart` is a separate post-match workflow and is out of scope.

## Problem Statement

Two gaps exist today:

1. A community can publish a collaboration, but cannot preview the detail page as a business would see it from inside the app.
2. A business can inspect a collaboration, but must leave that screen and visit the community profile to see past events, which weakens trust at the point of decision.

There is also one supporting defect in the current codebase:

- public/read-only past-event cards already navigate to `/event/:id`, but `EventDetailScreen` only resolves events from the current user's `eventsProvider`, so taps from public or embedded read-only surfaces are not reliable.

## Current State

### What already exists

- `CommunityOfferDetailScreen` already renders the business-facing offer detail layout.
- The detail screen already supports creator header, offer details, deliverables, location, and the bottom apply CTA.
- Public/read-only past events already exist on profile screens through `PastEventsSection(profileId: ...)`.
- Event cards already have tappable navigation to `/event/:id`.
- The current user profile model exposes the community profile ID, which can be used to detect preview mode for owned content.

### What is missing

- No explicit preview mode exists on the detail screen for the publishing community.
- No preview banner exists to distinguish owner preview from a real business session.
- No embedded past-events section exists on the collaboration detail screen.
- No limit/order contract is enforced specifically for this new trust section.
- Read-only event detail resolution is incomplete for public/embedded event cards.

### Important repo findings

- The app currently has overlapping legacy/newer management flows: `kolab`-based "My Kolabs" screens and `opportunity`-based public detail/apply flows.
- This ticket should use `CommunityOfferDetailScreen` as the **single source of truth** for the business-facing detail layout, even if the community-side list entry point currently lives in an older management stack.
- Public/read-only event detail must be fixed as part of this ticket; otherwise criterion 3 would be implemented visually but fail at interaction time.

## Requirements

### Functional

1. A community user can open any of their **published** collaborations in preview mode.
2. Preview mode must reuse the same layout a business sees.
3. Preview mode must show a clear top-of-screen banner indicating that the user is previewing the collaboration.
4. The bottom business CTA remains visible in preview mode, but is disabled.
5. Business viewers see a `Past events from this community` section on the detail screen when the community has at least one event.
6. The section shows the most recent events first.
7. The section shows at most 5 items and should still work when only 1 or 2 exist.
8. Tapping an event opens that event's detail screen in read-only mode.
9. If the community has zero past events, the section is hidden.

### Non-functional

- The preview layout must not fork into a separate screen implementation.
- The event section should feel like a trust/credibility extension of the detail screen, not a profile detour.
- The read-only event detail path must not expose owner-only destructive actions.

## Decision Summary

### Recommended architecture

Use `CommunityOfferDetailScreen` as the shared detail surface and add two role-aware extensions:

- `previewMode` handling for owned published collaborations
- an embedded read-only community past-events section fed from the existing event API/provider path

### Why this architecture

- It guarantees the preview is the same view businesses see.
- It avoids maintaining two similar screens that will drift over time.
- It reuses the event-fetching path already used by public profiles.
- It fixes the currently broken read-only event drill-in once, in the right place.

## UX Design

### 1. Community preview mode

When the viewer is a community user and the opened published collaboration belongs to that user's community profile:

- show a slim, high-visibility banner near the top of the detail screen
- banner copy: `You are previewing this collaboration as businesses see it`
- keep the standard business-facing body content unchanged
- keep the bottom CTA visible for fidelity, but disable interaction and label it as preview-only

Preview mode should not introduce owner editing controls into the detail layout. Editing remains available from the management list, not from the preview surface.

### 2. Past events section on detail

Append a new section after the main collaboration content, before the bottom action area:

- title: `Past events from this community`
- data source: the same read-only event source used on public profile screens
- item count: up to 5
- ordering: newest first
- card content: cover photo, title, date
- interaction: tap opens event detail

The section may be horizontal, matching the existing event card language already used on profile screens. Reusing the existing event card pattern is preferred for consistency and speed.

### 3. Read-only event detail

Event detail must support opens from read-only/public surfaces:

- if navigated from a public/read-only source, fetch the event by ID when it is not already present in the current user's editable event state
- render the same event detail content
- hide delete or other owner-only actions in read-only mode

This keeps public profile events and the new embedded collaboration events aligned.

## Data and State Design

### Preview detection

Preview mode should be derived from:

- current authenticated user role is community
- current user has a `communityProfile.id`
- opportunity detail payload marks the offer as owned, or the creator profile ID matches the current community profile ID
- offer status is `published`

The screen should not depend on route naming alone to determine preview behavior.

### Past events query

Use the existing event listing API with the creator/community profile ID:

- `EventService.getEvents(profileId: ...)`

The detail surface should request a limited, read-only slice of the results and locally cap rendering to 5 items if the provider/service does not yet expose limit-specific ergonomics.

### Event ordering

The ticket requires most recent first. If the API already returns newest-first, preserve that order. If not guaranteed, sort client-side by descending event date before slicing.

## Interaction Flow

### Community preview

1. Community opens one of their published collaborations from management UI.
2. The app routes to the shared detail screen.
3. The screen resolves that the collaboration belongs to the current community.
4. Preview banner appears.
5. Business CTA remains visible but disabled.

### Business viewer

1. Business opens `View Collaboration`.
2. The shared detail screen loads collaboration details as it does today.
3. The screen also loads the creator community's recent past events.
4. If events exist, show the embedded trust section.
5. Tapping an event opens read-only event detail.

## Acceptance Criteria Fit Check

### Criterion 1

> Community user can open any of their published collaborations and see the exact business-facing view, with a clear banner indicating preview mode.

Fit: **Yes**

- shared `CommunityOfferDetailScreen` remains the single layout
- preview adds only banner + disabled CTA state, not a separate visual structure

### Criterion 2

> Business user, on the collaboration detail screen, sees a "Past events from this community" section with at least 3 events when the community has them, scrollable horizontally or vertically.

Fit: **Yes**

- section is appended directly to the detail screen
- it renders 3 to 5 recent items when available
- horizontal scrolling is the preferred implementation because it matches the existing event card pattern

### Criterion 3

> Each past event card is tappable and opens the event detail.

Fit: **Yes, with one necessary supporting fix**

- cards already navigate to `/event/:id`
- this ticket must also update event detail resolution for read-only/public opens so taps succeed outside the owner's editable event state

### Criterion 4

> If the community has fewer than 3 past events, the section shows what it has. If zero, the section is hidden.

Fit: **Yes**

- section renders 1..5 items
- section is hidden when empty

### Criterion 5

> Past events ordering: most recent first.

Fit: **Yes**

- ordering is explicitly part of the design and must be guaranteed by API order or client-side sort

## Testing Strategy

### Widget tests

- preview mode shows banner for owned published community offers
- preview mode keeps CTA visible and disabled
- business view does not show preview banner
- past-events section appears when events exist
- past-events section is hidden when events are empty
- past-events section respects max item count and newest-first rendering

### Interaction tests

- tapping a past-event card navigates to event detail from the detail screen
- read-only event detail does not show destructive owner controls

### Regression checks

- existing business apply flow still works outside preview mode
- existing public profile past-event taps still work after the event-detail fix

## Files Likely Affected

- `lib/features/business/screens/community_offer_detail_screen.dart`
- `lib/features/event/providers/event_provider.dart`
- `lib/features/event/screens/event_detail_screen.dart`
- `lib/features/community/screens/my_opportunities_screen.dart` or `lib/features/kolab/widgets/my_kolab_card.dart`
- new or updated widget tests under `test/features/business/` and `test/features/event/`

## Risks and Constraints

- The current repo mixes `kolab` and `opportunity` management paths, so the preview entry point may require a small integration step even though the destination screen is clear.
- If the backend event API does not guarantee newest-first order, the client must normalize the ordering locally.
- If event detail remains tied to `eventsProvider` only, the new section will appear to work visually but fail functionally on tap.

## Out of Scope

- redesigning the accepted-collaboration workflow
- changing the public profile layout beyond benefiting from the shared event-detail fix
- introducing editing tools inside preview mode
- changing how past events are authored or uploaded
