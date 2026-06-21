import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/color_tokens.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../community/models/community_rewards.dart';
import '../../community/providers/community_rewards_providers.dart';
import '../../community/services/community_service.dart';
import '../models/me_rewards_overview.dart';
import '../providers/me_rewards_provider.dart';

/// Personal Rewards Screen (P3).
///
/// Fed by `GET /me/rewards-overview`. Layout:
///  - Top: "Redeem your XP" card — global XP balance + a disabled "Coming soon"
///    CTA; partner rewards listed muted/locked (read-only for now).
///  - Then per-community sections: community name + my_points, and that
///    community's redeemable rewards (Redeem reuses P2's redeem call).
///
/// Self-gated: a null overview (endpoint not deployed) renders a graceful empty
/// state; partner rewards are always read-only.
class PersonalRewardsScreen extends ConsumerWidget {
  const PersonalRewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(meRewardsOverviewProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(
          l10n.personalRewardsTitle,
          style: KolabingTextStyles.bodyMedium
              .copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: async.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: context.colors.primary),
        ),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(meRewardsOverviewProvider.notifier).reload(),
        ),
        data: (overview) => RefreshIndicator(
          color: context.colors.primary,
          onRefresh: () =>
              ref.read(meRewardsOverviewProvider.notifier).reload(),
          child: _Content(overview: overview ?? MeRewardsOverview.empty),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.overview});

  final MeRewardsOverview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      children: [
        _RedeemXpCard(
          xp: overview.xp,
          partnerRewards: overview.partnerRewards,
        ),
        const SizedBox(height: KolabingSpacing.lg),
        if (!overview.hasCommunities)
          _CommunitiesEmpty(l10n: l10n)
        else
          for (final section in overview.communities) ...[
            _CommunitySection(section: section),
            const SizedBox(height: KolabingSpacing.lg),
          ],
        const SizedBox(height: KolabingSpacing.xl),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Redeem your XP (coming soon)
// -----------------------------------------------------------------------------

class _RedeemXpCard extends StatelessWidget {
  const _RedeemXpCard({required this.xp, required this.partnerRewards});

  final int xp;
  final List<PartnerReward> partnerRewards;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.primary,
            context.colors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(KolabingRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, size: 20, color: context.colors.onPrimary),
              const SizedBox(width: KolabingSpacing.xs),
              Expanded(
                child: Text(
                  l10n.personalRewardsRedeemXpTitle,
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$xp',
                style: KolabingTextStyles.bodyLarge.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: context.colors.onPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  l10n.personalRewardsXpUnit,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.onPrimary.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KolabingSpacing.sm),
          // Disabled "Coming soon" CTA — partner rewards are read-only for now.
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: null,
              icon: const Icon(LucideIcons.lock, size: 16),
              label: Text(l10n.personalRewardsComingSoon),
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.onPrimary.withValues(alpha: 0.25),
                foregroundColor: context.colors.onPrimary,
                disabledBackgroundColor:
                    context.colors.onPrimary.withValues(alpha: 0.18),
                disabledForegroundColor:
                    context.colors.onPrimary.withValues(alpha: 0.7),
              ),
            ),
          ),
          if (partnerRewards.isNotEmpty) ...[
            const SizedBox(height: KolabingSpacing.md),
            for (final reward in partnerRewards)
              Padding(
                padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
                child: _PartnerRewardTile(reward: reward),
              ),
          ],
        ],
      ),
    );
  }
}

/// A single global partner reward — always muted/locked (coming soon).
class _PartnerRewardTile extends StatelessWidget {
  const _PartnerRewardTile({required this.reward});

  final PartnerReward reward;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.onPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(KolabingRadius.md),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.gift, size: 18, color: context.colors.onPrimary),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.onPrimary,
                  ),
                ),
                if (reward.partner != null && reward.partner!.isNotEmpty)
                  Text(
                    reward.partner!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: context.colors.onPrimary.withValues(alpha: 0.75),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Text(
            l10n.personalRewardsXpCost(reward.costXp),
            style: KolabingTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.onPrimary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Per-community section
// -----------------------------------------------------------------------------

class _CommunitySection extends StatelessWidget {
  const _CommunitySection({required this.section});

  final CommunityRewardsSection section;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: context.colors.primary.withValues(alpha: 0.15),
              backgroundImage: section.communityLogoUrl != null
                  ? CachedNetworkImageProvider(section.communityLogoUrl!)
                  : null,
              child: section.communityLogoUrl == null
                  ? Icon(LucideIcons.users,
                      size: 16, color: context.colors.primary)
                  : null,
            ),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: Text(
                section.communityName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.onSurface,
                ),
              ),
            ),
            const SizedBox(width: KolabingSpacing.sm),
            Icon(LucideIcons.star, size: 16, color: context.colors.primary),
            const SizedBox(width: 4),
            Text(
              l10n.personalRewardsMyPoints(section.myPoints),
              style: KolabingTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: KolabingSpacing.sm),
        if (section.rewards.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
            child: Text(
              l10n.personalRewardsNoRewards,
              style: KolabingTextStyles.bodySmall
                  .copyWith(color: context.colors.onSurfaceVariant),
            ),
          )
        else
          for (final reward in section.rewards)
            _CommunityRewardTile(
              communityId: section.communityId,
              reward: reward,
            ),
      ],
    );
  }
}

/// A redeemable per-community reward. Reuses P2's
/// `CommunityRewardsService.redeemReward`; on success it reloads the personal
/// overview so balances refresh.
class _CommunityRewardTile extends ConsumerStatefulWidget {
  const _CommunityRewardTile({
    required this.communityId,
    required this.reward,
  });

  final String communityId;
  final CommunityReward reward;

  @override
  ConsumerState<_CommunityRewardTile> createState() =>
      _CommunityRewardTileState();
}

class _CommunityRewardTileState extends ConsumerState<_CommunityRewardTile> {
  bool _busy = false;

  Future<void> _redeem() async {
    final l10n = AppLocalizations.of(context);
    final r = widget.reward;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.communityRewardsRedeemConfirmTitle),
        content:
            Text(l10n.communityRewardsRedeemConfirmBody(r.costPoints, r.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.communityRewardsRedeem),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(communityRewardsServiceProvider)
          .redeemReward(widget.communityId, r.id);
      // Refresh balances on both the personal overview and the community hub.
      unawaited(ref.read(meRewardsOverviewProvider.notifier).reload());
      unawaited(ref
          .read(communityRewardsHubProvider(widget.communityId).notifier)
          .reload());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.communityRewardsRedeemedSnack)),
        );
      }
    } on CommunityException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = widget.reward;
    final affordable = r.affordable ?? true;
    final canRedeem = affordable && !r.isOutOfStock && !_busy;
    return Padding(
      padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(KolabingSpacing.sm),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(KolabingRadius.md),
          border: Border.all(color: context.colors.hairline),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.title,
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.colors.onSurface,
                    ),
                  ),
                  if (r.description != null && r.description!.isNotEmpty)
                    Text(
                      r.description!,
                      style: KolabingTextStyles.bodySmall
                          .copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  Text(
                    r.stock == null
                        ? l10n.communityRewardsRewardCost(r.costPoints)
                        : '${l10n.communityRewardsRewardCost(r.costPoints)} · ${l10n.communityRewardsRewardStock(r.stock!)}',
                    style: KolabingTextStyles.bodySmall
                        .copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: KolabingSpacing.sm),
            FilledButton(
              onPressed: canRedeem ? _redeem : null,
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: context.colors.onPrimary,
              ),
              child: _busy
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.colors.onSurface,
                      ),
                    )
                  : Text(l10n.communityRewardsRedeem),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Empty / error states
// -----------------------------------------------------------------------------

class _CommunitiesEmpty extends StatelessWidget {
  const _CommunitiesEmpty({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(KolabingSpacing.lg),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(KolabingRadius.lg),
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(LucideIcons.gift,
                size: 36, color: context.colors.onSurfaceVariant),
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              l10n.personalRewardsEmptyTitle,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.personalRewardsEmptyBody,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodySmall
                  .copyWith(color: context.colors.onSurfaceVariant),
            ),
          ],
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
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
            Icon(LucideIcons.alertCircle,
                size: 48, color: context.colors.error.withValues(alpha: 0.7)),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              l10n.personalRewardsFailedToLoad,
              style: KolabingTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodySmall
                  .copyWith(color: context.colors.onSurfaceVariant),
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
