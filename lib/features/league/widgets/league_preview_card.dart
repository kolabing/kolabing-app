import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/league_models.dart';
import '../providers/league_provider.dart';
import '../utils/league_format.dart';
import 'league_row_tile.dart';

/// Organiser Home: where the community stands in its city league this month
/// (top 3 + its own row), with the next-reward banner underneath.
///
/// States:
/// - loading  -> a quiet placeholder block
/// - error    -> hidden (Home never shows a league error; the full table
///               screen does)
/// - `null`   -> hidden (not an organiser, or the endpoint is not live yet)
/// - no rows  -> the card with an empty-state line
/// - no city  -> league off for this organiser: only the reward banner
class LeaguePreviewCard extends ConsumerWidget {
  const LeaguePreviewCard({
    this.onOpenLeague,
    this.onOpenLevel,
    this.now,
    this.bottomSpacing = 0,
    super.key,
  });

  /// Space below the card, applied only while something is shown so a hidden
  /// card leaves no gap on Home.
  final double bottomSpacing;

  /// Tap on the card (opens the full league table).
  final VoidCallback? onOpenLeague;

  /// Tap on the reward banner (opens Your level). Null = banner not tappable.
  final VoidCallback? onOpenLevel;

  /// Clock override for tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankAsync = ref.watch(communityRankProvider);
    final child = rankAsync.when<Widget?>(
      loading: () => const _LeaguePreviewLoading(),
      error: (_, _) => null,
      data: (rank) {
        if (rank == null) return null;
        if (!rank.hasLeague) {
          // League flag off / no city: the level ladder still applies, so
          // keep the next-reward banner on its own.
          final reward = rank.nextReward;
          return reward == null
              ? null
              : KeyedSubtree(
                  key: const Key('league-reward-only'),
                  child: _RewardBanner(
                    message: reward.message,
                    onTap: onOpenLevel,
                  ),
                );
        }
        return _LeaguePreviewContent(
          rank: rank,
          now: now ?? DateTime.now(),
          onOpenLeague: onOpenLeague,
          onOpenLevel: onOpenLevel,
        );
      },
    );
    if (child == null) {
      return const SizedBox.shrink(key: Key('league-card-hidden'));
    }
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: child,
    );
  }
}

class _LeaguePreviewContent extends StatelessWidget {
  const _LeaguePreviewContent({
    required this.rank,
    required this.now,
    this.onOpenLeague,
    this.onOpenLevel,
  });

  final CommunityRank rank;
  final DateTime now;
  final VoidCallback? onOpenLeague;
  final VoidCallback? onOpenLevel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    final title = leagueTitle(l10n, rank.city);
    final month = formatLeagueMonth(context, rank.month);
    final heading = month == null || rank.city == null
        ? title
        : l10n.leagueCardHeading(rank.city!.name, month);

    final position = !rank.isRanked
        ? l10n.leagueNotRankedYet
        : (rank.total != null && rank.total! > 0)
        ? l10n.leagueRankOfTotal(rank.rank!, rank.total!)
        : l10n.leagueRankOnly(rank.rank!);
    final days = daysUntil(rank.seasonEndsAt, now);
    final subtitle = days == null
        ? position
        : '$position · ${l10n.leagueDaysLeft(days)}';

    return Column(
      key: const Key('league-card'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: colors.surface,
          borderRadius: KolabingRadius.borderRadiusCard,
          child: InkWell(
            key: const Key('league-card-tap'),
            onTap: onOpenLeague,
            borderRadius: KolabingRadius.borderRadiusCard,
            child: Container(
              padding: const EdgeInsets.all(KolabingSpacing.md),
              decoration: BoxDecoration(
                borderRadius: KolabingRadius.borderRadiusCard,
                border: Border.all(color: colors.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.trophy,
                        size: 20,
                        color: colors.onSurface,
                      ),
                      const SizedBox(width: KolabingSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              heading,
                              style: KolabingTextStyles.titleSmall.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: KolabingSpacing.xxxs),
                            Text(
                              subtitle,
                              style: KolabingTextStyles.bodySmall.copyWith(
                                color: colors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onOpenLeague != null)
                        Semantics(
                          label: l10n.leagueSeeFullTable,
                          child: Icon(
                            LucideIcons.chevronRight,
                            size: 20,
                            color: colors.textTertiary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: KolabingSpacing.sm),
                  if (rank.preview.isEmpty)
                    Text(
                      l10n.leagueEmpty,
                      key: const Key('league-card-empty'),
                      style: KolabingTextStyles.bodySmall.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    )
                  else
                    ...buildLeagueRows(rank.preview, dense: true),
                ],
              ),
            ),
          ),
        ),
        if (rank.nextReward != null) ...[
          const SizedBox(height: KolabingSpacing.xs),
          _RewardBanner(message: rank.nextReward!.message, onTap: onOpenLevel),
        ],
        if (rank.topReward != null) ...[
          const SizedBox(height: KolabingSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.xs),
            child: Text(
              rank.topReward!,
              key: const Key('league-card-top-reward'),
              style: KolabingTextStyles.bodySmall.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Yellow banner: the next reward the organiser can reach.
class _RewardBanner extends StatelessWidget {
  const _RewardBanner({required this.message, this.onTap});

  final String message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.primary,
      borderRadius: KolabingRadius.borderRadiusLg,
      child: InkWell(
        key: const Key('league-reward-banner'),
        onTap: onTap,
        borderRadius: KolabingRadius.borderRadiusLg,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KolabingSpacing.md,
            vertical: KolabingSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(LucideIcons.gift, size: 18, color: colors.onPrimary),
              const SizedBox(width: KolabingSpacing.xs),
              Expanded(
                child: Text(
                  message,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: colors.onPrimary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaguePreviewLoading extends StatelessWidget {
  const _LeaguePreviewLoading();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('league-card-loading'),
    height: 172,
    decoration: BoxDecoration(
      color: context.colors.surfaceContainerLow,
      borderRadius: KolabingRadius.borderRadiusCard,
    ),
  );
}
