import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../models/challenge.dart';
import 'difficulty_badge.dart';
import 'points_badge.dart';

/// Card widget displaying a challenge
class ChallengeCard extends StatelessWidget {
  const ChallengeCard({
    super.key,
    required this.challenge,
    this.onTap,
    this.showChevron = true,
  });

  final Challenge challenge;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? KolabingColors.darkSurface : KolabingColors.surface;
    final textColor =
        isDark ? KolabingColors.textOnDark : KolabingColors.textPrimary;
    final secondaryTextColor =
        isDark ? KolabingColors.textTertiary : KolabingColors.textSecondary;

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? KolabingColors.darkBorder : KolabingColors.border,
            ),
          ),
          child: Row(
            children: [
              // Challenge icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getDifficultyBgColor(challenge.difficulty),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getChallengeIcon(challenge.difficulty),
                  size: 24,
                  color: _getDifficultyColor(challenge.difficulty),
                ),
              ),

              const SizedBox(width: KolabingSpacing.sm),

              // Challenge info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            challenge.name,
                            style: GoogleFonts.rubik(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (challenge.isSystem)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: KolabingColors.info.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'SYSTEM',
                              style: GoogleFonts.openSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: KolabingColors.info,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (challenge.description != null &&
                        challenge.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        challenge.description!,
                        style: GoogleFonts.openSans(
                          fontSize: 13,
                          color: secondaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: KolabingSpacing.xs),
                    Row(
                      children: [
                        DifficultyBadge(difficulty: challenge.difficulty),
                        const SizedBox(width: KolabingSpacing.xs),
                        PointsBadge(
                          points: challenge.points,
                          size: PointsBadgeSize.small,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (showChevron) ...[
                const SizedBox(width: KolabingSpacing.xs),
                Icon(
                  LucideIcons.chevronRight,
                  size: 20,
                  color: KolabingColors.textTertiary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyBgColor(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return const Color(0xFFD4EDDA);
      case ChallengeDifficulty.medium:
        return const Color(0xFFFFF3CD);
      case ChallengeDifficulty.hard:
        return const Color(0xFFF8D7DA);
    }
  }

  Color _getDifficultyColor(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return const Color(0xFF155724);
      case ChallengeDifficulty.medium:
        return const Color(0xFF856404);
      case ChallengeDifficulty.hard:
        return const Color(0xFF721C24);
    }
  }

  IconData _getChallengeIcon(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return LucideIcons.leaf;
      case ChallengeDifficulty.medium:
        return LucideIcons.flame;
      case ChallengeDifficulty.hard:
        return LucideIcons.zap;
    }
  }
}
