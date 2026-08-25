import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../config/constants/layout.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/feature_flags.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/cards/kolabing_cards.dart';
import '../../auth/providers/auth_provider.dart';
import '../../event/providers/event_provider.dart';
import '../../event/models/event.dart';
import '../../event/screens/event_detail_screen.dart';
import '../../profile/providers/public_profile_provider.dart';
import '../providers/community_media_provider.dart';
import '../models/community.dart';
import '../models/community_member.dart';
import '../models/community_membership.dart';
import '../models/community_rewards.dart';
import '../models/community_tier.dart';
import '../providers/community_providers.dart';
import '../providers/community_rewards_providers.dart';
import '../services/community_service.dart';
import '../../../widgets/hero_circle_action.dart';
import '../widgets/community_page_sections.dart';
import '../../event/widgets/event_timeline.dart';
import '../widgets/community_rewards_editor_sheets.dart';
import 'roster_screen.dart';
import 'tier_editor_screen.dart';

/// Tabbed Community detail (gamification restructure): **Rewards · Members ·
/// Events**. The former Chats tab is now a "Chats →" header action that opens
/// the chat screen filtered to this community.
///
/// Opened by tapping a community the user belongs to (`my_communities_screen`).
/// LEADER vs MEMBER affordances key off [CommunityMembership.canManage].
class CommunityDetailScreen extends ConsumerStatefulWidget {
  const CommunityDetailScreen({
    super.key,
    required this.membership,
    this.embedded = false,
  });

  final CommunityMembership membership;

  /// When rendered as a bottom-nav tab body (the leader's COMMUNITY tab) rather
  /// than a pushed route — suppresses the hero's back button.
  final bool embedded;

  @override
  ConsumerState<CommunityDetailScreen> createState() =>
      _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends ConsumerState<CommunityDetailScreen> {
  Community get _community => widget.membership.community;
  bool get _canManage => widget.membership.canManage;

  /// The roster is a **manager** surface: `GET /communities/{id}/members` is
  /// gated on the `manage` ability and 403s for an ordinary member. Offering it
  /// to one only ever produced "You are not authorized to manage this
  /// community."
  bool get _showMembers => kCommunityMembersTabEnabled && _canManage;

  @override
  void initState() {
    super.initState();
    // Refresh events + rewards on open so newly-granted tier content (or a new
    // event / goal) appears without a manual pull-to-refresh.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_reload());
    });
  }

  Future<void> _reload() async {
    final id = _community.id;
    await Future.wait([
      ref.read(communityUpcomingEventsProvider(id).notifier).reload(),
      ref.read(communityRewardsHubProvider(id).notifier).reload(),
      // Only a manager may read the roster or the admin lists; firing either as
      // an ordinary member is a guaranteed 403.
      if (_showMembers)
        ref.read(communityMembersByIdProvider(id).notifier).reload(),
      if (_canManage)
        ref.read(communityRewardsAdminProvider(id).notifier).reloadAll(),
    ]);
  }

  /// Which community, and whose profile might hold its curated photos.
  CommunityMediaKey get _mediaKey =>
      (communityId: _community.id, ownerProfileId: _community.ownerProfileId);

  /// Open the chat inbox; the backend role-scopes the threads.
  void _openChats() => context.pushNamed('chats');

  /// Share a join-invite link for this community. Uses the backend's canonical
  /// link when present, else a slug fallback; degrades by copying the link if
  /// the OS share sheet is unavailable.
  Future<void> _shareInvite() async {
    final l10n = AppLocalizations.of(context);
    final c = _community;
    final url = c.shareInviteUrl;
    if (url == null) return;
    final message = l10n.communityShareInviteMessage(c.name, url);
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    try {
      final result = await Share.share(message, sharePositionOrigin: origin);
      if (result.status == ShareResultStatus.unavailable && mounted) {
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.communityShareInviteCopied)),
          );
        }
      }
    } on Exception {
      if (!mounted) return;
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.communityShareInviteCopied)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = _community;
    return Scaffold(
      backgroundColor: context.colors.background,
      body: RefreshIndicator(
        onRefresh: _reload,
        child: CustomScrollView(
          slivers: [
            // Cover + logo tile, with the two actions the old app bar carried.
            SliverToBoxAdapter(
              child: CommunityCoverHero(
                name: c.name,
                avatarUrl: c.avatarUrl,
                coverUrl: ref.watch(communityCoverPhotoProvider(_mediaKey)),
                showBack: !widget.embedded,
                actions: [
                  HeroCircleAction(
                    icon: LucideIcons.messageCircle,
                    tooltip: l10n.communityDetailChatsAction,
                    onTap: _openChats,
                  ),
                  // Self-gated: only when we have a usable link.
                  if (c.shareInviteUrl != null)
                    HeroCircleAction(
                      icon: LucideIcons.share2,
                      tooltip: l10n.communityShareInvite,
                      onTap: _shareInvite,
                    ),
                ],
              ),
            ),
            SliverToBoxAdapter(child: _Identity(community: c)),

            // The community's photographs: curated when the leader curated
            // some, its own event photos when not.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  KolabingSpacing.md,
                  KolabingSpacing.md,
                  0,
                  0,
                ),
                child: CommunityPhotoStrip(
                  photos: ref.watch(communityPhotosProvider(_mediaKey)),
                ),
              ),
            ),

            // Where the viewer stands in this community: a member sees points +
            // tier, a manager gets into the roster.
            if (!_canManage)
              SliverToBoxAdapter(child: _StandingNavRow(community: c)),
            if (_showMembers)
              SliverToBoxAdapter(child: _RosterNavRow(community: c)),

            // Events, grouped by day.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  KolabingSpacing.md,
                  KolabingSpacing.md,
                  KolabingSpacing.md,
                  0,
                ),
                child: _EventsSection(community: c, canManage: _canManage),
              ),
            ),

            // Rewards / goals / badges — leaders manage them, members earn them.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  KolabingSpacing.md,
                  KolabingSpacing.lg,
                  KolabingSpacing.md,
                  0,
                ),
                child: _canManage
                    ? _RewardsLeaderSection(communityId: c.id)
                    : _RewardsMemberSection(communityId: c.id),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: KolabingSpacing.xxl),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Standing / roster rows
// -----------------------------------------------------------------------------

/// A member's own standing: points and tier.
///
/// Both arrive inside `GET /communities/{id}` as `my_points` and `my_tier`, so
/// this no longer waits on the rewards hub — it was making a second call for
/// something the page had already been sent.
class _StandingNavRow extends StatelessWidget {
  const _StandingNavRow({required this.community});

  final Community community;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CommunityNavRow(
      icon: LucideIcons.star,
      title: l10n.communityMembersPoints(community.myPoints),
      subtitle: community.myTier?.name ?? l10n.communityRewardsNoTier,
    );
  }
}

/// Name, about, meta line and the owner's social handles.
class _Identity extends ConsumerWidget {
  const _Identity({required this.community});

  final Community community;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final owner = community.ownerProfileId;
    // Self-gated: the handles and the city live on the owner's public profile,
    // which may not have loaded (or may not exist for an older payload).
    final profile = owner.isEmpty
        ? null
        : ref
              .watch(publicProfileProvider(owner))
              .maybeWhen(data: (p) => p, orElse: () => null);

    final typeAndMembers = l10n.communityDetailTypeAndMembers(
      community.type.displayName,
      community.memberCount ?? 0,
    );
    final city = profile?.cityName;

    return CommunityIdentityBlock(
      name: community.name,
      description: community.description,
      metaText: city == null || city.isEmpty
          ? typeAndMembers
          : '$city · $typeAndMembers',
      metaIcon: city == null || city.isEmpty
          ? LucideIcons.users
          : LucideIcons.mapPin,
      instagram: profile?.instagram,
      tiktok: profile?.tiktok,
      website: profile?.website,
    );
  }
}

/// Manager-only: into the tier-grouped roster, which used to be a tab.
class _RosterNavRow extends StatelessWidget {
  const _RosterNavRow({required this.community});

  final Community community;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CommunityNavRow(
      icon: LucideIcons.users,
      title: l10n.communityDetailTabMembers,
      subtitle: l10n.attendeeCommunityProfileMemberCount(
        community.memberCount ?? 0,
      ),
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => _MembersScreen(community: community),
        ),
      ),
    );
  }
}

class _MembersScreen extends StatelessWidget {
  const _MembersScreen({required this.community});

  final Community community;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(title: Text(l10n.communityDetailTabMembers)),
      body: _MembersTab(community: community, canManage: true),
    );
  }
}

// =============================================================================
// Rewards tab
// =============================================================================

// -----------------------------------------------------------------------------
// Rewards — MEMBER view
// -----------------------------------------------------------------------------

class _RewardsMemberSection extends ConsumerWidget {
  const _RewardsMemberSection({required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(communityRewardsHubProvider(communityId));
    return async.when(
      loading: () => const _InlineLoader(),
      error: (_, _) => _comingSoon(context, l10n),
      data: (hub) {
        // Self-gated: null hub = endpoint not deployed yet.
        if (hub == null) return _comingSoon(context, l10n);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommunitySectionLabel(l10n.communityRewardsGoalsTitle),
            if (hub.goals.isEmpty)
              _emptyLine(context, l10n.communityRewardsGoalsEmpty)
            else
              for (final g in hub.goals) _MemberGoalTile(goal: g),
            const SizedBox(height: KolabingSpacing.lg),
            CommunitySectionLabel(l10n.communityRewardsBadgesTitle),
            if (hub.badges.isEmpty)
              _emptyLine(context, l10n.communityRewardsBadgesEmpty)
            else
              _BadgeGrid(badges: hub.badges),
            const SizedBox(height: KolabingSpacing.lg),
            CommunitySectionLabel(l10n.communityRewardsRewardsTitle),
            if (hub.rewards.isEmpty)
              _emptyLine(context, l10n.communityRewardsRewardsEmpty)
            else
              for (final r in hub.rewards)
                _MemberRewardTile(communityId: communityId, reward: r),
          ],
        );
      },
    );
  }

  Widget _comingSoon(BuildContext context, AppLocalizations l10n) => Padding(
    padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.md),
    child: EmptyStateCard(
      icon: LucideIcons.gift,
      title: l10n.communityRewardsComingSoonTitle,
      message: l10n.communityRewardsComingSoonBody,
    ),
  );
}

class _MemberGoalTile extends StatelessWidget {
  const _MemberGoalTile({required this.goal});

  final CommunityGoal goal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
      child: CompactListCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  l10n.communityRewardsGoalReward(goal.rewardPoints),
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: KolabingSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.progressRatio,
                minHeight: 8,
                backgroundColor: context.colors.onSurfaceVariant.withValues(
                  alpha: 0.15,
                ),
                color: goal.isCompleted
                    ? context.colors.success
                    : context.colors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.communityRewardsGoalProgress(
                goal.progress ?? 0,
                goal.target,
              ),
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({required this.badges});

  final List<CommunityBadge> badges;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: KolabingSpacing.md,
      runSpacing: KolabingSpacing.md,
      children: [for (final b in badges) _BadgeChip(badge: b)],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});

  final CommunityBadge badge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final earned = badge.isEarned;
    final color = earned
        ? context.colors.onSurface
        : context.colors.onSurfaceVariant;
    return SizedBox(
      width: 88,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: earned
                  ? context.colors.primary.withValues(alpha: 0.2)
                  : context.colors.onSurfaceVariant.withValues(alpha: 0.1),
            ),
            child: Icon(
              earned ? LucideIcons.award : LucideIcons.lock,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge.title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 11,
              color: color,
            ),
          ),
          Text(
            earned
                ? l10n.communityRewardsBadgeEarned
                : l10n.communityRewardsBadgeLocked,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: earned
                  ? context.colors.success
                  : context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRewardTile extends ConsumerStatefulWidget {
  const _MemberRewardTile({required this.communityId, required this.reward});

  final String communityId;
  final CommunityReward reward;

  @override
  ConsumerState<_MemberRewardTile> createState() => _MemberRewardTileState();
}

class _MemberRewardTileState extends ConsumerState<_MemberRewardTile> {
  bool _busy = false;

  Future<void> _redeem() async {
    final l10n = AppLocalizations.of(context);
    final r = widget.reward;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.communityRewardsRedeemConfirmTitle),
        content: Text(
          l10n.communityRewardsRedeemConfirmBody(r.costPoints, r.title),
        ),
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
      ref
          .read(communityRewardsHubProvider(widget.communityId).notifier)
          .reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.communityRewardsRedeemedSnack)),
        );
      }
    } on CommunityException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
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
      child: CompactListCard(
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
                    ),
                  ),
                  if (r.description != null && r.description!.isNotEmpty)
                    Text(
                      r.description!,
                      style: KolabingTextStyles.bodySmall.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  Text(
                    r.stock == null
                        ? l10n.communityRewardsRewardCost(r.costPoints)
                        : '${l10n.communityRewardsRewardCost(r.costPoints)} · ${l10n.communityRewardsRewardStock(r.stock!)}',
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: KolabingSpacing.sm),
            FilledButton(
              onPressed: canRedeem ? _redeem : null,
              // The app's FilledButtonTheme sets minimumSize.width = infinity
              // (full-width form buttons). A Row measures its non-flex children
              // with an unbounded width, so that infinity claimed the whole row
              // and left the Expanded title 0px wide — the reward name then
              // wrapped one letter per line. Bound the button here.
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: context.colors.onPrimary,
                minimumSize: const Size(
                  0,
                  KolabingLayout.buttonHeightSecondary,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: KolabingSpacing.md,
                ),
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
// Rewards — LEADER view
// -----------------------------------------------------------------------------

class _RewardsLeaderSection extends ConsumerWidget {
  const _RewardsLeaderSection({required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(communityRewardsAdminProvider(communityId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _AddButton(
                icon: LucideIcons.target,
                label: l10n.communityRewardsAddGoal,
                onTap: () => showGoalEditor(context, communityId: communityId),
              ),
            ),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: _AddButton(
                icon: LucideIcons.gift,
                label: l10n.communityRewardsAddReward,
                onTap: () =>
                    showRewardEditor(context, communityId: communityId),
              ),
            ),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: _AddButton(
                icon: LucideIcons.award,
                label: l10n.communityRewardsAddBadge,
                onTap: () => showBadgeEditor(context, communityId: communityId),
              ),
            ),
          ],
        ),
        const SizedBox(height: KolabingSpacing.lg),

        // Goals
        CommunitySectionLabel(l10n.communityRewardsGoalsTitle),
        state.goals.when(
          loading: () => const _InlineLoader(),
          error: (e, _) => _emptyLine(context, e.toString()),
          data: (goals) => goals.isEmpty
              ? _emptyLine(context, l10n.communityRewardsGoalsEmpty)
              : Column(
                  children: [
                    for (final g in goals)
                      _LeaderGoalRow(communityId: communityId, goal: g),
                  ],
                ),
        ),
        const SizedBox(height: KolabingSpacing.lg),

        // Rewards
        CommunitySectionLabel(l10n.communityRewardsRewardsTitle),
        state.rewards.when(
          loading: () => const _InlineLoader(),
          error: (e, _) => _emptyLine(context, e.toString()),
          data: (rewards) => rewards.isEmpty
              ? _emptyLine(context, l10n.communityRewardsRewardsEmpty)
              : Column(
                  children: [
                    for (final r in rewards)
                      _LeaderRewardRow(communityId: communityId, reward: r),
                  ],
                ),
        ),
        const SizedBox(height: KolabingSpacing.lg),

        // Badges
        CommunitySectionLabel(l10n.communityRewardsBadgesTitle),
        state.badges.when(
          loading: () => const _InlineLoader(),
          error: (e, _) => _emptyLine(context, e.toString()),
          data: (badges) => badges.isEmpty
              ? _emptyLine(context, l10n.communityRewardsBadgesEmpty)
              : Column(
                  children: [
                    for (final b in badges)
                      _LeaderBadgeRow(communityId: communityId, badge: b),
                  ],
                ),
        ),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: context.colors.onSurface,
        padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.sm),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 2),
          Text(
            '+ $label',
            style: KolabingTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderRowShell extends StatelessWidget {
  const _LeaderRowShell({
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
      child: CompactListCard(
        onTap: onEdit,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.pencil, size: 16),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(
                LucideIcons.trash2,
                size: 16,
                color: context.colors.error,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderGoalRow extends ConsumerWidget {
  const _LeaderGoalRow({required this.communityId, required this.goal});

  final String communityId;
  final CommunityGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _LeaderRowShell(
      title: goal.title,
      subtitle:
          '${l10n.communityRewardsGoalReward(goal.rewardPoints)} · ${l10n.communityRewardsGoalProgress(0, goal.target)}',
      onEdit: () =>
          showGoalEditor(context, communityId: communityId, goal: goal),
      onDelete: () => _confirmDelete(context, l10n, goal.title, () async {
        await ref.read(communityRewardsServiceProvider).deleteGoal(goal.id);
        ref
            .read(communityRewardsAdminProvider(communityId).notifier)
            .reloadGoals();
      }),
    );
  }
}

class _LeaderRewardRow extends ConsumerWidget {
  const _LeaderRewardRow({required this.communityId, required this.reward});

  final String communityId;
  final CommunityReward reward;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _LeaderRowShell(
      title: reward.title,
      subtitle: l10n.communityRewardsRewardCost(reward.costPoints),
      onEdit: () =>
          showRewardEditor(context, communityId: communityId, reward: reward),
      onDelete: () => _confirmDelete(context, l10n, reward.title, () async {
        await ref.read(communityRewardsServiceProvider).deleteReward(reward.id);
        ref
            .read(communityRewardsAdminProvider(communityId).notifier)
            .reloadRewards();
      }),
    );
  }
}

class _LeaderBadgeRow extends ConsumerWidget {
  const _LeaderBadgeRow({required this.communityId, required this.badge});

  final String communityId;
  final CommunityBadge badge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _LeaderRowShell(
      title: badge.title,
      subtitle: l10n.communityBadgeValueLabel,
      onEdit: () =>
          showBadgeEditor(context, communityId: communityId, badge: badge),
      onDelete: () => _confirmDelete(context, l10n, badge.title, () async {
        await ref.read(communityRewardsServiceProvider).deleteBadge(badge.id);
        ref
            .read(communityRewardsAdminProvider(communityId).notifier)
            .reloadBadges();
      }),
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  AppLocalizations l10n,
  String title,
  Future<void> Function() onConfirm,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(l10n.communityRewardsDeleteTitle),
      content: Text(l10n.communityRewardsDeleteBody(title)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.rosterRemove),
        ),
      ],
    ),
  );
  if (confirm != true) return;
  try {
    await onConfirm();
  } on CommunityException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

// =============================================================================
// Members tab — roster grouped by tier
// =============================================================================

class _MembersTab extends ConsumerWidget {
  const _MembersTab({required this.community, required this.canManage});

  final Community community;
  final bool canManage;

  Future<void> _openTierEditor(BuildContext context, WidgetRef ref) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TierEditorScreen(communityId: community.id),
      ),
    );
    if (changed ?? false) {
      ref.read(communityManageProvider.notifier).reloadTiers();
      ref.invalidate(communityTiersProvider(community.id));
    }
  }

  Future<void> _editMember(
    BuildContext context,
    WidgetRef ref,
    CommunityMember member,
  ) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      builder: (_) =>
          MemberRosterEditSheet(communityId: community.id, member: member),
    );
    if (changed ?? false) {
      // Refresh both the community-scoped roster and the leader's manage roster
      // (the edit sheet mutates via the leader provider).
      ref.read(communityMembersByIdProvider(community.id).notifier).reload();
      ref.read(communityManageProvider.notifier).reloadMembers();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Community-scoped roster + tiers so the tab is correct for ANY community
    // the viewer is in (not only the leader's primary). The viewer's own
    // attendee profileId marks the ★ You row in member view.
    final membersAsync = ref.watch(communityMembersByIdProvider(community.id));
    final tiersAsync = ref.watch(communityTiersProvider(community.id));
    final myProfileId = ref
        .watch(authProvider)
        .user
        ?.attendeeProfile
        ?.profileId;

    return Column(
      children: [
        if (canManage)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KolabingSpacing.md,
              KolabingSpacing.sm,
              KolabingSpacing.md,
              0,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _openTierEditor(context, ref),
                icon: const Icon(LucideIcons.settings, size: 16),
                label: Text(l10n.communityDetailTiersAction),
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.onSurface,
                ),
              ),
            ),
          ),
        Expanded(
          child: membersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _TabMessage(
              icon: LucideIcons.alertCircle,
              title: l10n.communityMembersLoadError,
              // The backend message, when there is one — never the exception's
              // toString(), which rendered as
              // "CommunityException(null: You are not authorized...)".
              subtitle: e is CommunityException
                  ? e.message
                  : l10n.commonErrorGeneric,
            ),
            data: (members) {
              if (members.isEmpty) {
                return _TabMessage(
                  icon: LucideIcons.users,
                  title: l10n.communityMembersEmptyTitle,
                  subtitle: l10n.communityMembersEmptyBody,
                );
              }
              final tiers = tiersAsync.value ?? const <CommunityTier>[];
              final groups = _groupByTier(members, tiers);
              return RefreshIndicator(
                onRefresh: () async => ref
                    .read(communityMembersByIdProvider(community.id).notifier)
                    .reload(),
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    vertical: KolabingSpacing.sm,
                  ),
                  children: [
                    for (final group in groups) ...[
                      _TierSectionHeader(
                        name:
                            group.tierName ?? l10n.communityMembersGroupNoTier,
                        count: group.members.length,
                        color: group.color,
                      ),
                      for (final m in group.members)
                        _MemberRow(
                          member: m,
                          canManage: canManage,
                          isSelf:
                              !canManage &&
                              myProfileId != null &&
                              m.profileId == myProfileId,
                          onTap: canManage
                              ? () => _editMember(context, ref, m)
                              : null,
                        ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Group [members] by their tier, ordered by tier rank (high→low), with the
  /// "no tier" bucket (null tier OR a tier the roster doesn't know) last.
  List<_TierGroup> _groupByTier(
    List<CommunityMember> members,
    List<CommunityTier> tiers,
  ) {
    final byId = {for (final t in tiers) t.id: t};
    final ordered = <_TierGroup>[];
    final sortedTiers = [...tiers]..sort((a, b) => b.rank.compareTo(a.rank));
    for (final t in sortedTiers) {
      final list = members.where((m) => m.tierId == t.id).toList();
      if (list.isNotEmpty) {
        ordered.add(
          _TierGroup(tierName: t.name, color: _tierColor(t), members: list),
        );
      }
    }
    final untiered = members
        .where((m) => m.tierId == null || !byId.containsKey(m.tierId))
        .toList();
    if (untiered.isNotEmpty) {
      ordered.add(_TierGroup(tierName: null, color: null, members: untiered));
    }
    return ordered;
  }

  Color? _tierColor(CommunityTier t) {
    if (t.color == null) return null;
    try {
      return Color(int.parse(t.color!.replaceFirst('#', '0xff')));
    } catch (_) {
      return null;
    }
  }
}

class _TierGroup {
  const _TierGroup({
    required this.tierName,
    required this.color,
    required this.members,
  });

  final String? tierName;
  final Color? color;
  final List<CommunityMember> members;
}

class _TierSectionHeader extends StatelessWidget {
  const _TierSectionHeader({
    required this.name,
    required this.count,
    this.color,
  });

  final String name;
  final int count;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.sm,
      ),
      color: context.colors.surfaceContainerLow,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color ?? context.colors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Text(
            name.toUpperCase(),
            style: KolabingTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          Text(
            l10n.communityMembersTierCount(count),
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.canManage,
    required this.isSelf,
    this.onTap,
  });

  final CommunityMember member;
  final bool canManage;
  final bool isSelf;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: context.colors.surfaceContainerHigh,
        backgroundImage: member.memberAvatarUrl != null
            ? NetworkImage(member.memberAvatarUrl!)
            : null,
        child: member.memberAvatarUrl == null
            ? const Icon(LucideIcons.user, size: 18)
            : null,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              member.memberName ?? l10n.rosterMemberFallback,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KolabingTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isSelf) ...[
            const SizedBox(width: KolabingSpacing.xs),
            Text(
              l10n.communityMembersYou,
              style: KolabingTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface,
              ),
            ),
          ],
        ],
      ),
      trailing: canManage
          ? Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: context.colors.onSurfaceVariant,
            )
          : null,
    );
  }
}

// =============================================================================
// Events tab — cards with profile picture + visibility badge + view toggle
// =============================================================================

class _EventsSection extends ConsumerStatefulWidget {
  const _EventsSection({required this.community, required this.canManage});

  final Community community;

  /// Whether the viewer manages this community. Decides whether tapping an
  /// event opens it in leader mode — without it a leader reaching their own
  /// event from here got the member view, with no way to show its check-in QR.
  final bool canManage;

  @override
  ConsumerState<_EventsSection> createState() => _EventsSectionState();
}

class _EventsSectionState extends ConsumerState<_EventsSection> {
  CommunityEventFilter _filter = CommunityEventFilter.upcoming;

  static bool _isPublic(Event e) => (e.visibility ?? 'members') == 'public';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final id = widget.community.id;

    final upcomingAsync = ref.watch(communityUpcomingEventsProvider(id));
    final upcoming = upcomingAsync.maybeWhen(
      data: (e) => e,
      orElse: () => const <Event>[],
    );
    // Past events make a community between events look alive rather than
    // abandoned. The provider has existed since NF-6 and nothing called it.
    final past = ref
        .watch(communityPastEventsProvider(id))
        .maybeWhen(data: (e) => e, orElse: () => const <Event>[]);

    final counts = <CommunityEventFilter, int>{
      CommunityEventFilter.upcoming: upcoming.length,
      CommunityEventFilter.past: past.length,
      CommunityEventFilter.publicOnly: upcoming.where(_isPublic).length,
      CommunityEventFilter.membersOnly: upcoming
          .where((e) => !_isPublic(e))
          .length,
    };

    final shown = switch (_filter) {
      CommunityEventFilter.upcoming => upcoming,
      CommunityEventFilter.past => past,
      CommunityEventFilter.publicOnly => upcoming.where(_isPublic).toList(),
      CommunityEventFilter.membersOnly =>
        upcoming.where((e) => !_isPublic(e)).toList(),
    };

    if (upcomingAsync.isLoading && upcoming.isEmpty && past.isEmpty) {
      return const _InlineLoader();
    }
    // Nothing at all, ever — the honest empty state.
    if (upcoming.isEmpty && past.isEmpty) return const _NoEvents();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommunityFilterChips(
          counts: counts,
          selected: _filter,
          onSelect: (f) => setState(() => _filter = f),
        ),
        if (shown.isEmpty)
          _emptyLine(context, l10n.communityDetailNoEventsBody)
        else
          EventTimeline(
            events: shown,
            onOpen: (event) => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => EventDetailScreen.forEvent(
                  event,
                  isLeader: widget.canManage,
                ),
              ),
            ),
            onLocked: (_) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.communityDetailEventLockedSnack)),
            ),
          ),
      ],
    );
  }
}

class _NoEvents extends StatelessWidget {
  const _NoEvents();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.sm),
      child: EmptyStateCard(
        icon: LucideIcons.calendar,
        title: l10n.communityDetailNoEventsTitle,
        message: l10n.communityDetailNoEventsBody,
      ),
    );
  }
}

// =============================================================================
// Small shared widgets
// =============================================================================

Widget _emptyLine(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.sm),
  child: Text(
    text,
    style: KolabingTextStyles.bodySmall.copyWith(
      color: context.colors.onSurfaceVariant,
    ),
  ),
);

class _InlineLoader extends StatelessWidget {
  const _InlineLoader();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: KolabingSpacing.md),
    child: Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}

class _TabMessage extends StatelessWidget {
  const _TabMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(KolabingSpacing.xl),
      child: EmptyStateCard(icon: icon, title: title, message: subtitle),
    ),
  );
}
