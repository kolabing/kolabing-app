import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/ui_icon.dart';
import '../models/gamification_stats.dart';
import '../providers/stats_provider.dart';
import '../widgets/stat_card.dart';

/// Screen showing user's gamification stats dashboard
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(myStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).statsScreenTitle,
          style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2),
            onPressed: () => _shareGameCard(context),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => _buildContent(context, ref, stats),
        loading: () => const Center(
          child: CircularProgressIndicator(color: KolabingColors.primary),
        ),
        error: (error, stack) => _buildErrorState(context, ref, error.toString()),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    GamificationStats stats,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myStatsProvider);
      },
      color: KolabingColors.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Points & Rank Card
            _buildPointsCard(context, stats),
            const SizedBox(height: KolabingSpacing.lg),

            // Stats Grid
            _buildStatsGrid(context, stats),
            const SizedBox(height: KolabingSpacing.lg),

            // Detailed Stats
            _buildDetailedStats(context, stats),
            const SizedBox(height: KolabingSpacing.lg),

            // Quick Actions
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsCard(BuildContext context, GamificationStats stats) {
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            KolabingColors.primary,
            KolabingColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: KolabingColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const UiIcon(
                icon: UiIconSlug.star,
                size: 32,
                color: KolabingColors.onPrimary,
              ),
              const SizedBox(width: KolabingSpacing.sm),
              Text(
                '${stats.totalPoints}',
                style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 48, fontWeight: FontWeight.w700, color: KolabingColors.onPrimary),
              ),
            ],
          ),
          Text(
            AppLocalizations.of(context).statsScreenTotalPoints,
            style: KolabingTextStyles.bodyMedium.copyWith(color: KolabingColors.onPrimary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, GamificationStats stats) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: LucideIcons.calendar,
            iconSlug: UiIconSlug.calendar,
            iconColor: KolabingColors.info,
            label: l10n.statsScreenEvents,
            value: '${stats.totalEventsAttended}',
          ),
        ),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: StatCard(
            icon: LucideIcons.target,
            iconSlug: UiIconSlug.target,
            iconColor: KolabingColors.success,
            label: l10n.statsScreenChallenges,
            value: '${stats.totalChallengesCompleted}',
          ),
        ),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: StatCard(
            icon: LucideIcons.award,
            iconSlug: UiIconSlug.award,
            iconColor: KolabingColors.warning,
            label: l10n.statsScreenBadges,
            value: '${stats.totalBadgesEarned}',
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedStats(BuildContext context, GamificationStats stats) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.statsScreenDetailedStats,
            style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: KolabingColors.onSurfaceVariant, letterSpacing: 1.2),
          ),
          const SizedBox(height: KolabingSpacing.md),

          _buildStatRow(
            LucideIcons.gift,
            l10n.statsScreenRewardsWon,
            '${stats.totalRewardsWon}',
            KolabingColors.primary,
            iconSlug: UiIconSlug.gift,
          ),
          const Divider(height: KolabingSpacing.lg),

          _buildStatRow(
            LucideIcons.checkCircle,
            l10n.statsScreenRewardsRedeemed,
            '${stats.totalRewardsRedeemed}',
            KolabingColors.success,
          ),
          const Divider(height: KolabingSpacing.lg),

          _buildStatRow(
            LucideIcons.mapPin,
            l10n.statsScreenEventsDiscovered,
            '${stats.totalEventsDiscovered}',
            KolabingColors.info,
          ),
          const Divider(height: KolabingSpacing.lg),

          _buildStatRow(
            LucideIcons.clock,
            l10n.statsScreenSpinsUsed,
            '${stats.totalSpins}',
            KolabingColors.warning,
            iconSlug: UiIconSlug.clock,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    IconData icon,
    String label,
    String value,
    Color color, {
    UiIconSlug? iconSlug,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: iconSlug != null
                ? UiIcon(icon: iconSlug, size: 20, color: color)
                : Icon(icon, size: 20, color: color),
          ),
        ),
        const SizedBox(width: KolabingSpacing.md),
        Expanded(
          child: Text(
            label,
            style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.onSurfaceVariant),
          ),
        ),
        Text(
          value,
          style: KolabingTextStyles.bodyMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w700, color: KolabingColors.onSurface),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).statsScreenQuickActions,
          style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: KolabingColors.onSurfaceVariant, letterSpacing: 1.2),
        ),
        const SizedBox(height: KolabingSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                LucideIcons.award,
                AppLocalizations.of(context).statsScreenBadges,
                () => context.push('/attendee/badges'),
                iconSlug: UiIconSlug.award,
              ),
            ),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: _buildActionButton(
                context,
                LucideIcons.gift,
                AppLocalizations.of(context).statsScreenRewards,
                () => context.push('/attendee/rewards'),
                iconSlug: UiIconSlug.gift,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    UiIconSlug? iconSlug,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.md),
        decoration: BoxDecoration(
          color: KolabingColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: KolabingColors.darkBorder,
          ),
        ),
        child: Column(
          children: [
            if (iconSlug != null)
              UiIcon(icon: iconSlug, size: 24, color: KolabingColors.primary)
            else
              Icon(icon, size: 24, color: KolabingColors.primary),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              label,
              style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: KolabingColors.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  void _shareGameCard(BuildContext context) {
    // TODO: Implement game card sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).statsScreenShareComingSoon),
        backgroundColor: KolabingColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: KolabingColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              AppLocalizations.of(context).statsScreenFailedToLoad,
              style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: KolabingColors.onSurface),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              error,
              style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.md),
            TextButton.icon(
              onPressed: () => ref.invalidate(myStatsProvider),
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(AppLocalizations.of(context).gamificationTryAgain),
              style: TextButton.styleFrom(
                foregroundColor: KolabingColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
