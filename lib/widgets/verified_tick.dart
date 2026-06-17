import 'package:flutter/material.dart';

import '../config/theme/colors.dart';
import '../l10n/app_localizations.dart';

/// A small brand-yellow check-circle shown next to a community's name when the
/// community is verified.
///
/// Read-only: it renders nothing when [isVerified] is false, so callers can
/// drop it inline next to any name and pass the model's `is_verified` flag.
///
/// Tap (mobile) or hover (web/desktop) shows a tooltip explaining what the tick
/// means. Visual: a filled brand-yellow ([KolabingColors.primary]) circle with a
/// black check glyph, ~16px by default.
class VerifiedTick extends StatelessWidget {
  const VerifiedTick({required this.isVerified, super.key, this.size = 16});

  /// Whether the community is verified. When false the widget is a no-op
  /// ([SizedBox.shrink]).
  final bool isVerified;

  /// Diameter of the circle in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!isVerified) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    return Tooltip(
      message: l10n.verifiedTickTooltip,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 4),
      preferBelow: false,
      child: Semantics(
        label: l10n.verifiedTickLabel,
        button: true,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: KolabingColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child:
              Icon(Icons.check_rounded, size: size * 0.7, color: Colors.black),
        ),
      ),
    );
  }
}
