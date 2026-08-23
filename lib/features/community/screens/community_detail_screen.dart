import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../config/constants/layout.dart';
import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/feature_flags.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/cards/kolabing_cards.dart';
import '../../auth/providers/auth_provider.dart';
import '../../event/models/event.dart';
import '../../event/providers/event_provider.dart';
import '../../event/screens/event_hub_screen.dart';
import '../models/community.dart';
import '../models/community_member.dart';
import '../models/community_membership.dart';
import '../models/community_rewards.dart';
import '../models/community_tier.dart';
import '../providers/community_providers.dart';
import '../providers/community_rewards_providers.dart';
import '../services/community_service.dart';
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
    this.initialTabIndex = 0,
    this.embedded = false,
  });

  final CommunityMembership membership;

  /// Which sub-tab to open on. Indices depend on [kCommunityMembersTabEnabled]:
  /// with Members shown it's (0 Rewards · 1 Members · 2 Events); with Members
  /// hidden it's (0 Rewards · 1 Events). The attendee community profile's
  /// "See all →" routes here on the Events tab via `_eventsTabIndex`.
  final int initialTabIndex;

  /// When rendered as a bottom-nav tab body (the leader's COMMUNITY tab) rather
  /// than a pushed route — suppresses the app-bar back button.
  final bool embedded;

  @override
  ConsumerState<CommunityDetailScreen> createState() =>
      _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends ConsumerState<CommunityDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  Community get _community => widget.membership.community;
  bool get _canManage => widget.membership.canManage;

  /// Members is a **manager** surface: `GET /communities/{id}/members` is gated
  /// on the `manage` ability and 403s for an ordinary member. Showing the tab
  /// to one only ever produced "You are not authorized to manage this
  /// community."
  bool get _showMembersTab => kCommunityMembersTabEnabled && _canManage;

  @override
  void initState() {
    super.initState();
    final tabCount = _showMembersTab ? 3 : 2;
    _tabs = TabController(
      length: tabCount,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, tabCount - 1),
    );
    // Refresh events + rewards on open so newly-granted tier content (or a new
    // event / goal) appears without a manual pull-to-refresh.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(communityUpcomingEventsProvider(_community.id).notifier)
          .reload();
      ref.read(communityRewardsHubProvider(_community.id).notifier).reload();
      // Only a manager may read the roster; firing this as a member is a
      // guaranteed 403.
      if (_showMembersTab) {
        ref.read(communityMembersByIdProvider(_community.id).notifier).reload();
      }
      if (_canManage) {
        ref
            .read(communityRewardsAdminProvider(_community.id).notifier)
            .reloadAll();
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  /// Open the chat inbox; the backend role-scopes the threads. Reuses the
  /// existing `/chats` navigation (the former Chats tab pointed at the same
  /// thread list).
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
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: Text(c.name),
        actions: [
          // Chats → opens the chat screen for this community.
          IconButton(
            icon: const Icon(LucideIcons.messageCircle),
            tooltip: l10n.communityDetailChatsAction,
            onPressed: _openChats,
          ),
          // Self-gated: only show Share invite when we have a usable link.
          if (c.shareInviteUrl != null)
            IconButton(
              icon: const Icon(LucideIcons.share2),
              tooltip: l10n.communityShareInvite,
              onPressed: _shareInvite,
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          // App bar is yellow; force dark labels/indicator so the SELECTED tab
          // isn't yellow-on-yellow (brand rule: black text on yellow).
          labelColor: context.colors.onSurface,
          unselectedLabelColor: context.colors.onSurface.withValues(alpha: 0.6),
          indicatorColor: context.colors.onSurface,
          tabs: [
            Tab(text: l10n.communityDetailTabRewards),
            if (_showMembersTab) Tab(text: l10n.communityDetailTabMembers),
            Tab(text: l10n.communityDetailTabEvents),
          ],
        ),
      ),
      body: Column(
        children: [
          _Header(membership: widget.membership, onChats: _openChats),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _RewardsTab(communityId: c.id, canManage: _canManage),
                if (_showMembersTab)
                  _MembersTab(community: c, canManage: _canManage),
                _EventsTab(communityId: c.id, canManage: _canManage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Header (logo + name + type + member count + Chats action)
// -----------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.membership, required this.onChats});

  final CommunityMembership membership;
  final VoidCallback onChats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = membership.community;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(bottom: BorderSide(color: context.colors.hairline)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: context.colors.primary.withValues(alpha: 0.2),
            backgroundImage: c.avatarUrl != null
                ? NetworkImage(c.avatarUrl!)
                : null,
            child: c.avatarUrl == null
                ? Icon(LucideIcons.flag, color: context.colors.onSurface)
                : null,
          ),
          const SizedBox(width: KolabingSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: KolabingTextStyles.bodyLarge.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.communityDetailTypeAndMembers(
                    c.type.displayName,
                    c.memberCount ?? 0,
                  ),
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onChats,
            icon: const Icon(LucideIcons.messageCircle, size: 16),
            label: Text(l10n.communityDetailChatsAction),
            style: TextButton.styleFrom(
              foregroundColor: context.colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Rewards tab
// =============================================================================

class _RewardsTab extends ConsumerWidget {
  const _RewardsTab({required this.communityId, required this.canManage});

  final String communityId;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return canManage
        ? _RewardsLeaderView(communityId: communityId)
        : _RewardsMemberView(communityId: communityId);
  }
}

// -----------------------------------------------------------------------------
// Rewards — MEMBER view
// -----------------------------------------------------------------------------

class _RewardsMemberView extends ConsumerWidget {
  const _RewardsMemberView({required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(communityRewardsHubProvider(communityId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _comingSoon(context, l10n),
      data: (hub) {
        // Self-gated: null hub = endpoint not deployed yet.
        if (hub == null) return _comingSoon(context, l10n);
        return RefreshIndicator(
          onRefresh: () => ref
              .read(communityRewardsHubProvider(communityId).notifier)
              .reload(),
          child: ListView(
            padding: const EdgeInsets.all(KolabingSpacing.md),
            children: [
              _PointsCard(points: hub.myPoints, tierName: hub.myTierName),
              const SizedBox(height: KolabingSpacing.lg),
              _SectionLabel(l10n.communityRewardsGoalsTitle),
              if (hub.goals.isEmpty)
                _emptyLine(context, l10n.communityRewardsGoalsEmpty)
              else
                for (final g in hub.goals) _MemberGoalTile(goal: g),
              const SizedBox(height: KolabingSpacing.lg),
              _SectionLabel(l10n.communityRewardsBadgesTitle),
              if (hub.badges.isEmpty)
                _emptyLine(context, l10n.communityRewardsBadgesEmpty)
              else
                _BadgeGrid(badges: hub.badges),
              const SizedBox(height: KolabingSpacing.lg),
              _SectionLabel(l10n.communityRewardsRewardsTitle),
              if (hub.rewards.isEmpty)
                _emptyLine(context, l10n.communityRewardsRewardsEmpty)
              else
                for (final r in hub.rewards)
                  _MemberRewardTile(communityId: communityId, reward: r),
            ],
          ),
        );
      },
    );
  }

  Widget _comingSoon(BuildContext context, AppLocalizations l10n) => Center(
    child: Padding(
      padding: const EdgeInsets.all(KolabingSpacing.xl),
      child: EmptyStateCard(
        icon: LucideIcons.gift,
        title: l10n.communityRewardsComingSoonTitle,
        message: l10n.communityRewardsComingSoonBody,
      ),
    ),
  );
}

class _PointsCard extends StatelessWidget {
  const _PointsCard({required this.points, this.tierName});

  final int points;
  final String? tierName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(KolabingRadius.lg),
        border: Border.all(
          color: context.colors.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.star, color: context.colors.onSurface),
          const SizedBox(width: KolabingSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.communityRewardsPointsLabel,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  l10n.communityMembersPoints(points),
                  style: KolabingTextStyles.bodyLarge.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.communityRewardsTierLabel,
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              Text(
                tierName ?? l10n.communityRewardsNoTier,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
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

class _RewardsLeaderView extends ConsumerWidget {
  const _RewardsLeaderView({required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(communityRewardsAdminProvider(communityId));
    return RefreshIndicator(
      onRefresh: () => ref
          .read(communityRewardsAdminProvider(communityId).notifier)
          .reloadAll(),
      child: ListView(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        children: [
          Row(
            children: [
              Expanded(
                child: _AddButton(
                  icon: LucideIcons.target,
                  label: l10n.communityRewardsAddGoal,
                  onTap: () =>
                      showGoalEditor(context, communityId: communityId),
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
                  onTap: () =>
                      showBadgeEditor(context, communityId: communityId),
                ),
              ),
            ],
          ),
          const SizedBox(height: KolabingSpacing.lg),

          // Goals
          _SectionLabel(l10n.communityRewardsGoalsTitle),
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
          _SectionLabel(l10n.communityRewardsRewardsTitle),
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
          _SectionLabel(l10n.communityRewardsBadgesTitle),
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
      ),
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

class _EventsTab extends ConsumerWidget {
  const _EventsTab({required this.communityId, required this.canManage});

  final String communityId;

  /// Whether the viewer manages this community. Decides whether tapping an
  /// event opens the hub in leader mode — without it a leader reaching their
  /// own event from here got the member view, with no way to show the event's
  /// check-in QR.
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(communityUpcomingEventsProvider(communityId));
    // No my-view/attendee-view toggle: a leader can access every event, so an
    // "attendee preview" filters nothing and renders identically. Each card
    // carries an always-on visibility badge (Public/Members/Tier), which is the
    // information that preview was meant to convey.
    Future<void> reload() => ref
        .read(communityUpcomingEventsProvider(communityId).notifier)
        .reload();
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _TabMessage(
        icon: LucideIcons.calendar,
        title: l10n.communityDetailNoEventsTitle,
        subtitle: l10n.communityDetailNoEventsBody,
      ),
      data: (events) {
        if (events.isEmpty) {
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              children: [
                const SizedBox(height: 120),
                _TabMessage(
                  icon: LucideIcons.calendar,
                  title: l10n.communityDetailNoEventsTitle,
                  subtitle: l10n.communityDetailNoEventsBody,
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: reload,
          child: ListView.builder(
            padding: const EdgeInsets.all(KolabingSpacing.md),
            itemCount: events.length,
            itemBuilder: (_, i) =>
                _EventCard(event: events[i], canManage: canManage),
          ),
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.canManage});

  final Event event;

  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locked = !event.canAccess;
    final muted = context.colors.onSurfaceVariant;
    final pictureUrl = event.coverPhotoUrl ?? event.partner.profilePhoto;
    return Padding(
      padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
      child: CompactListCard(
        onTap: locked
            ? () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.communityDetailEventLockedSnack)),
              )
            : () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      EventHubScreen(event: event, isLeader: canManage),
                ),
              ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(KolabingRadius.md),
              child: SizedBox(
                width: 56,
                height: 56,
                child: pictureUrl != null
                    ? Image.network(
                        pictureUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _eventPlaceholder(context, locked),
                      )
                    : _eventPlaceholder(context, locked),
              ),
            ),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: locked ? muted : context.colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    locked
                        ? l10n.communityDetailEventLockedSubtitle
                        : event.formattedDate,
                    style: KolabingTextStyles.bodySmall.copyWith(color: muted),
                  ),
                  const SizedBox(height: KolabingSpacing.xs),
                  _VisibilityBadge(visibility: event.visibility),
                ],
              ),
            ),
            Icon(
              locked ? LucideIcons.lock : LucideIcons.chevronRight,
              size: 18,
              color: locked ? muted : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventPlaceholder(BuildContext context, bool locked) => Container(
    color: context.colors.surfaceContainerHigh,
    child: Icon(
      locked ? LucideIcons.lock : LucideIcons.calendar,
      size: 20,
      color: context.colors.onSurfaceVariant,
    ),
  );
}

class _VisibilityBadge extends StatelessWidget {
  const _VisibilityBadge({this.visibility});

  final String? visibility;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Null visibility = legacy events default to "members" per the backend.
    final value = visibility ?? 'members';
    final (label, icon) = switch (value) {
      'public' => (l10n.communityEventVisibilityPublic, LucideIcons.globe),
      'tier' => (l10n.communityEventVisibilityTier, LucideIcons.layers),
      _ => (l10n.communityEventVisibilityMembers, LucideIcons.users),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: context.colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Small shared widgets
// =============================================================================

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
    child: Text(
      text.toUpperCase(),
      style: KolabingTextStyles.bodySmall.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: context.colors.onSurfaceVariant,
      ),
    ),
  );
}

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
