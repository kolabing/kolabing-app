import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../models/badge.dart';
import '../providers/badge_provider.dart';
import '../widgets/badge_card.dart';

/// Screen showing all badges and user's earned badges
class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allBadgesAsync = ref.watch(allBadgesProvider);
    final myBadgesAsync = ref.watch(myBadgesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Badges',
          style: GoogleFonts.rubik(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: allBadgesAsync.when(
        data: (allBadges) => myBadgesAsync.when(
          data: (myBadges) => _buildContent(context, ref, allBadges, myBadges),
          loading: () => const Center(
            child: CircularProgressIndicator(color: KolabingColors.primary),
          ),
          error: (error, stack) => _buildErrorState(context, ref, error.toString()),
        ),
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
    BadgesResponse allBadges,
    MyBadgesResponse myBadges,
  ) {
    // Create a map of earned badge IDs for quick lookup
    final earnedBadgeIds = myBadges.badges.map((b) => b.badge.id).toSet();
    final badgeAwardMap = {
      for (var award in myBadges.badges) award.badge.id: award
    };

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allBadgesProvider);
        ref.invalidate(myBadgesProvider);
      },
      color: KolabingColors.primary,
      child: CustomScrollView(
        slivers: [
          // Stats header
          SliverToBoxAdapter(
            child: _buildStatsHeader(myBadges),
          ),

          // Earned badges section
          if (myBadges.badges.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  KolabingSpacing.md,
                  KolabingSpacing.lg,
                  KolabingSpacing.md,
                  KolabingSpacing.sm,
                ),
                child: Text(
                  'EARNED BADGES',
                  style: GoogleFonts.rubik(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: KolabingColors.textSecondary,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: KolabingSpacing.sm,
                  mainAxisSpacing: KolabingSpacing.sm,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final award = myBadges.badges[index];
                    return BadgeCard(
                      badge: award.badge,
                      isEarned: true,
                      earnedAt: award.awardedAt,
                    );
                  },
                  childCount: myBadges.badges.length,
                ),
              ),
            ),
          ],

          // All badges section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                KolabingSpacing.md,
                KolabingSpacing.lg,
                KolabingSpacing.md,
                KolabingSpacing.sm,
              ),
              child: Text(
                'ALL BADGES',
                style: GoogleFonts.rubik(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: KolabingColors.textSecondary,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: KolabingSpacing.sm,
                mainAxisSpacing: KolabingSpacing.sm,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final badge = allBadges.badges[index];
                  final isEarned = earnedBadgeIds.contains(badge.id);
                  final award = badgeAwardMap[badge.id];

                  return BadgeCard(
                    badge: badge,
                    isEarned: isEarned,
                    earnedAt: award?.awardedAt,
                  );
                },
                childCount: allBadges.badges.length,
              ),
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

  Widget _buildStatsHeader(MyBadgesResponse myBadges) {
    return Container(
      margin: const EdgeInsets.all(KolabingSpacing.md),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.award,
              size: 32,
              color: KolabingColors.onPrimary,
            ),
          ),
          const SizedBox(width: KolabingSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${myBadges.badges.length}',
                style: GoogleFonts.rubik(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.onPrimary,
                ),
              ),
              Text(
                'Badges Earned',
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: KolabingColors.onPrimary.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
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
              'Failed to load badges',
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
                ref.invalidate(allBadgesProvider);
                ref.invalidate(myBadgesProvider);
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
