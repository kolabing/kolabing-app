import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/colors.dart';

/// Logo size presets
enum KolabingLogoSize {
  /// 40dp - Navigation bars, small headers
  small(40),

  /// 56dp - Medium contexts
  medium(56),

  /// 64dp - Auth screens
  large(64),

  /// 80dp - Welcome screen
  xLarge(80),

  /// 120dp - Splash screen
  splash(120);

  const KolabingLogoSize(this.value);

  final double value;
}

/// Logo variant styles
enum KolabingLogoVariant {
  /// Black K on yellow circle background (default for light backgrounds)
  yellowBackground,

  /// Yellow circle with black K (for dark backgrounds)
  yellowCircle,

  /// Black K only (no background, for splash screen)
  blackKOnly,
}

/// Kolabing logo widget
///
/// Displays the Kolabing logo with optional text below.
/// Supports different sizes and variants for various contexts.
class KolabingLogo extends StatelessWidget {
  const KolabingLogo({
    super.key,
    this.size = KolabingLogoSize.large,
    this.variant = KolabingLogoVariant.yellowCircle,
    this.showText = true,
    this.onDarkBackground = true,
    this.textColor,
  });

  /// Logo size
  final KolabingLogoSize size;

  /// Logo variant style
  final KolabingLogoVariant variant;

  /// Whether to show "Kolabing" text below the logo
  final bool showText;

  /// Whether the logo is on a dark background (affects text color)
  final bool onDarkBackground;

  /// Custom text color (overrides onDarkBackground)
  final Color? textColor;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Kolabing application logo',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo
            _buildLogo(),

            // Text below logo
            if (showText) ...[
              SizedBox(height: size == KolabingLogoSize.splash ? 16 : 12),
              Text(
                'Kolabing',
                style: GoogleFonts.rubik(
                  fontSize: _getTextSize(),
                  fontWeight: FontWeight.w800,
                  color: textColor ??
                      (onDarkBackground
                          ? KolabingColors.textOnDark
                          : KolabingColors.textPrimary),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ],
        ),
      );

  Widget _buildLogo() {
    switch (variant) {
      case KolabingLogoVariant.yellowBackground:
        return _buildYellowBackgroundLogo();
      case KolabingLogoVariant.yellowCircle:
        return _buildYellowCircleLogo();
      case KolabingLogoVariant.blackKOnly:
        return _buildBlackKOnly();
    }
  }

  /// Yellow circle with black K inside
  Widget _buildYellowCircleLogo() => Container(
        width: size.value,
        height: size.value,
        decoration: const BoxDecoration(
          color: KolabingColors.primary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            'K',
            style: GoogleFonts.rubik(
              fontSize: size.value * 0.5,
              fontWeight: FontWeight.w800,
              color: KolabingColors.onPrimary,
            ),
          ),
        ),
      );

  /// Black K on yellow background (for splash)
  Widget _buildYellowBackgroundLogo() => Container(
        width: size.value,
        height: size.value,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'K',
            style: GoogleFonts.rubik(
              fontSize: size.value * 0.67,
              fontWeight: FontWeight.w800,
              color: KolabingColors.onPrimary,
            ),
          ),
        ),
      );

  /// Black K only without background
  Widget _buildBlackKOnly() => SizedBox(
        width: size.value,
        height: size.value,
        child: Center(
          child: Text(
            'K',
            style: GoogleFonts.rubik(
              fontSize: size.value * 0.67,
              fontWeight: FontWeight.w800,
              color: KolabingColors.onPrimary,
            ),
          ),
        ),
      );

  double _getTextSize() {
    switch (size) {
      case KolabingLogoSize.small:
        return 14;
      case KolabingLogoSize.medium:
        return 16;
      case KolabingLogoSize.large:
        return 18;
      case KolabingLogoSize.xLarge:
        return 20;
      case KolabingLogoSize.splash:
        return 24;
    }
  }
}
