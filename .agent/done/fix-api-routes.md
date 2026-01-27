# Task: Fix API Routes - Align with Backend

## Status
- Created: 2026-01-26 18:00
- Started: 2026-01-26 18:00
- Completed: 2026-01-26 18:15

## Description
Fix incorrect API endpoints in the Flutter app to match the actual backend routes.

## Incorrect Routes Found

### explore_service.dart
| Current (Wrong) | Correct | Purpose |
|-----------------|---------|---------|
| `/api/v1/collab-requests` | `/api/v1/opportunities` | Browse opportunities (Communities post, Businesses browse) |
| `/api/v1/locations` | `/api/v1/cities` | Get available cities for filtering |

## Correct API Endpoints (from backend)

### Auth
- `POST /api/v1/auth/login` ✅
- `POST /api/v1/auth/logout` ✅
- `GET /api/v1/auth/me` ✅
- `POST /api/v1/auth/google` ✅
- `POST /api/v1/auth/register/business` ✅
- `POST /api/v1/auth/register/community` ✅

### Profile (Me)
- `GET /api/v1/me/profile` ✅
- `PUT /api/v1/me/profile` ✅
- `DELETE /api/v1/me/account` ✅
- `GET /api/v1/me/notification-preferences` ✅
- `PUT /api/v1/me/notification-preferences` ✅
- `GET /api/v1/me/subscription` ✅
- `POST /api/v1/me/subscription/checkout` ✅
- `GET /api/v1/me/subscription/portal` ✅
- `POST /api/v1/me/subscription/cancel` ✅
- `GET /api/v1/me/applications` - My sent applications
- `GET /api/v1/me/received-applications` - Applications received
- `GET /api/v1/me/opportunities` - My posted opportunities

### Opportunities (Communities post, Businesses browse)
- `GET /api/v1/opportunities` - List all (for Business Explore)
- `POST /api/v1/opportunities` - Create new
- `GET /api/v1/opportunities/{id}` - Get detail
- `PUT /api/v1/opportunities/{id}` - Update
- `DELETE /api/v1/opportunities/{id}` - Delete
- `POST /api/v1/opportunities/{id}/publish` - Publish draft
- `POST /api/v1/opportunities/{id}/close` - Close opportunity
- `GET /api/v1/opportunities/{id}/applications` - Get applications for opportunity
- `POST /api/v1/opportunities/{id}/applications` - Apply to opportunity

### Applications
- `GET /api/v1/applications/{id}` - Get application detail
- `POST /api/v1/applications/{id}/accept` - Accept application
- `POST /api/v1/applications/{id}/decline` - Decline application
- `POST /api/v1/applications/{id}/withdraw` - Withdraw application

### Collaborations (Active partnerships)
- `GET /api/v1/collaborations` - List active collaborations
- `GET /api/v1/collaborations/{id}` - Get detail
- `POST /api/v1/collaborations/{id}/activate` - Activate
- `POST /api/v1/collaborations/{id}/cancel` - Cancel
- `POST /api/v1/collaborations/{id}/complete` - Mark complete

### Lookup
- `GET /api/v1/cities` - Available cities ✅
- `GET /api/v1/lookup/business-types` - Business types
- `GET /api/v1/lookup/community-types` - Community types

## Changes Required

### lib/features/business/services/explore_service.dart
1. Change `/collab-requests` → `/opportunities`
2. Change `/locations` → `/cities`
3. Rename method `getCollabRequests` → `getOpportunities` (optional)

## Assigned Agents
- [x] @flutter-expert
