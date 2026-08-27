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
  static const EdgeInsets screenPaddingAll = EdgeInsets.all(KolabingSpacing.md);

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
  static const EdgeInsets cardPadding = EdgeInsets.all(KolabingSpacing.md);

  /// Large card internal padding
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(KolabingSpacing.lg);

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
  static const double buttonHeight = 56;

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

/// Kolabing shadow definitions — Calm redesign
///
/// Shadows are minimal. Cards use borders instead of elevation.
/// No glow effects anywhere. Buttons are flat.
abstract final class KolabingShadows {
  /// Card shadow — ambient, low opacity large blur (Stitch spec)
  static const BoxShadow card = BoxShadow(
    color: Color(0x0A1C1C16),
    blurRadius: 24,
    offset: Offset(0, 4),
  );

  /// Ambient shadow — softest elevation for floating surfaces
  static const BoxShadow ambient = BoxShadow(
    color: Color(0x081C1C16),
    blurRadius: 40,
    offset: Offset(0, 8),
  );

  /// Card hover shadow — slight lift on interaction
  static const BoxShadow cardHover = BoxShadow(
    color: Color(0x12000000),
    blurRadius: 10,
    offset: Offset(0, 3),
  );

  /// Primary button shadow — 0 12px 26px rgba(20,18,16,0.12).
  static const BoxShadow button = BoxShadow(
    color: Color(0x1F141210),
    blurRadius: 26,
    offset: Offset(0, 12),
  );

  /// Secondary button shadow — 0 10px 22px rgba(20,18,16,0.10).
  static const BoxShadow buttonSecondary = BoxShadow(
    color: Color(0x1A141210),
    blurRadius: 22,
    offset: Offset(0, 10),
  );

  /// Bottom navigation shadow — soft upward line
  static const BoxShadow bottomNav = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 12,
    offset: Offset(0, -2),
  );

  /// Focus ring — removed; focus expressed via border-color only
  static const BoxShadow focusRing = BoxShadow(
    color: Color(0x00000000),
    blurRadius: 0,
    spreadRadius: 0,
  );

  /// FAB shadow — soft drop shadow beneath the floating action button.
  /// Matches inline definition in kolabing_fab.dart.
  static List<BoxShadow> get fab => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  /// Overlay card shadow — depth behind glass/dark overlay cards on images.
  /// Matches inline definition in explore_swipe_card.dart.
  static List<BoxShadow> get overlayCard => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 18,
      offset: const Offset(0, 10),
    ),
  ];

  /// Modal top shadow — upward shadow on sticky bottom action bars in sheets.
  /// Matches inline definition in explore_detail_sheet.dart.
  static List<BoxShadow> get modalTop => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, -2),
    ),
  ];

  /// Design handoff card shadow — multi-layer ambient + elevated effect
  static const List<BoxShadow> designCardShadow = [
    BoxShadow(color: Color(0x0A19150F), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x0619150F), blurRadius: 24, offset: Offset(0, 8)),
  ];

  /// Design handoff button shadow — warm dark drop shadow beneath yellow buttons
  static const List<BoxShadow> designButtonShadow = [
    BoxShadow(color: Color(0x1F141210), blurRadius: 26, offset: Offset(0, 12)),
  ];

  // ---------------------------------------------------------------------------
  // List helpers for decoration
  // ---------------------------------------------------------------------------

  static List<BoxShadow> get cardShadow => [card];
  static List<BoxShadow> get ambientShadow => [ambient];
  static List<BoxShadow> get cardHoverShadow => [cardHover];
  static List<BoxShadow> get buttonShadow => [button];
  static List<BoxShadow> get buttonSecondaryShadow => [buttonSecondary];
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
