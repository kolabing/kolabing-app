import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/theme/colors.dart';
import '../../../widgets/brand/kolabing_k_mark.dart';

/// The shared furniture of the auth screens, ported from
/// `Mobile Login v2.dc.html` variant 1a (kolabing-app#193).
///
/// It lives here rather than in one screen because the sign-in and
/// forgot-password pages have to look like the same product — the two had
/// already drifted once, each carrying its own copy of the old yellow hero.
/// Anything a reviewer would expect to match between them is in this file, so
/// they cannot drift again without someone deciding to.
///
/// Every number is lifted from the design doc rather than a house token, which
/// is why they sit together and named: a reviewer should be able to diff them
/// against the source.
abstract final class AuthMetrics {
  static const double gutter = 24;
  static const double bottomPad = 28;
  static const double navHeight = 48;

  static const double markTop = 18;
  static const double markWidth = 76;

  /// −2° on the mark, −3° on the handwritten line, in radians.
  static const double markTilt = -2 * math.pi / 180;
  static const double subtitleTilt = -3 * math.pi / 180;

  static const double headingTop = 26;
  static const double subtitleTop = 12;
  static const double bodyTop = 26;
  static const double fieldHeight = 54;
  static const double fieldGap = 12;
  static const double ctaTop = 14;
  static const double ctaHeight = 56;
  static const double footerAfterCta = 32;

  static TextStyle get headingStyle => GoogleFonts.anton(
    fontSize: 44,
    fontWeight: FontWeight.w400,
    height: 0.95,
    letterSpacing: -0.44,
    color: KolabingColors.brandDark,
  );

  static TextStyle get subtitleStyle => GoogleFonts.caveat(
    fontSize: 21,
    fontWeight: FontWeight.w600,
    color: KolabingColors.inkBody,
  );

  static TextStyle get fieldTextStyle => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: KolabingColors.brandDark,
  );

  static Color get hairline => KolabingColors.brandDark.withValues(alpha: 0.12);

  static OutlineInputBorder fieldBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(fieldHeight / 2),
    borderSide: BorderSide(color: color, width: 1.5),
  );

  /// The pill field the design uses everywhere: 54 tall, fully rounded, white,
  /// hairline border that darkens on focus, glyph inset 20 from the edge.
  ///
  /// Height comes from padding rather than a BoxConstraints clamp: a clamp also
  /// caps the decorator when a validation message appears, and Material then
  /// squeezes the text instead of growing.
  static InputDecoration fieldDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: KolabingColors.muted,
    ),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
    prefixIcon: Padding(
      padding: const EdgeInsets.only(left: 20, right: 12),
      child: Icon(prefixIcon, color: KolabingColors.muted, size: 18),
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    suffixIcon: suffixIcon,
    suffixIconConstraints: const BoxConstraints(minWidth: 52, minHeight: 44),
    border: fieldBorder(hairline),
    enabledBorder: fieldBorder(hairline),
    focusedBorder: fieldBorder(KolabingColors.brandDark),
    errorBorder: fieldBorder(KolabingColors.error),
    focusedErrorBorder: fieldBorder(KolabingColors.error),
    errorStyle: GoogleFonts.inter(
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
      color: KolabingColors.error,
    ),
  );
}

/// The page shell: cream ground, safe area, one scroll view, and the gutter.
///
/// The scroll view's minimum height subtracts the padding it adds *below* the
/// content. Using the bare viewport height made the page permanently scrollable
/// by exactly that padding — a scroll with nothing at the end of it.
class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: KolabingColors.background,
    resizeToAvoidBottomInset: true,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AuthMetrics.gutter,
            0,
            AuthMetrics.gutter,
            AuthMetrics.bottomPad,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - AuthMetrics.bottomPad,
            ),
            child: child,
          ),
        ),
      ),
    ),
  );
}

/// `‹ back` on the left, an optional action on the right. Lowercase by design;
/// the casing lives in the ARBs because `toLowerCase()` is locale-sensitive.
class AuthNavRow extends StatelessWidget {
  const AuthNavRow({
    super.key,
    required this.backLabel,
    required this.onBack,
    this.trailingLabel,
    this.onTrailing,
  });

  final String backLabel;
  final VoidCallback? onBack;
  final String? trailingLabel;
  final VoidCallback? onTrailing;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AuthMetrics.navHeight,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(LucideIcons.chevronLeft, size: 18),
          label: Text(backLabel),
          style: TextButton.styleFrom(
            foregroundColor: KolabingColors.brandDark,
            padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (trailingLabel != null)
          TextButton(
            onPressed: onTrailing,
            style: TextButton.styleFrom(
              foregroundColor: KolabingColors.brandDark,
              padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              trailingLabel!,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    ),
  );
}

/// Mark, heading and handwritten line — the block every auth page opens with.
///
/// [keyboardOpen] folds the decorative half away. The design spends its top
/// third on brand, and the keyboard leaves ~596pt of 932; the heading stays
/// because that is the part people look for.
class AuthHero extends StatelessWidget {
  const AuthHero({
    super.key,
    required this.headingFirstLine,
    required this.headingSecondLine,
    required this.subtitle,
    required this.keyboardOpen,
  });

  final String headingFirstLine;

  /// The line carrying the yellow highlighter swash.
  final String headingSecondLine;

  final String subtitle;
  final bool keyboardOpen;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      AuthCollapsible(
        collapsed: keyboardOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AuthMetrics.markTop),
            Transform.rotate(
              angle: AuthMetrics.markTilt,
              child: const AnimatedKolabingKMark(
                width: AuthMetrics.markWidth,
                color: KolabingColors.brandDark,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AuthMetrics.headingTop),
      Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(headingFirstLine, style: AuthMetrics.headingStyle),
            AuthHighlightedText(
              text: headingSecondLine,
              style: AuthMetrics.headingStyle,
              color: KolabingColors.primary,
            ),
          ],
        ),
      ),
      AuthCollapsible(
        collapsed: keyboardOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AuthMetrics.subtitleTop),
            Transform.rotate(
              angle: AuthMetrics.subtitleTilt,
              child: Text(subtitle, style: AuthMetrics.subtitleStyle),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Collapses its child to nothing, with a bit of easing, when the keyboard
/// takes the room it was using.
///
/// [AnimatedSize] rather than a bare `if`: without the tween the page jumps by
/// ~170pt the instant a field takes focus, which reads as a glitch rather than
/// as the screen making space.
class AuthCollapsible extends StatelessWidget {
  const AuthCollapsible({
    super.key,
    required this.collapsed,
    required this.child,
  });

  final bool collapsed;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeOutCubic,
    alignment: Alignment.topCenter,
    child: collapsed
        ? const SizedBox(width: double.infinity)
        : Align(alignment: Alignment.centerLeft, child: child),
  );
}

/// Text with a highlighter swash behind its lower half.
///
/// The design paints it with a gradient that is transparent above 55% of the
/// line box and yellow from there to 92% — a marker stroke that sits on the
/// baseline rather than boxing the word. A [Stack] reproduces it without
/// measuring glyphs: the band is a fraction of whatever height the text takes.
class AuthHighlightedText extends StatelessWidget {
  const AuthHighlightedText({
    super.key,
    required this.text,
    required this.style,
    required this.color,
  });

  final String text;
  final TextStyle style;
  final Color color;

  /// 55% → 92% of the line box.
  static const double _bandHeight = 0.37;

  /// Alignment.y that puts a band of [_bandHeight] with its top at 55%.
  static const double _bandY = 0.746;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.centerLeft,
    children: [
      Positioned.fill(
        child: Align(
          alignment: const Alignment(0, _bandY),
          child: FractionallySizedBox(
            heightFactor: _bandHeight,
            widthFactor: 1,
            child: ColoredBox(color: color),
          ),
        ),
      ),
      // The design pads the swash 2px past the glyphs on each side.
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(text, style: style),
      ),
    ],
  );
}

/// Primary CTA — dark ground, yellow text. Inverted from the app's usual
/// yellow-on-dark, which is what the design system specifies for it
/// (`--kb-cta-bg` dark, `--kb-cta-ink` yellow).
class AuthPrimaryCta extends StatelessWidget {
  const AuthPrimaryCta({
    super.key,
    required this.label,
    required this.isLoading,
    required this.isEnabled,
    required this.onPressed,
    this.showSuccess = false,
  });

  final String label;
  final bool isLoading;
  final bool isEnabled;
  final bool showSuccess;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: isEnabled || isLoading || showSuccess ? 1 : 0.5,
    duration: const Duration(milliseconds: 200),
    child: SizedBox(
      height: AuthMetrics.ctaHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AuthMetrics.ctaHeight / 2),
          boxShadow: [
            BoxShadow(
              color: KolabingColors.primary.withValues(alpha: 0.8),
              blurRadius: 26,
              spreadRadius: -15,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: KolabingColors.brandDark,
          borderRadius: BorderRadius.circular(AuthMetrics.ctaHeight / 2),
          child: InkWell(
            onTap: isEnabled && !isLoading && !showSuccess ? onPressed : null,
            borderRadius: BorderRadius.circular(AuthMetrics.ctaHeight / 2),
            child: Center(
              child: showSuccess
                  ? const Icon(
                      Icons.check_rounded,
                      size: 24,
                      color: KolabingColors.primary,
                    )
                  : isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          KolabingColors.primary,
                        ),
                      ),
                    )
                  : Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: KolabingColors.primary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    ),
  );
}
