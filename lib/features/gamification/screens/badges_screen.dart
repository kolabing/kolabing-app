import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
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
          AppLocalizations.of(context).badgesScreenTitle,
          style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: allBadgesAsync.when(
        data: (allBadges) => myBadgesAsync.when(
          data: (myBadges) => _buildContent(context, ref, allBadges, myBadges),
          loading: () => Center(
            child: CircularProgressIndicator(color: context.colors.primary),
          ),
          error: (error, stack) => _buildErrorState(context, ref, error.toString()),
        ),
        loading: () => Center(
          child: CircularProgressIndicator(color: context.colors.primary),
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
      color: context.colors.primary,
      child: CustomScrollView(
        slivers: [
          // Stats header
          SliverToBoxAdapter(
            child: _buildStatsHeader(context, myBadges),
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
                  AppLocalizations.of(context).badgesScreenEarnedBadges,
                  style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1.2),
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
                AppLocalizations.of(context).badgesScreenAllBadges,
                style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1.2),
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

  Widget _buildStatsHeader(BuildContext context, MyBadgesResponse myBadges) {
    return Container(
      margin: const EdgeInsets.all(KolabingSpacing.md),
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.primary,
            context.colors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.colors.primary.withValues(alpha: 0.3),
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
            child: Icon(
              LucideIcons.award,
              size: 32,
              color: context.colors.onPrimary,
            ),
          ),
          const SizedBox(width: KolabingSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${myBadges.badges.length}',
                style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 36, fontWeight: FontWeight.w700, color: context.colors.onPrimary),
              ),
              Text(
                AppLocalizations.of(context).badgesScreenBadgesEarned,
                style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onPrimary.withValues(alpha: 0.9),
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
              color: context.colors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              AppLocalizations.of(context).badgesScreenFailedToLoad,
              style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: context.colors.onSurface),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              error,
              style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.md),
            TextButton.icon(
              onPressed: () {
                ref.invalidate(allBadgesProvider);
                ref.invalidate(myBadgesProvider);
              },
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(AppLocalizations.of(context).gamificationTryAgain),
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
