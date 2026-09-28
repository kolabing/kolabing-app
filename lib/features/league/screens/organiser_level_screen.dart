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
import '../widgets/league_states.dart';

/// "Your level": the organiser's level (New / Rising / Trusted / Top), each
/// criterion for the next level (met / not yet), current perks and what the
/// next level unlocks. Fed by `GET /me/organiser-level`.
class OrganiserLevelScreen extends ConsumerWidget {
  const OrganiserLevelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final levelAsync = ref.watch(organiserLevelProvider);
    // Optional: the league's top reward line, when the league is live.
    final topReward = ref.watch(communityRankProvider).value?.topReward;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.levelScreenTitle,
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: levelAsync.when(
        loading: () => const LeagueLoadingView(),
        error: (_, _) => LeagueMessageView(
          text: l10n.levelErrorLoad,
          onRetry: () => ref.invalidate(organiserLevelProvider),
        ),
        data: (level) => level == null
            ? LeagueMessageView(text: l10n.levelUnavailable)
            : _LevelContent(
                level: level,
                topReward: topReward,
                onRefresh: () async => ref
                  ..invalidate(organiserLevelProvider)
                  ..invalidate(communityRankProvider),
              ),
      ),
    );
  }
}

class _LevelContent extends StatelessWidget {
  const _LevelContent({
    required this.level,
    required this.onRefresh,
    this.topReward,
  });

  final OrganiserLevel level;
  final String? topReward;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    final levelName = organiserLevelName(l10n, level.level, level.levelRaw);
    final nextName = level.nextLevel == null
        ? null
        : organiserLevelName(l10n, level.nextLevel!, level.nextLevelRaw!);
    final criteriaHeading = nextName != null
        ? l10n.levelCriteriaHeadingNext(nextName)
        : l10n.levelCriteriaHeadingKeep(levelName);

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
          // Level hero
          Container(
            padding: const EdgeInsets.all(KolabingSpacing.lg),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: KolabingRadius.borderRadiusCard,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.shield, size: 18, color: colors.onPrimary),
                    const SizedBox(width: KolabingSpacing.xs),
                    Text(
                      levelName,
                      key: const Key('level-name'),
                      style: KolabingTextStyles.statNumber.copyWith(
                        fontSize: 28,
                        color: colors.onPrimary,
                      ),
                    ),
                  ],
                ),
                if (nextName != null) ...[
                  const SizedBox(height: KolabingSpacing.xxs),
                  Text(
                    l10n.levelNextLine(nextName),
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (level.nextReward != null) ...[
            const SizedBox(height: KolabingSpacing.sm),
            Container(
              key: const Key('level-next-reward'),
              padding: const EdgeInsets.all(KolabingSpacing.sm),
              decoration: BoxDecoration(
                color: colors.primaryTint,
                borderRadius: KolabingRadius.borderRadiusMd,
              ),
              child: Text(
                level.nextReward!.message,
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: KolabingSpacing.lg),

          // Criteria
          _SectionHeading(criteriaHeading),
          const SizedBox(height: KolabingSpacing.xs),
          if (level.criteria.isEmpty)
            Text(
              l10n.levelNoCriteria,
              key: const Key('level-no-criteria'),
              style: KolabingTextStyles.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            )
          else ...[
            // Rows that gate the next level first, then the informative ones.
            ...level.criteria
                .where((c) => c.required)
                .map((c) => _CriterionRow(criterion: c)),
            ...level.criteria
                .where((c) => !c.required)
                .map((c) => _CriterionRow(criterion: c, informative: true)),
          ],
          if (level.daysLeft != null)
            _InfoRow(
              key: const Key('level-days-left'),
              label: l10n.levelDaysLeftLabel,
              value: '${level.daysLeft}',
            ),

          if (level.perks.isNotEmpty) ...[
            const SizedBox(height: KolabingSpacing.lg),
            _SectionHeading(l10n.levelPerksHeading),
            const SizedBox(height: KolabingSpacing.xs),
            ...level.perks.map((p) => _PerkLine(text: p)),
          ],

          if (level.nextPerks.isNotEmpty) ...[
            const SizedBox(height: KolabingSpacing.lg),
            _SectionHeading(l10n.levelNextPerksHeading(nextName ?? levelName)),
            const SizedBox(height: KolabingSpacing.xs),
            ...level.nextPerks.map((p) => _PerkLine(text: p, upcoming: true)),
          ],

          // The top reward line, unless Top is already the next step (its
          // perks, intros included, are listed just above) or reached.
          if (topReward != null &&
              level.level != OrganiserLevelKind.top &&
              level.nextLevel != OrganiserLevelKind.top) ...[
            const SizedBox(height: KolabingSpacing.lg),
            _SectionHeading(l10n.levelTopRewardHeading),
            const SizedBox(height: KolabingSpacing.xs),
            _PerkLine(text: topReward!, upcoming: true),
          ],

          if (level.evaluatedAt != null) ...[
            const SizedBox(height: KolabingSpacing.lg),
            Text(
              l10n.levelUpdatedAt(
                formatLeagueDate(context, level.evaluatedAt!),
              ),
              style: KolabingTextStyles.bodySmall.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: KolabingTextStyles.labelLarge.copyWith(
      color: context.colors.onSurface,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _CriterionRow extends StatelessWidget {
  const _CriterionRow({required this.criterion, this.informative = false});

  final LevelCriterion criterion;

  /// Tracked but not needed for the next level: neutral styling.
  final bool informative;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final met = criterion.met;

    return Semantics(
      label: met ? l10n.levelCriterionMet : l10n.levelCriterionOpen,
      child: Container(
        key: ValueKey('criterion-${criterion.key}'),
        margin: const EdgeInsets.only(bottom: KolabingSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.sm,
          vertical: KolabingSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: met || informative ? colors.surface : colors.primaryTint,
          borderRadius: KolabingRadius.borderRadiusMd,
          border: Border.all(color: colors.hairline),
        ),
        child: Row(
          children: [
            Icon(
              met
                  ? LucideIcons.checkCircle2
                  : informative
                  ? LucideIcons.minus
                  : LucideIcons.alertCircle,
              key: ValueKey(
                met
                    ? 'criterion-met-${criterion.key}'
                    : 'criterion-open-${criterion.key}',
              ),
              size: 18,
              color: met
                  ? colors.success
                  : informative
                  ? colors.textTertiary
                  : colors.orange,
            ),
            const SizedBox(width: KolabingSpacing.xs),
            Expanded(
              child: Text(
                criterion.label,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: colors.onSurface,
                  fontWeight: met || informative
                      ? FontWeight.w500
                      : FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: KolabingSpacing.xs),
            Text(
              formatCriterionProgress(context, l10n, criterion),
              style: KolabingTextStyles.labelLarge.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Neutral label/value row (e.g. days left this month).
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: KolabingSpacing.xs),
      padding: const EdgeInsets.all(KolabingSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(color: colors.hairline),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.calendar, size: 18, color: colors.textTertiary),
          const SizedBox(width: KolabingSpacing.xs),
          Expanded(
            child: Text(
              label,
              style: KolabingTextStyles.bodyMedium.copyWith(
                color: colors.onSurface,
              ),
            ),
          ),
          Text(
            value,
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

class _PerkLine extends StatelessWidget {
  const _PerkLine({required this.text, this.upcoming = false});

  final String text;
  final bool upcoming;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            upcoming ? LucideIcons.lock : LucideIcons.check,
            size: 16,
            color: upcoming ? colors.textTertiary : colors.success,
          ),
          const SizedBox(width: KolabingSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: upcoming ? colors.onSurfaceVariant : colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
