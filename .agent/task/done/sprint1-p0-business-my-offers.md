# Task: Business "My Offers" Screen

## Status
- Created: 2026-02-01 12:00
- Started: 2026-02-01 12:00
- Completed:

## Description
Create the "My Offers" screen for Business users. Currently the "My Offers" tab in BusinessMainScreen shows the Dashboard instead of an actual offers list. This breaks the core Business user journey.

Reference: Community side has MyOpportunitiesScreen with full CRUD - use same patterns.

## Related API Endpoints
- [x] GET /api/v1/me/collab-requests (list own offers with pagination)
- [x] POST /api/v1/collab-requests (create - already exists)
- [ ] PUT /api/v1/collab-requests/{id} (update)
- [ ] POST /api/v1/collab-requests/{id}/publish
- [ ] POST /api/v1/collab-requests/{id}/close
- [ ] DELETE /api/v1/collab-requests/{id}

## Dependencies
- Depends on: None
- Blocks: Task 2 (Received Applications), Task 4 (Badge counts)

## Assigned Agents
- [x] @flutter-expert

## Progress

### Flutter Implementation
**Status:** In Progress
- Screens: MyOffersScreen (new)
- Widgets: MyOfferCard (new)
- State Management: Riverpod - MyOffersProvider, MyOffersNotifier
- API Integration: CollabRequestService (new or extend existing)
- Navigation: Update BusinessMainScreen _BusinessOffersTab to use MyOffersScreen
- Also: Add Dashboard as first tab, shift offers to second tab

## Notes
- Follow same patterns as MyOpportunitiesScreen
- Status tabs: All, Draft, Published, Closed
- Actions: Edit, Publish, Close, Delete
- Shimmer loading, empty state, error state, pull-to-refresh, pagination
