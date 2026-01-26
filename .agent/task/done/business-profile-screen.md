# Task: Business Profile Screen

## Status
- Created: 2026-01-26 14:30
- Started: 2026-01-26 14:30
- Completed: 2026-01-26 15:15

## Description
Implement the complete Business Profile screen with the following features:
- Profile card with photo, business name, and type badge
- About section
- Contact info section (email, phone, website, instagram)
- Notification preferences with toggle switches
- Subscription management (for business users)
- Account section with sign out and delete account

## Related API Endpoints
- [x] GET /api/v1/me/profile - Get full profile
- [x] PUT /api/v1/me/profile - Update profile
- [x] DELETE /api/v1/me/account - Delete account
- [x] GET /api/v1/me/notification-preferences - Get preferences
- [x] PUT /api/v1/me/notification-preferences - Update preferences
- [x] GET /api/v1/me/subscription - Get subscription
- [x] POST /api/v1/me/subscription/checkout - Create checkout
- [x] GET /api/v1/me/subscription/portal - Get portal URL
- [x] POST /api/v1/me/subscription/cancel - Cancel subscription

## Assigned Agents
- [x] @ux-designer
- [x] @flutter-expert

## Progress

### UX Design
**Status:** Complete

#### User Flow
1. User navigates to Profile tab
2. Screen loads profile data, notification preferences, and subscription
3. User can view all profile information
4. User can tap "Edit Profile" to navigate to edit screen (future)
5. User can toggle notification preferences (instant save)
6. User can manage subscription (Stripe portal/checkout)
7. User can sign out
8. User can delete account (with confirmation)

#### UI Components
1. **Profile Card**
   - Circular avatar (80x80dp) with placeholder
   - Business name (headline)
   - Business type badge
   - Edit Profile button (outlined)

2. **About Section**
   - Section header "About"
   - Description text
   - Empty state if no description

3. **Contact Info Section**
   - Section header "Contact Info"
   - List tiles: email, phone, website, instagram
   - Icons for each item

4. **Notification Preferences Section**
   - Section header "Notification Preferences"
   - 5 toggle switches:
     - Email Notifications
     - WhatsApp Notifications
     - New Application Alerts
     - Collaboration Updates
     - Marketing & Tips

5. **Subscription Section** (Business only)
   - Section header "Subscription"
   - Status badge (Active/Inactive/Cancelled/Past Due)
   - Period end date
   - Days remaining
   - Cancel at period end warning
   - Manage Subscription button (if active)
   - View Plans button (if inactive)

6. **Account Section**
   - Section header "Account"
   - Email display
   - Sign Out button (outlined, red)
   - Delete Account button (text, danger)

#### States
- **Loading:** Shimmer placeholders for all sections
- **Error:** Error message with retry button
- **Success:** Full profile display
- **Empty Subscription:** Show "View Plans" CTA

### Flutter Implementation
**Status:** Complete

#### Files Created
- lib/features/business/screens/business_profile_screen.dart
- lib/features/business/models/notification_preferences.dart
- lib/features/business/models/subscription.dart
- lib/features/business/services/profile_service.dart
- lib/features/business/providers/profile_provider.dart

#### Modified Files
- lib/features/business/screens/business_main_screen.dart (integrated profile screen)

## Notes
- Use existing KolabingColors, KolabingSpacing, KolabingRadius
- Follow existing patterns from explore_screen.dart
- Subscription features are business-only
- Sign out clears all cached data and navigates to welcome
