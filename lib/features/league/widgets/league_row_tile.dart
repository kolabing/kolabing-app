import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/league_models.dart';

/// One league row: rank · community name · league points. The viewer's own
/// row is highlighted and labelled "You".
class LeagueRowTile extends StatelessWidget {
  const LeagueRowTile({required this.row, this.dense = false, super.key});

  final LeagueRow row;

  /// Compact spacing for the Home preview card.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final name = row.isViewer
        ? l10n.leaderboardEntryYou
        : (row.displayName.isEmpty ? '–' : row.displayName);
    final weight = row.isViewer ? FontWeight.w700 : FontWeight.w500;

    return Container(
      key: ValueKey('league-row-${row.rank}'),
      padding: EdgeInsets.symmetric(
        horizontal: KolabingSpacing.sm,
        vertical: dense ? KolabingSpacing.xs : KolabingSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: row.isViewer ? colors.primaryTint : null,
        borderRadius: KolabingRadius.borderRadiusMd,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${row.rank}',
              style: KolabingTextStyles.labelLarge.copyWith(
                color: row.rank <= 3 ? colors.onSurface : colors.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KolabingTextStyles.bodyMedium.copyWith(
                color: colors.onSurface,
                fontWeight: weight,
              ),
            ),
          ),
          if (row.promotionZone)
            Semantics(
              label: l10n.leaguePromotionZone,
              child: Icon(
                LucideIcons.arrowUp,
                key: ValueKey('league-row-up-${row.rank}'),
                size: 14,
                color: colors.success,
              ),
            )
          else if (row.relegationZone)
            Semantics(
              label: l10n.leagueRelegationZone,
              child: Icon(
                LucideIcons.arrowDown,
                key: ValueKey('league-row-down-${row.rank}'),
                size: 14,
                color: colors.orange,
              ),
            ),
          const SizedBox(width: KolabingSpacing.xs),
          Text(
            '${row.points}',
            style: KolabingTextStyles.labelLarge.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rows with a "···" marker wherever ranks skip (top 3, then the viewer's
/// neighbourhood further down).
List<Widget> buildLeagueRows(List<LeagueRow> rows, {bool dense = false}) {
  final widgets = <Widget>[];
  LeagueRow? previous;
  for (final row in rows) {
    if (previous != null && row.rank > previous.rank + 1) {
      widgets.add(const _RankGap());
    }
    widgets.add(LeagueRowTile(row: row, dense: dense));
    previous = row;
  }
  return widgets;
}

class _RankGap extends StatelessWidget {
  const _RankGap();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: KolabingSpacing.sm),
    child: Text(
      '···',
      style: KolabingTextStyles.labelLarge.copyWith(
        color: context.colors.textTertiary,
      ),
    ),
  );
}
