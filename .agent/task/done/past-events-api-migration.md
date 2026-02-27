# Task: Past Events API Migration (Mock → Real API)

## Status
- Created: 2026-02-05
- Started: 2026-02-05
- Completed:

## Description
Migrate the Past Events feature from mock data to real API integration. Replace dummy API calls in EventService with real HTTP calls matching the API documentation.

## Related API Endpoints
- [x] GET /api/v1/events (list events with pagination & profile_id)
- [x] GET /api/v1/events/{id} (single event detail)
- [x] POST /api/v1/events (create event with multipart/form-data photos)
- [x] PUT /api/v1/events/{id} (update event - owner only)
- [x] DELETE /api/v1/events/{id} (delete event - owner only)

## Assigned Agents
- [x] @flutter-expert

## Progress

### Flutter Implementation
**Status:** In Progress
- [x] Update EventRequest model (File-based photos instead of base64)
- [x] Rewrite EventService with real HTTP calls
- [x] Update EventProvider for new service interface + pagination
- [x] Update AddEventModal for File upload
- [ ] Verify compilation

## Notes
- Uses http.Client + AuthService pattern (same as ApplicationService)
- Photos sent as multipart/form-data, NOT base64
- API response format: { success: true, data: { events: [...], pagination: {...} } }
- PUT endpoint does NOT support photo updates
