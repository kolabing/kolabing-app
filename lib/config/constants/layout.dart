import 'package:flutter/material.dart';

import 'spacing.dart';

/// Kolabing layout constants
///
/// Screen-level layout values for consistent spacing and sizing.
abstract final class KolabingLayout {
  // ---------------------------------------------------------------------------
  // Screen Padding
  // ---------------------------------------------------------------------------

  /// Standard horizontal padding for screens
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: KolabingSpacing.md,
  );

  /// Screen padding with vertical spacing
  static const EdgeInsets screenPaddingAll = EdgeInsets.all(
    KolabingSpacing.md,
  );

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  /// Bottom navigation bar height (including safe area)
  static const double bottomNavHeight = 80;

  /// Bottom safe area padding
  static const double bottomSafeArea = 16;

  // ---------------------------------------------------------------------------
  // Card Padding
  // ---------------------------------------------------------------------------

  /// Standard card internal padding
  static const EdgeInsets cardPadding = EdgeInsets.all(
    KolabingSpacing.md,
  );

  /// Large card internal padding
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(
    KolabingSpacing.lg,
  );

  // ---------------------------------------------------------------------------
  // List & Grid Spacing
  // ---------------------------------------------------------------------------

  /// Spacing between list items
  static const double listItemSpacing = 12;

  /// Grid spacing between items
  static const double gridSpacing = 16;

  // ---------------------------------------------------------------------------
  // Content Constraints
  // ---------------------------------------------------------------------------

  /// Maximum content width for tablets
  static const double maxContentWidth = 600;

  // ---------------------------------------------------------------------------
  // Component Sizes
  // ---------------------------------------------------------------------------

  /// Primary button height
  static const double buttonHeight = 52;

  /// Secondary button height
  static const double buttonHeightSecondary = 48;

  /// Input field height (dark theme)
  static const double inputHeightDark = 52;

  /// Input field height (light theme)
  static const double inputHeightLight = 48;

  /// Minimum touch target size (accessibility)
  static const double minTouchTarget = 48;

  /// Icon size for bottom navigation
  static const double bottomNavIconSize = 24;

  /// Standard icon size
  static const double iconSize = 24;

  /// Large icon size
  static const double iconSizeLarge = 32;

  /// Small icon size
  static const double iconSizeSmall = 20;
}

/// Kolabing shadow definitions
///
/// Consistent shadow styles for elevation throughout the app.
abstract final class KolabingShadows {
  /// Card shadow - subtle elevation
  static const BoxShadow card = BoxShadow(
    color: Color(0x1A374957), // rgba(55, 73, 87, 0.10)
    blurRadius: 8,
    offset: Offset(0, 1.5),
  );

  /// Card hover shadow - increased elevation on interaction
  static const BoxShadow cardHover = BoxShadow(
    color: Color(0x1F374957), // rgba(55, 73, 87, 0.12)
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  /// Button shadow - slight elevation for CTAs
  static const BoxShadow button = BoxShadow(
    color: Color(0x1C374957), // rgba(55, 73, 87, 0.11)
    blurRadius: 4,
    offset: Offset(0, 1.5),
  );

  /// Bottom navigation shadow
  static const BoxShadow bottomNav = BoxShadow(
    color: Color(0x14000000), // rgba(0, 0, 0, 0.08)
    blurRadius: 20,
    offset: Offset(0, -4),
  );

  /// Focus ring shadow for inputs
  static const BoxShadow focusRing = BoxShadow(
    color: Color(0x66FFF6D8), // rgba(255, 246, 216, 0.4)
    blurRadius: 0,
    spreadRadius: 3,
  );

  // ---------------------------------------------------------------------------
  // List helpers for decoration
  // ---------------------------------------------------------------------------

  /// Card shadow as list
  static List<BoxShadow> get cardShadow => [card];

  /// Card hover shadow as list
  static List<BoxShadow> get cardHoverShadow => [cardHover];

  /// Button shadow as list
  static List<BoxShadow> get buttonShadow => [button];

  /// Bottom navigation shadow as list
  static List<BoxShadow> get bottomNavShadow => [bottomNav];
}

/// Kolabing responsive breakpoints
///
/// Screen width breakpoints for responsive layouts.
abstract final class KolabingBreakpoints {
  /// Mobile breakpoint start - 0px
  static const double mobile = 0;

  /// Tablet breakpoint start - 600px
  static const double tablet = 600;

  /// Desktop breakpoint start - 1024px
  static const double desktop = 1024;

  /// Check if current screen width is mobile
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < tablet;

  /// Check if current screen width is tablet
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet &&
      MediaQuery.of(context).size.width < desktop;

  /// Check if current screen width is desktop
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;
}

/// Kolabing animation durations
///
/// Consistent animation timing throughout the app.
abstract final class KolabingTransitions {
  /// Default page transition duration
  static const Duration defaultDuration = Duration(milliseconds: 300);

  /// Modal/bottom sheet transition duration
  static const Duration modalDuration = Duration(milliseconds: 250);

  /// Tab switching transition duration
  static const Duration tabDuration = Duration(milliseconds: 200);

  /// Quick interaction duration (button press, etc.)
  static const Duration quickDuration = Duration(milliseconds: 100);

  /// Shimmer animation duration
  static const Duration shimmerDuration = Duration(milliseconds: 1500);

  /// Default animation curve
  static const Curve defaultCurve = Curves.easeInOut;

  /// Modal animation curve
  static const Curve modalCurve = Curves.easeOut;
}
