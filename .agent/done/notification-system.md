# Task: Notification System

## Status
- Created: 2026-01-30
- Started: 2026-01-30
- Completed: 2026-01-30

## Description
Design and implement a notification system for the app.
- Application messaging notifications
- Notification page with badge on top-right
- Kollab request (application) received notifications
- Backend API integration (real endpoints)

## Assigned Agents
- [x] @ui-designer
- [x] @flutter-expert

## Progress

### UX Design
**Status:** Complete

### Flutter Implementation
**Status:** Complete

#### API Integration (2026-01-30)
- Replaced mock NotificationService with real HTTP calls (http.Client + AuthService)
- Endpoints: GET /me/notifications, GET /me/notifications/unread-count, POST /me/notifications/{id}/read, POST /me/notifications/read-all
- Added pagination support (PaginatedResponse, infinite scroll)
- Updated NotificationState with currentPage, lastPage, total, isLoadingMore, hasMore
- Updated NotificationNotifier with loadMore() for infinite scroll
- Updated NotificationsScreen with ScrollController infinite scroll detection
- Navigation: new_message -> chat screen, other types -> application detail screen
- Error handling: ApiException, AuthException, NetworkException (consistent with ApplicationService)

## Notes
- FCM push notification integration deferred (backend endpoint not ready yet)
- Badge count refreshes via unreadNotificationCountProvider
