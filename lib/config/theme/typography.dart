import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kolabing font configuration — clean sans-serif system
///
/// Display/headlines and Body/Labels/Buttons all use Inter. Anton has been
/// fully retired from the product UI (kept only for external marketing/
/// social assets, outside this Flutter app).
abstract final class KolabingTypography {
  /// Display font — Inter
  static String get fontDisplay => GoogleFonts.inter().fontFamily!;

  /// Body font — Inter
  static String get fontBody => GoogleFonts.inter().fontFamily!;

  /// Label/button font — Inter (was Hanken Grotesk)
  static String get fontLabel => GoogleFonts.inter().fontFamily!;

  // Legacy aliases kept for API compatibility
  static String get fontAccent => GoogleFonts.inter().fontFamily!;
  static String get fontFallback => GoogleFonts.inter().fontFamily!;
  static String get fontPageTitle => GoogleFonts.inter().fontFamily!;
}

/// Kolabing text styles — clean sans-serif scale
///
/// Every role (display, headline, body, label) uses Inter. Former Anton
/// roles keep their original size/letter-spacing/color but move to Inter
/// Bold (w700) so the display roles keep their intended visual weight —
/// Anton renders as an effectively-bold face regardless of numeric weight,
/// so Inter w400 at these sizes would read as too light for the same role.
abstract final class KolabingTextStyles {
  // ---------------------------------------------------------------------------
  // Display — Inter Bold. Former Anton roles; casing is caller-controlled.
  // ---------------------------------------------------------------------------

  static TextStyle get displayLarge => GoogleFonts.inter(
    fontSize: 64,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF857E70),
    height: 90 / 80,
    letterSpacing: 0.02 * 64,
  );

  static TextStyle get displayMedium => GoogleFonts.inter(
    fontSize: 38,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF857E70),
    height: 56 / 48,
    letterSpacing: 0.02 * 38,
  );

  static TextStyle get displaySmall => GoogleFonts.inter(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF857E70),
    height: 40 / 32,
    letterSpacing: 0.02 * 26,
  );

  // ---------------------------------------------------------------------------
  // Headlines — Inter Bold, mobile display roles. Former Anton roles.
  // ---------------------------------------------------------------------------

  static TextStyle get headlineLarge => GoogleFonts.inter(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF857E70),
    height: 38 / 32,
    letterSpacing: 0.02 * 26,
  );

  static TextStyle get headlineMedium => GoogleFonts.inter(
    fontSize: 19,
    fontWeight: FontWeight.w700,
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

  /// Hero card title — Inter Bold 38px. Large explore swipe cards.
  /// Former Anton role; no known call sites currently.
  static TextStyle get cardTitleHero => GoogleFonts.inter(
    fontSize: 38,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF857E70),
    letterSpacing: 0.02 * 38,
  );

  /// Standard card title — Inter Bold 26px.
  /// Former Anton role; no known call sites currently.
  static TextStyle get cardTitleLarge => GoogleFonts.inter(
    fontSize: 26,
    fontWeight: FontWeight.w700,
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
  static TextStyle get captionSecondary =>
      GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400);

  // ---------------------------------------------------------------------------
  // Legacy styles — kept until widget files are migrated
  // ---------------------------------------------------------------------------

  /// @deprecated Use [headlineLarge]
  static TextStyle get pageTitle => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF857E70),
    letterSpacing: 0.02 * 18,
    height: 1.1,
  );

  /// @deprecated Use [headlineMedium]
  static TextStyle get pageTitleSmall => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w700,
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
  static TextStyle get chipLabelSmall =>
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600);

  /// @deprecated Use [labelMedium]
  static TextStyle get chipLabelMedium =>
      GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600);

  // ---------------------------------------------------------------------------
  // New semantic style constants (Task 1.2)
  // ---------------------------------------------------------------------------

  /// Major screen title — Inter Bold 32px. Former Anton role; casing is
  /// caller-controlled (do not assume uppercase).
  static TextStyle get displayTitle => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    height: 1.1,
  );

  /// Large section heading — Inter Bold 22px. Former Anton role; casing is
  /// caller-controlled (do not assume uppercase).
  static TextStyle get sectionHeadingLarge => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    height: 1.2,
  );

  static TextStyle get sectionHeader => sectionHeadingLarge;

  /// Large button label — Inter 16px Bold.
  static TextStyle get buttonLabelLg => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
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
  static TextStyle get bodyLg =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);

  /// Medium body text — Inter 14px Regular.
  static TextStyle get bodyMd =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);

  /// Small body text — Inter 12px Regular.
  static TextStyle get bodySm =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4);

  /// Community/business name — Inter 16px ExtraBold. NOT Anton.
  static TextStyle get nameBold =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800);

  // ---------------------------------------------------------------------------
  // Screen title — Inter, sentence case. Reusable main-screen title token.
  // NOT Anton, NOT uppercase — do not add .toUpperCase() at call sites.
  // ---------------------------------------------------------------------------

  /// Main screen title (Explore, Business dashboard, My Kolabs, Profile...) —
  /// Inter 28px Bold, sentence case. Color is set by the caller via
  /// [TextStyle.copyWith] (see other tokens in this file for the convention).
  static TextStyle get screenTitle => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.2,
  );

  // ---------------------------------------------------------------------------
  // Stat number — Inter Extra Bold. Big emphasized numbers (dashboard
  // stats, XP counters). Callers set fontSize/color via [TextStyle.copyWith]
  // — this replaces the former one-off GoogleFonts.anton(...) calls used for
  // the same role.
  // ---------------------------------------------------------------------------

  static TextStyle get statNumber =>
      GoogleFonts.inter(fontWeight: FontWeight.w800, height: 1.0);
}
