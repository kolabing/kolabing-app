import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kolabing font configuration — Atmospheric Editorial
///
/// Display: Anton (editorial, always uppercase)
/// Body/Labels/Buttons: Inter (readable, neutral)
abstract final class KolabingTypography {
  /// Display font — Anton
  static String get fontDisplay => GoogleFonts.anton().fontFamily!;

  /// Body font — Inter
  static String get fontBody => GoogleFonts.inter().fontFamily!;

  /// Label/button font — Inter (was Hanken Grotesk)
  static String get fontLabel => GoogleFonts.inter().fontFamily!;

  // Legacy aliases kept for API compatibility
  static String get fontAccent => GoogleFonts.inter().fontFamily!;
  static String get fontFallback => GoogleFonts.inter().fontFamily!;
  static String get fontPageTitle => GoogleFonts.anton().fontFamily!;
}

/// Kolabing text styles — Atmospheric Editorial scale
///
/// Display/headlines: Anton. Body/Labels/Buttons: Inter.
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
  // Labels — Inter
  // ---------------------------------------------------------------------------

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        letterSpacing: 0.05 * 14,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        letterSpacing: 0.05 * 12,
      );

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.05 * 11,
      );

  // ---------------------------------------------------------------------------
  // Eyebrow — Inter uppercase
  // Usage: always .toUpperCase() on the string
  // ---------------------------------------------------------------------------

  static TextStyle get eyebrow => GoogleFonts.inter(
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

  /// Button label — Inter 16px Bold, slightly tight tracking.
  static TextStyle get button => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
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
  static TextStyle get buttonSmall => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05 * 13,
        height: 1.2,
      );

  /// @deprecated Use [labelSmall]
  static TextStyle get chipLabelSmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      );

  /// @deprecated Use [labelMedium]
  static TextStyle get chipLabelMedium => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      );

  // ---------------------------------------------------------------------------
  // New semantic style constants (Task 1.2)
  // ---------------------------------------------------------------------------

  /// Major screen title — Anton 32px. Use .toUpperCase() on the string.
  static TextStyle get displayTitle => GoogleFonts.anton(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.1,
      );

  /// Large section heading — Anton 22px. Use .toUpperCase() on the string.
  static TextStyle get sectionHeadingLarge => GoogleFonts.anton(
        fontSize: 22,
        letterSpacing: 0.3,
        height: 1.2,
      );

  /// Large button label — Inter 16px Bold.
  static TextStyle get buttonLabelLg => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      );

  /// Medium button label — Inter 14px Bold.
  static TextStyle get buttonLabelMd => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      );

  /// Chip label — Inter 13px SemiBold.
  static TextStyle get chipLabel => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );

  /// Uppercase section micro-label — Inter 11px Bold, wide tracking.
  static TextStyle get metaLabel => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      );

  /// Large body text — Inter 16px Regular.
  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  /// Medium body text — Inter 14px Regular.
  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  /// Small body text — Inter 12px Regular.
  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  /// Community/business name — Inter 16px ExtraBold. NOT Anton.
  static TextStyle get nameBold => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w800,
      );
}
