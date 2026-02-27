import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
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
          'My Stats',
          style: GoogleFonts.rubik(
            fontWeight: FontWeight.w600,
          ),
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
            _buildPointsCard(stats),
            const SizedBox(height: KolabingSpacing.lg),

            // Stats Grid
            _buildStatsGrid(stats),
            const SizedBox(height: KolabingSpacing.lg),

            // Detailed Stats
            _buildDetailedStats(stats),
            const SizedBox(height: KolabingSpacing.lg),

            // Quick Actions
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsCard(GamificationStats stats) {
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
              const Icon(
                LucideIcons.star,
                size: 32,
                color: KolabingColors.onPrimary,
              ),
              const SizedBox(width: KolabingSpacing.sm),
              Text(
                '${stats.totalPoints}',
                style: GoogleFonts.rubik(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.onPrimary,
                ),
              ),
            ],
          ),
          Text(
            'Total Points',
            style: GoogleFonts.openSans(
              fontSize: 16,
              color: KolabingColors.onPrimary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.md,
              vertical: KolabingSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.trophy,
                  size: 16,
                  color: KolabingColors.onPrimary,
                ),
                const SizedBox(width: 4),
                Text(
                  stats.globalRank != null
                      ? 'Global Rank #${stats.globalRank}'
                      : 'Unranked',
                  style: GoogleFonts.rubik(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(GamificationStats stats) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: LucideIcons.calendar,
            iconColor: KolabingColors.info,
            label: 'Events',
            value: '${stats.totalEventsAttended}',
          ),
        ),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: StatCard(
            icon: LucideIcons.target,
            iconColor: KolabingColors.success,
            label: 'Challenges',
            value: '${stats.totalChallengesCompleted}',
          ),
        ),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: StatCard(
            icon: LucideIcons.award,
            iconColor: KolabingColors.warning,
            label: 'Badges',
            value: '${stats.totalBadgesEarned}',
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedStats(GamificationStats stats) {
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
            'DETAILED STATS',
            style: GoogleFonts.rubik(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: KolabingColors.textSecondary,
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),

          _buildStatRow(
            LucideIcons.gift,
            'Rewards Won',
            '${stats.totalRewardsWon}',
            KolabingColors.primary,
          ),
          const Divider(height: KolabingSpacing.lg),

          _buildStatRow(
            LucideIcons.checkCircle,
            'Rewards Redeemed',
            '${stats.totalRewardsRedeemed}',
            KolabingColors.success,
          ),
          const Divider(height: KolabingSpacing.lg),

          _buildStatRow(
            LucideIcons.mapPin,
            'Events Discovered',
            '${stats.totalEventsDiscovered}',
            KolabingColors.info,
          ),
          const Divider(height: KolabingSpacing.lg),

          _buildStatRow(
            LucideIcons.clock,
            'Spins Used',
            '${stats.totalSpins}',
            KolabingColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: KolabingSpacing.md),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: KolabingColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.rubik(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: KolabingColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
          style: GoogleFonts.rubik(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: KolabingColors.textSecondary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                LucideIcons.trophy,
                'Leaderboard',
                () => context.push('/attendee/leaderboard'),
              ),
            ),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: _buildActionButton(
                context,
                LucideIcons.award,
                'Badges',
                () => context.push('/attendee/badges'),
              ),
            ),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: _buildActionButton(
                context,
                LucideIcons.gift,
                'Rewards',
                () => context.push('/attendee/rewards'),
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
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.md),
        decoration: BoxDecoration(
          color: KolabingColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: KolabingColors.border,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: KolabingColors.primary),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              label,
              style: GoogleFonts.openSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: KolabingColors.textPrimary,
              ),
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
        content: const Text('Game card sharing coming soon!'),
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
              'Failed to load stats',
              style: GoogleFonts.rubik(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: KolabingColors.textPrimary,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              error,
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: KolabingColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.md),
            TextButton.icon(
              onPressed: () => ref.invalidate(myStatsProvider),
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Try Again'),
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
