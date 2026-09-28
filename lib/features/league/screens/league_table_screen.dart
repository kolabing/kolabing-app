import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/league_models.dart';
import '../providers/league_provider.dart';
import '../utils/league_format.dart';
import '../widgets/league_row_tile.dart';
import '../widgets/league_states.dart';

/// Full city league table for the current monthly season (organisers only).
///
/// The city comes from `GET /me/community-rank`; the table from
/// `GET /leagues/{city_id}/current`.
class LeagueTableScreen extends ConsumerWidget {
  const LeagueTableScreen({super.key});

  Future<void> _refresh(WidgetRef ref, String? cityKey) async {
    ref.invalidate(communityRankProvider);
    if (cityKey != null) ref.invalidate(leagueTableProvider(cityKey));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rankAsync = ref.watch(communityRankProvider);
    final rank = rankAsync.value;
    final cityKey = rank?.city?.key;

    Widget body;
    if (rankAsync.isLoading && rank == null) {
      body = const LeagueLoadingView();
    } else if (rankAsync.hasError && rank == null) {
      body = LeagueMessageView(
        text: l10n.leagueErrorLoad,
        onRetry: () => _refresh(ref, null),
      );
    } else if (rank == null || cityKey == null) {
      body = LeagueMessageView(text: l10n.leagueUnavailable);
    } else {
      final tableAsync = ref.watch(leagueTableProvider(cityKey));
      body = tableAsync.when(
        loading: () => const LeagueLoadingView(),
        error: (_, _) => LeagueMessageView(
          text: l10n.leagueErrorLoad,
          onRetry: () => _refresh(ref, cityKey),
        ),
        data: (table) => table == null
            ? LeagueMessageView(text: l10n.leagueUnavailable)
            : _LeagueTableContent(
                table: table,
                rank: rank,
                onRefresh: () => _refresh(ref, cityKey),
              ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          leagueTitle(l10n, rank?.city),
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: body,
    );
  }
}

class _LeagueTableContent extends StatelessWidget {
  const _LeagueTableContent({
    required this.table,
    required this.rank,
    required this.onRefresh,
  });

  final LeagueTable table;
  final CommunityRank rank;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    final month = formatLeagueMonth(context, table.month ?? rank.month);
    final endsAt = table.seasonEndsAt ?? rank.seasonEndsAt;
    final seasonLine = month != null && endsAt != null
        ? l10n.leagueSeasonEnds(month, formatLeagueDate(context, endsAt))
        : month;

    // The table's own `is_viewer` flag wins; otherwise highlight the viewer's
    // rank (from /me/community-rank) inside their own division.
    final hasViewer = table.divisions.any((d) => d.rows.any((r) => r.isViewer));
    List<LeagueRow> rowsOf(LeagueDivision division) {
      final isViewerDivision =
          table.divisions.length == 1 ||
          (division.key != null && division.key == rank.divisionKey);
      if (hasViewer || !isViewerDivision || rank.rank == null) {
        return division.rows;
      }
      return division.rows
          .map((r) => r.rank == rank.rank ? r.asViewer() : r)
          .toList();
    }

    final children = <Widget>[];
    for (final division in table.divisions) {
      if (division.rows.isEmpty) continue;
      if (table.showDivisionHeaders && division.label != null) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(
              top: KolabingSpacing.md,
              bottom: KolabingSpacing.xs,
            ),
            child: Text(
              division.label!,
              key: ValueKey('league-division-${division.key}'),
              style: KolabingTextStyles.labelLarge.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }
      children.addAll(buildLeagueRows(rowsOf(division)));
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: colors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          KolabingSpacing.md,
          KolabingSpacing.md,
          KolabingSpacing.md,
          KolabingSpacing.xl,
        ),
        children: [
          if (seasonLine != null)
            _InfoBlock(key: const Key('league-season-line'), text: seasonLine),
          const SizedBox(height: KolabingSpacing.sm),
          if (table.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xl),
              child: Text(
                l10n.leagueEmpty,
                key: const Key('league-table-empty'),
                textAlign: TextAlign.center,
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            )
          else
            ...children,
          const SizedBox(height: KolabingSpacing.md),
          _InfoBlock(text: l10n.leagueHowPointsWork),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(KolabingSpacing.sm),
    decoration: BoxDecoration(
      color: context.colors.surfaceContainerHigh,
      borderRadius: KolabingRadius.borderRadiusMd,
    ),
    child: Text(
      text,
      style: KolabingTextStyles.bodySmall.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    ),
  );
}
