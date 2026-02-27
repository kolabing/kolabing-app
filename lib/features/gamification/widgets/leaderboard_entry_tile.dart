import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../models/leaderboard.dart';

/// Tile displaying a leaderboard entry
class LeaderboardEntryTile extends StatelessWidget {
  const LeaderboardEntryTile({
    super.key,
    required this.entry,
    this.isCurrentUser = false,
  });

  final LeaderboardEntry entry;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.xs,
      ),
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? KolabingColors.primary.withValues(alpha: 0.1)
            : KolabingColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: KolabingColors.primary.withValues(alpha: 0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 40,
            child: Text(
              '#${entry.rank}',
              style: GoogleFonts.rubik(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isCurrentUser
                    ? KolabingColors.primary
                    : KolabingColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),

          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: KolabingColors.primary.withValues(alpha: 0.1),
            backgroundImage: entry.profilePhoto != null
                ? NetworkImage(entry.profilePhoto!)
                : null,
            child: entry.profilePhoto == null
                ? Text(
                    entry.displayName.isNotEmpty
                        ? entry.displayName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.rubik(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: KolabingColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: KolabingSpacing.md),

          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.displayName,
                        style: GoogleFonts.rubik(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: KolabingColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: KolabingColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'You',
                          style: GoogleFonts.rubik(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: KolabingColors.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Points
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.star,
                size: 16,
                color: KolabingColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '${entry.totalPoints}',
                style: GoogleFonts.rubik(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
