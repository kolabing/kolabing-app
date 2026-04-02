import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../models/reward_badge.dart';

/// Displays a single [RewardBadge] as either a full grid card (160x180) or a
/// compact chip (80x96).
///
/// Locked badges are rendered with reduced opacity, grey tones, and a dashed-
/// style border. Unlocked badges have a white background, yellow border, and a
/// subtle shadow.
class RewardBadgeCard extends StatelessWidget {
  const RewardBadgeCard({
    required this.badge,
    this.compact = false,
    super.key,
  });

  /// The badge to display.
  final RewardBadge badge;

  /// When `true`, renders the smaller 80x96 compact variant.
  final bool compact;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) =>
      compact ? _buildCompact() : _buildGrid();

  // ---------------------------------------------------------------------------
  // Grid mode (160 x 180)
  // ---------------------------------------------------------------------------

  Widget _buildGrid() {
    final isUnlocked = badge.isUnlocked;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isUnlocked ? 1.0 : 0.5,
      child: Container(
        width: 160,
        height: 180,
        padding: const EdgeInsets.all(KolabingSpacing.sm),
        decoration: BoxDecoration(
          color: isUnlocked ? KolabingColors.surface : KolabingColors.surfaceVariant,
          borderRadius: KolabingRadius.borderRadiusLg,
          border: Border.all(
            color: isUnlocked
                ? KolabingColors.primary
                : KolabingColors.border,
            width: isUnlocked ? 2 : 1,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: KolabingColors.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIconCircle(
              size: 64,
              iconSize: 28,
              isUnlocked: isUnlocked,
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              badge.slug.displayName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.rubik(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isUnlocked
                    ? KolabingColors.textPrimary
                    : KolabingColors.textTertiary,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xxxs),
            Text(
              isUnlocked
                  ? (badge.earnedAt != null
                      ? 'Earned ${badge.earnedDateFormatted}'
                      : badge.slug.description)
                  : badge.slug.requirement,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.openSans(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: isUnlocked
                    ? KolabingColors.textSecondary
                    : KolabingColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Compact mode (80 x 96)
  // ---------------------------------------------------------------------------

  Widget _buildCompact() {
    final isUnlocked = badge.isUnlocked;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isUnlocked ? 1.0 : 0.5,
      child: SizedBox(
        width: 80,
        height: 96,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIconCircle(
              size: 40,
              iconSize: 18,
              isUnlocked: isUnlocked,
            ),
            const SizedBox(height: KolabingSpacing.xxs),
            Text(
              badge.slug.shortName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.rubik(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isUnlocked
                    ? KolabingColors.textPrimary
                    : KolabingColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared icon circle
  // ---------------------------------------------------------------------------

  Widget _buildIconCircle({
    required double size,
    required double iconSize,
    required bool isUnlocked,
  }) =>
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isUnlocked
              ? KolabingColors.softYellow
              : KolabingColors.surfaceVariant,
          border: Border.all(
            color: isUnlocked
                ? KolabingColors.softYellowBorder
                : KolabingColors.border,
          ),
        ),
        child: Icon(
          badge.slug.icon,
          size: iconSize,
          color: isUnlocked
              ? KolabingColors.textPrimary
              : KolabingColors.textTertiary,
        ),
      );
}
