import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/theme/colors.dart';

/// Badge displaying points with optional earned state
class PointsBadge extends StatelessWidget {
  const PointsBadge({
    super.key,
    required this.points,
    this.isEarned = false,
    this.size = PointsBadgeSize.medium,
  });

  final int points;
  final bool isEarned;
  final PointsBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final double fontSize;
    final double iconSize;
    final EdgeInsets padding;

    switch (size) {
      case PointsBadgeSize.small:
        fontSize = 11;
        iconSize = 10;
        padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 3);
      case PointsBadgeSize.medium:
        fontSize = 13;
        iconSize = 12;
        padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case PointsBadgeSize.large:
        fontSize = 16;
        iconSize = 14;
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    }

    final bgColor = isEarned
        ? KolabingColors.primary
        : KolabingColors.primary.withValues(alpha: 0.15);
    final textColor = isEarned
        ? KolabingColors.onPrimary
        : KolabingColors.primary;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.star,
            size: iconSize,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            '+$points',
            style: GoogleFonts.rubik(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

enum PointsBadgeSize { small, medium, large }
