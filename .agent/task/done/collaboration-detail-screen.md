# Task: Collaboration Detail & Event Management Screen

## Status
- Created: 2026-02-08
- Started: 2026-02-08
- Completed:

## Description
Build a comprehensive collaboration detail screen that both business and community users see after accepting a kolabing request. The screen shows:
- Event information (date, time, location)
- Partner information (business/community profile)
- Expectations from both sides (business offers + community deliverables)
- Full process timeline
- Gamification setup section (challenge selection, QR code setup)
- Mock data (no real API integration)
- API documentation for backend developer

## Assigned Agents
- [x] @ui-designer
- [x] @flutter-expert

## Progress

### UX Design
**Status:** Complete (inline)

#### User Flow
1. User accepts application -> navigates to collaboration detail
2. Screen shows all collaboration info in scrollable sections
3. Both business and community see same screen (role-aware content)
4. Challenge section allows selecting/managing challenges
5. QR code section shows event QR for check-in

#### UI Sections
1. **Header** - Status badge, collaboration title
2. **Event Info Card** - Date, time, location, venue type
3. **Partner Info Card** - Other party's profile (avatar, name, category, city)
4. **What's Offered / Expected** - Business offers & Community deliverables
5. **Process Timeline** - Visual timeline of collaboration stages
6. **Gamification Setup** - Challenge list with selection, difficulty indicators
7. **QR Code Section** - Generated QR for event check-in
8. **Action Buttons** - Context-specific actions

#### States
- [x] Loading state (shimmer)
- [x] Error state (retry)
- [x] Success state (full content)
- [x] Empty challenges state

### Flutter Implementation
**Status:** In Progress
- Screens: collaboration_detail_screen.dart
- Models: collaboration.dart (new)
- Provider: collaboration_detail_provider.dart (mock)
- Widgets: section widgets within screen file

## Notes
- Uses mock data, no real API calls
- API documentation generated for backend team
