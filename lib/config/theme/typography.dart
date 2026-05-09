import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kolabing font configuration
///
/// Inter is used for all UI text. Anton is reserved exclusively
/// for top-level page titles (editorial, branded, controlled).
abstract final class KolabingTypography {
  /// Primary font — Inter, used everywhere
  static String get fontDisplay => GoogleFonts.inter().fontFamily!;

  /// Body font — Inter
  static String get fontBody => GoogleFonts.inter().fontFamily!;

  /// Accent/label font — Inter
  static String get fontAccent => GoogleFonts.inter().fontFamily!;

  /// Fallback — Inter (same)
  static String get fontFallback => GoogleFonts.inter().fontFamily!;

  /// Page title font — Anton, used ONLY for major section headers
  static String get fontPageTitle => GoogleFonts.anton().fontFamily!;
}

/// Kolabing text styles — calm, Inter-only scale
///
/// All styles use Inter. Weights and sizes are restrained:
/// nothing feels like a poster or a billboard.
abstract final class KolabingTextStyles {
  // ---------------------------------------------------------------------------
  // Display Styles — largest text, entry/hero screens only
  // ---------------------------------------------------------------------------

  /// Display Large — 28px, SemiBold. Calm version of a big headline.
  static TextStyle get displayLarge => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.02,
        height: 1.2,
      );

  /// Display Medium — 24px, SemiBold
  static TextStyle get displayMedium => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.018,
        height: 1.2,
      );

  /// Display Small — 20px, SemiBold
  static TextStyle get displaySmall => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.015,
        height: 1.2,
      );

  // ---------------------------------------------------------------------------
  // Headline Styles — section headings
  // ---------------------------------------------------------------------------

  /// Headline Large — 22px, SemiBold
  static TextStyle get headlineLarge => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.015,
        height: 1.3,
      );

  /// Headline Medium — 19px, SemiBold
  static TextStyle get headlineMedium => GoogleFonts.inter(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.012,
        height: 1.3,
      );

  /// Headline Small — 17px, SemiBold
  static TextStyle get headlineSmall => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01,
        height: 1.3,
      );

  // ---------------------------------------------------------------------------
  // Title Styles — card headers, screen titles, nav bar
  // ---------------------------------------------------------------------------

  /// Title Large — 18px, SemiBold
  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01,
        height: 1.4,
      );

  /// Title Medium — 16px, SemiBold
  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.008,
        height: 1.4,
      );

  /// Title Small — 14px, SemiBold
  static TextStyle get titleSmall => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.005,
        height: 1.4,
      );

  // ---------------------------------------------------------------------------
  // Body Styles — paragraph and descriptive text
  // ---------------------------------------------------------------------------

  /// Body Large — 16px, Regular
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  /// Body Medium — 14px, Regular
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  /// Body Small — 12px, Regular
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  // ---------------------------------------------------------------------------
  // Label Styles — form labels, chips, nav items, metadata
  // ---------------------------------------------------------------------------

  /// Label Large — 15px, Medium
  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.005,
        height: 1.2,
      );

  /// Label Medium — 13px, Medium
  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.2,
      );

  /// Label Small — 11px, Medium — badges, nav labels
  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.01,
        height: 1.2,
      );

  // ---------------------------------------------------------------------------
  // Button Styles — CTA labels, Rubik to match section heading typography
  // ---------------------------------------------------------------------------

  /// Button — 15px, Rubik SemiBold. Matches heading label style (e.g. section titles).
  static TextStyle get button => GoogleFonts.rubik(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        height: 1.2,
      );

  /// Button small — 13px, Rubik SemiBold
  static TextStyle get buttonSmall => GoogleFonts.rubik(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        height: 1.2,
      );

  // ---------------------------------------------------------------------------
  // Page Title — Anton, major section headers ONLY
  // ---------------------------------------------------------------------------

  /// Page Title — 22px, Anton. Editorial, controlled. Not for cards or body.
  static TextStyle get pageTitle => GoogleFonts.anton(
        fontSize: 22,
        fontWeight: FontWeight.w400, // Anton is inherently bold
        letterSpacing: 0.5,
        height: 1.1,
      );

  /// Page Title Small — 18px, Anton. For AppBar-style page titles.
  static TextStyle get pageTitleSmall => GoogleFonts.anton(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.1,
      );
}
