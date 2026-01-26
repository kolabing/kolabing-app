import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kolabing font family definitions
///
/// Primary fonts used throughout the application via Google Fonts.
abstract final class KolabingTypography {
  /// Display font - Used for headlines and titles
  static String get fontDisplay => GoogleFonts.rubik().fontFamily!;

  /// Body font - Used for body text and inputs
  static String get fontBody => GoogleFonts.openSans().fontFamily!;

  /// Accent font - Used for buttons and CTAs
  /// Note: Darker Grotesque is not available in Google Fonts, using DM Sans as alternative
  static String get fontAccent => GoogleFonts.dmSans().fontFamily!;

  /// Fallback font
  static String get fontFallback => GoogleFonts.inter().fontFamily!;
}

/// Kolabing text styles
///
/// All text style definitions following the design system.
/// Organized by semantic meaning: Display, Headline, Title, Body, Label, Button.
abstract final class KolabingTextStyles {
  // ---------------------------------------------------------------------------
  // Display Styles - Hero headings (Rubik, uppercase)
  // ---------------------------------------------------------------------------

  /// Display Large - 32px, ExtraBold
  static TextStyle get displayLarge => GoogleFonts.rubik(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        height: 1.2,
      );

  /// Display Medium - 28px, ExtraBold
  static TextStyle get displayMedium => GoogleFonts.rubik(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        height: 1.2,
      );

  /// Display Small - 24px, Bold
  static TextStyle get displaySmall => GoogleFonts.rubik(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        height: 1.2,
      );

  // ---------------------------------------------------------------------------
  // Headline Styles - Section headings (Rubik)
  // ---------------------------------------------------------------------------

  /// Headline Large - 22px, Bold
  static TextStyle get headlineLarge => GoogleFonts.rubik(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.3,
      );

  /// Headline Medium - 20px, SemiBold
  static TextStyle get headlineMedium => GoogleFonts.rubik(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  /// Headline Small - 18px, SemiBold
  static TextStyle get headlineSmall => GoogleFonts.rubik(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  // ---------------------------------------------------------------------------
  // Title Styles - Card titles, navigation (Open Sans)
  // ---------------------------------------------------------------------------

  /// Title Large - 18px, Bold
  static TextStyle get titleLarge => GoogleFonts.openSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.4,
      );

  /// Title Medium - 16px, SemiBold
  static TextStyle get titleMedium => GoogleFonts.openSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  /// Title Small - 14px, SemiBold
  static TextStyle get titleSmall => GoogleFonts.openSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  // ---------------------------------------------------------------------------
  // Body Styles - Regular text (Open Sans)
  // ---------------------------------------------------------------------------

  /// Body Large - 16px, Regular
  static TextStyle get bodyLarge => GoogleFonts.openSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  /// Body Medium - 14px, Regular
  static TextStyle get bodyMedium => GoogleFonts.openSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  /// Body Small - 12px, Regular
  static TextStyle get bodySmall => GoogleFonts.openSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  // ---------------------------------------------------------------------------
  // Label Styles - Buttons, form labels (DM Sans as Darker Grotesque alternative)
  // ---------------------------------------------------------------------------

  /// Label Large - 16px, SemiBold
  static TextStyle get labelLarge => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.2,
      );

  /// Label Medium - 14px, Medium
  static TextStyle get labelMedium => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        height: 1.2,
      );

  /// Label Small - 12px, Medium
  static TextStyle get labelSmall => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        height: 1.2,
      );

  // ---------------------------------------------------------------------------
  // Button Style - CTA buttons (DM Sans, uppercase)
  // ---------------------------------------------------------------------------

  /// Button text style - 16px, SemiBold, uppercase
  static TextStyle get button => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        height: 1.2,
      );

  /// Button small text style - 14px, SemiBold
  static TextStyle get buttonSmall => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        height: 1.2,
      );
}
