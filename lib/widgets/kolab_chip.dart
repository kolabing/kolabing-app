// lib/widgets/kolab_chip.dart
import 'package:flutter/material.dart';

import '../config/constants/radius.dart';
import '../config/constants/spacing.dart';
import '../config/theme/colors.dart';
import '../config/theme/typography.dart';

enum KolabChipVariant {
  neutral,   // surfaceVariant — generic meta
  amber,     // amberChipContainer — city, discount, promo
  sage,      // tertiaryContainer — date ranges, wellness, nature
  lavender,  // secondaryContainer — community, lifestyle
  blueGrey,  // categoryBlueGrey — music, art, culture, film
  peach,     // #FFE9D9 — food & drink, bars, restaurants
}

/// Shared pastel tag chip used in Explore cards and all My Kolabs cards.
class KolabChip extends StatelessWidget {
  const KolabChip({
    required this.label,
    this.variant = KolabChipVariant.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final KolabChipVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(variant);
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: KolabingRadius.borderRadiusRound,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: KolabingTextStyles.labelSmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  static (Color, Color) _colors(KolabChipVariant v) => switch (v) {
    KolabChipVariant.amber => (
      KolabingColors.amberChipContainer,
      KolabingColors.amberChipText,
    ),
    KolabChipVariant.sage => (
      KolabingColors.tertiaryContainer,
      KolabingColors.tertiary,
    ),
    KolabChipVariant.lavender => (
      KolabingColors.secondaryContainer,
      KolabingColors.secondary,
    ),
    KolabChipVariant.blueGrey => (
      KolabingColors.categoryBlueGrey,
      KolabingColors.categoryBlueGreyText,
    ),
    KolabChipVariant.peach => (
      const Color(0xFFFFE9D9),
      const Color(0xFFB05A2A),
    ),
    KolabChipVariant.neutral => (
      KolabingColors.surfaceVariant,
      KolabingColors.onSurfaceVariant,
    ),
  };
}

/// Pick a [KolabChipVariant] from a raw category/tag string.
KolabChipVariant kolabChipVariantFor(String category) {
  final c = category.toLowerCase();
  if (c.contains('food') ||
      c.contains('drink') ||
      c.contains('bar') ||
      c.contains('restaurant') ||
      c.contains('cafe')) {
    return KolabChipVariant.peach;
  }
  if (c.contains('wellness') ||
      c.contains('yoga') ||
      c.contains('health') ||
      c.contains('fitness') ||
      c.contains('sport')) {
    return KolabChipVariant.sage;
  }
  if (c.contains('music') ||
      c.contains('art') ||
      c.contains('film') ||
      c.contains('culture') ||
      c.contains('photo')) {
    return KolabChipVariant.blueGrey;
  }
  if (c.contains('community') ||
      c.contains('event') ||
      c.contains('social')) {
    return KolabChipVariant.lavender;
  }
  if (c.contains('discount') || c.contains('promo')) {
    return KolabChipVariant.amber;
  }
  return KolabChipVariant.neutral;
}
