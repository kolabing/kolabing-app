import 'package:flutter/material.dart';
import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../widgets/ui_icon.dart';

/// A stats card widget used on both Business and Community dashboards.
///
/// Displays a count with a label, subtitle, and a colored icon circle.
class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({
    super.key,
    required this.title,
    required this.count,
    required this.icon,
    required this.accentColor,
    required this.index,
    this.subtitle,
    this.iconSlug,
    this.iconVariant = UiIconVariant.minimal,
  });

  /// Uppercase label at the top (e.g. "PUBLISHED OPPORTUNITIES")
  final String title;

  /// Large numeric count
  final int count;

  /// Fallback icon (used when [iconSlug] is null)
  final IconData icon;

  /// When provided, renders a custom [UiIcon] instead of the Lucide [icon].
  final UiIconSlug? iconSlug;

  /// Icon variant — defaults to minimal; pass expressive for the B direction.
  final UiIconVariant iconVariant;

  /// Accent color for the icon circle background and icon tint
  final Color accentColor;

  /// Optional subtitle text below the count
  final String? subtitle;

  /// Position index — even = lavender, odd = sage
  final int index;

  Color get _cardColor => index.isEven
      ? KolabingColors.secondaryContainer
      : KolabingColors.tertiaryContainer;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? KolabingColors.darkSurface : _cardColor,
        borderRadius: KolabingRadius.borderRadiusXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title label
          Text(
            title,
            style: KolabingTextStyles.labelSmall.copyWith(
              color: isDark
                  ? KolabingColors.textOnDark.withValues(alpha: 0.45)
                  : KolabingColors.textTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: KolabingSpacing.sm),

          // Count + icon row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Count
              Text(
                count.toString(),
                style: KolabingTextStyles.displaySmall.copyWith(
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.5,
                  color: isDark
                      ? KolabingColors.textOnDark
                      : KolabingColors.onSurface,
                ),
              ),

              // Colored icon circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: iconSlug != null
                    ? UiIcon(
                        icon: iconSlug!,
                        size: 22,
                        variant: iconVariant,
                        color: iconVariant == UiIconVariant.expressive
                            ? null
                            : accentColor,
                      )
                    : Icon(icon, size: 20, color: accentColor),
              ),
            ],
          ),

          // Optional subtitle
          if (subtitle != null) ...[
            const SizedBox(height: KolabingSpacing.xxs),
            Text(
              subtitle!,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: isDark
                    ? KolabingColors.textOnDark.withValues(alpha: 0.45)
                    : KolabingColors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
