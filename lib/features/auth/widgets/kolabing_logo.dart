import 'package:flutter/material.dart';

/// Which logo asset to render
enum KolabingLogoVariant {
  /// Black cloud + yellow text — for yellow/light backgrounds
  onYellow('assets/images/logo_cloud_on_yellow.png'),

  /// Yellow cloud + black text — for dark/black backgrounds
  onDark('assets/images/logo_cloud_on_dark.png'),

  /// Black cloud + white text on transparent — for mixed/floating contexts
  transparent('assets/images/logo_cloud_transparent.png'),

  /// Black cloud + yellow text on transparent
  yellowTransparent('assets/images/logo_cloud_yellow_transparent.png'),

  /// Yellow cloud + black text on transparent
  lightTransparent('assets/images/logo_cloud_light_transparent.png'),

  /// Black cloud + white text — maximum contrast
  whiteOnDark('assets/images/logo_wordmark_white_on_dark.png');

  const KolabingLogoVariant(this.assetPath);
  final String assetPath;
}

/// Kolabing logo widget — renders the real logo image asset.
///
/// [width] controls the rendered width; height scales automatically.
/// Pick [variant] based on the background:
///   dark bg → onDark, yellow/light bg → onYellow, floating → transparent.
class KolabingLogo extends StatelessWidget {
  const KolabingLogo({
    super.key,
    this.width = 200,
    this.variant = KolabingLogoVariant.onDark,
  });

  final double width;
  final KolabingLogoVariant variant;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Kolabing logo',
        image: true,
        child: Image.asset(
          variant.assetPath,
          width: width,
          fit: BoxFit.contain,
        ),
      );
}
