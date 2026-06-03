import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/leaderboard.dart';
import '../providers/leaderboard_provider.dart';
import '../widgets/leaderboard_entry_tile.dart';
import '../widgets/leaderboard_podium.dart';

/// Screen showing event or global leaderboard
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({
    super.key,
    this.eventId,
    this.eventName,
  });

  /// If provided, shows event leaderboard. Otherwise shows global.
  final String? eventId;
  final String? eventName;

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  Widget build(BuildContext context) {
    final isGlobal = widget.eventId == null;

    final leaderboardAsync = isGlobal
        ? ref.watch(globalLeaderboardProvider)
        : ref.watch(eventLeaderboardSimpleProvider(widget.eventId!));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isGlobal
              ? AppLocalizations.of(context).leaderboardScreenGlobalTitle
              : (widget.eventName ?? AppLocalizations.of(context).leaderboardScreenTitle),
          style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: leaderboardAsync.when(
        data: (response) => _buildContent(context, response),
        loading: () => const Center(
          child: CircularProgressIndicator(color: KolabingColors.primary),
        ),
        error: (error, stack) => _buildErrorState(context, error.toString()),
      ),
    );
  }

  Widget _buildContent(BuildContext context, LeaderboardResponse response) {
    if (response.entries.isEmpty) {
      return _buildEmptyState(context);
    }

    // Get top 3 for podium
    final topThree = response.entries.take(3).toList();
    final rest = response.entries.skip(3).toList();

    return RefreshIndicator(
      onRefresh: () async {
        if (widget.eventId == null) {
          ref.invalidate(globalLeaderboardProvider);
        } else {
          ref.invalidate(eventLeaderboardSimpleProvider(widget.eventId!));
        }
      },
      color: KolabingColors.primary,
      child: CustomScrollView(
        slivers: [
          // Podium
          SliverToBoxAdapter(
            child: LeaderboardPodium(topThree: topThree),
          ),

          // My rank section
          if (response.myRank != null)
            SliverToBoxAdapter(
              child: _buildMyRankCard(response.myRank!),
            ),

          // Rest of the list header
          if (rest.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  KolabingSpacing.md,
                  KolabingSpacing.lg,
                  KolabingSpacing.md,
                  KolabingSpacing.sm,
                ),
                child: Text(
                  AppLocalizations.of(context).leaderboardScreenRankings,
                  style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: KolabingColors.onSurfaceVariant, letterSpacing: 1.2),
                ),
              ),
            ),

          // Rest of the leaderboard
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = rest[index];
                return LeaderboardEntryTile(
                  entry: entry,
                  isCurrentUser: response.myRank?.profileId == entry.profileId,
                );
              },
              childCount: rest.length,
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: KolabingSpacing.xl),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRankCard(MyRank myRank) {
    return Container(
      margin: const EdgeInsets.all(KolabingSpacing.md),
      padding: const EdgeInsets.all(KolabingSpacing.md),
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
      child: Row(
        children: [
          // Rank
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#${myRank.rank}',
                style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: KolabingColors.onPrimary),
              ),
            ),
          ),
          const SizedBox(width: KolabingSpacing.md),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).leaderboardScreenYourRanking,
                  style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: KolabingColors.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  myRank.displayName,
                  style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: KolabingColors.onPrimary),
                ),
              ],
            ),
          ),

          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${myRank.totalPoints}',
                style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: KolabingColors.onPrimary),
              ),
              Text(
                AppLocalizations.of(context).leaderboardScreenPoints,
                style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: KolabingColors.onPrimary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.trophy,
              size: 80,
              color: KolabingColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: KolabingSpacing.lg),
            Text(
              AppLocalizations.of(context).leaderboardScreenNoRankings,
              style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: KolabingColors.onSurface),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              AppLocalizations.of(context).leaderboardScreenNoRankingsHint,
              style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
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
              AppLocalizations.of(context).leaderboardScreenFailedToLoad,
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
              onPressed: () {
                if (widget.eventId == null) {
                  ref.invalidate(globalLeaderboardProvider);
                } else {
                  ref.invalidate(eventLeaderboardSimpleProvider(widget.eventId!));
                }
              },
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
