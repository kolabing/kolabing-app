import 'package:flutter/material.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../widgets/ui_icon.dart';

/// A card widget displaying a stat with icon, label, and value
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.showBackground = false,
    this.iconSlug,
    this.iconVariant = UiIconVariant.minimal,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool showBackground;

  /// Optional UiIconSlug. When provided, [UiIcon] is rendered in place of
  /// the [icon] IconData.
  final UiIconSlug? iconSlug;
  final UiIconVariant iconVariant;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? KolabingColors.textOnDark : KolabingColors.onSurface;
    final secondaryTextColor =
        isDark ? KolabingColors.textTertiary : KolabingColors.onSurfaceVariant;
    final surfaceColor =
        isDark ? KolabingColors.darkSurface : KolabingColors.surface;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: iconSlug != null
                ? UiIcon(
                    icon: iconSlug!,
                    size: 20,
                    variant: iconVariant,
                    color: iconColor,
                  )
                : Icon(
                    icon,
                    size: 20,
                    color: iconColor,
                  ),
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          value,
          style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: secondaryTextColor),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    if (showBackground) {
      return Container(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? KolabingColors.darkBorder : KolabingColors.darkBorder,
          ),
        ),
        child: content,
      );
    }

    return content;
  }
}
