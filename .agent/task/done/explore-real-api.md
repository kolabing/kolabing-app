# Task: Explore Screen Real API Integration

## Status
- Created: 2026-01-26 15:45
- Started: 2026-01-26 15:45
- Completed: 2026-01-26 15:55

## Description
Update Explore screen to work with real API data instead of mock data fallback.

## Changes Made

### 1. CollabRequest Model (`lib/features/business/models/collab_request.dart`)
- Fixed `id` parsing to handle both int and String from API
- Added `communityId` field for API calls
- Added support for nested `user` object (alternative to `community`)
- Added support for `business_name`, `slug` field mappings
- Added `profile_photo` field mapping for avatar
- Added `event_date` as fallback for `start_date`
- Added new fields: `expectedAttendees`, `budget`, `requirements`
- Improved date parsing with try-catch for invalid formats
- Added `_parseDate` and `_parseDateNullable` helper methods

### 2. ExploreService (`lib/features/business/services/explore_service.dart`)
- Removed mock data fallback on API error (now throws proper exception)
- Added detailed debug logging for API responses
- Improved error handling with per-item parsing (skips invalid items)
- Fixed cities endpoint to handle empty responses
- Returns empty list instead of mock data on cities error

## API Endpoints Used
- GET /api/v1/opportunities - List collaboration opportunities
- GET /api/v1/cities - List available cities for filtering

## API Response Format Expected
```json
{
  "data": [
    {
      "id": 1,
      "title": "Event Title",
      "description": "...",
      "type": "event",
      "status": "active",
      "start_date": "2026-01-26",
      "end_date": null,
      "location": "Barcelona",
      "has_reward": true,
      "reward_description": "...",
      "user": {
        "id": 1,
        "name": "Community Name",
        "username": "community_handle",
        "profile_photo": "https://..."
      }
    }
  ]
}
```

## Definition of Done
- [x] Model handles various API response formats
- [x] Service uses real API without mock fallback
- [x] Proper error handling and logging
- [x] Code compiles without errors
