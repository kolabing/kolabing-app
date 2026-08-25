import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/leaderboard.dart';

/// Tile displaying a leaderboard entry.
///
/// P3: renders the row's [LeaderboardEntry.tier] + badge count under the name,
/// and per-community points. Tapping the current user's row opens the Personal
/// Rewards Screen (wired via [onTap]).
class LeaderboardEntryTile extends StatelessWidget {
  const LeaderboardEntryTile({
    super.key,
    required this.entry,
    this.isCurrentUser = false,
    this.onTap,
  });

  final LeaderboardEntry entry;
  final bool isCurrentUser;

  /// Tapped → open Personal Rewards (current user) or a light peek (others).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tile = Container(
      margin: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.xs,
      ),
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? context.colors.primary.withValues(alpha: 0.1)
            : context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: context.colors.primary.withValues(alpha: 0.3))
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
              style: KolabingTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: isCurrentUser
                    ? context.colors.primary
                    : context.colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),

          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: context.colors.primary.withValues(alpha: 0.1),
            backgroundImage: entry.profilePhoto != null
                ? NetworkImage(entry.profilePhoto!)
                : null,
            child: entry.profilePhoto == null
                ? Text(
                    entry.displayName.isNotEmpty
                        ? entry.displayName[0].toUpperCase()
                        : '?',
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: KolabingSpacing.md),

          // Name + tier/badge subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.displayName,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.colors.onSurface,
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
                          color: context.colors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.leaderboardEntryYou,
                          style: KolabingTextStyles.bodySmall.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: context.colors.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (entry.tier != null ||
                    (entry.badgeCount != null && entry.badgeCount! > 0)) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (entry.tier != null) ...[
                        Icon(
                          LucideIcons.award,
                          size: 12,
                          color: context.colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            entry.tier!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: KolabingTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                      if (entry.badgeCount != null &&
                          entry.badgeCount! > 0) ...[
                        if (entry.tier != null)
                          const SizedBox(width: KolabingSpacing.sm),
                        Icon(
                          LucideIcons.medal,
                          size: 12,
                          color: context.colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          l10n.leaderboardEntryBadgeCount(entry.badgeCount!),
                          style: KolabingTextStyles.bodySmall.copyWith(
                            fontSize: 11,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Points (per-community points when present, else total)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.star, size: 16, color: context.colors.primary),
              const SizedBox(width: 4),
              Text(
                '${entry.displayPoints}',
                style: KolabingTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.onSurface,
                ),
              ),
              if (onTap != null && isCurrentUser) ...[
                const SizedBox(width: 4),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: context.colors.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return tile;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: tile,
    );
  }
}
