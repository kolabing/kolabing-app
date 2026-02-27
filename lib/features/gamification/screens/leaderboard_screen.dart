import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
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
          isGlobal ? 'Global Leaderboard' : (widget.eventName ?? 'Leaderboard'),
          style: GoogleFonts.rubik(
            fontWeight: FontWeight.w600,
          ),
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
                  'RANKINGS',
                  style: GoogleFonts.rubik(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: KolabingColors.textSecondary,
                  ),
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
                style: GoogleFonts.rubik(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.onPrimary,
                ),
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
                  'Your Ranking',
                  style: GoogleFonts.openSans(
                    fontSize: 12,
                    color: KolabingColors.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  myRank.displayName,
                  style: GoogleFonts.rubik(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.onPrimary,
                  ),
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
                style: GoogleFonts.rubik(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.onPrimary,
                ),
              ),
              Text(
                'points',
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: KolabingColors.onPrimary.withValues(alpha: 0.8),
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
              'No Rankings Yet',
              style: GoogleFonts.rubik(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: KolabingColors.textPrimary,
              ),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              'Be the first to earn points\nand claim the top spot!',
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: KolabingColors.textSecondary,
              ),
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
              'Failed to load leaderboard',
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
              onPressed: () {
                if (widget.eventId == null) {
                  ref.invalidate(globalLeaderboardProvider);
                } else {
                  ref.invalidate(eventLeaderboardSimpleProvider(widget.eventId!));
                }
              },
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
