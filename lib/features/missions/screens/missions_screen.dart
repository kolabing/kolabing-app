import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/category_icon.dart';
import '../models/mission.dart';
import '../providers/missions_provider.dart';
import '../utils/mission_category.dart';

/// Shows the signed-in user their gamification missions + progress, grouped by
/// category. Fed by `GET /api/v1/me/missions` via [myMissionsProvider].
///
/// The backend already role-scopes + filters the list, so this screen only
/// presents what it receives: it groups by `category`, sorts completed missions
/// after active ones within each group, and renders progress + points.
class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final missionsAsync = ref.watch(myMissionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.missionsTitle,
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: missionsAsync.when(
        data: (missions) => _MissionsContent(
          missions: missions,
          onRefresh: () async => ref.invalidate(myMissionsProvider),
        ),
        loading: () => const _MissionsLoading(),
        error: (error, _) =>
            _MissionsError(onRetry: () => ref.invalidate(myMissionsProvider)),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Content (grouped list + empty state)
// -----------------------------------------------------------------------------

class _MissionsContent extends StatelessWidget {
  const _MissionsContent({required this.missions, required this.onRefresh});

  final List<Mission> missions;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: context.colors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [SizedBox(height: 120), _MissionsEmpty()],
        ),
      );
    }

    // Group by category, then sort groups by a stable display order.
    final grouped = <String, List<Mission>>{};
    for (final mission in missions) {
      grouped.putIfAbsent(mission.category, () => []).add(mission);
    }
    final categories = grouped.keys.toList()
      ..sort((a, b) {
        final byOrder = MissionCategory.order(
          a,
        ).compareTo(MissionCategory.order(b));
        return byOrder != 0 ? byOrder : a.compareTo(b);
      });

    // Within a group: active missions first, completed after (preserving the
    // backend order within each partition).
    for (final list in grouped.values) {
      list.sort((a, b) {
        if (a.completed == b.completed) return 0;
        return a.completed ? 1 : -1;
      });
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: context.colors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          left: KolabingSpacing.md,
          right: KolabingSpacing.md,
          top: KolabingSpacing.md,
          bottom: KolabingSpacing.xl,
        ),
        // One extra row at the top: a line saying nobody has to confirm these
        // (#158). Without it the screen sits next to the peer-challenge flow
        // looking like the same thing with a different name, when the whole
        // point of §5 is that not every challenge needs another person.
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return const _SoloExplainer();

          final category = categories[index - 1];
          final list = grouped[category]!;
          return _CategorySection(category: category, missions: list);
        },
      ),
    );
  }
}

/// Why this screen is not the peer-challenge flow (#158).
class _SoloExplainer extends StatelessWidget {
  const _SoloExplainer();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: KolabingSpacing.md),
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.checkCircle,
            size: 18,
            color: context.colors.onSurfaceVariant,
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: Text(
              l10n.soloChallengesHint,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category, required this.missions});

  final String category;
  final List<Mission> missions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: KolabingSpacing.sm,
            bottom: KolabingSpacing.sm,
          ),
          child: Text(
            MissionCategory.label(l10n, category).toUpperCase(),
            style: KolabingTextStyles.labelLarge.copyWith(
              color: context.colors.onSurfaceVariant,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...missions.map((m) => _MissionTile(mission: m)),
        const SizedBox(height: KolabingSpacing.md),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Mission tile
// -----------------------------------------------------------------------------

class _MissionTile extends StatelessWidget {
  const _MissionTile({required this.mission});

  final Mission mission;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final completed = mission.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: KolabingSpacing.sm),
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(
          color: completed
              ? context.colors.success.withValues(alpha: 0.35)
              : context.colors.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personalised category SVG (docs/ICONS-AND-IMAGES.md §1).
              CategoryIcon(
                name: MissionCategory.iconKeyword(mission.category),
                size: 36,
              ),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.name,
                      style: KolabingTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colors.onSurface,
                      ),
                    ),
                    if (mission.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        mission.description!,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: KolabingSpacing.sm),
              _trailing(context, l10n),
            ],
          ),
          const SizedBox(height: KolabingSpacing.sm),
          _ProgressBar(
            fraction: completed ? 1 : mission.progressFraction,
            completed: completed,
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            l10n.missionsProgress(
              completed ? mission.targetValue : mission.progressCount,
              mission.targetValue,
            ),
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// Completed → green check; otherwise → points chip.
  Widget _trailing(BuildContext context, AppLocalizations l10n) {
    if (mission.completed) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: context.colors.success.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(LucideIcons.check, size: 16, color: context.colors.success),
      );
    }
    return _PointsChip(points: mission.points, label: l10n.missionsPointsLabel);
  }
}

class _PointsChip extends StatelessWidget {
  const _PointsChip({required this.points, required this.label});

  final int points;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(KolabingRadius.round),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.star, size: 12, color: context.colors.onSurface),
          const SizedBox(width: 4),
          Text(
            '+$points $label',
            style: KolabingTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.fraction, required this.completed});

  final double fraction;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final fillColor = completed
        ? context.colors.success
        : context.colors.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(KolabingRadius.round),
      child: LinearProgressIndicator(
        value: fraction.clamp(0.0, 1.0),
        minHeight: 8,
        backgroundColor: context.colors.surfaceVariant,
        valueColor: AlwaysStoppedAnimation<Color>(fillColor),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Empty state (brand yellow glyph in a soft-yellow circle)
// -----------------------------------------------------------------------------

class _MissionsEmpty extends StatelessWidget {
  const _MissionsEmpty();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.xl,
        vertical: KolabingSpacing.xl,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Brand empty-state treatment: yellow glyph in a soft-yellow circle.
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: KolabingColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.target,
                size: 30,
                color: KolabingColors.primary,
              ),
            ),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              l10n.missionsEmptyTitle,
              style: KolabingTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              l10n.missionsEmptyMessage,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Error state
// -----------------------------------------------------------------------------

class _MissionsError extends StatelessWidget {
  const _MissionsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: context.colors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              l10n.missionsLoadError,
              style: KolabingTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.md),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(l10n.gamificationTryAgain),
              style: TextButton.styleFrom(
                foregroundColor: context.colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Loading shimmer
// -----------------------------------------------------------------------------

class _MissionsLoading extends StatelessWidget {
  const _MissionsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      children: [for (var i = 0; i < 6; i++) const _MissionShimmerTile()],
    );
  }
}

class _MissionShimmerTile extends StatelessWidget {
  const _MissionShimmerTile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
      child: Shimmer.fromColors(
        baseColor: context.colors.surfaceVariant,
        highlightColor: context.colors.surface,
        child: Container(
          height: 104,
          decoration: BoxDecoration(
            color: context.colors.surfaceVariant,
            borderRadius: KolabingRadius.borderRadiusLg,
          ),
        ),
      ),
    );
  }
}
