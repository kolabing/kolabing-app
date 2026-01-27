# Task: Business Profile Screen Redesign

## Status
- Created: 2026-01-26 17:15
- Started: 2026-01-26 17:15
- Completed: 2026-01-26 17:45

## Description
Redesign the Business Profile screen to:
1. Remove all debug information
2. Add profile photo upload capability
3. Display subscription status prominently
4. Create a clean, professional layout

## Current Issues
- Debug info card visible at top of screen
- Profile photo not editable
- Debug print statements throughout code
- Using simplified `_buildBodySafe` instead of full `_buildBody`

## Requirements

### UI Components
1. **Profile Header**
   - Large profile photo with edit overlay
   - Tap to change photo (camera or gallery)
   - Business name and type badge
   - Edit profile button

2. **About Section** (if available)
   - Business description

3. **Contact Info Section**
   - Email, phone, location
   - Social links (Instagram, website)

4. **Subscription Section** (Business only)
   - Status badge (Active, Cancelled, etc.)
   - Renewal date
   - Days remaining
   - Manage/Upgrade button

5. **Settings Section**
   - Notification preferences toggles

6. **Account Section**
   - Sign out button
   - Delete account (text link)

### Photo Upload Flow
1. Tap profile photo
2. Show bottom sheet: "Camera" or "Gallery"
3. Pick/capture image
4. Crop to square
5. Upload to API
6. Update local state

### API Endpoints
- `PUT /api/v1/me/profile` with `profile_photo` (base64 data URI)
- `GET /api/v1/me/subscription`
- `GET /api/v1/me/subscription/portal`

## Assigned Agents
- [x] @flutter-expert

## Files to Modify
- `lib/features/business/screens/business_profile_screen.dart`
- `lib/features/business/providers/profile_provider.dart` (add photo upload)
- `lib/features/business/services/profile_service.dart` (photo upload endpoint)
