import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../models/leaderboard.dart';

/// Widget displaying the top 3 in a podium layout
class LeaderboardPodium extends StatelessWidget {
  const LeaderboardPodium({
    super.key,
    required this.topThree,
  });

  final List<LeaderboardEntry> topThree;

  @override
  Widget build(BuildContext context) {
    if (topThree.isEmpty) {
      return const SizedBox.shrink();
    }

    // Reorder: 2nd, 1st, 3rd
    final List<LeaderboardEntry?> ordered = [
      topThree.length > 1 ? topThree[1] : null, // 2nd place
      topThree.isNotEmpty ? topThree[0] : null, // 1st place
      topThree.length > 2 ? topThree[2] : null, // 3rd place
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            KolabingColors.primary.withValues(alpha: 0.1),
            KolabingColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          if (ordered[0] != null)
            _buildPodiumEntry(ordered[0]!, 2, 100)
          else
            const SizedBox(width: 100),

          const SizedBox(width: KolabingSpacing.sm),

          // 1st place
          if (ordered[1] != null)
            _buildPodiumEntry(ordered[1]!, 1, 130)
          else
            const SizedBox(width: 100),

          const SizedBox(width: KolabingSpacing.sm),

          // 3rd place
          if (ordered[2] != null)
            _buildPodiumEntry(ordered[2]!, 3, 80)
          else
            const SizedBox(width: 100),
        ],
      ),
    );
  }

  Widget _buildPodiumEntry(LeaderboardEntry entry, int rank, double height) {
    Color crownColor;
    Color bgColor;

    switch (rank) {
      case 1:
        crownColor = const Color(0xFFFFD700); // Gold
        bgColor = const Color(0xFFFFD700).withValues(alpha: 0.2);
        break;
      case 2:
        crownColor = const Color(0xFFC0C0C0); // Silver
        bgColor = const Color(0xFFC0C0C0).withValues(alpha: 0.2);
        break;
      default:
        crownColor = const Color(0xFFCD7F32); // Bronze
        bgColor = const Color(0xFFCD7F32).withValues(alpha: 0.2);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown for 1st place
        if (rank == 1)
          Icon(
            LucideIcons.crown,
            size: 28,
            color: crownColor,
          ),
        if (rank == 1) const SizedBox(height: 4),

        // Avatar
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: crownColor,
                  width: rank == 1 ? 3 : 2,
                ),
              ),
              child: CircleAvatar(
                radius: rank == 1 ? 36 : 28,
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
                          fontSize: rank == 1 ? 24 : 18,
                          fontWeight: FontWeight.w600,
                          color: KolabingColors.primary,
                        ),
                      )
                    : null,
              ),
            ),
            // Rank badge
            Positioned(
              bottom: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: crownColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: crownColor.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: GoogleFonts.rubik(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: rank == 1 ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: KolabingSpacing.sm),

        // Name
        SizedBox(
          width: 80,
          child: Text(
            entry.displayName,
            style: GoogleFonts.rubik(
              fontSize: rank == 1 ? 14 : 12,
              fontWeight: FontWeight.w600,
              color: KolabingColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Points
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.star,
              size: 12,
              color: KolabingColors.primary,
            ),
            const SizedBox(width: 2),
            Text(
              '${entry.totalPoints}',
              style: GoogleFonts.rubik(
                fontSize: rank == 1 ? 14 : 12,
                fontWeight: FontWeight.w700,
                color: KolabingColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: KolabingSpacing.sm),

        // Podium block
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
            border: Border.all(
              color: crownColor.withValues(alpha: 0.5),
            ),
          ),
          child: Center(
            child: Text(
              _ordinal(rank),
              style: GoogleFonts.rubik(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: crownColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _ordinal(int number) {
    switch (number) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      default:
        return '${number}th';
    }
  }
}
