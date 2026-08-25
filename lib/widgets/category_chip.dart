// lib/widgets/category_chip.dart
import 'package:flutter/material.dart';

import '../config/constants/radius.dart';
import '../config/constants/spacing.dart';
import '../config/theme/category_style.dart';
import '../config/theme/color_tokens.dart';
import '../config/theme/typography.dart';

/// Passive, display-only chip for a **category / community-type** label.
///
/// The [label] is rendered verbatim (it is already localized/display-ready from
/// the backend); only the colours — and the optional [leading] icon — are
/// looked up, via [CategoryStyleResolver], from the label's canonical key.
///
/// This widget is intentionally NOT interactive. Selectable/filter chips stay in
/// `KolabingSelectableChip` / `MultiSelectChips<T>` / the Explore filter sheet.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    required this.label,
    this.leading,
    this.dense = false,
    this.forceLightSurface = false,
    super.key,
  });

  /// The label shown to the user, verbatim.
  final String label;

  /// Optional leading icon. Only supply one where the screen already shows one;
  /// it is tinted by the caller, not by this widget.
  final Widget? leading;

  /// Slightly tighter vertical rhythm, used inside dense list cards.
  final bool dense;

  /// Resolve colours against the LIGHT palette regardless of the active theme.
  ///
  /// For the one card that paints itself `Colors.white` unconditionally
  /// (`ExploreSwipeCard`). Without this, dark mode gave that card near-black
  /// pills with light text on a white background — the chip was theme-aware and
  /// the surface under it was not.
  ///
  /// A flag rather than fixing the card: making that card theme-aware touches
  /// every colour in it and belongs in the redesign that owns it, not in a
  /// review fix.
  final bool forceLightSurface;

  @override
  Widget build(BuildContext context) {
    final tokens = forceLightSurface
        ? KolabingColorTokens.light
        : context.colors;
    final style = CategoryStyleResolver.styleFor(label, tokens);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: KolabingSpacing.xs,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: KolabingRadius.borderRadiusRound,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 4)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KolabingTextStyles.labelSmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: style.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
