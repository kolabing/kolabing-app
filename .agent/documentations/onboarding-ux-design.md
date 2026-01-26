# Kolabing Onboarding Flow - UX Design

**Version:** 2.0
**Date:** 2026-01-25
**Designer:** @ux-designer

---

## Overview

New onboarding flow where Google Sign In happens AFTER data collection, not before.

### Key Changes from v1.0

1. **Google Sign In moved to END** - Users complete onboarding BEFORE authentication
2. **No email/password registration** - Google OAuth only
3. **User type selection first** - Determines onboarding path
4. **4-step wizard** - Collect profile data progressively
5. **Final review screen** - Confirm data before Google Sign In

---

## User Flow

```
User Type Selection
    ↓
Onboarding Step 1: Basics (Photo + Name)
    ↓
Onboarding Step 2: Type Selection (Business/Community Type)
    ↓
Onboarding Step 3: City Selection
    ↓
Onboarding Step 4: Details (About + Social Links)
    ↓
Final Review Screen
    ↓
"Complete with Google" Button
    ↓
Google OAuth
    ↓
POST /auth/google {id_token, user_type}
    ↓
PUT /onboarding/business or /onboarding/community
    ↓
Dashboard
```

---

## Screen-by-Screen Breakdown

### 1. User Type Selection

**Purpose:** Choose Business or Community path

**Components:**
- Two large selection cards
- Business: "I want to find communities"
- Community: "I want to find businesses and sponsors"
- Continue button (disabled until selection)
- "Already have account? Sign In" link

**Validation:**
- User type required before proceeding

**Design:**
- Selected card: Yellow border (#FFD861), soft yellow background (#FFF6D8)
- Unselected: White background, gray border
- Card height: 120dp
- Spacing: 16dp between cards

---

### 2. Business Onboarding (4 Steps)

#### Step 1: Basics
- Profile photo upload (optional, circle, 80x80dp)
- Business name (required, max 255 chars)
- Character counter
- Continue button (disabled if name empty)

#### Step 2: Business Type
- Grid of 10 business types (cafe, restaurant, bar, etc.)
- 3 columns, 96dp height per card
- Icon + label in each card
- Single selection
- Data from `GET /lookup/business-types`

#### Step 3: City
- Search bar for filtering
- List of cities with country
- Data from `GET /cities`
- Selected city highlighted with yellow accent
- Popular cities shown first

#### Step 4: Details
- About (multiline, max 1000 chars, optional)
- Phone number (optional, +34 prefix)
- Instagram handle (optional, @ prefix)
- Website (optional, https:// prefix)
- All fields optional, continue always enabled

---

### 3. Community Onboarding (4 Steps)

#### Step 1: Basics
- Profile photo upload (optional)
- Display name (required, max 255 chars)

#### Step 2: Community Type
- Grid of 10 community types (food blogger, influencer, etc.)
- Same layout as business type selection
- Data from `GET /lookup/community-types`

#### Step 3: City
- Identical to business city selection

#### Step 4: Details
- About/Bio (multiline, max 1000 chars, optional)
- Instagram (optional)
- TikTok (optional)
- Website (optional)

---

### 4. Final Review Screen

**Purpose:** Show summary of collected data before Google Sign In

**Components:**
- Summary card with:
  - Profile photo (if uploaded)
  - Name
  - Type + City
  - About (first 2 lines)
  - Contact info (phone, social links)
- Edit button (goes back to step 1)
- "Complete with Google" button (primary, yellow)
- Terms & Privacy links

**Action:**
- Tapping "Complete with Google" triggers:
  1. Google OAuth flow
  2. POST /auth/google with collected data
  3. Store auth token
  4. PUT /onboarding/business or /onboarding/community
  5. Navigate to dashboard

---

## Design System Reference

### Colors

| Element | Color | Usage |
|---------|-------|-------|
| Primary button | #FFD861 | Continue, Complete with Google |
| Primary text | #232323 | Headlines, labels |
| Secondary text | #606060 | Descriptions, hints |
| Background | #F7F8FA | Main screen background |
| Card background | #FFFFFF | Input fields, cards |
| Selected state | #FFF6D8 | Selected card background |
| Border active | #FFD861 | Selected card border |
| Border default | #EBEBEB | Default borders |
| Error | #E14D76 | Validation errors |
| Input background | #F5F6F8 | Text field backgrounds |

### Typography

| Style | Font | Size | Weight | Usage |
|-------|------|------|--------|-------|
| Headline | Rubik | 20-24sp | Semibold/Bold | Screen titles |
| Description | Open Sans | 14sp | Regular | Helper text |
| Input text | Open Sans | 16sp | Regular | Form inputs |
| Input label | Open Sans | 14sp | Medium | Field labels |
| Button | Darker Grotesque | 16sp | Semibold | Button text |
| Caption | Open Sans | 12sp | Regular | Hints, counters |

### Spacing

| Element | Value |
|---------|-------|
| Screen padding | 16dp horizontal |
| Section spacing | 24dp vertical |
| Input field spacing | 16dp vertical |
| Button height | 52dp |
| Input height | 52dp |
| Card radius | 12-16dp |
| Button radius | 12dp |

---

## Components

### Progress Indicator
- 4 circles connected by lines
- Active: Filled yellow (#FFD861)
- Inactive: Filled gray (#E8E8E8)
- Circle diameter: 12dp
- Line height: 2dp
- Spacing: 24dp between circles

### Onboarding Header
- Back button (left, 40x40dp touch)
- "Step X of 4" text (12sp, gray)
- Skip button (right, text button) - only on optional steps
- Progress indicator

### Selection Card
- Default: White bg, 1px gray border
- Selected: Soft yellow bg, 2px yellow border
- Pressed: Scale 0.98
- Icon: 32dp centered
- Label: 14sp semibold
- Minimum height: 96dp

### Photo Upload
- Circle shape, 80x80dp
- Empty state: Dashed border, camera icon
- With image: Solid yellow border
- Tap to upload/change
- Max size: 5MB
- Formats: jpg, png, webp

### Summary Card
- White background
- 1px border #EBEBEB
- 16dp radius
- 20dp padding
- Includes all collected data
- Read-only display

---

## Validation Rules

### Required Fields

**Business:**
- name (Step 1)
- business_type (Step 2)
- city_id (Step 3)

**Community:**
- name (Step 1)
- community_type (Step 2)
- city_id (Step 3)

### Optional Fields
- profile_photo
- about
- phone_number
- instagram
- tiktok (community only)
- website

### Field Constraints

| Field | Max Length | Format |
|-------|------------|--------|
| name | 255 chars | Text |
| about | 1000 chars | Multiline text |
| phone_number | - | E.164 (+34...) |
| instagram | - | Alphanumeric, no @ |
| tiktok | - | Alphanumeric, no @ |
| website | - | Valid URL (https://) |
| profile_photo | 5MB | jpg/png/webp |

---

## States

### Loading States

**Button Loading:**
- Spinner icon (20dp) replaces text
- Button stays yellow
- Disabled state active

**Full Screen Loading:**
- Semi-transparent overlay (40% black)
- Yellow spinner (48dp)
- "Signing in with Google..." text

### Error States

**Field Validation Error:**
- Border: 1px solid #E14D76
- Background tint: #FFF5F7
- Error message below field (12sp, #E14D76)
- Icon: ⚠️

**API Error:**
- Error card with red border
- Error message
- "Try Again" button
- Option to go back

### Empty States

**No cities found (search):**
- "No cities match your search"
- Clear search button

**Photo not uploaded:**
- Camera icon placeholder
- "Add photo (optional)" text

---

## Animations

### Transitions
- Page forward: Slide from right (300ms, easeInOut)
- Page backward: Slide to right (250ms, easeOut)
- Modal: Slide up (250ms)

### Interactions
- Button press: Scale 0.98 (100ms)
- Card selection: Border + background animate (150ms)
- Progress fill: 200ms per step

### Loading
- Spinner rotation: Continuous
- Button spinner: Fade in 200ms

---

## Accessibility

### Touch Targets
- Minimum: 48x48dp
- Buttons: 52dp height
- Cards: Full card tappable

### Screen Reader
- Progress announced: "Step 1 of 4, Profile setup"
- Required fields: "Business name, required field"
- Optional fields: "Instagram, optional"
- Skip button: "Skip this step"

### Keyboard Navigation
- Tab order: Logical top-to-bottom
- Enter: Proceed/select
- Escape: Go back
- Focus indicators: Yellow outline

### Color Contrast
- Primary text on white: 15.5:1 (AAA)
- Secondary text on white: 7:1 (AA)
- Black text on yellow: 12:1 (AAA)

---

## API Integration

### Endpoints Used

1. **GET /lookup/business-types**
   - Called once, cached 7 days
   - Used in Business Step 2

2. **GET /lookup/community-types**
   - Called once, cached 7 days
   - Used in Community Step 2

3. **GET /cities**
   - Called once, cached 24 hours
   - Used in Step 3 (both flows)

4. **POST /auth/google**
   - Called after final screen
   - Payload: `{id_token, user_type}`
   - Returns: `{token, user, is_new_user}`

5. **PUT /onboarding/business** or **PUT /onboarding/community**
   - Called after successful Google auth
   - Payload: All collected data
   - Returns: Updated user profile

### Data Storage

**Local State (before auth):**
```json
{
  "user_type": "business",
  "name": "Café Barcelona",
  "profile_photo": "data:image/jpeg;base64,...",
  "business_type": "cafe",
  "city_id": "uuid-here",
  "about": "Artisan coffee shop...",
  "phone_number": "+34612345678",
  "instagram": "cafebarcelona",
  "website": "https://cafebarcelona.com"
}
```

**After Auth:**
- Token stored in secure storage (Keychain/EncryptedSharedPrefs)
- User profile stored in app state
- Navigate to dashboard

---

## Error Handling

### Network Errors
- Show error message
- "Try Again" button
- Option to go back and edit

### Google Sign In Cancelled
- Return to final review screen
- Show message: "Sign in cancelled. Try again when ready."

### API Validation Errors
- Map field errors to respective steps
- Navigate back to error step
- Highlight error fields
- Show specific error messages

### Photo Upload Errors
- File too large: "Photo must be under 5MB"
- Invalid format: "Only JPG, PNG, WEBP allowed"
- Upload failed: "Upload failed. Try again."

---

## Edge Cases

### Back Navigation
- Step 1: Go to user type selection
- Steps 2-4: Go to previous step
- Final review: Go to step 4
- Data preserved when going back

### Skip Button
- Available on Step 4 only (all fields optional)
- Skipping goes directly to final review
- Required fields (Steps 1-3) cannot be skipped

### Leaving Flow
- Show confirmation dialog: "Are you sure? Your progress will be lost."
- If confirmed: Clear local state, return to home

### Multiple User Type Mismatch
- If Google account already registered as different type
- Show error: "This account is already registered as [Business/Community]"
- Option to sign in instead

---

## Mobile Specifics

### iOS
- Native keyboard handling
- Photo picker: PHPickerViewController
- Haptic feedback on selection
- Safe area handling (notch, home indicator)

### Android
- Material keyboard handling
- Photo picker: Intent.ACTION_PICK_IMAGES
- Material ripple effects
- Edge-to-edge display

### Cross-Platform
- Same visual design
- Platform-specific photo pickers
- Platform-specific keyboard types
- Platform-specific animations (optional)

---

## Success Metrics

### UX Goals
- Completion rate > 80%
- Average time < 2 minutes
- Drop-off rate < 15% per step
- Error rate < 5%

### Tracking Events
- `onboarding_started` - User type selected
- `onboarding_step_completed` - Each step completion
- `onboarding_skipped` - Step 4 skipped
- `onboarding_completed` - Google sign in successful
- `onboarding_abandoned` - User left flow

---

## Next Steps

1. @flutter-expert implements screens
2. Test with real users
3. Iterate based on drop-off data
4. A/B test optional vs required photo

---

**Design Status:** Complete ✓
**Ready for Implementation:** Yes
**Approved by:** Product Team
