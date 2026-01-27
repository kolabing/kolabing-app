# Task: Business Explore Screen - Backend Integration

## Status
- Created: 2026-01-26 15:00
- Started: 2026-01-26 15:00
- Completed: 2026-01-26 15:30

## Description
Connect the Business Explore screen to the real backend API. The UI is already implemented with mock data - this task focuses on integrating with the Laravel backend at `https://kolabing-v2-master-tgxggi.laravel.cloud/api/v1`.

## API Endpoints
- `GET /api/v1/collab-requests` - List all collab requests
- `GET /api/v1/collab-requests?type={type}&location={location}&query={query}` - With filters
- `GET /api/v1/collab-requests/{id}` - Detail (future)

## Expected API Response Format
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "community": {
        "id": "uuid",
        "name": "Community Name",
        "username": "handle",
        "avatar_url": "https://..."
      },
      "title": "Collab Title",
      "description": "Description text",
      "collab_type": "event|partnership|campaign",
      "location": "City Name",
      "start_date": "2026-03-15T00:00:00Z",
      "end_date": "2026-03-22T00:00:00Z",
      "status": "active|published|closed",
      "has_reward": true,
      "reward_description": "Reward details"
    }
  ],
  "meta": {
    "current_page": 1,
    "total": 100,
    "per_page": 20
  }
}
```

## Implementation Steps
1. [x] Update `ExploreService` to call real API with auth token
2. [x] Update `CollabRequest` model to match API response (added fromJson/toJson)
3. [x] Add proper error handling following existing patterns
4. [x] Test integration with loading/error/empty states
5. [x] Keep mock data fallback for development (debug mode fallback)

## Changes Made

### `lib/features/business/models/collab_request.dart`
- Added `fromString()` and `toApiValue()` methods to `CollabType` and `CollabStatus` enums
- Added `fromJson()` factory constructor to `CollabRequest` class
- Added `toJson()` method to `CollabRequest` class
- Handles both flat and nested API response formats (e.g., `community.name` or `community_name`)

### `lib/features/business/services/explore_service.dart`
- Refactored from singleton pattern to dependency injection pattern (with backward compatibility)
- Added `AuthService` integration for token management
- Added `_getHeaders()` method for authenticated requests
- `getCollabRequests()` now calls `GET /api/v1/collab-requests` with query params:
  - `search` - Search query
  - `type` - Collab type filter (event, partnership, campaign)
  - `location` - Location filter
- `getAvailableLocations()` attempts `GET /api/v1/locations` first, falls back to extracting from collab requests
- Added graceful fallback to mock data in debug mode when API fails
- Kept mock data for development and offline testing

## Assigned Agents
- [x] @flutter-expert

## Files to Modify
- `lib/features/business/services/explore_service.dart`
- `lib/features/business/models/collab_request.dart`
- `lib/features/business/providers/explore_provider.dart`

## Notes
- Follow existing API patterns from `profile_service.dart`
- Use AuthService for token management
- Handle 401 (session expired) and network errors
