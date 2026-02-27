import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../models/badge.dart';

/// Card displaying a badge
class BadgeCard extends StatelessWidget {
  const BadgeCard({
    super.key,
    required this.badge,
    this.isEarned = false,
    this.earnedAt,
    this.onTap,
  });

  final GamificationBadge badge;
  final bool isEarned;
  final DateTime? earnedAt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () => _showBadgeDetail(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(KolabingSpacing.sm),
        decoration: BoxDecoration(
          color: isEarned
              ? KolabingColors.primary.withValues(alpha: 0.1)
              : KolabingColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEarned
                ? KolabingColors.primary.withValues(alpha: 0.3)
                : KolabingColors.border,
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
                        ? KolabingColors.primary.withValues(alpha: 0.2)
                        : KolabingColors.textTertiary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: badge.iconUrl != null
                        ? Image.network(
                            badge.iconUrl!,
                            width: 32,
                            height: 32,
                            color: isEarned ? null : KolabingColors.textTertiary,
                            colorBlendMode: isEarned ? null : BlendMode.saturation,
                          )
                        : Icon(
                            _getBadgeIcon(),
                            size: 28,
                            color: isEarned
                                ? KolabingColors.primary
                                : KolabingColors.textTertiary,
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
                    child: const Icon(
                      LucideIcons.lock,
                      size: 20,
                      color: KolabingColors.textTertiary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: KolabingSpacing.xs),

            // Badge name
            Text(
              badge.name,
              style: GoogleFonts.rubik(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isEarned
                    ? KolabingColors.textPrimary
                    : KolabingColors.textTertiary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getBadgeIcon() {
    // Map badge types to icons based on name/slug
    final name = (badge.slug ?? badge.name).toLowerCase();

    if (name.contains('first') || name.contains('event')) {
      return LucideIcons.calendar;
    }
    if (name.contains('challenge') || name.contains('complete')) {
      return LucideIcons.target;
    }
    if (name.contains('point') || name.contains('collector')) {
      return LucideIcons.star;
    }
    if (name.contains('win') || name.contains('lucky')) {
      return LucideIcons.gift;
    }
    if (name.contains('veteran') || name.contains('legend')) {
      return LucideIcons.trophy;
    }
    if (name.contains('streak')) {
      return LucideIcons.flame;
    }
    return LucideIcons.award;
  }

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
                  color: KolabingColors.border,
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
                    ? KolabingColors.primary.withValues(alpha: 0.2)
                    : KolabingColors.textTertiary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: badge.iconUrl != null
                    ? Image.network(
                        badge.iconUrl!,
                        width: 48,
                        height: 48,
                        color: isEarned ? null : KolabingColors.textTertiary,
                        colorBlendMode: isEarned ? null : BlendMode.saturation,
                      )
                    : Icon(
                        _getBadgeIcon(),
                        size: 40,
                        color: isEarned
                            ? KolabingColors.primary
                            : KolabingColors.textTertiary,
                      ),
              ),
            ),
            const SizedBox(height: KolabingSpacing.md),

            // Badge name
            Text(
              badge.name,
              style: GoogleFonts.rubik(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: KolabingColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.xs),

            // Description
            Text(
              badge.description,
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: KolabingColors.textSecondary,
              ),
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
                color: KolabingColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Requirement: ${badge.thresholdValue} ${badge.thresholdType}',
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: KolabingColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Earned status
            if (isEarned && earnedAt != null) ...[
              const SizedBox(height: KolabingSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.checkCircle,
                    size: 16,
                    color: KolabingColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Earned on ${earnedAt!.day}/${earnedAt!.month}/${earnedAt!.year}',
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: KolabingColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],

            if (!isEarned) ...[
              const SizedBox(height: KolabingSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.lock,
                    size: 16,
                    color: KolabingColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Not yet earned',
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: KolabingColors.textTertiary,
                    ),
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
