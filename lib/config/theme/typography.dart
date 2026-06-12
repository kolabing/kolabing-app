import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kolabing font configuration — Atmospheric Editorial
///
/// Display: Anton (editorial, always uppercase)
/// Body: Inter (readable, neutral)
/// Labels: Hanken Grotesk (refined, spaced)
abstract final class KolabingTypography {
  /// Display font — Anton
  static String get fontDisplay => GoogleFonts.anton().fontFamily!;

  /// Body font — Inter
  static String get fontBody => GoogleFonts.inter().fontFamily!;

  /// Label/button font — Hanken Grotesk
  static String get fontLabel => GoogleFonts.hankenGrotesk().fontFamily!;

  // Legacy aliases kept for API compatibility
  static String get fontAccent => GoogleFonts.inter().fontFamily!;
  static String get fontFallback => GoogleFonts.inter().fontFamily!;
  static String get fontPageTitle => GoogleFonts.anton().fontFamily!;
}

/// Kolabing text styles — Atmospheric Editorial scale
///
/// Display/headlines: Anton. Body: Inter. Labels/buttons: Hanken Grotesk.
abstract final class KolabingTextStyles {
  // ---------------------------------------------------------------------------
  // Display — Anton, editorial. Always .toUpperCase() on the string.
  // ---------------------------------------------------------------------------

  static TextStyle get displayLarge => GoogleFonts.anton(
        fontSize: 64,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF857E70),
        height: 90 / 80,
        letterSpacing: 0.02 * 64,
      );

  static TextStyle get displayMedium => GoogleFonts.anton(
        fontSize: 38,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF857E70),
        height: 56 / 48,
        letterSpacing: 0.02 * 38,
      );

  static TextStyle get displaySmall => GoogleFonts.anton(
        fontSize: 26,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF857E70),
        height: 40 / 32,
        letterSpacing: 0.02 * 26,
      );

  // ---------------------------------------------------------------------------
  // Headlines — Anton, mobile display roles
  // ---------------------------------------------------------------------------

  static TextStyle get headlineLarge => GoogleFonts.anton(
        fontSize: 26,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF857E70),
        height: 38 / 32,
        letterSpacing: 0.02 * 26,
      );

  static TextStyle get headlineMedium => GoogleFonts.anton(
        fontSize: 19,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF857E70),
        letterSpacing: 0.02 * 19,
      );

  // ---------------------------------------------------------------------------
  // Body — Inter
  // ---------------------------------------------------------------------------

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 28 / 18,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
      );

  // ---------------------------------------------------------------------------
  // Labels — Hanken Grotesk
  // ---------------------------------------------------------------------------

  static TextStyle get labelLarge => GoogleFonts.hankenGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        letterSpacing: 0.05 * 14,
      );

  static TextStyle get labelMedium => GoogleFonts.hankenGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        letterSpacing: 0.05 * 12,
      );

  static TextStyle get labelSmall => GoogleFonts.hankenGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.05 * 11,
      );

  // ---------------------------------------------------------------------------
  // Eyebrow — Hanken Grotesk uppercase
  // Usage: always .toUpperCase() on the string
  // ---------------------------------------------------------------------------

  static TextStyle get eyebrow => GoogleFonts.hankenGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.05 * 12,
      );

  // ---------------------------------------------------------------------------
  // Component-specific styles (kept for explicit widget usage)
  // ---------------------------------------------------------------------------

  /// Hero card title — Anton 38px. Large explore swipe cards.
  static TextStyle get cardTitleHero => GoogleFonts.anton(
        fontSize: 38,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF857E70),
        letterSpacing: 0.02 * 38,
      );

  /// Standard card title — Anton 26px.
  static TextStyle get cardTitleLarge => GoogleFonts.anton(
        fontSize: 26,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF857E70),
        letterSpacing: 0.02 * 26,
      );

  /// Button label — Hanken Grotesk 14px Bold, spaced.
  static TextStyle get button => GoogleFonts.hankenGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.05 * 14,
      );

  /// Secondary caption — Inter 13px Regular. Subtitles on cards.
  static TextStyle get captionSecondary => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
      );

  // ---------------------------------------------------------------------------
  // Legacy styles — kept until widget files are migrated
  // ---------------------------------------------------------------------------

  /// @deprecated Use [headlineLarge]
  static TextStyle get pageTitle => GoogleFonts.anton(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF857E70),
        letterSpacing: 0.02 * 18,
        height: 1.1,
      );

  /// @deprecated Use [headlineMedium]
  static TextStyle get pageTitleSmall => GoogleFonts.anton(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF857E70),
        letterSpacing: 0.02 * 14,
        height: 1.1,
      );

  /// Mixed-case heading — Inter 24px Bold. Use when text is NOT uppercase.
  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 32 / 24,
      );

  /// Mixed-case heading — Inter 20px Bold. Use when text is NOT uppercase.
  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 28 / 20,
      );

  /// @deprecated Use [labelLarge]
  static TextStyle get titleSmall => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.005,
        height: 1.4,
      );

  /// @deprecated Use [headlineMedium]
  static TextStyle get headlineSmall => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01,
        height: 1.3,
      );

  /// @deprecated Use [button]
  static TextStyle get buttonSmall => GoogleFonts.hankenGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05 * 13,
        height: 1.2,
      );

  /// @deprecated Use [labelSmall]
  static TextStyle get chipLabelSmall => GoogleFonts.hankenGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      );

  /// @deprecated Use [labelMedium]
  static TextStyle get chipLabelMedium => GoogleFonts.hankenGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      );
}
