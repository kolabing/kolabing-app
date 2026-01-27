# Task: Business Explore Screen

## Status
- Created: 2026-01-26 00:00
- Started: 2026-01-26 00:00
- Completed: 2026-01-26

## Description
Design and implement the Business Explore screen where businesses can browse and discover community collaboration requests. The screen should display collab request cards with filtering capabilities.

## Reference (Web Version Analysis)
Based on provided screenshots:
- Grid of collaboration request cards
- Search bar at top
- Filter dropdowns: Community Type, Location, Collaboration Type, Reward Type
- Card shows: Community avatar, name, username, status badge, description, type tag, location tag
- Action buttons: View Details, Apply

## Feature Requirements

### Screen Components
1. **Search Bar** - Search collabs by title, community, keywords
2. **Filter Section** - Filter chips/dropdowns
3. **Results Counter** - "Showing X of Y opportunities"
4. **Collab Request Cards** - Main content
5. **Empty State** - When no results

### Card Information Hierarchy (Priority Order)
1. **Who** - Community name + avatar (instant recognition)
2. **What** - Collab type (Event, Partnership, etc.)
3. **Where** - Location
4. **When** - Date range (start/end)
5. **Why** - Description/reward info
6. **Status** - Published, Active, etc.

### Mobile UX Improvements over Web
- Single column layout (not grid)
- Swipeable cards or vertical scroll
- Quick action gestures
- Collapsible filters
- Prominent primary action

## API Endpoints (Mock for now)
- GET /api/v1/collab-requests - List all collab requests
- GET /api/v1/collab-requests?filters - With filters
- GET /api/v1/collab-requests/{id} - Detail

## Assigned Agents
- [x] @ui-designer - UX design and card specifications
- [x] @ui-engineer - UI implementation

## Progress

### UX Design
**Status:** Completed

Detailed UX specifications created:
- Information hierarchy optimized for scannability
- Card layout with 4 zones: Header, Tags, Content, Action
- Component specifications with exact dimensions
- All states: default, pressed, loading, error, applied, saved
- Accessibility specifications

### UI Implementation
**Status:** Completed

Files created:
- `lib/features/business/models/collab_request.dart` - Data model with CollabType and CollabStatus enums
- `lib/features/business/services/explore_service.dart` - Mock service with 10 realistic collab requests
- `lib/features/business/providers/explore_provider.dart` - Riverpod providers with AsyncNotifier pattern
- `lib/features/business/widgets/collab_request_card.dart` - Card widget with avatar, status badge, tags, reward indicator
- `lib/features/business/screens/explore_screen.dart` - Main screen with search, filters, loading/empty/error states

Integration:
- ExploreScreen integrated into BusinessMainScreen Browse tab

## Notes
- Mock service returns 10 realistic Spanish collaboration opportunities
- Pull-to-refresh supported
- Filter by type (Event, Partnership, Campaign) and location
- Search by title, community name, username, description
- Card designed for easy scanning with clear information hierarchy
