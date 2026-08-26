/// The leader's view of a community's reward programme: goals, rewards, badges,
/// each with add / edit / delete.
///
/// Extracted from `community_detail_screen.dart`, where it was private to the
/// Rewards tab. That was the whole reason the merged profile page's Manage →
/// Rewards row pointed at the old Community page: the only way to reach this UI
/// was to open that screen and land on the right tab. It is a widget now, so
/// [CommunityRewardsAdminScreen] can host it directly and the detail screen
/// keeps using the same one — one implementation, two entry points.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/cards/kolabing_cards.dart';
import '../models/community_rewards.dart';
import '../providers/community_rewards_providers.dart';
import '../services/community_rewards_service.dart';
import '../services/community_service.dart';
import 'community_page_sections.dart';
import 'community_rewards_editor_sheets.dart';

class CommunityRewardsAdminPanel extends ConsumerWidget {
  const CommunityRewardsAdminPanel({super.key, required this.communityId});

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

        // Goals earn the points, so they come first.
        _List<CommunityGoal>(
          title: l10n.communityRewardsGoalsTitle,
          value: state.goals,
          emptyText: l10n.communityRewardsGoalsEmpty,
          rowTitle: (g) => g.title,
          // The old row rendered `progress 0 / target`, a zero it invented on
          // every goal. A leader is setting the target, so name the target.
          rowMeta: (g) =>
              '${l10n.communityRewardsGoalReward(g.rewardPoints)} · '
              '${l10n.communityRewardsGoalTarget(g.target)}',
          isActive: (g) => g.isActive,
          onEdit: (g) =>
              showGoalEditor(context, communityId: communityId, goal: g),
          onDelete: (g) => _confirmDelete(
            context,
            ref,
            title: g.title,
            delete: (svc) => svc.deleteGoal(g.id),
          ),
        ),
        const SizedBox(height: KolabingSpacing.lg),

        // Rewards spend them.
        _List<CommunityReward>(
          title: l10n.communityRewardsRewardsTitle,
          value: state.rewards,
          emptyText: l10n.communityRewardsRewardsEmpty,
          rowTitle: (r) => r.title,
          rowMeta: (r) => r.stock == null
              ? l10n.communityRewardsRewardCost(r.costPoints)
              : '${l10n.communityRewardsRewardCost(r.costPoints)} · '
                    '${l10n.communityRewardsRewardStock(r.stock!)}',
          isActive: (r) => r.isActive,
          onEdit: (r) =>
              showRewardEditor(context, communityId: communityId, reward: r),
          onDelete: (r) => _confirmDelete(
            context,
            ref,
            title: r.title,
            delete: (svc) => svc.deleteReward(r.id),
          ),
        ),
        const SizedBox(height: KolabingSpacing.lg),

        // Badges mark what someone did.
        _List<CommunityBadge>(
          title: l10n.communityRewardsBadgesTitle,
          value: state.badges,
          emptyText: l10n.communityRewardsBadgesEmpty,
          rowTitle: (b) => b.title,
          // Was the bare word "Value" under every badge, identical for all of
          // them — the number is the part that distinguishes one badge.
          rowMeta: (b) => l10n.communityRewardsBadgeCriteria(b.criteriaValue),
          isActive: (b) => b.isActive,
          onEdit: (b) =>
              showBadgeEditor(context, communityId: communityId, badge: b),
          onDelete: (b) => _confirmDelete(
            context,
            ref,
            title: b.title,
            delete: (svc) => svc.deleteBadge(b.id),
          ),
        ),
      ],
    );
  }

  /// Confirm, delete, then reload all three lists.
  ///
  /// Reloading everything rather than the one list is deliberate: deleting a
  /// goal can change what a badge or reward is reachable through, and one extra
  /// request is cheaper than a stale row.
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required Future<void> Function(CommunityRewardsService) delete,
  }) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.communityRewardsDeleteTitle),
        content: Text(l10n.communityRewardsDeleteBody(title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            // The old dialog confirmed a delete with "Remove"
            // (`rosterRemove`), borrowed from the member roster.
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final notifier = ref.read(
      communityRewardsAdminProvider(communityId).notifier,
    );
    try {
      await delete(ref.read(communityRewardsServiceProvider));
      await notifier.reloadAll();
    } on CommunityException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on Object catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.communityRewardsDeleteFailed)),
      );
    }
  }
}

/// One programme section: its label, then its rows.
///
/// Loading and error are per-section because the three lists are three separate
/// requests — one failing should not blank the other two.
class _List<T> extends StatelessWidget {
  const _List({
    required this.title,
    required this.value,
    required this.emptyText,
    required this.rowTitle,
    required this.rowMeta,
    required this.isActive,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final AsyncValue<List<T>> value;
  final String emptyText;
  final String Function(T) rowTitle;
  final String Function(T) rowMeta;
  final bool Function(T) isActive;
  final void Function(T) onEdit;
  final void Function(T) onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommunitySectionLabel(title),
        value.when(
          loading: () => const _InlineLoader(),
          // Was `e.toString()` — a raw exception in front of the user.
          error: (_, _) => _Line(text: l10n.communityRewardsLoadFailed),
          data: (items) => items.isEmpty
              ? _Line(text: emptyText)
              : Column(
                  children: [
                    for (final item in items)
                      _Row(
                        title: rowTitle(item),
                        meta: rowMeta(item),
                        isActive: isActive(item),
                        onEdit: () => onEdit(item),
                        onDelete: () => onDelete(item),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.meta,
    required this.isActive,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String meta;
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KolabingTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      // A paused item used to look exactly like a live one, so
                      // there was no way to tell from this list what members
                      // could actually see.
                      if (!isActive) ...[
                        const SizedBox(width: KolabingSpacing.xs),
                        _PausedPill(label: l10n.communityRewardsPaused),
                      ],
                    ],
                  ),
                  Text(
                    meta,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.pencil, size: 16),
              tooltip: l10n.myOpportunityCardActionEdit,
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(
                LucideIcons.trash2,
                size: 16,
                color: context.colors.error,
              ),
              tooltip: l10n.commonDelete,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _PausedPill extends StatelessWidget {
  const _PausedPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: KolabingSpacing.xs,
      vertical: 1,
    ),
    decoration: BoxDecoration(
      color: context.colors.surfaceVariant,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label.toUpperCase(),
      style: KolabingTextStyles.labelSmall.copyWith(
        fontWeight: FontWeight.w700,
        color: context.colors.onSurfaceVariant,
      ),
    ),
  );
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
  Widget build(BuildContext context) => OutlinedButton(
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

class _Line extends StatelessWidget {
  const _Line({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.sm),
    child: Text(
      text,
      style: KolabingTextStyles.bodySmall.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    ),
  );
}

class _InlineLoader extends StatelessWidget {
  const _InlineLoader();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.md),
    child: Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: context.colors.primary,
        ),
      ),
    ),
  );
}
