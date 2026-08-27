import 'package:flutter/material.dart';
import '../../../config/constants/layout.dart';
import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../widgets/ui_icon.dart';

/// Semantic accent for a dashboard stat card.
///
/// Maps meaning → icon circle fill + icon color.
/// Do not alternate by index — assign by what the stat represents.
enum StatCardAccent { pending, accepted, active, completed }

extension _StatCardAccentColors on StatCardAccent {
  Color circleFill(BuildContext context) {
    switch (this) {
      case StatCardAccent.pending:
        return context
            .colors
            .surfaceContainerHigh; // warm neutral (was lavender)
      case StatCardAccent.accepted:
        return context.colors.softYellow; // soft yellow (was sage green)
      case StatCardAccent.active:
        return context.colors.primary;
      case StatCardAccent.completed:
        return context.colors.surfaceContainerHigh;
    }
  }

  Color iconColor(BuildContext context) {
    switch (this) {
      case StatCardAccent.pending:
        return context.colors.onSurfaceVariant; // matches warm neutral fill
      case StatCardAccent.accepted:
        return context.colors.onPrimary; // warm charcoal on soft yellow
      case StatCardAccent.active:
        return context.colors.onPrimary;
      case StatCardAccent.completed:
        return context.colors.onSurfaceVariant;
    }
  }
}

/// A stats card widget used on both Business and Community dashboards.
///
/// Neutral cream card face — personality comes from the small icon circle only.
class DashboardStatCard extends StatelessWidget {
  const DashboardStatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.accent,
    super.key,
    this.subtitle,
    this.iconSlug,
  });

  /// Uppercase label (e.g. "PENDING")
  final String title;

  /// Large numeric count
  final int count;

  /// Fallback icon (used when [iconSlug] is null)
  final IconData icon;

  /// Optional custom [UiIcon] slug
  final UiIconSlug? iconSlug;

  /// Semantic accent — determines icon circle fill and icon color
  final StatCardAccent accent;

  /// Optional subtitle text below the count
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(KolabingSpacing.lg),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: KolabingRadius.borderRadiusXl,
      border: Border.all(color: context.colors.hairline),
      boxShadow: const [KolabingShadows.card],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Text(
          title.toUpperCase(),
          style: KolabingTextStyles.labelSmall.copyWith(
            color: context.colors.textTertiary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: KolabingSpacing.sm),

        // Count + icon circle row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              count.toString(),
              style: KolabingTextStyles.displaySmall.copyWith(
                fontSize: 38,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                color: context.colors.onSurface,
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.circleFill(context),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: iconSlug != null
                    ? UiIcon(
                        icon: iconSlug!,
                        size: 20,
                        color: accent.iconColor(context),
                      )
                    : Icon(icon, size: 20, color: accent.iconColor(context)),
              ),
            ),
          ],
        ),

        if (subtitle != null) ...[
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            subtitle!,
            style: KolabingTextStyles.captionSecondary.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    ),
  );
}
