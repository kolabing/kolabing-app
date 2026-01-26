# Kolabing Flutter Mobile App - Design Guide

**Version:** 1.0
**Date:** 2026-01-24
**Platform:** Flutter (iOS & Android)

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Brand Identity](#brand-identity)
3. [Color System](#color-system)
4. [Typography](#typography)
5. [Spacing & Layout](#spacing--layout)
6. [Components](#components)
7. [Authentication Flows](#authentication-flows)
8. [Onboarding Flow](#onboarding-flow)
9. [Navigation Structure](#navigation-structure)
10. [Animations & Transitions](#animations--transitions)
11. [Accessibility Guidelines](#accessibility-guidelines)
12. [Platform-Specific Guidelines](#platform-specific-guidelines)

---

## Project Overview

### What is Kolabing?

Kolabing is a collaboration marketplace that connects **businesses** and **communities** for partnership opportunities. The platform enables:

- **Businesses**: Seek community collaborations for brand awareness, event partnerships, and content creation
- **Communities**: Partner with businesses to find sponsors and venue providers for their events

### Mobile App Goals

1. **Seamless Collaboration Discovery** - Quick browsing and filtering of opportunities
2. **Easy Application Process** - Apply to opportunities with minimal friction
3. **Real-time Communication** - Push notifications for applications and messages
4. **On-the-go Management** - Manage collaborations from anywhere
5. **Native Experience** - Platform-optimized UX for iOS and Android

### Target Users

| User Type | Description | Key Needs |
|-----------|-------------|-----------|
| **Business** | Companies seeking community partnerships | Browse communities, post opportunities, manage applications |
| **Community** | Organizations seeking business sponsors | Discover sponsors, apply to opportunities, track collaborations |

---

## Brand Identity

### Brand Values

- **Collaborative** - Bringing people together
- **Energetic** - Bold and vibrant
- **Accessible** - Easy to use for everyone
- **Trustworthy** - Reliable partnerships

### Logo Usage

```
Primary Logo: Kolabing "K" mark in yellow circle
- Minimum size: 32x32dp
- Clear space: 8dp on all sides
- Use on dark backgrounds preferred
```

### Brand Voice

- Friendly and approachable
- Professional but not corporate
- Action-oriented
- Community-focused

---

## Color System

### Primary Colors

```dart
class KolabingColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFFFFD861);        // Yellow - Main brand
  static const Color primaryDark = Color(0xFFE5C057);    // Darker yellow for pressed states
  static const Color onPrimary = Color(0xFF000000);      // Black text on primary

  // Background Colors
  static const Color background = Color(0xFFF7F8FA);     // Light gray background
  static const Color surface = Color(0xFFFFFFFF);        // White surfaces/cards
  static const Color surfaceVariant = Color(0xFFF5F6F8); // Input backgrounds

  // Text Colors
  static const Color textPrimary = Color(0xFF232323);    // Primary text
  static const Color textSecondary = Color(0xFF606060);  // Secondary/muted text
  static const Color textTertiary = Color(0xFF888888);   // Tertiary/hint text
  static const Color textOnDark = Color(0xFFFFFFFF);     // White text on dark

  // Dark Theme Colors (for auth screens)
  static const Color darkBackground = Color(0xFF000000); // Black background
  static const Color darkSurface = Color(0xFF222222);    // Dark surface/inputs
  static const Color darkBorder = Color(0xFF444444);     // Dark borders

  // Semantic Colors
  static const Color success = Color(0xFF7AE7A3);        // Success green
  static const Color warning = Color(0xFFFBC02D);        // Warning yellow
  static const Color error = Color(0xFFE14D76);          // Error/destructive red
  static const Color info = Color(0xFF2196F3);           // Info blue

  // Border Colors
  static const Color border = Color(0xFFEBEBEB);         // Default border
  static const Color borderFocus = Color(0xFFE8D7A0);    // Focus border
  static const Color borderError = Color(0xFFFF6B6B);    // Error border

  // Accent Colors (for categories/badges)
  static const Color accentOrange = Color(0xFFFFDDAC);   // Orange badge bg
  static const Color accentOrangeText = Color(0xFFD8910B); // Orange badge text
  static const Color softYellow = Color(0xFFFFF6D8);     // Soft yellow bg
  static const Color softYellowBorder = Color(0xFFF9E9AC); // Soft yellow border
}
```

### Color Usage Guidelines

| Context | Color | Usage |
|---------|-------|-------|
| Primary Actions | `primary (#FFD861)` | Main CTAs, active tabs, highlights |
| Secondary Actions | `surface + border` | Secondary buttons, outlined actions |
| Text on Yellow | `onPrimary (#000000)` | Always use black on yellow |
| Card Backgrounds | `surface (#FFFFFF)` | Cards, modals, bottom sheets |
| Page Backgrounds | `background (#F7F8FA)` | Main app background |
| Auth Screens | `darkBackground (#000000)` | Login, signup, onboarding |

### Gradient (Optional)

```dart
static const LinearGradient primaryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFFFD861),
    Color(0xFFFFE082),
  ],
);
```

---

## Typography

### Font Families

```dart
class KolabingTypography {
  // Primary Fonts
  static const String fontDisplay = 'Rubik';        // Headlines, titles
  static const String fontBody = 'Open Sans';       // Body text, inputs
  static const String fontAccent = 'Darker Grotesque'; // Buttons, CTAs

  // Fallback
  static const String fontFallback = 'Inter';
}
```

### Font Installation (pubspec.yaml)

```yaml
fonts:
  - family: Rubik
    fonts:
      - asset: assets/fonts/Rubik-Regular.ttf
        weight: 400
      - asset: assets/fonts/Rubik-Medium.ttf
        weight: 500
      - asset: assets/fonts/Rubik-SemiBold.ttf
        weight: 600
      - asset: assets/fonts/Rubik-Bold.ttf
        weight: 700
      - asset: assets/fonts/Rubik-ExtraBold.ttf
        weight: 800

  - family: OpenSans
    fonts:
      - asset: assets/fonts/OpenSans-Regular.ttf
        weight: 400
      - asset: assets/fonts/OpenSans-Medium.ttf
        weight: 500
      - asset: assets/fonts/OpenSans-SemiBold.ttf
        weight: 600
      - asset: assets/fonts/OpenSans-Bold.ttf
        weight: 700

  - family: DarkerGrotesque
    fonts:
      - asset: assets/fonts/DarkerGrotesque-Medium.ttf
        weight: 500
      - asset: assets/fonts/DarkerGrotesque-SemiBold.ttf
        weight: 600
      - asset: assets/fonts/DarkerGrotesque-Bold.ttf
        weight: 700
```

### Text Styles

```dart
class KolabingTextStyles {
  // Display - Hero headings (Rubik, uppercase)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Rubik',
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Rubik',
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
    height: 1.2,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: 'Rubik',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    height: 1.2,
  );

  // Headlines - Section headings (Rubik)
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Rubik',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Rubik',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: 'Rubik',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // Title - Card titles, navigation (Open Sans)
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'OpenSans',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'OpenSans',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: 'OpenSans',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Body - Regular text (Open Sans)
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'OpenSans',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'OpenSans',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'OpenSans',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Label - Buttons, form labels (Darker Grotesque)
  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'DarkerGrotesque',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.2,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'DarkerGrotesque',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    height: 1.2,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'DarkerGrotesque',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    height: 1.2,
  );

  // Button - CTA buttons (Darker Grotesque, uppercase)
  static const TextStyle button = TextStyle(
    fontFamily: 'DarkerGrotesque',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    height: 1.2,
  );
}
```

---

## Spacing & Layout

### Spacing Scale

```dart
class KolabingSpacing {
  static const double xxxs = 2;
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}
```

### Border Radius

```dart
class KolabingRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double round = 999;  // Fully rounded (pills)
}
```

### Screen Padding

```dart
class KolabingLayout {
  // Screen horizontal padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16);

  // Safe area with bottom navigation
  static const double bottomNavHeight = 80;
  static const double bottomSafeArea = 16;

  // Card internal padding
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(24);

  // List item spacing
  static const double listItemSpacing = 12;
  static const double gridSpacing = 16;

  // Maximum content width (for tablets)
  static const double maxContentWidth = 600;
}
```

### Shadows

```dart
class KolabingShadows {
  static const BoxShadow card = BoxShadow(
    color: Color(0x1A374957),  // rgba(55, 73, 87, 0.10)
    blurRadius: 8,
    offset: Offset(0, 1.5),
  );

  static const BoxShadow cardHover = BoxShadow(
    color: Color(0x1F374957),  // rgba(55, 73, 87, 0.12)
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  static const BoxShadow button = BoxShadow(
    color: Color(0x1C374957),  // rgba(55, 73, 87, 0.11)
    blurRadius: 4,
    offset: Offset(0, 1.5),
  );

  static const BoxShadow bottomNav = BoxShadow(
    color: Color(0x14000000),  // rgba(0, 0, 0, 0.08)
    blurRadius: 20,
    offset: Offset(0, -4),
  );
}
```

---

## Components

### Buttons

```dart
// Primary Button (Yellow)
class KolabingPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;

  // Specifications:
  // - Background: primary (#FFD861)
  // - Text: black, Darker Grotesque, uppercase, semibold
  // - Height: 52dp
  // - Border radius: 12dp
  // - Padding: horizontal 24dp
  // - Shadow: button shadow
}

// Secondary Button (Outlined)
class KolabingSecondaryButton extends StatelessWidget {
  // Specifications:
  // - Background: transparent or white
  // - Border: 1.5px solid border color
  // - Text: textPrimary, Darker Grotesque
  // - Height: 48dp
  // - Border radius: 12dp
}

// Text Button
class KolabingTextButton extends StatelessWidget {
  // Specifications:
  // - No background or border
  // - Text: primary color (#FFD861)
  // - Underline on hover/focus
}
```

### Input Fields

```dart
class KolabingTextField extends StatelessWidget {
  // Dark theme (Auth screens):
  // - Background: #222222
  // - Border: 1px solid #444444
  // - Text: white
  // - Hint: #888888
  // - Border radius: 12dp
  // - Padding: 16dp horizontal, 14dp vertical

  // Light theme (Dashboard):
  // - Background: #F5F6F8
  // - Border: none (or 1px solid #EBEBEB)
  // - Text: #232323
  // - Hint: #888888
  // - Border radius: 8dp

  // Focus state:
  // - Border: 2px solid #E8D7A0
  // - Shadow: 0 0 0 3px rgba(255, 246, 216, 0.4)

  // Error state:
  // - Border: 1px solid #FF6B6B
  // - Helper text: #FF6B6B
}
```

### Cards

```dart
class KolabingCard extends StatelessWidget {
  // Standard Card:
  // - Background: white
  // - Border radius: 16dp
  // - Border: 1px solid #EBEBEB
  // - Shadow: card shadow
  // - Padding: 16dp

  // Opportunity Card (Soft Yellow):
  // - Background: #FFF6D8
  // - Border radius: 18dp
  // - Border: 1.5px solid #F9E9AC
  // - Shadow: custom yellow shadow
  // - Hover: scale(1.02)
}
```

### Badges/Chips

```dart
class KolabingBadge extends StatelessWidget {
  // Status badges:
  // - Pending: bg #FFDDAC, text #D8910B
  // - Active/Published: bg #D4EDDA, text #155724
  // - Completed: bg #E8E8E8, text #666666
  // - Error/Declined: bg #F8D7DA, text #721C24

  // Specifications:
  // - Border radius: 12dp
  // - Padding: 4dp vertical, 12dp horizontal
  // - Font: bodySmall, semibold
}
```

### Bottom Navigation

```dart
class KolabingBottomNav extends StatelessWidget {
  // Specifications:
  // - Background: white
  // - Height: 80dp (including safe area)
  // - Shadow: bottomNav shadow
  // - Border top: 1px solid #EBEBEB

  // Items:
  // - Icon size: 24dp
  // - Label: labelSmall
  // - Active: primary color (#FFD861)
  // - Inactive: textSecondary (#606060)

  // Business tabs:
  // 1. Home (Dashboard)
  // 2. Browse (Discover)
  // 3. My Opportunities
  // 4. Applications
  // 5. Profile

  // Community tabs:
  // 1. Home (Dashboard)
  // 2. Browse (Discover)
  // 3. My Opportunities
  // 4. Applications
  // 5. Profile
}
```

---

## Authentication Flows

### Sign In Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     SIGN IN SCREEN                          │
│  Background: Black (#000000)                                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ← Back to Home                     Don't have account? →   │
│                                                             │
│                    ┌───┐                                    │
│                    │ K │  Kolabing                          │
│                    └───┘                                    │
│                                                             │
│               WELCOME BACK                                  │
│        Sign in to your account                              │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Email                                               │    │
│  │  ┌─────────────────────────────────────────────────┐│    │
│  │  │ Enter your email                            │   ││    │
│  │  └─────────────────────────────────────────────────┘│    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Password                                            │    │
│  │  ┌───────────────────────────────────────────────👁┐│    │
│  │  │ Enter your password                           ││││    │
│  │  └─────────────────────────────────────────────────┘│    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              SIGN IN                                 │    │
│  │         (Yellow button)                              │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│              Forgot your password?                          │
│                 (Yellow text)                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### Sign In Fields

| Field | Type | Validation | Keyboard |
|-------|------|------------|----------|
| Email | email | Required, valid email format | email |
| Password | password | Required, min 6 chars | text |

#### Sign In States

- **Default**: Empty fields
- **Loading**: Button shows spinner, fields disabled
- **Error - Invalid Credentials**: Both fields show error border
- **Error - Email Not Confirmed**: Toast with message
- **Success**: Navigate to dashboard based on user_type

---

### Sign Up Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     SIGN UP SCREEN                          │
│  Background: Black (#000000)                                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ← Back to Home                   Already have account? →   │
│                                                             │
│                    ┌───┐                                    │
│                    │ K │  Kolabing                          │
│                    └───┘                                    │
│                                                             │
│            CREATE YOUR ACCOUNT                              │
│    Join the marketplace for collaborations                  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Account Type                                        │    │
│  │  ┌────────────────────┬────────────────────┐        │    │
│  │  │    🏢 Business     │    👥 Community    │        │    │
│  │  │    (Active/Yellow) │    (Inactive)       │        │    │
│  │  └────────────────────┴────────────────────┘        │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Business Name (or Community Name)                   │    │
│  │  ┌─────────────────────────────────────────────────┐│    │
│  │  │ Enter your business name                    │   ││    │
│  │  └─────────────────────────────────────────────────┘│    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Email                                               │    │
│  │  ┌─────────────────────────────────────────────────┐│    │
│  │  │ Enter your email                            │   ││    │
│  │  └─────────────────────────────────────────────────┘│    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Phone Number                                        │    │
│  │  ┌─────────────────────────────────────────────────┐│    │
│  │  │ +34 123 456 789                             │   ││    │
│  │  └─────────────────────────────────────────────────┘│    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Password                                            │    │
│  │  ┌───────────────────────────────────────────────👁┐│    │
│  │  │ Create a password                             ││││    │
│  │  └─────────────────────────────────────────────────┘│    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Confirm Password                                    │    │
│  │  ┌───────────────────────────────────────────────👁┐│    │
│  │  │ Confirm your password                         ││││    │
│  │  └─────────────────────────────────────────────────┘│    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Invitation Code (Optional)                          │    │
│  │  ┌─────────────────────────────────────────────────┐│    │
│  │  │ Enter invitation code                       │   ││    │
│  │  └─────────────────────────────────────────────────┘│    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              CREATE ACCOUNT                          │    │
│  │            (Yellow button)                           │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### Sign Up Fields

| Field | Type | Validation | Required |
|-------|------|------------|----------|
| User Type | toggle | business / community | Yes |
| Display Name | text | Not empty | Yes |
| Email | email | Valid email format | Yes |
| Phone Number | phone | Valid phone format | Yes |
| Password | password | Min 6 characters | Yes |
| Confirm Password | password | Must match password | Yes |
| Invitation Code | text | Max 8 chars, uppercase | No |

#### Account Type Toggle Behavior

```dart
// When user type changes:
// - Business: Label shows "Business Name"
// - Community: Label shows "Community Name"
// - Invitation code helper text updates:
//   - Business: "(Optional - Get 1 free credit)"
//   - Community: "(Optional)"
```

#### Sign Up States

- **Default**: Business type selected
- **Type Selection**: Visual toggle between Business/Community
- **Validation Errors**: Inline field errors
- **Loading**: Button spinner, fields disabled
- **Email Already Exists**: Email field error
- **Phone Already Exists**: Phone field error
- **Success**: Toast "Check your email", navigate to dashboard

---

### Forgot Password Flow

```
┌─────────────────────────────────────────────────────────────┐
│                 FORGOT PASSWORD SCREEN                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ← Back to Sign In                                          │
│                                                             │
│               RESET PASSWORD                                │
│  Enter your email and we'll send you a reset link           │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Email                                               │    │
│  │  ┌─────────────────────────────────────────────────┐│    │
│  │  │ Enter your email                            │   ││    │
│  │  └─────────────────────────────────────────────────┘│    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              SEND RESET LINK                         │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘

                           ↓ Success

┌─────────────────────────────────────────────────────────────┐
│               CHECK YOUR EMAIL                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                    📧                                       │
│                                                             │
│        We've sent a password reset link to                  │
│            your@email.com                                   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              BACK TO SIGN IN                         │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│           Didn't receive the email?                         │
│              Resend (60s countdown)                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Onboarding Flow

### Onboarding Screens (First Launch)

The onboarding consists of 3-4 swipeable screens introducing the app:

```
┌─────────────────────────────────────────────────────────────┐
│                    ONBOARDING SCREEN 1                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                      [Illustration]                         │
│                    Business + Community                     │
│                      Collaboration                          │
│                                                             │
│                                                             │
│               CONNECT & COLLABORATE                         │
│                                                             │
│    Kolabing brings businesses and communities               │
│     together for meaningful partnerships                    │
│                                                             │
│                                                             │
│                    ● ○ ○ ○                                  │
│                                                             │
│                                              Skip →         │
│                                                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    ONBOARDING SCREEN 2                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                      [Illustration]                         │
│                     Browse Opportunities                    │
│                                                             │
│                                                             │
│              DISCOVER OPPORTUNITIES                         │
│                                                             │
│     Find the perfect collaboration partner                  │
│        filtered by location and category                    │
│                                                             │
│                                                             │
│                    ○ ● ○ ○                                  │
│                                                             │
│                                              Skip →         │
│                                                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    ONBOARDING SCREEN 3                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                      [Illustration]                         │
│                        Apply & Match                        │
│                                                             │
│                                                             │
│                  APPLY WITH EASE                            │
│                                                             │
│    Submit applications and manage your                      │
│      collaborations all in one place                        │
│                                                             │
│                                                             │
│                    ○ ○ ● ○                                  │
│                                                             │
│                                              Skip →         │
│                                                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    ONBOARDING SCREEN 4                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                      [Illustration]                         │
│                      Choose Your Path                       │
│                                                             │
│                                                             │
│                   GET STARTED                               │
│                                                             │
│           Are you a business looking for                    │
│      communities, or a community seeking sponsors?          │
│                                                             │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │       I'M A BUSINESS / BRAND                         │    │
│  │            (Yellow button)                           │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │          I'M A COMMUNITY                             │    │
│  │            (Outline button)                          │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│                    ○ ○ ○ ●                                  │
│                                                             │
│         Already have an account? Sign In                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Onboarding Logic

```dart
// Onboarding state management
class OnboardingState {
  static const String onboardingKey = 'hasSeenOnboarding';

  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(onboardingKey) ?? false;
  }

  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingKey, true);
  }
}

// App launch flow:
// 1. Check if onboarding completed
// 2. If not completed → Show Onboarding
// 3. If completed → Check auth state
// 4. If authenticated → Navigate to dashboard (based on user_type)
// 5. If not authenticated → Show Sign In
```

### Profile Completion (Post-Registration)

After successful registration, users are prompted to complete their profile:

```
┌─────────────────────────────────────────────────────────────┐
│                COMPLETE YOUR PROFILE                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   Welcome to Kolabing! Let's set up your profile            │
│   so you can start collaborating.                           │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │           [Profile Photo Upload]                     │    │
│  │                Add Photo                             │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  City                                                       │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Select your city                              ▼     │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  [Business Type / Community Type] (dropdown)                │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Select category                               ▼     │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  Website (optional)                                         │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ https://                                            │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  Instagram (optional)                                       │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ @username                                           │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              COMPLETE PROFILE                        │    │
│  │            (Yellow button)                           │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│                    Skip for now →                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Navigation Structure

### Bottom Navigation Tabs

#### Business User

| Tab | Icon | Screen |
|-----|------|--------|
| Home | `home` | BusinessDashboard |
| Browse | `search` | BusinessBrowse (Community opportunities) |
| My Offers | `briefcase` | BusinessOffers (My posted opportunities) |
| Applications | `inbox` | BusinessApplications |
| Profile | `user` | BusinessProfile |

#### Community User

| Tab | Icon | Screen |
|-----|------|--------|
| Home | `home` | CommunityDashboard |
| Browse | `search` | CommunityOffers (Business opportunities) |
| My Opportunities | `calendar` | CommunityMyOpportunities |
| Applications | `inbox` | CommunityApplications |
| Profile | `user` | CommunityProfile |

### Navigation Routes

```dart
// Route definitions
class KolabingRoutes {
  // Auth routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String signIn = '/auth/sign-in';
  static const String signUp = '/auth/sign-up';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Business routes
  static const String businessDashboard = '/business';
  static const String businessBrowse = '/business/browse';
  static const String businessOffers = '/business/offers';
  static const String businessOffersNew = '/business/offers/new';
  static const String businessOffersEdit = '/business/offers/:id/edit';
  static const String businessApplications = '/business/applications';
  static const String businessMyApplications = '/business/my-applications';
  static const String businessCollaborations = '/business/collaborations';
  static const String businessProfile = '/business/profile';
  static const String businessPlans = '/business/plans';

  // Community routes
  static const String communityDashboard = '/community';
  static const String communityOffers = '/community/offers';
  static const String communityMyOpportunities = '/community/my-opportunities';
  static const String communityOpportunitiesNew = '/community/opportunities/new';
  static const String communityOpportunitiesEdit = '/community/opportunities/:id/edit';
  static const String communityApplications = '/community/applications';
  static const String communityMyApplications = '/community/my-applications';
  static const String communityCollaborations = '/community/collaborations';
  static const String communityProfile = '/community/profile';
  static const String communityReferrals = '/community/referrals';

  // Shared routes
  static const String opportunityDetails = '/opportunity/:id';
  static const String collaborationDetails = '/collaboration/:id';
  static const String applicationDetails = '/application/:id';
}
```

---

## Animations & Transitions

### Page Transitions

```dart
class KolabingTransitions {
  // Default page transition
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Curve defaultCurve = Curves.easeInOut;

  // Modal bottom sheet
  static const Duration modalDuration = Duration(milliseconds: 250);

  // Tab switching
  static const Duration tabDuration = Duration(milliseconds: 200);
}

// Route transition
PageRouteBuilder<T> fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
    transitionDuration: KolabingTransitions.defaultDuration,
  );
}

// Slide up for modals
PageRouteBuilder<T> slideUpRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        )),
        child: child,
      );
    },
    transitionDuration: KolabingTransitions.modalDuration,
  );
}
```

### Component Animations

```dart
// Button press
// Scale: 0.98 on press
// Duration: 100ms

// Card hover/tap
// Scale: 1.02
// Shadow elevation increase
// Duration: 200ms

// List item entrance
// Fade + slide from bottom
// Stagger delay: 50ms per item
// Duration: 300ms

// Skeleton loading
// Shimmer animation
// Duration: 1500ms, repeat
```

---

## Accessibility Guidelines

### Touch Targets

- Minimum touch target: 48x48dp
- Buttons: 52dp height minimum
- List items: 56dp height minimum
- Input fields: 52dp height minimum

### Color Contrast

- Text on primary (yellow): Use black (#000000) - 12:1 ratio
- Primary text on white: #232323 - 15.5:1 ratio
- Secondary text: #606060 - 7:1 ratio
- Error text on white: #E14D76 - 4.5:1 ratio (passes WCAG AA)

### Screen Reader Support

```dart
// All interactive elements must have semantics
Semantics(
  button: true,
  label: 'Create new opportunity',
  child: IconButton(
    icon: Icon(Icons.add),
    onPressed: () {},
  ),
)

// Images must have descriptions
Semantics(
  label: 'Profile photo of Barcelona Coffee Club',
  child: Image.network(imageUrl),
)

// Form fields must be labeled
TextField(
  decoration: InputDecoration(
    labelText: 'Email',
    hintText: 'Enter your email address',
  ),
)
```

### Keyboard Navigation

- All focusable elements in logical order
- Visible focus indicators
- Escape closes modals/sheets
- Enter/Space activates buttons

---

## Platform-Specific Guidelines

### iOS Specific

```dart
// Cupertino adaptations
// - Use CupertinoPageScaffold for main screens
// - CupertinoNavigationBar for navigation
// - CupertinoTabBar for bottom navigation
// - CupertinoAlertDialog for alerts
// - CupertinoDatePicker for date selection
// - Swipe right to go back

// Safe areas
// - Top: status bar + notch
// - Bottom: home indicator
```

### Android Specific

```dart
// Material adaptations
// - Use Scaffold with AppBar
// - Material bottom navigation
// - MaterialApp theme
// - Android back button handling
// - Edge-to-edge display

// System UI
// - Status bar color matches screen
// - Navigation bar transparent/themed
```

### Responsive Breakpoints

```dart
class KolabingBreakpoints {
  static const double mobile = 0;     // 0-599
  static const double tablet = 600;   // 600-1023
  static const double desktop = 1024; // 1024+

  static bool isMobile(BuildContext context) =>
    MediaQuery.of(context).size.width < tablet;

  static bool isTablet(BuildContext context) =>
    MediaQuery.of(context).size.width >= tablet &&
    MediaQuery.of(context).size.width < desktop;

  static bool isDesktop(BuildContext context) =>
    MediaQuery.of(context).size.width >= desktop;
}
```

---

## Implementation Checklist

### Phase 1: Foundation
- [ ] Set up Flutter project with proper folder structure
- [ ] Implement color tokens and theme
- [ ] Implement typography system
- [ ] Create base components (Button, TextField, Card)
- [ ] Set up Supabase client

### Phase 2: Authentication
- [ ] Splash screen
- [ ] Onboarding screens (4 screens)
- [ ] Sign In screen
- [ ] Sign Up screen with user type toggle
- [ ] Forgot Password flow
- [ ] Email verification handling
- [ ] Auth state persistence

### Phase 3: Core Screens
- [ ] Bottom navigation shell
- [ ] Dashboard (Business & Community)
- [ ] Browse/Discover screen
- [ ] Opportunity detail screen
- [ ] Create/Edit opportunity form
- [ ] Application management

### Phase 4: Profile & Settings
- [ ] Profile screen (view/edit)
- [ ] Profile completion flow
- [ ] Settings screen
- [ ] Notification preferences

### Phase 5: Polish
- [ ] Push notifications
- [ ] Animations and transitions
- [ ] Error handling and offline states
- [ ] Performance optimization
- [ ] Accessibility audit

---

## Resources

### Figma Files
- (Add Figma link when available)

### Icon Library
- Lucide Icons (Flutter package: `lucide_icons`)

### Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.4.0

  # Backend
  supabase_flutter: ^2.3.0

  # Navigation
  go_router: ^13.0.0

  # UI Components
  lucide_icons: ^0.257.0
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0

  # Forms
  flutter_form_builder: ^9.1.1
  form_builder_validators: ^9.1.0

  # Storage
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0

  # Utils
  intl: ^0.18.1
  url_launcher: ^6.2.2
```

---

**Document Version:** 1.0
**Last Updated:** 2026-01-24
**Author:** Kolabing Development Team

