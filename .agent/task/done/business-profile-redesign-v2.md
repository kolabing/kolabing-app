# Task: Business Profile Redesign V2

## Status
- Created: 2026-01-26 14:35
- Started: 2026-01-26 14:35
- Completed:

## Description
Redesign Business Profile screen to match the web design with:
1. Yellow header card with profile photo, name, type badge, and edit button
2. About section card
3. Contact Info card with all social links
4. Business Photos gallery with upload capability
5. Past Collaborations section
6. Subscription status
7. Account settings (sign out, delete)

## Reference: Web Design
- Yellow (#FFD861) header card with rounded corners
- Profile photo in circle with white border
- Business name in bold black
- Type badge (e.g., "OTHER", "COWORKING") in dark pill
- "EDIT PROFILE" button with icon on right side
- About and Contact Info in separate white cards
- Clean, modern, spacious layout

## New Features Required
- Business Photos upload (gallery)
- Past Collaborations list
- Subscription management

## Related API Endpoints
- GET /api/v1/me/profile - Get profile
- PUT /api/v1/me/profile - Update profile
- POST /api/v1/me/profile/photo - Upload photo
- GET /api/v1/me/collaborations - Get past collaborations
- GET /api/v1/me/subscription - Get subscription

## Assigned Agents
- [ ] @brand-designer - Brand guidelines for profile
- [ ] @ui-designer - Full UI/UX specifications
- [ ] @flutter-expert - Implementation

## Definition of Done
- [ ] Yellow header card matching web design
- [ ] All profile sections implemented
- [ ] Photo upload working
- [ ] Collaborations list displayed
- [ ] Subscription section working
- [ ] Code compiles without errors
