# Collab Completion Review Flow Design

## Goal
Replace the mixed completion/feedback system with one product flow:

1. A collaboration is completed as soon as one participant confirms it happened.
2. Both participants can later leave one lightweight optional review each.
3. Public profiles show recent review cards and a full review list page.

## Product Decisions
- Completion is one-sided: first participant to confirm moves the collaboration to `completed`.
- Completion still awards XP to both parties immediately.
- Review is optional, not blocking.
- Review shape is lightweight only: `rating`, `body`, `would_collaborate_again`.
- Public profile summary stats card is removed.
- Public profile shows the latest 3 received reviews and a `View more` entry into a paginated review list.
- The old detailed post-collaboration feedback flow is removed from the active product path.

## Backend Design

### Completion
- Keep `POST /api/v1/collaborations/{id}/complete` as the single completion endpoint.
- Remove the old `finish` route from the active API surface.
- `complete()` remains responsible for changing status and awarding XP.

### Review
- Keep `POST /api/v1/collaborations/{id}/review`.
- One review per reviewer per collaboration.
- `reviewed_profile_id` remains the source of truth for profile review aggregation.

### Public Profile
- Extend `GET /api/v1/profiles/{id}` to include:
  - `recent_reviews`: latest 3 received reviews
- Add `GET /api/v1/profiles/{id}/reviews`:
  - paginated
  - newest first
  - includes reviewer identity, rating, body, would-collaborate-again, created_at
- Remove `review_stats` from the public profile contract used by the app.

### Legacy Feedback Cleanup
- Remove the old `/finish` route from `routes/api.php`.
- Remove `finish()` from `CollaborationController`.
- Remove `FinishCollaborationRequest` from the active path.
- Remove `CollaborationFeedback` serialization from `CollaborationResource`.
- Leave the existing `collaboration_feedback` table in place for now to avoid destructive deploy risk.

## Mobile Design

### Collaboration Detail
- Completion CTA uses only the completion sheet and `POST /complete`.
- Post-completion area shows:
  - `Leave review` CTA when the viewer has not reviewed
  - `Review submitted` state when they have

### Completion Sheet
- Fix the broken completion service import and network call.
- Keep it lightweight: confirm, celebrate XP, close.

### Public Profile
- Remove the review reputation summary card.
- Add a `Recent Reviews` section that renders up to 3 review cards.
- Add `View more` to push a dedicated review list screen.

### Review List Screen
- New paginated screen for all received reviews on a profile.

### Legacy Cleanup
- Remove the old feedback sheet, draft model, and feedback provider from the mobile app.

## Verification
- Backend:
  - review endpoint still works
  - profile endpoint returns recent reviews
  - reviews list endpoint paginates correctly
  - `/finish` is no longer exposed
- Mobile:
  - collaboration detail builds
  - completion sheet builds and submits
  - public profile renders recent reviews
  - review list screen navigates and paginates
