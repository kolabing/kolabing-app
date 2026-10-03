import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/colors.dart';

/// Pure black, deliberately not the warm ink: it matches the splash and the
/// K asset's own ground, so splash → welcome → login has no colour seam.
const Color kAuthHeroNight = Color(0xFF000000);

/// The warm cream of the auth sheets.
const Color kAuthSheetCream = Color(0xFFF6F1E7);

const String _kLogoMarkAsset = 'assets/brand/kolabing-k-mark.png';

/// Light status-bar icons over the black hero, cream system nav bar.
const SystemUiOverlayStyle kAuthHeroOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: kAuthSheetCream,
  systemNavigationBarIconBrightness: Brightness.dark,
);

/// The logged-out brand hero: the yellow K logomark and KOLABING on black,
/// a soft glow behind the mark, and the cream sheet's rounded top drawn
/// along its bottom edge so the content below reads as a sheet.
///
/// Used by Welcome, Login and Forgot password.
class AuthBrandHero extends StatelessWidget {
  const AuthBrandHero({
    required this.height,
    this.markHeight = 78,
    this.reveal,
    this.leading,
    super.key,
  });

  /// Total height, including the status bar inset and the sheet radius.
  final double height;

  final double markHeight;

  /// Drives the mark's scale-in and fade (0 → 1). Null shows it at rest.
  final Animation<double>? reveal;

  /// Sits top-left under the status bar, e.g. [AuthHeroBackButton].
  final Widget? leading;

  static const double navHeight = 56;
  static const double sheetRadius = 32;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final reveal = this.reveal ?? kAlwaysCompleteAnimation;
    // The mark sits centred in what is left between the nav row and the sheet.
    final markTop = topInset + navHeight;
    final markAreaHeight = height - markTop - sheetRadius;

    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(child: ColoredBox(color: kAuthHeroNight)),
          // A soft yellow glow behind the mark.
          Positioned(
            left: 0,
            right: 0,
            top: markTop - 30,
            height: markAreaHeight + 60,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.45,
                  colors: [Color(0x38FFE28C), Color(0x00FFE28C)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: markTop,
            height: markAreaHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 0.6, end: 1).animate(
                    CurvedAnimation(parent: reveal, curve: Curves.easeOutBack),
                  ),
                  child: FadeTransition(
                    opacity: reveal,
                    child: Image.asset(
                      _kLogoMarkAsset,
                      key: const Key('auth-logo-mark'),
                      height: markHeight,
                      semanticLabel: 'Kolabing',
                    ),
                  ),
                ),
                SizedBox(height: markHeight * 0.23),
                FadeTransition(
                  opacity: reveal,
                  // Brand name — exempt from i18n, as on the splash.
                  child: Text(
                    'KOLABING',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: KolabingColors.primary,
                      letterSpacing: 6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (leading != null)
            Positioned(
              left: 16,
              top: topInset,
              height: navHeight,
              child: Align(alignment: Alignment.centerLeft, child: leading),
            ),
          // The cream sheet's rounded top, overlapping the black.
          const Positioned(
            left: 0,
            right: 0,
            bottom: -1,
            height: sheetRadius + 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: kAuthSheetCream,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(sheetRadius),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular back button for the black hero.
class AuthHeroBackButton extends StatelessWidget {
  const AuthHeroBackButton({
    required this.onTap,
    required this.semanticLabel,
    this.isEnabled = true,
    super.key,
  });

  final VoidCallback onTap;
  final bool isEnabled;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel,
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: isEnabled ? 1 : 0.35,
      child: Material(
        color: Colors.white.withValues(alpha: 0.1),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEnabled
              ? () {
                  HapticFeedback.lightImpact();
                  onTap();
                }
              : null,
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 17,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ),
  );
}
