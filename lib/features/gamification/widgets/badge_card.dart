import 'package:flutter/material.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../widgets/ui_icon.dart';
import '../models/badge.dart';

/// Card displaying a badge
class BadgeCard extends StatelessWidget {
  const BadgeCard({
    required this.badge,
    super.key,
    this.isEarned = false,
    this.earnedAt,
    this.onTap,
  });

  final GamificationBadge badge;
  final bool isEarned;
  final DateTime? earnedAt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap ?? () => _showBadgeDetail(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(KolabingSpacing.sm),
        decoration: BoxDecoration(
          color: isEarned
              ? context.colors.primary.withValues(alpha: 0.1)
              : context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEarned
                ? context.colors.primary.withValues(alpha: 0.3)
                : context.colors.darkBorder,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge icon
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isEarned
                        ? context.colors.primary.withValues(alpha: 0.2)
                        : context.colors.textTertiary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: badge.iconUrl != null
                        ? Image.network(
                            badge.iconUrl!,
                            width: 32,
                            height: 32,
                            color: isEarned ? null : context.colors.textTertiary,
                            colorBlendMode: isEarned ? null : BlendMode.saturation,
                          )
                        : _buildBadgeIcon(
                            size: 28,
                            color: isEarned
                                ? null
                                : context.colors.textTertiary,
                          ),
                  ),
                ),
                if (!isEarned)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: UiIcon(
                        icon: UiIconSlug.lock,
                        size: 20,
                        color: context.colors.textTertiary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: KolabingSpacing.xs),

            // Badge name
            Text(
              badge.name,
              style: KolabingTextStyles.bodySmall.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: isEarned
                    ? context.colors.onSurface
                    : context.colors.textTertiary),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );

  UiIconSlug _getBadgeIconSlug() {
    // Map badge types to icons based on name/slug
    final name = (badge.slug ?? badge.name).toLowerCase();

    if (name.contains('first') || name.contains('event')) {
      return UiIconSlug.calendar;
    }
    if (name.contains('challenge') || name.contains('complete')) {
      return UiIconSlug.target;
    }
    if (name.contains('point') || name.contains('collector')) {
      return UiIconSlug.star;
    }
    if (name.contains('win') || name.contains('lucky')) {
      return UiIconSlug.gift;
    }
    if (name.contains('veteran') || name.contains('legend')) {
      return UiIconSlug.trophy;
    }
    if (name.contains('streak')) {
      return UiIconSlug.flame;
    }
    return UiIconSlug.award;
  }

  Widget _buildBadgeIcon({required double size, Color? color}) => UiIcon(
    icon: _getBadgeIconSlug(),
    size: size,
    variant: UiIconVariant.expressive,
    color: color,
  );

  void _showBadgeDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(KolabingSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: KolabingSpacing.lg),

            // Badge icon large
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isEarned
                    ? context.colors.primary.withValues(alpha: 0.2)
                    : context.colors.textTertiary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: badge.iconUrl != null
                    ? Image.network(
                        badge.iconUrl!,
                        width: 48,
                        height: 48,
                        color: isEarned ? null : context.colors.textTertiary,
                        colorBlendMode: isEarned ? null : BlendMode.saturation,
                      )
                    : _buildBadgeIcon(
                        size: 40,
                        color:
                            isEarned ? null : context.colors.textTertiary,
                      ),
              ),
            ),
            const SizedBox(height: KolabingSpacing.md),

            // Badge name
            Text(
              badge.name,
              style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: context.colors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.xs),

            // Description
            Text(
              badge.description,
              style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.md),

            // Threshold
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.md,
                vertical: KolabingSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.colors.hairline),
              ),
              child: Text(
                'Requirement: ${badge.thresholdValue} ${badge.thresholdType}',
                style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.onSurfaceVariant),
              ),
            ),

            // Earned status
            if (isEarned && earnedAt != null) ...[
              const SizedBox(height: KolabingSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  UiIcon(
                    icon: UiIconSlug.checkCircle,
                    size: 16,
                    color: context.colors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Earned on ${earnedAt!.day}/${earnedAt!.month}/${earnedAt!.year}',
                    style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.success),
                  ),
                ],
              ),
            ],

            if (!isEarned) ...[
              const SizedBox(height: KolabingSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  UiIcon(
                    icon: UiIconSlug.lock,
                    size: 16,
                    color: context.colors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Not yet earned',
                    style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.textTertiary),
                  ),
                ],
              ),
            ],

            const SizedBox(height: KolabingSpacing.lg),
          ],
        ),
      ),
    );
  }
}
