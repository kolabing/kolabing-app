import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/layout.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/kolabing_button.dart';
import '../../models/community_rank.dart';
import '../../providers/community_rank_provider.dart';
import '../../utils/community_rank_projection.dart';
import 'community_onboarding_cards_screen.dart';

/// Organiser onboarding "what's next" — Direction C (live preview).
///
/// Daniel LOCKED this as the long-term design (spec cbdffbbe, handoff
/// 2c29e013, 1 Oct); Direction A ([CommunityOnboardingCardsScreen], PR #240)
/// shipped first only because `/me/community-rank` was still a backend
/// dependency. That dependency is now live (`CityLeagueController::me`,
/// merged via #359) — this screen replaces Direction A at both entry points.
///
/// Shows the organiser's REAL city-league standing, then a slider that
/// projects the points/rank jump from running one kolab with up to 20
/// check-ins (the Trusted threshold — see [CommunityRankWeights]), using the
/// backend's own scoring weights, not fabricated numbers.
///
/// Falls back to the Direction A static cards when `/me/community-rank`
/// 403s (not a community profile) or otherwise fails — never a blank or
/// dead screen.
class CommunityRankPreviewScreen extends ConsumerStatefulWidget {
  const CommunityRankPreviewScreen({
    required this.onPostFirstKolab,
    this.onSkip,
    super.key,
  });

  /// Called when the user taps "Post your first kolab".
  final VoidCallback onPostFirstKolab;

  /// Called when the user taps "Skip". Defaults to [onPostFirstKolab] so a
  /// skip never strands the user on this screen.
  final VoidCallback? onSkip;

  @override
  ConsumerState<CommunityRankPreviewScreen> createState() =>
      _CommunityRankPreviewScreenState();
}

class _CommunityRankPreviewScreenState
    extends ConsumerState<CommunityRankPreviewScreen> {
  double _checkins = CommunityRankWeights.trustedMinCheckins.toDouble();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: KolabingColors.appBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  void _skip() => (widget.onSkip ?? widget.onPostFirstKolab)();

  @override
  Widget build(BuildContext context) {
    final rankAsync = ref.watch(myCommunityRankProvider);

    return rankAsync.when(
      loading: () => const _LoadingScreen(),
      error: (error, _) => CommunityOnboardingCardsScreen(
        onPostFirstKolab: widget.onPostFirstKolab,
        onSkip: widget.onSkip,
      ),
      data: (rank) {
        if (!rank.hasLeague) {
          return CommunityOnboardingCardsScreen(
            onPostFirstKolab: widget.onPostFirstKolab,
            onSkip: widget.onSkip,
          );
        }
        return _LivePreview(
          rank: rank,
          checkins: _checkins,
          onCheckinsChanged: (v) => setState(() => _checkins = v),
          onSkip: _skip,
          onPostFirstKolab: widget.onPostFirstKolab,
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.colors.appBackground,
    body: const SafeArea(child: Center(child: CircularProgressIndicator())),
  );
}

class _LivePreview extends StatelessWidget {
  const _LivePreview({
    required this.rank,
    required this.checkins,
    required this.onCheckinsChanged,
    required this.onSkip,
    required this.onPostFirstKolab,
  });

  final CommunityRank rank;
  final double checkins;
  final ValueChanged<double> onCheckinsChanged;
  final VoidCallback onSkip;
  final VoidCallback onPostFirstKolab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final checkinsInt = checkins.round();
    final newPoints = projectedPoints(rank, checkinsInt);
    final newRank = projectedRank(rank, newPoints);
    final willBeTrusted =
        checkinsInt >= CommunityRankWeights.trustedMinCheckins;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: c.appBackground,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: onSkip,
                      child: Text(
                        l10n.commonSkip,
                        style: KolabingTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KolabingSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: KolabingSpacing.sm),
                      _CurrentStandingCard(rank: rank, l10n: l10n),
                      const SizedBox(height: KolabingSpacing.lg),
                      _ProjectionCard(
                        rank: rank,
                        checkinsInt: checkinsInt,
                        newPoints: newPoints,
                        newRank: newRank,
                        willBeTrusted: willBeTrusted,
                        onCheckinsChanged: onCheckinsChanged,
                        l10n: l10n,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: KolabingButton(
                  label: l10n.communityOnboardingCardsPostFirstKolab,
                  onPressed: onPostFirstKolab,
                  variant: KolabingButtonVariant.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentStandingCard extends StatelessWidget {
  const _CurrentStandingCard({required this.rank, required this.l10n});

  final CommunityRank rank;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final city = rank.city ?? '';
    final standing = rank.rank != null
        ? l10n.communityRankPreviewCurrentRank(rank.rank!, city)
        : l10n.communityRankPreviewNotRankedYet(city);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.hairline),
        boxShadow: const [KolabingShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.trophy,
                  size: 22,
                  color: c.onSurface,
                ),
              ),
              const SizedBox(width: KolabingSpacing.md),
              Expanded(
                child: Text(
                  standing,
                  style: KolabingTextStyles.bodyLarge.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: c.ink,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            l10n.communityRankPreviewCurrentPoints(rank.points),
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 14,
              color: c.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectionCard extends StatelessWidget {
  const _ProjectionCard({
    required this.rank,
    required this.checkinsInt,
    required this.newPoints,
    required this.newRank,
    required this.willBeTrusted,
    required this.onCheckinsChanged,
    required this.l10n,
  });

  final CommunityRank rank;
  final int checkinsInt;
  final int newPoints;
  final int? newRank;
  final bool willBeTrusted;
  final ValueChanged<double> onCheckinsChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.hairline),
        boxShadow: const [KolabingShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.communityRankPreviewSliderTitle,
            style: KolabingTextStyles.bodyLarge.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.communityRankPreviewSliderSubtitle(checkinsInt),
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 14,
              color: c.onSurfaceVariant,
            ),
          ),
          Slider(
            value: checkinsInt.toDouble(),
            min: 0,
            max: CommunityRankWeights.trustedMinCheckins.toDouble(),
            divisions: CommunityRankWeights.trustedMinCheckins,
            label: '$checkinsInt',
            activeColor: c.primaryDark,
            onChanged: onCheckinsChanged,
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  label: l10n.communityRankPreviewProjectedPoints,
                  value: '$newPoints',
                ),
              ),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: _StatPill(
                  label: l10n.communityRankPreviewProjectedRank,
                  value: newRank != null
                      ? '#$newRank'
                      : l10n.communityRankPreviewNotRankedShort,
                ),
              ),
            ],
          ),
          if (willBeTrusted) ...[
            const SizedBox(height: KolabingSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.sm,
                vertical: KolabingSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: KolabingColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    LucideIcons.badgeCheck,
                    size: 16,
                    color: KolabingColors.success,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.communityRankPreviewTrustedUnlocked,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: KolabingColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.sm,
        vertical: KolabingSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: c.appBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 12,
              color: c.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: KolabingTextStyles.bodyLarge.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: c.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pushes [CommunityRankPreviewScreen] on the current (non-go_router)
/// [Navigator] stack — the in-app "create a community" entry path. Mirrors
/// [pushCommunityOnboardingCards] (Direction A); see that function's doc for
/// why this is a plain push rather than a [GoRoute].
Future<void> pushCommunityRankPreview(BuildContext context) =>
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CommunityRankPreviewScreen(
          onPostFirstKolab: () {
            Navigator.of(context).pop();
            context.push(KolabingRoutes.kolabNew);
          },
        ),
      ),
    );
