// lib/widgets/kolab_chip.dart
import 'package:flutter/material.dart';

import '../config/constants/radius.dart';
import '../config/constants/spacing.dart';
import '../config/theme/colors.dart';
import '../config/theme/typography.dart';

enum KolabChipVariant {
  neutral,   // surfaceVariant — unselected / inactive
  amber,     // amberChipContainer — warm sand: location, venue, city
  sage,      // tertiaryContainer — sage green: date ranges, recurrence, time
  lavender,  // categoryOrangeBg — orange accent: role (Business, Community) & status
  blueGrey,  // categoryBlueBg — sky blue: music, art, culture, selected states
  peach,     // accentOrange — peach/apricot: categories, food & drink, sports, offers
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
    final (bg, fg) = _colors(variant, context.colors);
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

  static (Color, Color) _colors(KolabChipVariant v, KolabingColorTokens c) =>
      switch (v) {
        KolabChipVariant.amber => (c.amberChipContainer, c.amberChipText),
        KolabChipVariant.sage => (c.categorySageBg, c.categorySageText),
        KolabChipVariant.lavender => (c.categoryOrangeBg, c.categoryOrangeText),
        KolabChipVariant.blueGrey => (c.categoryBlueBg, c.categoryBlueText),
        KolabChipVariant.peach => (c.accentOrange, c.accentOrangeText),
        KolabChipVariant.neutral => (c.surfaceVariant, c.onSurfaceVariant),
      };
}

/// Pick a [KolabChipVariant] from a raw category/tag string.
KolabChipVariant kolabChipVariantFor(String category) {
  final c = category.toLowerCase();
  // Role / status labels → orange accent
  if (c == 'business' || c == 'community') {
    return KolabChipVariant.lavender;
  }
  // Date / time / recurrence → sage green
  if (c.contains('recurring') ||
      c.contains('daily') ||
      c.contains('weekly') ||
      c.contains('monthly')) {
    return KolabChipVariant.sage;
  }
  // Location / venue → warm sand
  if (c.contains('venue') || c.contains('location')) {
    return KolabChipVariant.amber;
  }
  // Category / offer type → peach/apricot
  if (c.contains('food') ||
      c.contains('drink') ||
      c.contains('bar') ||
      c.contains('restaurant') ||
      c.contains('cafe') ||
      c.contains('sport') ||
      c.contains('fitness') ||
      c.contains('yoga') ||
      c.contains('gym') ||
      c.contains('wellness') ||
      c.contains('health') ||
      c.contains('discount') ||
      c.contains('promo') ||
      c.contains('offer')) {
    return KolabChipVariant.peach;
  }
  // Creative / cultural → sky blue
  if (c.contains('music') ||
      c.contains('art') ||
      c.contains('film') ||
      c.contains('culture') ||
      c.contains('photo') ||
      c.contains('community') ||
      c.contains('social') ||
      c.contains('event')) {
    return KolabChipVariant.blueGrey;
  }
  return KolabChipVariant.neutral;
}
