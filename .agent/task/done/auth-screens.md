# Task: Authentication Screens (Google OAuth)

## Status
- Created: 2026-01-25 15:15
- Started: 2026-01-25 16:00
- Completed: 2026-01-25 17:30

## Description
Google OAuth ile login ve register ekranlarini tasarla ve implemente et.

## Related API Endpoints
- [x] POST /auth/google - Google OAuth login/register
- [x] GET /auth/me - Get current user
- [x] POST /auth/logout - Logout

## API Documentation
Kaynak: api_integration_documentations/docs/MOBILE_API_DOCUMENTATION.md

### POST /auth/google
Request:
```json
{
  "id_token": "eyJhbGciOiJSUzI1...",
  "user_type": "business" // or "community"
}
```

Response:
```json
{
  "success": true,
  "data": {
    "token": "1|abc123...",
    "is_new_user": false,
    "user": {
      "id": "...",
      "email": "...",
      "user_type": "business",
      "onboarding_completed": true
    }
  }
}
```

## Assigned Agents
- [x] @ui-designer
- [x] @flutter-expert

## Progress

### UX Design
**Status:** Completed

---

## 1. SIGN IN SCREEN

### Screen Layout

```
┌─────────────────────────────────────────────────────┐
│  Status Bar (dark icons)                            │
├─────────────────────────────────────────────────────┤
│  Background: #000000                                │
│                                                     │
│  [Safe Area Top = 60dp]                             │
│                                                     │
│                  ┌────────┐                         │
│                  │   K    │  72x72dp                │
│                  └────────┘                         │
│                  Kolabing                           │
│                  (white, 16sp)                      │
│                                                     │
│  [32dp spacing]                                     │
│                                                     │
│             WELCOME BACK                            │
│         (Rubik, 32sp, bold, white)                  │
│         (uppercase, letter-spacing: 1.5)            │
│                                                     │
│  [8dp spacing]                                      │
│                                                     │
│          Sign in to continue                        │
│       (Open Sans, 16sp, #888888)                    │
│                                                     │
│  [48dp spacing]                                     │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │  [Google Icon] Sign in with Google           │  │
│  │  (Yellow #FFD861, 52dp height)               │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  [24dp spacing]                                     │
│                                                     │
│         Don't have an account? Sign Up              │
│         (Open Sans, 14sp, white + yellow)           │
│                                                     │
│  [Bottom Safe Area = 40dp]                          │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Component Specifications

#### Logo Section
- **Logo Image:** 72x72dp circular container
- **Background:** #FFD861 (yellow circle)
- **Icon:** Black "K" mark, 48dp size
- **Text:** "Kolabing" below logo
  - Font: Open Sans, 16sp, Regular
  - Color: #FFFFFF
  - Spacing from logo: 8dp

#### Title Section
- **Main Heading:** "WELCOME BACK"
  - Font: Rubik, 32sp, ExtraBold (800)
  - Color: #FFFFFF
  - Text Transform: Uppercase
  - Letter Spacing: 1.5
  - Line Height: 1.2
  - Alignment: Center

- **Subtitle:** "Sign in to continue"
  - Font: Open Sans, 16sp, Regular
  - Color: #888888
  - Line Height: 1.5
  - Alignment: Center
  - Top Margin: 8dp

#### Google Sign In Button
- **Container:**
  - Width: Full width minus 32dp horizontal padding (16dp each side)
  - Height: 52dp
  - Background: #FFD861
  - Border Radius: 12dp
  - Shadow: 0px 1.5px 4px rgba(55, 73, 87, 0.11)

- **Content:**
  - Google "G" icon: 24x24dp, left aligned, 16dp from left edge
  - Text: "Sign in with Google"
    - Font: Darker Grotesque, 16sp, SemiBold
    - Color: #000000
    - Text Transform: Uppercase
    - Letter Spacing: 1.0
  - Layout: Row with icon + 12dp spacing + text, centered

- **Touch Feedback:**
  - Press: Scale to 0.98, opacity 0.9
  - Release: Spring back animation (200ms)

#### Footer Link
- **Text:** "Don't have an account? Sign Up"
  - "Don't have an account?" - Open Sans, 14sp, #FFFFFF
  - "Sign Up" - Open Sans, 14sp, #FFD861, SemiBold
  - Alignment: Center
  - Touch target: 48dp height minimum

- **Interaction:**
  - Tap "Sign Up" text navigates to Sign Up screen
  - Underline on "Sign Up" on press

### Screen States

#### 1. Default State
- All elements visible
- Button enabled
- No error messages

#### 2. Loading State
- Button shows centered CircularProgressIndicator
  - Size: 24dp
  - Stroke width: 2.5dp
  - Color: #000000
- Button text hidden
- Button disabled (no tap response)
- Link disabled and dimmed (opacity 0.5)

#### 3. Error State - Invalid Token
- Show SnackBar from bottom:
  - Background: #E14D76 (error red)
  - Text: "Authentication failed. Please try again."
  - Font: Open Sans, 14sp, SemiBold
  - Text Color: #FFFFFF
  - Height: 56dp
  - Border Radius: 12dp (top corners only)
  - Duration: 4 seconds
  - Action button: "Dismiss" (white text)

#### 4. Error State - User Type Mismatch (409)
- Show Dialog:
  - Background: #222222
  - Border Radius: 16dp
  - Padding: 24dp
  - Title: "Account Type Mismatch"
    - Font: Rubik, 20sp, Bold
    - Color: #FFFFFF
  - Message: "This Google account is registered as a [Business/Community] user. Please sign in from the correct screen."
    - Font: Open Sans, 14sp, Regular
    - Color: #CCCCCC
  - Button: "Got it" (Yellow, 48dp height)

#### 5. Error State - Network Error
- Show SnackBar:
  - Background: #E14D76
  - Text: "No internet connection. Please check your network."
  - Duration: 5 seconds
  - Action: "Retry"

#### 6. Success State
- Button shows checkmark icon (24dp, black) for 500ms
- Fade out screen (300ms)
- Navigate to appropriate screen:
  - If `is_new_user = true` → Onboarding flow
  - If `onboarding_completed = false` → Profile completion
  - If `onboarding_completed = true` → Dashboard (based on user_type)

### Spacing & Measurements

```dart
class SignInScreenLayout {
  static const double topSafeArea = 60;
  static const double bottomSafeArea = 40;
  static const double horizontalPadding = 16;

  static const double logoSize = 72;
  static const double logoToTitle = 32;
  static const double titleToSubtitle = 8;
  static const double subtitleToButton = 48;
  static const double buttonToFooter = 24;

  static const double buttonHeight = 52;
  static const double buttonRadius = 12;
}
```

### Accessibility

- Logo: Semantic label "Kolabing logo"
- Button: Semantic label "Sign in with Google button"
- Footer link: Semantic label "Don't have an account? Navigate to sign up screen"
- Loading state: Announce "Signing in with Google"
- Error state: Announce error message immediately
- Minimum contrast ratio: WCAG AA compliant

---

## 2. SIGN UP SCREEN

### Screen Layout

```
┌─────────────────────────────────────────────────────┐
│  Status Bar (dark icons)                            │
├─────────────────────────────────────────────────────┤
│  Background: #000000                                │
│                                                     │
│  [Safe Area Top = 60dp]                             │
│                                                     │
│                  ┌────────┐                         │
│                  │   K    │  72x72dp                │
│                  └────────┘                         │
│                  Kolabing                           │
│                  (white, 16sp)                      │
│                                                     │
│  [32dp spacing]                                     │
│                                                     │
│           CREATE ACCOUNT                            │
│         (Rubik, 32sp, bold, white)                  │
│         (uppercase, letter-spacing: 1.5)            │
│                                                     │
│  [8dp spacing]                                      │
│                                                     │
│    Join the collaboration marketplace               │
│       (Open Sans, 16sp, #888888)                    │
│                                                     │
│  [32dp spacing]                                     │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │  ┌──────────────────┬──────────────────┐     │  │
│  │  │    BUSINESS      │    COMMUNITY     │     │  │
│  │  │  (Active/Yellow) │   (Inactive)      │     │  │
│  │  └──────────────────┴──────────────────┘     │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  [32dp spacing]                                     │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │  [Google Icon] Sign in with Google           │  │
│  │  (Yellow #FFD861, 52dp height)               │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  [24dp spacing]                                     │
│                                                     │
│       Already have an account? Sign In              │
│         (Open Sans, 14sp, white + yellow)           │
│                                                     │
│  [Bottom Safe Area = 40dp]                          │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Component Specifications

#### User Type Toggle (Segmented Control)

**Container:**
- Width: Full width minus 32dp horizontal padding
- Height: 48dp
- Background: Transparent
- Border: 1px solid #444444
- Border Radius: 12dp
- Padding: 4dp internal

**Segment Layout:**
- Two equal-width segments
- Gap between segments: 4dp
- Each segment: 50% width minus 2dp

**Active Segment (Selected):**
- Background: #FFD861
- Text Color: #000000
- Font: Darker Grotesque, 16sp, SemiBold
- Text Transform: Uppercase
- Letter Spacing: 0.8
- Border Radius: 10dp (inside container)
- Shadow: 0px 1px 2px rgba(0, 0, 0, 0.2)

**Inactive Segment:**
- Background: Transparent
- Text Color: #FFFFFF
- Font: Darker Grotesque, 16sp, Medium
- Text Transform: Uppercase
- Letter Spacing: 0.8
- Border Radius: 10dp

**Interaction:**
- Tap switches selection with animation
- Spring animation: 250ms, Curves.easeOut
- Active segment slides to new position
- Text color cross-fades: 200ms

**States:**
- Default: "BUSINESS" selected
- Hover/Press: Scale active segment to 0.98
- Disabled: Opacity 0.5, no interaction

#### Google Sign In Button
Same as Sign In screen specifications.

#### Footer Link
- **Text:** "Already have an account? Sign In"
  - "Already have an account?" - Open Sans, 14sp, #FFFFFF
  - "Sign In" - Open Sans, 14sp, #FFD861, SemiBold
  - Alignment: Center

### User Type Toggle Behavior

```dart
class UserTypeToggleState {
  UserType selectedType = UserType.business; // Default

  void onToggle(UserType newType) {
    // 1. Animate background pill to new position (250ms)
    // 2. Cross-fade text colors (200ms)
    // 3. Haptic feedback (light impact)
    // 4. Update selected type
    selectedType = newType;
  }
}
```

**Business Selected:**
- Left segment highlighted
- User will be registered as business user
- Will see business onboarding after OAuth

**Community Selected:**
- Right segment highlighted
- User will be registered as community user
- Will see community onboarding after OAuth

### Screen States

#### 1. Default State
- Business type selected by default
- All elements visible and enabled
- No error messages

#### 2. Type Toggle Interaction
- Smooth slide animation between segments
- Haptic feedback on toggle
- Text color transition
- No delay in interaction

#### 3. Loading State
- Toggle disabled (opacity 0.6, no interaction)
- Button shows CircularProgressIndicator
  - Size: 24dp
  - Stroke width: 2.5dp
  - Color: #000000
- Button text hidden
- Footer link disabled (opacity 0.5)

#### 4. Error State - Invalid Token
Same as Sign In screen error handling.

#### 5. Error State - User Type Mismatch (409)
- Show Dialog:
  - Background: #222222
  - Border Radius: 16dp
  - Padding: 24dp
  - Title: "Account Already Exists"
    - Font: Rubik, 20sp, Bold
    - Color: #FFFFFF
  - Message: "This Google account is already registered as a [Business/Community] user. Please switch to [Business/Community] or sign in instead."
    - Font: Open Sans, 14sp, Regular
    - Color: #CCCCCC
    - Line Height: 1.6
  - Actions Row:
    - "Switch Type" button (Yellow, auto-switches toggle)
    - "Go to Sign In" button (Outlined, navigates to sign in)

#### 6. Success State
- Button shows checkmark icon (24dp, black) for 500ms
- Fade out screen (300ms)
- Navigate to onboarding flow (since all new registrations go through onboarding)

### Spacing & Measurements

```dart
class SignUpScreenLayout {
  static const double topSafeArea = 60;
  static const double bottomSafeArea = 40;
  static const double horizontalPadding = 16;

  static const double logoSize = 72;
  static const double logoToTitle = 32;
  static const double titleToSubtitle = 8;
  static const double subtitleToToggle = 32;
  static const double toggleToButton = 32;
  static const double buttonToFooter = 24;

  static const double toggleHeight = 48;
  static const double toggleBorder = 1;
  static const double toggleInternalPadding = 4;
  static const double toggleRadius = 12;

  static const double buttonHeight = 52;
  static const double buttonRadius = 12;
}
```

### Accessibility
- Logo: Semantic label "Kolabing logo"
- Toggle: Semantic label "Select account type. Business or Community. Currently selected: Business"
- Button: Semantic label "Sign up with Google button"
- Footer link: Semantic label "Already have an account? Navigate to sign in screen"
- Toggle interaction: Announce "Business selected" or "Community selected"

---

## 3. UI COMPONENTS LIBRARY

### GoogleSignInButton

**Component Structure:**
```dart
class GoogleSignInButton {
  final VoidCallback onPressed;
  final bool isLoading;
  final String buttonText; // "Sign in with Google" or "Sign up with Google"
}
```

**Visual Specifications:**
- Width: MediaQuery.width - 32dp
- Height: 52dp
- Background: #FFD861
- Border Radius: 12dp
- Shadow: BoxShadow(
    color: rgba(55, 73, 87, 0.11),
    blurRadius: 4,
    offset: Offset(0, 1.5)
  )

**Icon + Text Layout:**
- Horizontal padding: 16dp
- Icon: Google "G" logo SVG, 24x24dp
- Gap between icon and text: 12dp
- Text: Darker Grotesque, 16sp, SemiBold, #000000, Uppercase
- Alignment: Center (icon-text group centered)

**Interaction States:**
- Default: Full opacity
- Pressed: Scale 0.98, opacity 0.9, duration 100ms
- Disabled: Opacity 0.6, no interaction
- Loading: Show black CircularProgressIndicator (24dp), hide text

**Animations:**
- Press down: Scale + opacity change (100ms, easeOut)
- Release: Spring back (200ms, easeOut)
- Loading start: Text fade out (150ms) → Spinner fade in (150ms)
- Success: Spinner → Checkmark (300ms), then navigate

---

### UserTypeToggle (Segmented Control)

**Component Structure:**
```dart
class UserTypeToggle {
  final UserType selectedType;
  final ValueChanged<UserType> onChanged;
  final bool isEnabled;
}

enum UserType { business, community }
```

**Visual Specifications:**
- Width: MediaQuery.width - 32dp
- Height: 48dp
- Background: Transparent
- Border: 1px solid #444444
- Border Radius: 12dp
- Internal Padding: 4dp

**Segment Specifications:**
- Each segment width: (container width - 8dp - 4dp gap) / 2
- Height: 40dp (48dp - 4dp top - 4dp bottom)
- Border Radius: 10dp

**Active Segment:**
- Background: #FFD861
- Text: #000000, Darker Grotesque, 16sp, SemiBold, Uppercase
- Shadow: 0px 1px 2px rgba(0, 0, 0, 0.2)
- Z-index: Above inactive segment

**Inactive Segment:**
- Background: Transparent
- Text: #FFFFFF, Darker Grotesque, 16sp, Medium, Uppercase
- No shadow

**Animation Flow:**
```
User taps inactive segment:
1. Haptic feedback (HapticFeedback.lightImpact())
2. Active background pill slides to new position (250ms, Curves.easeOut)
3. Text colors cross-fade (200ms, Curves.easeInOut)
4. Update selectedType state
5. Call onChanged callback
```

**Labels:**
- Business segment: "BUSINESS"
- Community segment: "COMMUNITY"

**Disabled State:**
- Opacity: 0.6
- No tap response
- Cursor: not-allowed

---

### KolabingLogo Widget

**Component Structure:**
```dart
class KolabingLogo {
  final double size;
  final bool showText;
}
```

**Specifications:**
- Default size: 72dp
- Circle background: #FFD861
- "K" icon: Black, centered, size = circle size * 0.67
- Text below (if showText = true):
  - "Kolabing"
  - Font: Open Sans, size * 0.22, Regular
  - Color: #FFFFFF (on dark) or #232323 (on light)
  - Margin top: size * 0.11

**Variations:**
- Small: 40dp (no text)
- Medium: 56dp (optional text)
- Large: 72dp (with text) - Auth screens
- XLarge: 96dp (with text) - Splash screen

---

### AuthLink (Footer Navigation)

**Component Structure:**
```dart
class AuthLink {
  final String leadingText;    // "Don't have an account?"
  final String actionText;     // "Sign Up"
  final VoidCallback onTap;
  final bool isEnabled;
}
```

**Visual Specifications:**
- Leading text: Open Sans, 14sp, Regular, #FFFFFF
- Action text: Open Sans, 14sp, SemiBold, #FFD861
- Spacing between texts: 4dp
- Alignment: Center

**Touch Target:**
- Minimum height: 48dp
- Horizontal padding: 16dp
- Vertical padding: 12dp

**Interaction:**
- Press: Action text underline appears
- Press: Scale 0.98
- Release: Navigate to target screen
- Duration: 100ms

**Disabled State:**
- Opacity: 0.5
- No interaction

---

## 4. ERROR HANDLING & FEEDBACK

### Toast/SnackBar Specifications

**Container:**
- Width: MediaQuery.width - 32dp (16dp margin each side)
- Height: Auto (minimum 56dp)
- Border Radius: 12dp (top) or 12dp (all sides if floating)
- Margin from bottom: 16dp
- Position: Bottom of screen

**Error Toast:**
- Background: #E14D76
- Text Color: #FFFFFF
- Icon: Alert circle, 20dp, white
- Layout: Icon + 12dp + Text + 16dp + Action

**Success Toast:**
- Background: #7AE7A3
- Text Color: #000000
- Icon: Checkmark circle, 20dp, black

**Warning Toast:**
- Background: #FBC02D
- Text Color: #000000
- Icon: Warning triangle, 20dp, black

**Animation:**
- Enter: Slide up from bottom (300ms, Curves.easeOut)
- Exit: Slide down + fade (250ms, Curves.easeIn)
- Auto-dismiss: 4 seconds (6 seconds if has action button)

### Dialog Specifications

**Container:**
- Width: MediaQuery.width - 64dp (max 400dp)
- Background: #222222 (dark theme)
- Border Radius: 16dp
- Padding: 24dp

**Title:**
- Font: Rubik, 20sp, Bold
- Color: #FFFFFF
- Margin bottom: 12dp

**Message:**
- Font: Open Sans, 14sp, Regular
- Color: #CCCCCC
- Line Height: 1.6
- Margin bottom: 24dp

**Action Buttons:**
- Layout: Row, main axis end alignment
- Gap: 12dp
- Button height: 44dp
- Primary action: Yellow button
- Secondary action: Text button (white text)

**Backdrop:**
- Color: rgba(0, 0, 0, 0.6)
- Blur: 4px backdrop filter

**Animation:**
- Enter: Fade in backdrop (200ms) + Scale dialog from 0.9 to 1.0 (300ms, Curves.easeOut)
- Exit: Fade out backdrop (200ms) + Scale dialog to 0.9 (200ms, Curves.easeIn)

---

## 5. NAVIGATION FLOW

### Sign In Navigation

```
Sign In Screen
      │
      ├─ Tap "Sign Up" link → Sign Up Screen
      │
      └─ Tap Google Sign In button
            │
            ├─ Success + is_new_user = true → Onboarding Flow
            │
            ├─ Success + onboarding_completed = false → Profile Completion
            │
            └─ Success + onboarding_completed = true → Dashboard
                  │
                  ├─ user_type = "business" → Business Dashboard
                  │
                  └─ user_type = "community" → Community Dashboard
```

### Sign Up Navigation

```
Sign Up Screen
      │
      ├─ Tap "Sign In" link → Sign In Screen
      │
      └─ Tap Google Sign In button
            │
            ├─ Success (is_new_user = true) → Onboarding Flow
            │
            └─ Error (409 User Type Mismatch) → Show Dialog
                  │
                  ├─ "Switch Type" → Auto-switch toggle, stay on screen
                  │
                  └─ "Go to Sign In" → Navigate to Sign In Screen
```

### Route Transitions

**Push Navigation (Forward):**
- Type: Slide from right (iOS) / Fade (Android)
- Duration: 300ms
- Curve: Curves.easeInOut

**Pop Navigation (Back):**
- Type: Slide to right (iOS) / Fade (Android)
- Duration: 250ms
- Curve: Curves.easeIn

**Modal Presentation:**
- Type: Slide from bottom
- Duration: 300ms
- Curve: Curves.easeOut

---

## 6. RESPONSIVE DESIGN

### Mobile Portrait (Default)
- Screen width: 360-428dp
- Layout: Single column, centered content
- Logo: 72dp
- Horizontal padding: 16dp
- All elements stack vertically

### Mobile Landscape
- Logo: 56dp (smaller)
- Reduce vertical spacing by 25%
- Keep horizontal padding: 16dp
- May need scrollable content

### Tablet (600dp+)
- Max content width: 400dp, centered
- Logo: 80dp
- Horizontal padding: 24dp
- Increase spacing slightly (+20%)

---

## 7. ANIMATIONS & MICRO-INTERACTIONS

### Screen Entry Animation
```dart
void initState() {
  super.initState();
  // Fade in from black
  _fadeController.forward();

  // Stagger element animations:
  // 1. Logo fades + scales in (300ms, delay 0ms)
  // 2. Title slides up + fades (300ms, delay 100ms)
  // 3. Subtitle slides up + fades (300ms, delay 150ms)
  // 4. Toggle/Button slides up + fades (300ms, delay 200ms)
  // 5. Footer link fades in (200ms, delay 300ms)
}
```

### Button Press Animation
1. Scale to 0.98 (100ms, Curves.easeOut)
2. Opacity to 0.9
3. Haptic feedback (medium impact)
4. On release: Spring back (200ms, Curves.elasticOut)

### Toggle Switch Animation
1. Haptic feedback (light impact)
2. Active pill slides horizontally (250ms, Curves.easeOut)
3. Text colors cross-fade (200ms, linear)
4. Subtle scale on tap (0.98)

### Loading Animation
1. Text fades out (150ms)
2. Spinner fades in at center (150ms)
3. Spinner rotates continuously
4. On success: Spinner → Checkmark morph (200ms)

### Success Animation
1. Button background pulse (300ms)
2. Checkmark scale in (200ms, Curves.elasticOut)
3. Screen fade out (300ms) after 500ms delay
4. Navigate to next screen

---

## 8. ACCESSIBILITY REQUIREMENTS

### Semantic Labels

**Sign In Screen:**
- Logo: "Kolabing application logo"
- Title: Header role, "Welcome back"
- Subtitle: "Sign in to continue"
- Google button: "Sign in with Google button. Tap to authenticate with your Google account."
- Footer link: "Don't have an account? Tap Sign Up to create a new account"

**Sign Up Screen:**
- Logo: "Kolabing application logo"
- Title: Header role, "Create account"
- Subtitle: "Join the collaboration marketplace"
- Toggle: "Select account type. Two options: Business or Community. Currently selected: Business. Double tap to switch."
- Google button: "Sign up with Google button. Account type: Business. Tap to authenticate."
- Footer link: "Already have an account? Tap Sign In to access your account"

### Screen Reader Flow

**Sign In:**
1. "Sign in screen"
2. "Kolabing application logo"
3. "Heading: Welcome back"
4. "Sign in to continue"
5. "Button: Sign in with Google"
6. "Link: Don't have an account? Sign Up"

**Sign Up:**
1. "Sign up screen"
2. "Kolabing application logo"
3. "Heading: Create account"
4. "Join the collaboration marketplace"
5. "Toggle control: Select account type. Business or Community. Business selected"
6. "Button: Sign up with Google. Account type: Business"
7. "Link: Already have an account? Sign In"

### Keyboard Navigation
- Tab order: Logo (focusable) → Toggle (if Sign Up) → Google Button → Footer Link
- Enter/Space: Activate focused element
- Arrow keys: Switch toggle selection
- Escape: Dismiss any open dialogs

### Focus Indicators
- Focus ring: 2px solid #FFD861
- Focus ring offset: 2dp outside element
- Focus ring radius: Element radius + 2dp

### Color Contrast Ratios
- White text on black: 21:1 (AAA)
- Yellow primary on black: 12.6:1 (AAA)
- Black text on yellow: 12.6:1 (AAA)
- Gray subtitle on black: 7.2:1 (AA)
- Yellow link text on black: 12.6:1 (AAA)

### Dynamic Type Support
- Support system font scaling up to 200%
- Maintain minimum touch targets (48dp)
- Allow vertical scroll if content exceeds screen

---

## 9. PLATFORM-SPECIFIC ADAPTATIONS

### iOS Specific

**Status Bar:**
- Style: Light content (white icons)
- Background: Black
- Height: Dynamic (includes notch/Dynamic Island)

**Safe Areas:**
- Top: Status bar + notch/Dynamic Island
- Bottom: Home indicator (34dp on notched devices)

**Haptics:**
- Toggle switch: UIImpactFeedbackGenerator.light
- Button press: UIImpactFeedbackGenerator.medium
- Error: UINotificationFeedbackGenerator.error
- Success: UINotificationFeedbackGenerator.success

**Navigation:**
- Swipe from left edge: Pop navigation (not applicable on auth screens)
- iOS modal presentation: Slide up from bottom

**Keyboard:**
- Dismiss on tap outside (if keyboard visible)
- Safe area adjusts for keyboard

---

### Android Specific

**Status Bar:**
- Color: #000000
- Icons: Light (white)
- Edge-to-edge mode enabled

**Navigation Bar:**
- Color: #000000
- Icons: Light (white)
- Gesture navigation support

**Haptics:**
- Toggle switch: HapticFeedback.lightImpact()
- Button press: HapticFeedback.mediumImpact()
- Error: HapticFeedback.heavyImpact()

**Back Button:**
- Hardware back button: Pop navigation
- Show exit confirmation if on root auth screen

**Keyboard:**
- Adjust layout with android:windowSoftInputMode="adjustResize"
- Material ripple effect on touch

---

## 10. ERROR SCENARIOS & USER FEEDBACK

### Error Type Matrix

| Error Code | Scenario | UI Response | User Action |
|------------|----------|-------------|-------------|
| 400 | Invalid Google token | SnackBar: "Authentication failed" | Retry Sign In |
| 401 | Token expired | Auto-logout → Sign In screen | Sign in again |
| 403 | Access denied | Dialog: "Access denied" | Contact support |
| 409 | User type mismatch | Dialog: Switch type or Sign In | Switch or navigate |
| 422 | Validation error | Field-level error messages | Fix and resubmit |
| 500 | Server error | SnackBar: "Server error" | Retry later |
| Network | No connection | SnackBar: "No internet" | Check connection |
| Timeout | Request timeout | SnackBar: "Request timed out" | Retry |

### Error Message Copy

**Network Errors:**
- No connection: "No internet connection. Please check your network and try again."
- Timeout: "Request timed out. Please try again."
- Unknown: "Something went wrong. Please try again later."

**Authentication Errors:**
- Invalid token: "Authentication failed. Please try signing in again."
- Token expired: "Your session has expired. Please sign in again."
- User type mismatch: "This Google account is registered as a [type] user. Please select [type] or sign in instead."

**Server Errors:**
- 500 error: "Server error. We're working on fixing this. Please try again later."
- 503 unavailable: "Service temporarily unavailable. Please try again in a few minutes."

### Success Messages

**Sign In Success:**
- No toast/snackbar (direct navigation)
- Optional: Brief checkmark animation on button

**Sign Up Success:**
- No toast/snackbar (proceed to onboarding)
- Button morphs to checkmark

---

## 11. INTERACTION GUIDELINES

### Touch Gestures

**Google Sign In Button:**
- Tap: Trigger Google OAuth flow
- Long press: No action (disabled)
- Double tap: Same as single tap

**User Type Toggle:**
- Tap inactive segment: Switch selection
- Tap active segment: No action
- Long press: No action
- Swipe left/right: No action (future: could switch)

**Footer Link:**
- Tap action text: Navigate to target screen
- Tap leading text: Navigate to target screen (entire line is tappable)

### Visual Feedback

**Button Press:**
- Immediate scale feedback (100ms)
- Visual press state (opacity change)
- Haptic feedback

**Toggle Switch:**
- Immediate animation start
- Smooth pill slide
- Color transition
- Haptic feedback

**Loading States:**
- Spinner appears within 100ms
- Smooth opacity transitions
- No jank or flicker

---

## 12. DEVELOPMENT SPECIFICATIONS

### Widget Tree Structure

**Sign In Screen:**
```
Scaffold(
  backgroundColor: #000000,
  body: SafeArea(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: center,
        children: [
          Spacer(flex: 2),
          KolabingLogo(size: 72, showText: true),
          SizedBox(height: 32),
          Text("WELCOME BACK"), // Display style
          SizedBox(height: 8),
          Text("Sign in to continue"), // Body style
          SizedBox(height: 48),
          GoogleSignInButton(
            onPressed: _handleGoogleSignIn,
            isLoading: _isLoading,
            buttonText: "Sign in with Google",
          ),
          SizedBox(height: 24),
          AuthLink(
            leadingText: "Don't have an account?",
            actionText: "Sign Up",
            onTap: () => context.go('/auth/sign-up'),
          ),
          Spacer(flex: 3),
        ],
      ),
    ),
  ),
)
```

**Sign Up Screen:**
```
Scaffold(
  backgroundColor: #000000,
  body: SafeArea(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: center,
        children: [
          Spacer(flex: 2),
          KolabingLogo(size: 72, showText: true),
          SizedBox(height: 32),
          Text("CREATE ACCOUNT"), // Display style
          SizedBox(height: 8),
          Text("Join the collaboration marketplace"), // Body style
          SizedBox(height: 32),
          UserTypeToggle(
            selectedType: _userType,
            onChanged: (type) => setState(() => _userType = type),
            isEnabled: !_isLoading,
          ),
          SizedBox(height: 32),
          GoogleSignInButton(
            onPressed: _handleGoogleSignUp,
            isLoading: _isLoading,
            buttonText: "Sign up with Google",
          ),
          SizedBox(height: 24),
          AuthLink(
            leadingText: "Already have an account?",
            actionText: "Sign In",
            onTap: () => context.go('/auth/sign-in'),
          ),
          Spacer(flex: 3),
        ],
      ),
    ),
  ),
)
```

### State Management

```dart
class AuthState {
  final bool isLoading;
  final String? error;
  final User? user;
  final String? token;

  AuthState({
    this.isLoading = false,
    this.error,
    this.user,
    this.token,
  });
}

class SignUpScreenState {
  UserType selectedUserType = UserType.business;
  bool isLoading = false;
  String? errorMessage;
}
```

---

## 13. DESIGN CHECKLIST

### Sign In Screen
- [x] Logo centered at top (72dp, with text)
- [x] "WELCOME BACK" title (Rubik, 32sp, bold, uppercase, white)
- [x] "Sign in to continue" subtitle (Open Sans, 16sp, gray)
- [x] Google Sign In button (Yellow, 52dp, full width)
- [x] "Don't have account? Sign Up" link (white + yellow)
- [x] Loading state with spinner
- [x] Error states with SnackBar
- [x] Success state with navigation
- [x] Safe area handling (top + bottom)
- [x] Accessibility labels
- [x] Haptic feedback

### Sign Up Screen
- [x] Logo centered at top (72dp, with text)
- [x] "CREATE ACCOUNT" title (Rubik, 32sp, bold, uppercase, white)
- [x] "Join the collaboration marketplace" subtitle (Open Sans, 16sp, gray)
- [x] User Type Toggle (Business/Community, segmented control)
- [x] Toggle default state (Business selected)
- [x] Toggle animation (250ms slide)
- [x] Google Sign In button (Yellow, 52dp, full width)
- [x] "Already have account? Sign In" link (white + yellow)
- [x] Loading state with spinner
- [x] Error states with Dialog and SnackBar
- [x] User type mismatch handling (409 error)
- [x] Success state with navigation to onboarding
- [x] Safe area handling
- [x] Accessibility labels
- [x] Haptic feedback

### Shared Components
- [x] GoogleSignInButton with loading/success/error states
- [x] UserTypeToggle with smooth animations
- [x] KolabingLogo with size variants
- [x] AuthLink with press feedback
- [x] Error SnackBar component
- [x] Error Dialog component
- [x] Responsive layout system

---

## SUMMARY

The UX design for Google OAuth authentication screens follows these principles:

1. **Minimal & Focused:** Only essential elements, no distractions
2. **Dark Theme:** Black background creates premium feel for auth screens
3. **Clear Hierarchy:** Logo → Title → Action → Link
4. **User Type Clarity:** Segmented toggle makes business/community choice obvious
5. **Smooth Interactions:** Animations provide feedback and guide attention
6. **Error Resilience:** Comprehensive error handling with clear recovery paths
7. **Accessibility First:** Full screen reader, keyboard, and dynamic type support
8. **Platform Native:** Respects iOS and Android design patterns

**Key Differentiators:**
- Sign In: No user type selection (determined from existing account)
- Sign Up: User type toggle required before OAuth
- Both screens: Google-only authentication (no email/password forms)
- Error handling: User type mismatch gracefully handled with actionable dialog

**Navigation Logic:**
- Sign In → Check `is_new_user` + `onboarding_completed` → Route accordingly
- Sign Up → Always route to onboarding (new users only)
- User type passed to API determines onboarding flow and dashboard type

### Flutter Implementation
**Status:** Completed

#### Files Created
- lib/features/auth/screens/sign_in_screen.dart - Sign In screen with Google OAuth
- lib/features/auth/screens/sign_up_screen.dart - Sign Up screen with user type toggle
- lib/features/auth/widgets/google_sign_in_button.dart - Reusable Google sign-in button
- lib/features/auth/widgets/user_type_toggle.dart - Business/Community toggle
- lib/features/auth/widgets/kolabing_logo.dart - Logo widget with text
- lib/features/auth/widgets/auth_link.dart - Footer navigation link
- lib/features/auth/widgets/widgets.dart - Barrel export
- lib/features/auth/providers/auth_provider.dart - Riverpod auth state management
- lib/features/auth/services/auth_service.dart - Google OAuth + API service (mock mode)
- lib/features/auth/models/auth_response.dart - API response models
- lib/features/auth/models/user_model.dart - User, Profile, City models
- lib/features/auth/models/models.dart - Barrel export

#### Updated Files
- lib/config/routes/routes.dart - Added SignInScreen and SignUpScreen routes
- pubspec.yaml - Added google_sign_in package

#### Dependencies Used
- google_sign_in: ^6.2.1 (Google OAuth)
- flutter_riverpod (state management)
- go_router (navigation)
- flutter_secure_storage (token storage)

#### Navigation Flow
```
Sign In -> Google OAuth ->
  - is_new_user=true -> Onboarding
  - is_new_user=false, onboarding_completed=false -> Onboarding
  - is_new_user=false, onboarding_completed=true -> Dashboard (based on user_type)

Sign Up -> Select Type -> Google OAuth ->
  - Always -> Onboarding
```

#### Mock API
- Mock mode enabled by default (_useMockApi = true)
- Simulates 1.5s network delay
- 10% chance of user type mismatch error (409) for testing
- 5% chance of network error for testing
- Random isNewUser response for testing both flows

#### Error Handling
- AuthCancelledException: User cancelled Google sign-in
- ApiException: API errors (400, 401, 403, 409, 422, 500)
- NetworkException: Network connectivity issues
- SnackBar for network/general errors
- Dialog for user type mismatch (409)

## Notes
- Google Sign In iOS/Android konfigurasyonu gerekli
- Token secure storage'da saklanmali
- User type mismatch hatasi handle edilmeli (409)
