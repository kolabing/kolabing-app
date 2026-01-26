# Task: Splash Screen

## Status
- Created: 2026-01-25 15:15
- Started: 2026-01-25 15:20
- Completed: 2026-01-25 16:00

## Description
Kolabing uygulamasinin acilis splash screen'ini tasarla ve implemente et.

Logo URL: https://qcmperlkuujhweikoyru.supabase.co/storage/v1/object/sign/media/Logo_Kolabing-removebg-preview.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV9mOWQ2MzU4NS1iNjc3LTQ1NGYtOTRhZS1iODg3NjU5MWU3OGIiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJtZWRpYS9Mb2dvX0tvbGFiaW5nLXJlbW92ZWJnLXByZXZpZXcucG5nIiwiaWF0IjoxNzYwMDAwMjY3LCJleHAiOjE3OTE1MzYyNjd9.WlXIWFEuiQztblbyF1mWhhOva8mD5hcjKghi55y3jRo

### Requirements
- Siyah arka plan (#000000) - auth tema ile uyumlu
- Ortalanmis Kolabing logosu
- Logo animasyonu (fade in + scale)
- Yumusak gecis animasyonu
- Onboarding/Auth/Dashboard durumuna gore yonlendirme

### Design Specs (README.md)
- Primary: #FFD861 (Yellow)
- Dark Background: #000000
- Animation: 300ms default
- Logo min size: 32x32dp, 8dp clear space

## Assigned Agents
- [x] @ux-designer - Completed (2026-01-25)
- [x] @flutter-expert - Completed (2026-01-25)

## Progress

### UX Design
**Status:** Completed
**Completed by:** @ux-designer
**Date:** 2026-01-25

---

## User Flow

```
App Launch
    ↓
┌─────────────────────────────────────┐
│      SPLASH SCREEN (2-3 sec)        │
│  - Logo fade in animation (0-800ms) │
│  - Hold state (800-2000ms)          │
│  - Parallel auth check starts       │
└─────────────────────────────────────┘
    ↓
[Background: Checking states]
    ↓
┌─────────────────────────────────────┐
│  Check onboarding completed?        │
└─────────────────────────────────────┘
    ↓           ↓
   NO          YES
    ↓           ↓
Onboarding   Check auth state
Screen 1        ↓           ↓
             Auth'd    Not Auth'd
                ↓           ↓
          Check user    Sign In
          type          Screen
             ↓     ↓
        Business Community
             ↓     ↓
        Dashboard Dashboard
```

**Flow Duration:**
- Minimum display: 2000ms (branding)
- Animation: 800ms
- Hold: 1200ms minimum
- Fade out: 300ms

---

## Visual Design Specification

### Layout Structure

```
┌─────────────────────────────────────────┐
│         Safe Area (Top)                 │
├─────────────────────────────────────────┤
│                                         │
│                                         │
│                                         │
│             [Flex Space]                │
│                                         │
│         ┌───────────────┐               │
│         │               │               │
│         │  Kolabing     │ 120x120dp     │
│         │  Logo         │ (centered)    │
│         │               │               │
│         └───────────────┘               │
│                                         │
│             [Flex Space]                │
│                                         │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│      Safe Area (Bottom) - 32dp          │
└─────────────────────────────────────────┘
```

### Component Specifications

#### Background
- **Color:** `#000000` (Black - matches auth theme)
- **Type:** Solid color
- **Edge-to-edge:** Full screen including safe areas
- **Status Bar:** Hidden or black with white icons

#### Logo Container
- **Position:** Absolute center (both horizontal & vertical)
- **Size:** 120x120dp
- **Logo URL:** Network image from Supabase storage
- **Clear Space:** 32dp minimum on all sides
- **Aspect Ratio:** 1:1 (square container)
- **Background:** Transparent
- **Shadow:** None (logo on dark already has visual weight)

#### Loading Indicator (Optional - shown if auth check takes >2s)
- **Position:** Below logo, 48dp gap
- **Type:** Circular progress indicator
- **Color:** `#FFD861` (Primary yellow)
- **Size:** 24x24dp
- **Stroke Width:** 2dp
- **Visibility:** Only appears if auth check exceeds minimum display time

---

## Animation Timeline

### Phase 1: Entry Animation (0-800ms)

**Logo Fade In + Scale**
```dart
Duration: 800ms
Curve: Curves.easeOut

0ms:
  - opacity: 0.0
  - scale: 0.85

800ms:
  - opacity: 1.0
  - scale: 1.0
```

### Phase 2: Hold State (800-2000ms)

**Static Display**
- Logo fully visible
- Auth check runs in parallel
- Minimum branding exposure: 1200ms

### Phase 3: Exit Animation (2000-2300ms)

**Fade Out Transition**
```dart
Duration: 300ms
Curve: Curves.easeIn

2000ms:
  - opacity: 1.0

2300ms:
  - opacity: 0.0
```

**Next Screen Fade In** (overlaps last 150ms)
```dart
Duration: 300ms
Curve: Curves.easeOut
Starts at: 2150ms (overlaps splash fade out)
```

---

## Interaction States

### State 1: Initial Load
**Visual:**
- Black background
- Logo: opacity 0
- No loading indicator

**Behavior:**
- Trigger fade-in animation
- Start auth check in parallel
- Cache logo image immediately

**Duration:** 0-800ms

---

### State 2: Display (Normal Flow)
**Visual:**
- Black background
- Logo: opacity 1, scale 1
- No loading indicator

**Behavior:**
- Continue auth/onboarding checks
- Hold for minimum duration (2000ms total)
- Prepare next route

**Duration:** 800-2000ms

---

### State 3: Extended Loading (if auth slow)
**Visual:**
- Black background
- Logo: fully visible
- Loading indicator: appears with fade-in

**Behavior:**
- Show circular progress below logo
- Continue waiting for auth resolution
- No timeout (will eventually resolve)

**Duration:** 2000ms+

---

### State 4: Transition Out
**Visual:**
- Fade out entire screen (logo + background)
- Next screen fades in simultaneously

**Behavior:**
- Navigate to determined route
- Remove splash screen from stack
- Release cached resources

**Duration:** 300ms

---

## Edge Cases & Error Handling

### Case 1: Network Logo Load Failure
**Fallback:**
- Show text "KOLABING" in Rubik ExtraBold, #FFD861
- Size: 32sp, letter-spacing: 2.0
- Same animation behavior

### Case 2: Auth Check Failure
**Behavior:**
- After minimum display (2s), navigate to Sign In
- Log error silently
- Show toast: "Please check your connection"

### Case 3: Slow Device / First Launch
**Behavior:**
- Extend hold state until ready
- Show loading indicator after 2s
- No force timeout

### Case 4: App Resumed from Background
**Behavior:**
- Skip splash, go directly to last route
- Only show splash on cold start

---

## Accessibility Specifications

### Screen Reader
```dart
Semantics(
  label: 'Kolabing - Loading application',
  child: SplashScreen(),
)
```

### Reduced Motion
- If user has reduced motion enabled:
  - Skip scale animation
  - Use only fade in/out
  - Reduce duration to 1500ms total

### High Contrast Mode
- Logo already high contrast (yellow/white on black)
- No changes needed

---

## Technical Implementation Notes

### Asset Management
```dart
// Logo caching strategy
CachedNetworkImage(
  imageUrl: logoUrl,
  placeholder: (context, url) => SizedBox.shrink(),
  errorWidget: (context, url, error) => Text('KOLABING'),
  fadeInDuration: Duration.zero, // We control fade with AnimatedOpacity
)
```

### State Management
```dart
// Splash screen states
enum SplashState {
  initial,       // 0-800ms
  displaying,    // 800-2000ms
  loading,       // 2000ms+ (if needed)
  transitioning, // 2000-2300ms
}
```

### Navigation Logic
```dart
Future<void> _determineNextRoute() async {
  // Run in parallel during splash
  final hasSeenOnboarding = await OnboardingState.hasCompletedOnboarding();

  if (!hasSeenOnboarding) {
    return '/onboarding';
  }

  final session = await Supabase.instance.client.auth.currentSession;

  if (session == null) {
    return '/auth/sign-in';
  }

  // Fetch user type from profile
  final userType = await _getUserType(session.user.id);

  return userType == 'business'
    ? '/business'
    : '/community';
}
```

---

## Platform-Specific Considerations

### iOS
- Hide status bar during splash
- Use `SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive)`
- Restore after transition

### Android
- Set status bar color to black
- Set navigation bar color to black
- Edge-to-edge mode

### Both Platforms
- Prevent back button (Android)
- Disable swipe back (iOS)
- Lock orientation to portrait during splash

---

## Design Tokens Used

**Colors:**
- Background: `KolabingColors.darkBackground` (#000000)
- Logo fallback text: `KolabingColors.primary` (#FFD861)
- Loading indicator: `KolabingColors.primary` (#FFD861)

**Typography:**
- Logo fallback: `KolabingTextStyles.displayLarge` (Rubik, 32sp, 800)

**Spacing:**
- Logo size: 120dp
- Logo to loader gap: `KolabingSpacing.xxl` (48dp)
- Bottom safe area: `KolabingSpacing.xl` (32dp)

**Timing:**
- Entry animation: 800ms
- Minimum display: 2000ms
- Exit animation: `KolabingTransitions.defaultDuration` (300ms)

**Curves:**
- Entry: `Curves.easeOut`
- Exit: `Curves.easeIn`

---

## Success Criteria

✅ Logo loads and displays correctly
✅ Animation is smooth (60fps)
✅ Minimum 2s branding display respected
✅ Correct navigation based on auth state
✅ No janky transitions
✅ Works offline (with fallback)
✅ Accessible to screen readers
✅ Respects reduced motion preferences

---

## UI States Checklist
- [x] Initial (logo fade in) - Defined
- [x] Loading (checking auth) - Defined
- [x] Extended loading (slow auth) - Defined
- [x] Transition (fade out to next screen) - Defined
- [x] Error fallback - Defined

### Flutter Implementation
**Status:** Completed
**Completed by:** @flutter-expert
**Date:** 2026-01-25

#### Files Created
- `lib/features/auth/screens/splash_screen.dart` - Main splash screen widget with animations
- `lib/features/auth/providers/auth_state_provider.dart` - State management for auth/onboarding check

#### Updated Files
- `lib/config/routes/routes.dart` - Updated splash route to use real SplashScreen

#### Implementation Details

**SplashScreen Features:**
- Black background (#000000) using KolabingColors.darkBackground
- Centered 120x120dp logo loaded from Supabase via CachedNetworkImage
- Entry animation: 800ms fade in + scale (0.85 -> 1.0) with Curves.easeOut
- Exit animation: 300ms fade out with Curves.easeIn
- Minimum 2 second display time for branding
- Extended loading indicator (yellow circular progress) if auth check takes >2s
- Error toast displayed on connection issues
- Text fallback "KOLABING" in primary yellow if logo fails to load
- Reduced motion support (skips scale animation if enabled)
- Screen reader accessibility with semantic label
- Edge-to-edge display with proper system UI configuration
- Back button disabled (PopScope canPop: false)

**Auth State Provider Features:**
- Riverpod 3.x NotifierProvider pattern
- Parallel auth/onboarding check during animation
- Navigation routing:
  - `/onboarding` if onboarding not completed
  - `/auth/sign-in` if not authenticated
  - `/business` if business user type
  - `/community` if community user type
- SharedPreferences for onboarding status persistence
- Supabase profile query for user type detection
- Error handling with fallback to sign-in screen

#### Dependencies Used
- shared_preferences (onboarding check)
- go_router (navigation)
- flutter_riverpod 3.x (state management)
- cached_network_image (logo caching)
- supabase_flutter (auth check)

## Notes
- Logo network'ten yukleniyor, CachedNetworkImage ile cache'leniyor
- Minimum 2 saniye gosterilmeli (branding) - implemented
- Auth check parallel yapiliyor animasyon sirasinda
- Tum UX spesifikasyonlari implemente edildi
