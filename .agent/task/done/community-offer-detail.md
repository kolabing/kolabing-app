# Task: Community Offer Detail Page

## Status
- Created: 2026-01-26 15:00
- Started: 2026-01-26 15:00
- Completed: 2026-01-26 15:30

## Description
Create a detail page for community offers/opportunities in the Business Explore screen.
When a business clicks "VIEW" on a collab request card, they should see:
1. Full event/offer details (title, description, dates, location, reward)
2. Event photos gallery (if available)
3. Community profile info
4. Community's previous events/collaborations
5. Apply button

## User Flow
```
Business Explore Screen
  → Tap "VIEW" on CollabRequest card
  → Community Offer Detail Screen
    - Hero section with community info
    - Event details card
    - Photos gallery (carousel)
    - Previous events section
    - Apply CTA button
```

## Data Requirements

### Current CollabRequest Model Has:
- id, title, description
- communityName, communityUsername, communityAvatarUrl
- collabType, location, startDate, endDate
- status, hasReward, rewardDescription

### Missing Data (Need API/Extensions):
- Event photos array (new field)
- Community's previous events list (new endpoint)
- Community profile details (bio, follower count, social links)

## API Endpoints

### Existing:
- GET /api/v1/opportunities - List all opportunities ✓
- GET /api/v1/opportunities/:id - Get single opportunity detail (need to verify)

### Missing/Needed:
- GET /api/v1/opportunities/:id/photos - Event photos
- GET /api/v1/communities/:id/events - Community's past events
- GET /api/v1/communities/:id - Community profile detail

## Design Requirements
- Yellow header with community avatar and name
- White cards for sections
- Photo carousel with page indicators
- Previous events as horizontal scroll cards
- Fixed bottom Apply button

## Assigned Agents
- [x] @ui-designer - Detail page UI specifications
- [x] @flutter-expert - Implementation

## Files to Create/Modify
1. lib/features/business/screens/community_offer_detail_screen.dart (NEW)
2. lib/features/business/providers/explore_provider.dart (extend for detail)
3. lib/features/business/services/explore_service.dart (add detail endpoint)
4. lib/config/routes/routes.dart (add route)
5. lib/features/business/screens/explore_screen.dart (navigation)

## Definition of Done
- [x] Detail screen displays all offer information
- [x] Photo gallery works (or gracefully handles no photos)
- [x] Previous events section displays (or shows empty state)
- [x] Navigation from explore screen works
- [x] Apply button triggers application flow
- [x] Loading/Error states implemented
- [x] Code compiles without errors
