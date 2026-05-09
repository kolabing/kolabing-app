import 'package:flutter/material.dart';

/// Kolabing design system colors — Calm redesign
///
/// Palette: warm beige surfaces, muted yellow CTA, near-black text,
/// purple for links/active states only. No pure-black backgrounds.
abstract final class KolabingColors {
  // ---------------------------------------------------------------------------
  // Primary Brand Colors
  // ---------------------------------------------------------------------------

  /// Primary CTA — warm soft yellow
  static const Color primary = Color(0xFFFFE28C);

  /// Darker yellow for pressed states
  static const Color primaryDark = Color(0xFFF5D070);

  /// Near-black on primary (always use for text on yellow)
  static const Color onPrimary = Color(0xFF0D0D0D);

  // ---------------------------------------------------------------------------
  // Background Colors
  // ---------------------------------------------------------------------------

  /// Warm beige — main background, all screens
  static const Color background = Color(0xFFF5F1E8);

  /// Warm off-white — cards, modals, elevated content
  static const Color surface = Color(0xFFFCFAF5);

  /// Pure white — input fills
  static const Color surfaceVariant = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Text Colors
  // ---------------------------------------------------------------------------

  /// Primary text — near black
  static const Color textPrimary = Color(0xFF0D0D0D);

  /// Secondary/muted text
  static const Color textSecondary = Color(0xFF5A5A55);

  /// Tertiary/hint text
  static const Color textTertiary = Color(0xFF8C8A82);

  /// White text (badge text on dark fills, overlays)
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Auth context colors
  // Auth screens now share the same warm beige — no pure-black mode.
  // These aliases are kept for API compatibility with existing screens.
  // ---------------------------------------------------------------------------

  /// Auth screen background — warm beige (same as [background])
  static const Color darkBackground = Color(0xFFF5F1E8);

  /// Auth input surface — pure white
  static const Color darkSurface = Color(0xFFFFFFFF);

  /// Auth border — subtle warm divider
  static const Color darkBorder = Color(0x0F0D0D0D);

  // ---------------------------------------------------------------------------
  // Accent — Purple
  // State/navigation/intelligence color. Yellow = action, Purple = state.
  // ---------------------------------------------------------------------------

  /// Purple accent — active nav, section labels, progress, chips, badges
  static const Color accent = Color(0xFF7F77DD);

  /// Text/icons on purple accent fills
  static const Color onAccent = Color(0xFFFFFFFF);

  /// Soft purple — light fill for selected chips and subtle tints
  static const Color softAccent = Color(0xFFEFEEFA);

  // ---------------------------------------------------------------------------
  // Semantic Colors
  // ---------------------------------------------------------------------------

  /// Success green
  static const Color success = Color(0xFF7AE7A3);

  /// Warning amber
  static const Color warning = Color(0xFFFBC02D);

  /// Error/destructive rose
  static const Color error = Color(0xFFE14D76);

  /// Info blue
  static const Color info = Color(0xFF2196F3);

  // ---------------------------------------------------------------------------
  // Border Colors
  // ---------------------------------------------------------------------------

  /// Default border — subtle warm divider (rgba 0,0,0,0.06)
  static const Color border = Color(0x0F0D0D0D);

  /// Focus border — near black (high contrast on warm surface)
  static const Color borderFocus = Color(0xFF0D0D0D);

  /// Error border
  static const Color borderError = Color(0xFFE14D76);

  // ---------------------------------------------------------------------------
  // Accent / Badge backgrounds
  // ---------------------------------------------------------------------------

  /// Orange badge background
  static const Color accentOrange = Color(0xFFFFDDAC);

  /// Orange badge text
  static const Color accentOrangeText = Color(0xFFD8910B);

  /// Soft yellow — selected card fills, soft chips
  static const Color softYellow = Color(0xFFFFF4C2);

  /// Soft yellow border
  static const Color softYellowBorder = Color(0xFFFFE28C);

  // ---------------------------------------------------------------------------
  // Status Badge Colors
  // ---------------------------------------------------------------------------

  static const Color pendingBg = Color(0xFFFFDDAC);
  static const Color pendingText = Color(0xFFD8910B);

  static const Color activeBg = Color(0xFFD4EDDA);
  static const Color activeText = Color(0xFF155724);

  static const Color completedBg = Color(0xFFEDEAE0);
  static const Color completedText = Color(0xFF5A5A55);

  static const Color errorBg = Color(0xFFF8D7DA);
  static const Color errorText = Color(0xFF721C24);

  // ---------------------------------------------------------------------------
  // Gradient
  // ---------------------------------------------------------------------------

  /// Primary gradient — promotional banners and highlight elements only
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFE28C),
      Color(0xFFFFF4C2),
    ],
  );
}
