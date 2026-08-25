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
    final textColor = isDark
        ? context.colors.textOnDark
        : context.colors.onSurface;
    final secondaryTextColor = isDark
        ? context.colors.textTertiary
        : context.colors.onSurfaceVariant;
    final surfaceColor = isDark
        ? context.colors.darkSurface
        : context.colors.surface;

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
                : Icon(icon, size: 20, color: iconColor),
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          value,
          style: KolabingTextStyles.bodyLarge.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: KolabingTextStyles.bodySmall.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: secondaryTextColor,
          ),
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
            color: isDark
                ? context.colors.darkBorder
                : context.colors.darkBorder,
          ),
        ),
        child: content,
      );
    }

    return content;
  }
}
