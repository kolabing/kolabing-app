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

  /// The yellow hero band, as a fraction of the screen. Restored at Volkan's
  /// request (2026-08-30) after the v2 port had replaced it with a cream page
  /// and a small left-aligned mark: he wanted the forgot-password top back, on
  /// both screens.
  static const double heroFraction = 0.32;

  /// The mark centred in that band. Larger than the v2 port's 76 — this is the
  /// size it had in the hero it is returning to.
  static const double heroMarkWidth = 84;

  /// Two Anton lines at 44/0.95, plus breathing room. What the band keeps when
  /// it collapses for the keyboard.
  static const double headingBlockHeight = 104;

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

  /// The wave asset was drawn 402x130; scale its height with the screen.
  static double waveHeightFor(double screenWidth) =>
      130.0 * screenWidth / 402.0;

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

/// The page shell: a yellow hero band with the mark, a wave into the cream
/// sheet, and the scrolling body beneath it.
///
/// The band collapses to the nav row while the keyboard is up. That is not
/// decoration — the version of this layout that shipped before took a fixed
/// 0.32 of the FULL screen height and never shrank, so with a keyboard open the
/// form was left ~298pt for ~560pt of content and the submit button sat below
/// the fold. Keeping the collapse is what makes the band affordable.
///
/// The scroll view's minimum height subtracts the padding it adds *below* the
/// content. Using the bare viewport height made the page permanently scrollable
/// by exactly that padding — a scroll with nothing at the end of it.
class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({
    super.key,
    required this.navRow,
    required this.headingFirstLine,
    required this.headingSecondLine,
    required this.keyboardOpen,
    required this.child,
  });

  final Widget navRow;

  final String headingFirstLine;

  /// The line carrying the yellow highlighter swash.
  final String headingSecondLine;

  final bool keyboardOpen;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final waveHeight = AuthMetrics.waveHeightFor(size.width);

    /// The heading lives in the band, not in the cream sheet.
    ///
    /// It used to sit above the form, where its two Anton lines plus their gap
    /// cost ~110pt and pushed the footer off the bottom — measured at 100.6pt
    /// of overflow on a 393x852. The band had ~141pt going spare around the
    /// mark, so the heading moved into it and the page stopped scrolling.
    ///
    /// Collapsed, the band drops the MARK and keeps the HEADING. Dropping the
    /// heading instead would re-create the thing Volkan reported in the first
    /// place: "welcome back" vanishing the moment he typed.
    final bandHeight = keyboardOpen
        ? topInset + AuthMetrics.navHeight + AuthMetrics.headingBlockHeight
        : size.height * AuthMetrics.heroFraction;

    return Scaffold(
      backgroundColor: KolabingColors.primary,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned(
            top: bandHeight,
            left: 0,
            right: 0,
            bottom: 0,
            child: const ColoredBox(color: KolabingColors.background),
          ),
          Positioned(
            top: bandHeight - waveHeight + 12,
            left: 0,
            right: 0,
            height: waveHeight,
            child: const CustomPaint(
              painter: AuthWavePainter(color: KolabingColors.background),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                height: bandHeight,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AuthMetrics.gutter,
                        ),
                        child: navRow,
                      ),
                      Expanded(
                        child: Padding(
                          // Clear the wave. Its path starts the cream at 66/130
                          // of the wave rect on the LEFT edge, where the heading
                          // sits, so the lockup has to stop about half a wave
                          // above the band's bottom or "BACK." lands on the
                          // curve.
                          padding: EdgeInsets.only(
                            left: AuthMetrics.gutter,
                            right: AuthMetrics.gutter,
                            bottom: keyboardOpen ? 0 : waveHeight * 0.42,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // The mark stands down for the keyboard; the
                              // heading does not.
                              AuthCollapsible(
                                collapsed: keyboardOpen,
                                child: const Padding(
                                  padding: EdgeInsets.only(right: 16),
                                  child: AnimatedKolabingKMark(
                                    width: AuthMetrics.heroMarkWidth,
                                    color: KolabingColors.brandDark,
                                  ),
                                ),
                              ),
                              Expanded(
                                // Scale down rather than wrap. Beside the mark
                                // the heading has ~170pt on a 320pt phone, and
                                // "BIENVENIDO" is longer than "WELCOME" — left
                                // to wrap it becomes four lines and overflows
                                // the band, which is what the narrow-screen
                                // test caught.
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        headingFirstLine,
                                        maxLines: 1,
                                        softWrap: false,
                                        style: AuthMetrics.headingStyle,
                                      ),
                                      AuthHighlightedText(
                                        text: headingSecondLine,
                                        style: AuthMetrics.headingStyle,
                                        color: KolabingColors.background,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
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
                        minHeight:
                            constraints.maxHeight - AuthMetrics.bottomPad,
                      ),
                      child: SafeArea(top: false, child: child),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The curve the cream sheet makes as it meets the yellow band. Lifted verbatim
/// from the pre-v2 auth screens, which is where Volkan wanted it back from.
class AuthWavePainter extends CustomPainter {
  const AuthWavePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final sx = size.width / 402.0;
    final sy = size.height / 130.0;

    final path = Path()
      ..moveTo(0, 130 * sy)
      ..lineTo(0, 66 * sy)
      ..cubicTo(72 * sx, 22 * sy, 150 * sx, 52 * sy, 230 * sx, 60 * sy)
      ..cubicTo(300 * sx, 67 * sy, 352 * sx, 34 * sy, 402 * sx, 50 * sy)
      ..lineTo(402 * sx, 130 * sy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(AuthWavePainter old) => old.color != color;
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

/// The handwritten line the cream sheet opens with. The heading and the mark
/// live in the yellow band above, drawn by [AuthPageScaffold].
class AuthSubtitle extends StatelessWidget {
  const AuthSubtitle({
    super.key,
    required this.text,
    required this.keyboardOpen,
  });

  final String text;

  /// Folded away with the mark, so the fields keep the room.
  final bool keyboardOpen;

  @override
  Widget build(BuildContext context) => AuthCollapsible(
    collapsed: keyboardOpen,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AuthMetrics.subtitleTop),
        Transform.rotate(
          angle: AuthMetrics.subtitleTilt,
          child: Text(text, style: AuthMetrics.subtitleStyle),
        ),
      ],
    ),
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
        child: Text(text, maxLines: 1, softWrap: false, style: style),
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
