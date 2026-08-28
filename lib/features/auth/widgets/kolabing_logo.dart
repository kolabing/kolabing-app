import 'package:flutter/material.dart';

import '../../../config/theme/colors.dart';
import '../../../widgets/brand/kolabing_k_mark.dart';

/// Which ink the mark is drawn in — pick it from the background it sits on.
enum KolabingLogoTone {
  /// Charcoal K — for yellow, cream and other light grounds.
  dark(KolabingColors.charcoal),

  /// Yellow K — for black and other dark grounds.
  light(KolabingColors.primary);

  const KolabingLogoTone(this.color);

  final Color color;
}

/// The Kolabing logo — the K mark, filling itself once as the screen arrives.
///
/// It used to render one of six cloud-lockup PNGs picked by background. The mark
/// replaced the lockup everywhere (app icon, splash, app bar), so this now draws
/// the same animated K and the only thing left to choose is its ink.
///
/// [width] is the mark's rendered width; the height follows the asset, which is
/// all but square — so a mark wants roughly half the width the old wide lockup
/// took to read at the same size.
class KolabingLogo extends StatelessWidget {
  const KolabingLogo({
    super.key,
    this.width = 96,
    this.tone = KolabingLogoTone.light,
  });

  final double width;
  final KolabingLogoTone tone;

  @override
  Widget build(BuildContext context) =>
      AnimatedKolabingKMark(width: width, color: tone.color);
}
