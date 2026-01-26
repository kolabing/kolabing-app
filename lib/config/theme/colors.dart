import 'package:flutter/material.dart';

/// Kolabing design system colors
///
/// All color definitions for the Kolabing app following the brand guidelines.
/// Use these constants throughout the app for consistent styling.
abstract final class KolabingColors {
  // ---------------------------------------------------------------------------
  // Primary Brand Colors
  // ---------------------------------------------------------------------------

  /// Primary brand color - Yellow
  /// Used for main CTAs, active tabs, and highlights
  static const Color primary = Color(0xFFFFD861);

  /// Darker yellow for pressed/hover states
  static const Color primaryDark = Color(0xFFE5C057);

  /// Black text on primary color (always use for text on yellow)
  static const Color onPrimary = Color(0xFF000000);

  // ---------------------------------------------------------------------------
  // Background Colors
  // ---------------------------------------------------------------------------

  /// Light gray background - Main app background
  static const Color background = Color(0xFFF7F8FA);

  /// White surfaces for cards, modals, bottom sheets
  static const Color surface = Color(0xFFFFFFFF);

  /// Input backgrounds (light theme)
  static const Color surfaceVariant = Color(0xFFF5F6F8);

  // ---------------------------------------------------------------------------
  // Text Colors
  // ---------------------------------------------------------------------------

  /// Primary text color
  static const Color textPrimary = Color(0xFF232323);

  /// Secondary/muted text color
  static const Color textSecondary = Color(0xFF606060);

  /// Tertiary/hint text color
  static const Color textTertiary = Color(0xFF888888);

  /// White text for dark backgrounds
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Dark Theme Colors (Auth Screens)
  // ---------------------------------------------------------------------------

  /// Black background for auth screens
  static const Color darkBackground = Color(0xFF000000);

  /// Dark surface for inputs on auth screens
  static const Color darkSurface = Color(0xFF222222);

  /// Dark border color
  static const Color darkBorder = Color(0xFF444444);

  // ---------------------------------------------------------------------------
  // Semantic Colors
  // ---------------------------------------------------------------------------

  /// Success green
  static const Color success = Color(0xFF7AE7A3);

  /// Warning yellow
  static const Color warning = Color(0xFFFBC02D);

  /// Error/destructive red
  static const Color error = Color(0xFFE14D76);

  /// Info blue
  static const Color info = Color(0xFF2196F3);

  // ---------------------------------------------------------------------------
  // Border Colors
  // ---------------------------------------------------------------------------

  /// Default border color
  static const Color border = Color(0xFFEBEBEB);

  /// Focus border color
  static const Color borderFocus = Color(0xFFE8D7A0);

  /// Error border color
  static const Color borderError = Color(0xFFFF6B6B);

  // ---------------------------------------------------------------------------
  // Accent Colors (Categories/Badges)
  // ---------------------------------------------------------------------------

  /// Orange badge background
  static const Color accentOrange = Color(0xFFFFDDAC);

  /// Orange badge text
  static const Color accentOrangeText = Color(0xFFD8910B);

  /// Soft yellow background
  static const Color softYellow = Color(0xFFFFF6D8);

  /// Soft yellow border
  static const Color softYellowBorder = Color(0xFFF9E9AC);

  // ---------------------------------------------------------------------------
  // Status Badge Colors
  // ---------------------------------------------------------------------------

  /// Pending badge background
  static const Color pendingBg = Color(0xFFFFDDAC);

  /// Pending badge text
  static const Color pendingText = Color(0xFFD8910B);

  /// Active/Published badge background
  static const Color activeBg = Color(0xFFD4EDDA);

  /// Active/Published badge text
  static const Color activeText = Color(0xFF155724);

  /// Completed badge background
  static const Color completedBg = Color(0xFFE8E8E8);

  /// Completed badge text
  static const Color completedText = Color(0xFF666666);

  /// Error/Declined badge background
  static const Color errorBg = Color(0xFFF8D7DA);

  /// Error/Declined badge text
  static const Color errorText = Color(0xFF721C24);

  // ---------------------------------------------------------------------------
  // Gradient
  // ---------------------------------------------------------------------------

  /// Primary gradient for special elements
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFD861),
      Color(0xFFFFE082),
    ],
  );
}
