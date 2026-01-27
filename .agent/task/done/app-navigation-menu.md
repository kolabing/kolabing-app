# Task: App Navigation Menu - Business & Community

## Status
- Created: 2026-01-25 21:30
- Started: 2026-01-25 21:30
- Completed: 2026-01-25 22:00

## Description
Business ve Community kullanıcıları için ayrı bottom navigation menu tasarla ve implement et.

## User Types & Navigation Needs

### Business User
- **Primary Actions:** Create opportunities, manage received applications, track collaborations
- **Browse:** Find communities to collaborate with

### Community User
- **Primary Actions:** Browse opportunities, apply, track sent applications, manage collaborations
- **Create:** Can also create opportunities for businesses

## API Endpoints Reference

### For Business Users
- `GET /opportunities` - Browse opportunities (from communities)
- `GET /me/opportunities` - My created opportunities
- `GET /me/received-applications` - Applications received
- `GET /collaborations` - Active collaborations

### For Community Users
- `GET /opportunities` - Browse opportunities (from businesses)
- `GET /me/opportunities` - My created opportunities
- `GET /me/applications` - My sent applications
- `GET /collaborations` - Active collaborations

## Assigned Agents
- [x] @ui-designer - Navigation UX design
- [x] @flutter-expert - Implementation

## Progress

### UX Design
**Status:** Completed

#### Business User Navigation
| Position | Label | Icon (Lucide) | Badge Logic |
|----------|-------|---------------|-------------|
| 1 | Home | `Home` | None |
| 2 | Browse | `Search` | None |
| 3 | My Offers | `Briefcase` | Count of draft/pending offers |
| 4 | Applications | `Inbox` | Count of unread/pending applications |
| 5 | Profile | `User` | Notification dot for incomplete profile |

#### Community User Navigation
| Position | Label | Icon (Lucide) | Badge Logic |
|----------|-------|---------------|-------------|
| 1 | Home | `Home` | None |
| 2 | Explore | `Compass` | None |
| 3 | My Opps | `Star` | Count of active opportunities |
| 4 | Applications | `Send` | Count of unread status updates |
| 5 | Profile | `User` | Notification dot for incomplete profile |

#### Navigation States
- **Inactive:** Icon/Label #9CA3AF (Gray-400)
- **Active:** Icon #FFD861 (Primary Yellow), Label #232323 (Text Primary)
- **Pressed:** Icon #E5C057 (Darker Yellow) with ripple effect

#### Badge Styling
- **Numeric Badge:** Background #E14D76 (Red), Text White, 18dp pill shape
- **Dot Badge:** 8dp diameter, Yellow or Red depending on urgency

#### FAB Configuration
- **Icon:** `Plus` (Lucide)
- **Position:** Bottom right, 16dp from edges, above nav bar
- **Action:** Opens create flow (Offer for Business, Opportunity for Community)
- **Style:** 56dp diameter, #FFD861 background, #232323 icon

#### Navigation Bar Container
- Background: #FFFFFF
- Height: 64dp + safe area
- Border Top: 1dp solid #E5E7EB

### Flutter Implementation
**Status:** Completed

#### Files Created
- `lib/widgets/navigation/kolabing_bottom_nav_bar.dart` - Bottom nav bar widget
- `lib/widgets/navigation/kolabing_fab.dart` - FAB widget
- `lib/widgets/navigation/navigation.dart` - Export barrel file
- `lib/features/business/screens/business_main_screen.dart` - Business main screen
- `lib/features/community/screens/community_main_screen.dart` - Community main screen

#### Files Modified
- `lib/config/routes/routes.dart` - Updated routes for main screens

## Implementation Checklist
- [x] Create `BusinessMainScreen` with bottom navigation
- [x] Create `CommunityMainScreen` with bottom navigation
- [x] Implement `KolabingBottomNavBar` widget
- [x] Implement `KolabingFAB` widget
- [x] Create placeholder screens for each tab
- [x] Update GoRouter configuration
- [x] Handle FAB visibility on specific routes
- [ ] Add badge providers (Riverpod) - Future task when API integration ready

## Notes
- Badge count from API: pending applications count, unread notifications
- Quick action: FAB for create opportunity
- Profile access from navigation
- Use IndexedStack for state preservation
- Hide FAB on detail screens and create flows
- Badge providers will be implemented when API endpoints are integrated
