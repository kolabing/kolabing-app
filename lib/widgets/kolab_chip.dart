// lib/widgets/kolab_chip.dart
import 'package:flutter/material.dart';

import '../config/constants/radius.dart';
import '../config/constants/spacing.dart';
import '../config/theme/colors.dart';
import '../config/theme/typography.dart';

enum KolabChipVariant {
  neutral, // surfaceVariant fill — unselected / inactive
  amber, // warm sand — location, venue, city
  sage, // collapses to amber — date, recurrence
  lavender, // orange accent — role badges (Business, Community), status labels
  blueGrey, // collapses to neutral — no more sky-blue pastel
  peach, // orange accent — categories, food & drink, sports, offers
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
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KolabingTextStyles.labelSmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static (Color, Color) _colors(KolabChipVariant v, KolabingColorTokens c) =>
      switch (v) {
        // Warm sand — location, venue, city
        KolabChipVariant.amber => (c.amberChipContainer, c.amberChipText),
        // Sage collapses to amber (warm sand) — date, recurrence
        KolabChipVariant.sage => (c.amberChipContainer, c.amberChipText),
        // Orange accent — role badges (Business, Community), status labels
        KolabChipVariant.lavender => (c.categoryOrangeBg, c.categoryOrangeText),
        // blueGrey collapses to neutral — no more sky-blue pastel
        KolabChipVariant.blueGrey => (c.surfaceVariant, c.onSurfaceVariant),
        // Peach → clean orange accent (replaces old apricot peach tint)
        KolabChipVariant.peach => (c.categoryOrangeBg, c.categoryOrangeText),
        // Neutral — default unselected state
        KolabChipVariant.neutral => (c.surfaceVariant, c.onSurfaceVariant),
      };
}

/// NOTE: category/community-type labels no longer go through [KolabChip].
/// Use `CategoryChip` (`lib/widgets/category_chip.dart`), which resolves colours
/// via `CategoryStyleResolver`. [KolabChip] remains for city/date/secondary
/// metadata chips only.
