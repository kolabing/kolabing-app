# Task: Redesign Splash Screen & Auth Flow

## Status
- Created: 2026-01-25 16:00
- Started: 2026-01-25 16:00
- Completed:

## Description
Splash screen ve authentication flow'u yeniden tasarla:

### Splash Screen
- Sarı arka plan (#FFD861)
- Siyah "K" logosu (ortalanmış)
- "Kolabing" yazısı logonun altında (siyah, Rubik font)
- 2-3 saniye sonra Welcome ekranına geçiş

### Welcome/Landing Screen (Splash sonrası)
- Kullanıcıyı karşılayan ekran
- "Login" ve "Create Account" seçenekleri
- Temaya uygun tasarım

### Auth Flow
- Login: Google Sign In -> Dashboard
- Register: User Type seçimi (Business/Community) -> Google Sign In -> Onboarding

## User Flow
```
App Start
    ↓
Splash Screen (2-3 sn)
    ↓
Welcome Screen
    ├── Login Button → Google Sign In → Dashboard
    └── Create Account → User Type Selection
                              ├── Business → Google Sign In → Business Onboarding
                              └── Community → Google Sign In → Community Onboarding
```

## Assigned Agents
- [ ] @ui-designer
- [ ] @flutter-expert

## Progress

### UX Design
**Status:** Completed
**Designer:** @ui-designer
**Completed:** 2026-01-25

---

## Screen 1: Splash Screen

### Purpose
First screen shown when app launches. Brand introduction with minimal delay.

### Layout Specifications

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                                                             │
│                                                             │
│                                                             │
│                         ┌───────┐                           │
│                         │       │                           │
│                         │   K   │  120x120dp                │
│                         │       │                           │
│                         └───────┘                           │
│                                                             │
│                        Kolabing                             │
│                     (Rubik ExtraBold)                       │
│                                                             │
│                                                             │
│                                                             │
│                                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Component Specifications

| Element | Specification |
|---------|--------------|
| **Background** | Solid #FFD861 (primary yellow) |
| **Logo "K"** | Black (#000000), size: 120x120dp, centered vertically and horizontally |
| **Logo Font** | Custom or Rubik ExtraBold, 80pt |
| **Text "Kolabing"** | Black (#000000), Rubik ExtraBold, 24pt, 16dp below logo |
| **Text Letter Spacing** | 1.0 |
| **Animation** | Fade in (200ms), hold (2000ms), fade out (300ms) |

### States

1. **Enter Animation** (0-200ms)
   - Fade in from opacity 0 to 1
   - Slight scale up from 0.9 to 1.0

2. **Hold State** (200-2200ms)
   - Full opacity, stable

3. **Exit Animation** (2200-2500ms)
   - Fade out to opacity 0
   - Navigate to Welcome Screen

### Technical Notes
- Total duration: 2500ms (2.5 seconds)
- No user interaction required
- Status bar: Hidden
- Navigation bar: Hidden

---

## Screen 2: Welcome Screen

### Purpose
Landing screen that introduces the app and provides clear paths to Login or Create Account.

### Layout Specifications

```
┌─────────────────────────────────────────────────────────────┐
│  Status Bar (Dark icons)                                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                                                             │
│                         ┌─────┐                             │
│                         │  K  │  80x80dp                    │
│                         └─────┘                             │
│                                                             │
│                        Kolabing                             │
│                                                             │
│                                                             │
│               WHERE BRANDS MEET                             │
│                    COMMUNITIES                              │
│                                                             │
│                                                             │
│     Connect with the perfect collaboration partner          │
│      to grow your business or community together            │
│                                                             │
│                                                             │
│                                                             │
│                                                             │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                   LOGIN                              │    │
│  │               (Primary Button)                       │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │               CREATE ACCOUNT                         │    │
│  │              (Secondary Button)                      │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│                                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Component Specifications

| Element | Specification |
|---------|--------------|
| **Background** | #F7F8FA (light gray background) |
| **Status Bar** | Light mode, dark icons |
| **Logo "K"** | Yellow (#FFD861) circle with black K, 80x80dp, centered |
| **App Name** | "Kolabing", Rubik Bold, 20pt, #232323, 12dp below logo |
| **Headline** | "WHERE BRANDS MEET COMMUNITIES", Rubik ExtraBold, 24pt, #232323, uppercase, letter-spacing: 1.5, center aligned, 32dp below app name |
| **Description** | Body text, Open Sans Regular, 16pt, #606060, center aligned, line-height: 1.6, 16dp below headline |
| **Buttons Container** | Positioned 64dp from bottom, 16dp horizontal padding |
| **Login Button** | Primary yellow button, full width, 52dp height, "LOGIN" text, 12dp bottom margin |
| **Create Account Button** | Secondary outlined button, full width, 48dp height, "CREATE ACCOUNT" text |

### Button Specifications

**Login Button (Primary)**
- Background: #FFD861
- Text: #000000, Darker Grotesque SemiBold, 16pt, uppercase
- Border radius: 12dp
- Height: 52dp
- Shadow: 0 1.5px 4px rgba(55, 73, 87, 0.11)
- Press state: Scale 0.98, background #E5C057

**Create Account Button (Secondary)**
- Background: transparent
- Border: 1.5px solid #EBEBEB
- Text: #232323, Darker Grotesque SemiBold, 16pt, uppercase
- Border radius: 12dp
- Height: 48dp
- Press state: Background #F5F6F8

### Animations

**Screen Enter** (from Splash)
- Fade in from opacity 0 to 1 (300ms)
- Elements slide up slightly (20dp) with stagger:
  - Logo: 0ms delay
  - App name: 50ms delay
  - Headline: 100ms delay
  - Description: 150ms delay
  - Buttons: 200ms delay

**Button Press**
- Scale animation: 1.0 → 0.98 (100ms)
- Haptic feedback: light impact

### User Actions

| Action | Navigation |
|--------|-----------|
| Login button tap | → Login Screen |
| Create Account button tap | → User Type Selection Screen |

---

## Screen 3: User Type Selection Screen

### Purpose
Allow new users to choose their account type before proceeding with Google Sign In.

### Layout Specifications

```
┌─────────────────────────────────────────────────────────────┐
│  Status Bar                                                 │
│  ┌──┐                                                       │
│  │ ← │  Back                                                │
│  └──┘                                                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                                                             │
│                 CHOOSE YOUR PATH                            │
│                                                             │
│         Select your account type to get started             │
│                                                             │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                                                     │    │
│  │                      🏢                              │    │
│  │                                                     │    │
│  │                 I'M A BUSINESS                       │    │
│  │                                                     │    │
│  │     Looking for communities to partner with         │    │
│  │                                                     │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                                                     │    │
│  │                      👥                              │    │
│  │                                                     │    │
│  │                I'M A COMMUNITY                       │    │
│  │                                                     │    │
│  │      Seeking sponsors and collaboration partners    │    │
│  │                                                     │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│                                                             │
│                                                             │
│            Already have an account? Login                   │
│                                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Component Specifications

| Element | Specification |
|---------|--------------|
| **Background** | #F7F8FA (light gray background) |
| **Back Button** | Icon + "Back" text, #232323, 16dp top-left padding, tap to return to Welcome |
| **Headline** | "CHOOSE YOUR PATH", Rubik ExtraBold, 24pt, #232323, uppercase, center aligned, 32dp from top |
| **Subtitle** | Open Sans Regular, 16pt, #606060, center aligned, 12dp below headline |
| **Card Spacing** | First card: 48dp below subtitle, Second card: 16dp below first card |
| **Bottom Link** | 24dp from bottom, center aligned |

### Selection Card Specifications

**Idle State**
- Background: #FFFFFF
- Border: 2px solid #EBEBEB
- Border radius: 16dp
- Padding: 32dp vertical, 24dp horizontal
- Shadow: 0 1.5px 8px rgba(55, 73, 87, 0.10)

**Hover/Press State**
- Border: 2px solid #FFD861
- Shadow: 0 4px 16px rgba(255, 216, 97, 0.20)
- Scale: 1.02

**Card Content Layout**
- Icon: 48x48dp emoji/icon, centered, top
- Title: 16dp below icon, Darker Grotesque Bold, 18pt, #232323, uppercase, center aligned
- Description: 8dp below title, Open Sans Regular, 14pt, #606060, center aligned

### Card Variants

**Business Card**
- Icon: 🏢 or custom business icon
- Title: "I'M A BUSINESS"
- Description: "Looking for communities to partner with"

**Community Card**
- Icon: 👥 or custom community icon
- Title: "I'M A COMMUNITY"
- Description: "Seeking sponsors and collaboration partners"

### Animations

**Card Selection**
- Tap animation: Scale 0.98 → 1.02 (150ms)
- Border color: #EBEBEB → #FFD861 (200ms)
- Haptic: Medium impact

**Selection Confirmation**
- Selected card scales up briefly (1.02 → 1.0)
- Fade out all elements (200ms)
- Navigate to Google Sign In

### User Actions

| Action | Result |
|--------|--------|
| Back button tap | → Return to Welcome Screen |
| Business card tap | Store user_type = 'business', → Google Sign In flow |
| Community card tap | Store user_type = 'community', → Google Sign In flow |
| "Login" link tap | → Login Screen |

---

## Screen 4: Login Screen

### Purpose
Simplified Google Sign In screen for existing users.

### Layout Specifications

```
┌─────────────────────────────────────────────────────────────┐
│  Status Bar (Light icons on dark)                          │
│  ┌──┐                                           Sign Up →   │
│  │ ← │  Back                                                │
│  └──┘                                                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                                                             │
│                         ┌─────┐                             │
│                         │  K  │  64x64dp                    │
│                         └─────┘                             │
│                                                             │
│                        Kolabing                             │
│                                                             │
│                                                             │
│                     WELCOME BACK                            │
│                                                             │
│                Sign in to your account                      │
│                                                             │
│                                                             │
│                                                             │
│                                                             │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  ┌─┐  Continue with Google                         │    │
│  │  └─┘                                                │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│                                                             │
│                                                             │
│                                                             │
│                                                             │
│                                                             │
│                Don't have an account?                       │
│                     Create One                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Component Specifications

| Element | Specification |
|---------|--------------|
| **Background** | #000000 (black) |
| **Status Bar** | Dark mode, light icons |
| **Navigation** | Back button (left), "Sign Up" link (right), white text |
| **Logo** | Yellow circle (#FFD861) with black K, 64x64dp |
| **App Name** | "Kolabing", Rubik Bold, 18pt, #FFFFFF, 12dp below logo |
| **Headline** | "WELCOME BACK", Rubik ExtraBold, 28pt, #FFFFFF, uppercase, 40dp below app name |
| **Subtitle** | "Sign in to your account", Open Sans Regular, 16pt, #888888, 12dp below headline |
| **Google Button** | 64dp below subtitle, full width (with 16dp side padding) |

### Google Sign In Button Specifications

**Appearance**
- Background: #FFFFFF
- Text: #232323, Darker Grotesque SemiBold, 16pt
- Height: 52dp
- Border radius: 12dp
- Google icon: 20x20dp, 16dp left padding
- Text: "Continue with Google", centered with icon
- Shadow: 0 1.5px 4px rgba(255, 255, 255, 0.10)

**Press State**
- Background: #F5F6F8
- Scale: 0.98

### Bottom Text Link

**Appearance**
- "Don't have an account?" - Open Sans Regular, 14pt, #888888
- "Create One" - Open Sans SemiBold, 14pt, #FFD861, underline on press
- Position: 32dp from bottom, center aligned

### Animations

**Screen Enter**
- Fade in from opacity 0 (300ms)
- Slide up 30dp (300ms, ease-out)

**Google Sign In Progress**
- Button shows loading spinner
- Text changes to "Signing in..."
- Disable user interaction

### User Actions & Flow

| Action | Result |
|--------|--------|
| Back button | → Return to Welcome Screen |
| "Sign Up" link | → User Type Selection Screen |
| Google Sign In button | Trigger Google OAuth flow |
| Google Sign In success | → Check user in database → Navigate to appropriate dashboard |
| Google Sign In failure | Show error toast, keep on screen |
| "Create One" link | → User Type Selection Screen |

---

## Screen 5: Google Sign In (Post-Selection)

### Purpose
Complete Google authentication after user type selection during registration.

### Layout Specifications

```
┌─────────────────────────────────────────────────────────────┐
│  Status Bar (Light icons on dark)                          │
│  ┌──┐                                                       │
│  │ ← │  Back                                                │
│  └──┘                                                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                                                             │
│                         ┌─────┐                             │
│                         │  K  │  64x64dp                    │
│                         └─────┘                             │
│                                                             │
│                        Kolabing                             │
│                                                             │
│                                                             │
│                   LET'S GET STARTED                         │
│                                                             │
│             Sign in with your Google account                │
│                                                             │
│                                                             │
│                                                             │
│                                                             │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  ┌─┐  Continue with Google                         │    │
│  │  └─┘                                                │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              Selected: Business                      │    │
│  │              (or Community)                          │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│                                                             │
│                                                             │
│                     Change Selection                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Component Specifications

| Element | Specification |
|---------|--------------|
| **Background** | #000000 (black) |
| **Status Bar** | Dark mode, light icons |
| **Back Button** | White icon + text, top-left |
| **Logo** | Yellow circle with black K, 64x64dp, centered |
| **App Name** | "Kolabing", Rubik Bold, 18pt, #FFFFFF |
| **Headline** | "LET'S GET STARTED", Rubik ExtraBold, 28pt, #FFFFFF, uppercase |
| **Subtitle** | "Sign in with your Google account", Open Sans Regular, 16pt, #888888 |
| **Google Button** | Same as Login Screen, 64dp below subtitle |
| **Selection Info Badge** | 16dp below Google button |
| **Change Link** | 24dp below badge, center aligned |

### Selection Info Badge Specifications

**Appearance**
- Background: rgba(255, 216, 97, 0.15)
- Border: 1px solid rgba(255, 216, 97, 0.3)
- Border radius: 8dp
- Padding: 12dp vertical, 16dp horizontal
- Text: "Selected: Business" (or Community)
- Font: Open Sans Medium, 14pt, #FFD861
- Icon: Small check mark or user type icon, 4dp left of text

### User Actions & Flow

| Action | Result |
|--------|--------|
| Back button | → Return to User Type Selection |
| Google Sign In button | Trigger Google OAuth with selected user_type |
| OAuth success | Create new user in database with user_type → Navigate to Onboarding (profile completion) |
| OAuth failure | Show error toast |
| "Change Selection" link | → Return to User Type Selection |

---

## Global Animations & Transitions

### Screen Transitions

**Forward Navigation** (Welcome → Selection → Sign In)
- Duration: 300ms
- Type: Slide from right + fade
- Curve: ease-in-out

**Backward Navigation** (Back button)
- Duration: 250ms
- Type: Slide to right + fade
- Curve: ease-out

**Modal/Bottom Sheet** (if needed for errors)
- Duration: 250ms
- Type: Slide up from bottom
- Backdrop: rgba(0, 0, 0, 0.5)

### Loading States

**Button Loading**
- Show spinner inside button
- Disable button interaction
- Text: "Loading..." or hide text
- Spinner: 20x20dp, white or black based on button type

**Full Screen Loading** (Google OAuth in progress)
- Show loading overlay with spinner
- Background: rgba(0, 0, 0, 0.7)
- Spinner: 32x32dp, white
- Optional text: "Authenticating..."

### Error States

**Toast Notifications**
- Position: Top of screen, 16dp from edges
- Background: #E14D76 (error red)
- Text: White, Open Sans Medium, 14pt
- Icon: Error icon, 16x16dp
- Duration: 3000ms auto-dismiss
- Animation: Slide down + fade in, slide up + fade out

**Inline Errors** (if validation needed)
- Error text: #E14D76, Open Sans Regular, 12pt
- Error icon: 14x14dp, left of text
- Position: 4dp below affected input/component

---

## User Flow Summary

```
App Launch
    ↓
Splash Screen (2.5s)
    ↓
Welcome Screen
    ├── Login Button
    │       ↓
    │   Login Screen
    │       ↓
    │   Google Sign In
    │       ↓
    │   Check existing user → Dashboard (based on user_type)
    │
    └── Create Account Button
            ↓
        User Type Selection
            ├── Business selected
            │       ↓
            │   Google Sign In (business)
            │       ↓
            │   Create user (user_type: business)
            │       ↓
            │   Onboarding/Profile Completion
            │       ↓
            │   Business Dashboard
            │
            └── Community selected
                    ↓
                Google Sign In (community)
                    ↓
                Create user (user_type: community)
                    ↓
                Onboarding/Profile Completion
                    ↓
                Community Dashboard
```

---

## Component Inventory

### Reusable Components Needed

1. **KolabingPrimaryButton**
   - Yellow background, black text, 52dp height
   - Used in: Welcome, User Selection, Sign In

2. **KolabingSecondaryButton**
   - White background, bordered, 48dp height
   - Used in: Welcome

3. **KolabingSelectionCard**
   - White background, icon + title + description
   - Interactive states: idle, pressed, selected
   - Used in: User Type Selection

4. **KolabingGoogleButton**
   - White background, Google icon + text
   - Used in: Login, Sign In flows

5. **KolabingTextLink**
   - Underlined text, color changes on press
   - Used in: Bottom navigation between auth screens

6. **KolabingBackButton**
   - Icon + optional "Back" text
   - Used in: All sub-screens

7. **KolabingLoadingSpinner**
   - Circular progress indicator
   - Variants: button-sized, screen overlay

8. **KolabingToast**
   - Error/success/info message
   - Auto-dismiss, slide animation

---

## Design Tokens Summary

### Colors Used

| Token | Hex | Usage |
|-------|-----|-------|
| primary | #FFD861 | Splash bg, buttons, accents |
| onPrimary | #000000 | Text on yellow |
| background | #F7F8FA | Light screen backgrounds |
| darkBackground | #000000 | Auth screen backgrounds |
| surface | #FFFFFF | Cards, buttons |
| textPrimary | #232323 | Primary text on light |
| textSecondary | #606060 | Secondary text on light |
| textTertiary | #888888 | Hint text, disabled |
| textOnDark | #FFFFFF | Text on black backgrounds |
| border | #EBEBEB | Default borders |
| borderFocus | #E8D7A0 | Focus state borders |
| error | #E14D76 | Error messages, alerts |

### Typography Used

| Style | Font | Size | Weight | Usage |
|-------|------|------|--------|-------|
| displayLarge | Rubik | 28pt | ExtraBold | Main headlines |
| displayMedium | Rubik | 24pt | ExtraBold | Section headlines |
| displaySmall | Rubik | 20pt | Bold | App name |
| bodyLarge | Open Sans | 16pt | Regular | Descriptions |
| bodyMedium | Open Sans | 14pt | Regular | Helper text |
| button | Darker Grotesque | 16pt | SemiBold | Button labels |
| labelMedium | Darker Grotesque | 14pt | Medium | Small labels |

### Spacing Used

| Token | Value | Usage |
|-------|-------|-------|
| xs | 8dp | Tight spacing |
| sm | 12dp | Small spacing |
| md | 16dp | Standard spacing, screen padding |
| lg | 24dp | Section spacing |
| xl | 32dp | Large gaps between sections |
| xxl | 48dp | Hero spacing |
| xxxl | 64dp | Extra large gaps |

### Border Radius Used

| Token | Value | Usage |
|-------|-------|-------|
| sm | 8dp | Small badges, info cards |
| md | 12dp | Buttons, inputs |
| lg | 16dp | Large cards, selection cards |

---

## Accessibility Considerations

### Touch Targets
- All buttons: minimum 48x48dp
- Cards: entire card tappable, minimum 120dp height
- Links: minimum 44dp tap target with padding

### Color Contrast
- Black on yellow (#000000 on #FFD861): 12:1 - Passes AAA
- Primary text on white (#232323 on #FFFFFF): 15.5:1 - Passes AAA
- Secondary text on white (#606060 on #FFFFFF): 7:1 - Passes AAA
- White on black (#FFFFFF on #000000): 21:1 - Passes AAA

### Screen Reader Support
- All buttons labeled with semantic descriptions
- Icons have alt text
- Screen titles announced on navigation
- Loading states announced

### Keyboard Navigation
- Tab order follows visual hierarchy
- Focus indicators visible on all interactive elements
- Enter/Space activates buttons
- Escape dismisses modals

---

## Success Metrics

### Performance Targets
- Splash screen load time: < 300ms
- Screen transitions: 300ms (smooth 60fps)
- Button press response: < 100ms
- Google OAuth complete: < 3s (network dependent)

### User Experience Goals
- Time to sign in: < 30s (from app launch)
- Account creation completion rate: > 80%
- User type selection clarity: < 5s decision time
- Zero confusion between Login/Sign Up paths

---

### Flutter Implementation
**Status:** Completed
**Developer:** @flutter-expert
**Completed:** 2026-01-25

#### Implemented Files

**New Screens:**
- `lib/features/auth/screens/splash_screen.dart` - Yellow background with black K logo, fade animations
- `lib/features/auth/screens/welcome_screen.dart` - Light mode landing with LOGIN/CREATE ACCOUNT buttons
- `lib/features/auth/screens/user_type_selection_screen.dart` - Business/Community card selection
- `lib/features/auth/screens/login_screen.dart` - Dark mode Google Sign In for existing users
- `lib/features/auth/screens/register_screen.dart` - Dark mode Google Sign In with user type badge

**Updated Widgets:**
- `lib/features/auth/widgets/kolabing_logo.dart` - Added size variants and logo variants
- `lib/features/auth/widgets/selection_card.dart` - New selection card widget for user type

**Updated Routes:**
- `lib/config/routes/routes.dart` - Added new routes: welcome, user-type, login, register

#### User Flow
```
Splash (2.5s, yellow bg)
    -> Welcome Screen (light mode)
        -> LOGIN -> Login Screen (dark mode) -> Google Sign In -> Dashboard
        -> CREATE ACCOUNT -> User Type Selection -> Register Screen (dark mode) -> Google Sign In -> Onboarding
```

#### Animation Specs Implemented
- Splash: fade in (200ms) + scale (0.9->1.0), hold (2s), fade out (300ms)
- Welcome: staggered entry with slide up (20dp) animations
- User Selection: staggered card animations
- Login/Register: slide up (30dp) + fade in animations
- Button press: scale (0.98) + haptic feedback

## Notes
- Real user perspective ile dusun
- Minimal ve anlasilir flow
- Temaya sadik kal (sari #FFD861, siyah #000000)
