import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../chat/models/chat_thread.dart';
import '../../chat/providers/chat_providers.dart';
import '../../chat/screens/chat_thread_screen.dart';
import '../../chat/services/chat_service.dart';
import '../../event/providers/event_provider.dart';
import '../../event/screens/create_event_screen.dart';
import '../../event/screens/event_detail_screen.dart';
import '../../gamification/screens/community_challenges_screen.dart';
import '../models/community.dart';
import '../models/community_member.dart';
import '../models/community_tier.dart';
import '../providers/community_providers.dart';
import '../services/community_service.dart';
import 'create_community_screen.dart';
import 'roster_screen.dart';
import 'tier_editor_screen.dart';

/// The Community Leader's "Community" tab.
///
/// Reads [communityManageProvider]:
/// - none yet  → create-your-community empty state
/// - one       → its overview (header + tiers + roster preview)
/// - more (NF-7 Premium) → a picker; for now shows the first.
class CommunityHubScreen extends ConsumerWidget {
  const CommunityHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(communityManageProvider).communities;
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(
        message: e.toString(),
        onRetry: () => ref.read(communityManageProvider.notifier).loadAll(),
      ),
      data: (communities) {
        if (communities.isEmpty) {
          // Pull-to-refresh so a stale empty result can always recover.
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(communityManageProvider.notifier).reloadCommunities(),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: _EmptyState(onCreate: () => _openCreate(context, ref)),
                ),
              ),
            ),
          );
        }
        return _CommunityOverview(community: communities.first);
      },
    );
  }

  Future<void> _openCreate(BuildContext context, WidgetRef ref) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateCommunityScreen()),
    );
    if (created ?? false) {
      await ref.read(communityManageProvider.notifier).reloadCommunities();
    }
  }
}

// -----------------------------------------------------------------------------
// Empty state
// -----------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.users,
                size: 32,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: KolabingSpacing.lg),
            Text(
              l10n.communityHubEmptyTitle,
              style: KolabingTextStyles.bodyLarge.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              l10n.communityHubEmptyBody,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onCreate,
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.onPrimary,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(l10n.communityHubCreateCommunity),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Single-community overview
// -----------------------------------------------------------------------------

class _CommunityOverview extends ConsumerWidget {
  const _CommunityOverview({required this.community});

  final Community community;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(communityManageProvider.notifier).reloadCommunities(),
      child: ListView(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        children: [
          _Header(community: community),
          const SizedBox(height: KolabingSpacing.lg),
          _SectionLabel(l10n.communityHubSectionTiers),
          const SizedBox(height: KolabingSpacing.sm),
          _TiersSection(communityId: community.id),
          const SizedBox(height: KolabingSpacing.lg),
          _SectionLabel(l10n.communityHubSectionMembers),
          const SizedBox(height: KolabingSpacing.sm),
          _MembersPreview(communityId: community.id),
          const SizedBox(height: KolabingSpacing.lg),
          // Which challenges this community plays (#150). Above Events on
          // purpose: it is a standing decision about what the community is for,
          // not a per-event one.
          Card(
            margin: const EdgeInsets.only(bottom: KolabingSpacing.sm),
            child: ListTile(
              leading: Icon(
                LucideIcons.listChecks,
                color: context.colors.onSurface,
              ),
              title: Text(
                l10n.communityChallengesTitle,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                l10n.communityChallengesHubSubtitle,
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              trailing: const Icon(LucideIcons.chevronRight, size: 18),
              onTap: () => CommunityChallengesScreen.open(
                context,
                communityId: community.id,
                communityName: community.name,
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.lg),
          _SectionLabel(l10n.communityHubSectionEvents),
          const SizedBox(height: KolabingSpacing.sm),
          _EventsSection(
            communityId: community.id,
            communityName: community.name,
          ),
          const SizedBox(height: KolabingSpacing.lg),
          _SectionLabel(l10n.communityHubSectionChats),
          const SizedBox(height: KolabingSpacing.sm),
          _ChatsSection(communityId: community.id),
        ],
      ),
    );
  }
}

/// This community's upcoming events (Phase-3 `GET /events?community_id&time=
/// upcoming`). Read-only list for now; create/RSVP/event-chat come next. Errors
/// (e.g. backend filter not deployed) degrade to an empty state.
class _EventsSection extends ConsumerWidget {
  const _EventsSection({
    required this.communityId,
    required this.communityName,
  });

  final String communityId;
  final String communityName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(communityUpcomingEventsProvider(communityId));
    final content = async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: KolabingSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const _EventsEmpty(),
      data: (events) {
        if (events.isEmpty) return const _EventsEmpty();
        return Column(
          children: [
            for (final e in events)
              Card(
                margin: const EdgeInsets.only(bottom: KolabingSpacing.sm),
                child: ListTile(
                  leading: Icon(
                    LucideIcons.calendar,
                    color: context.colors.onSurface,
                  ),
                  title: Text(
                    e.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    e.formattedDate,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (e.isRecurring)
                        Icon(
                          LucideIcons.repeat,
                          size: 14,
                          color: context.colors.onSurfaceVariant,
                        ),
                      if (e.isRecurring)
                        const SizedBox(width: KolabingSpacing.xs),
                      const Icon(LucideIcons.chevronRight, size: 18),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => EventDetailScreen.forEvent(
                          e,
                          isLeader: true,
                          communityName: communityName,
                        ),
                      ),
                    );
                    ref
                        .read(
                          communityUpcomingEventsProvider(communityId).notifier,
                        )
                        .reload();
                  },
                ),
              ),
          ],
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        content,
        const SizedBox(height: KolabingSpacing.sm),
        OutlinedButton.icon(
          onPressed: () async {
            final created = await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (_) => CreateEventScreen(
                  communityId: communityId,
                  communityName: communityName,
                ),
              ),
            );
            if (created == true) {
              ref
                  .read(communityUpcomingEventsProvider(communityId).notifier)
                  .reload();
            }
          },
          icon: const Icon(LucideIcons.plus, size: 18),
          label: Text(AppLocalizations.of(context).communityHubCreateEvent),
        ),
      ],
    );
  }
}

class _EventsEmpty extends StatelessWidget {
  const _EventsEmpty();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.md),
    child: Text(
      AppLocalizations.of(context).communityHubNoEvents,
      style: KolabingTextStyles.bodySmall.copyWith(
        color: context.colors.onSurfaceVariant,
      ),
    ),
  );
}

/// Community chats (main + up to 5 custom). Lists this community's chat threads
/// and lets the leader create custom ones (≤5). Backend: POST
/// /communities/{id}/chats (NF-CHAT Phase 2) — until it ships, create errors
/// gracefully.
class _ChatsSection extends ConsumerWidget {
  const _ChatsSection({required this.communityId});

  final String communityId;

  static const _maxCustom = 5;

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.communityHubNewChatTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: l10n.communityHubChatNameLabel,
            hintText: l10n.communityHubChatNameHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.communityHubCreate),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await ref
          .read(chatServiceProvider)
          .createCommunityChat(communityId, name: name);
      ref.read(chatThreadsProvider.notifier).reload();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.communityHubChatCreated(name))),
        );
      }
    } on ChatException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.isChatLimitReached
                  ? l10n.communityHubChatLimit(_maxCustom)
                  : e.message,
            ),
          ),
        );
      }
    }
  }

  /// Short summary of who can currently open a custom chat, by tier count.
  /// (Owners/managers always have access; this counts member tiers granted.)
  static String _accessLabel(
    AppLocalizations l10n,
    ChatThread thread,
    List<CommunityTier> tiers,
  ) {
    final slug = thread.slug;
    if (slug == null || tiers.isEmpty) return l10n.communityHubAccess;
    final granted = tiers
        .where((t) => t.permissions.chatChannels.contains(slug))
        .length;
    if (granted == 0) return l10n.communityHubAccessNoTiers;
    if (granted == tiers.length) return l10n.communityHubAccessAllTiers;
    return granted == 1
        ? l10n.communityHubAccessOneTier
        : l10n.communityHubAccessTierCount(granted);
  }

  /// Per-chat tier gating: pick which member tiers can open this custom chat.
  /// Writes the chat's slug into each selected tier's permissions.chat_channels
  /// (and removes it from the deselected ones).
  Future<void> _manageAccess(
    BuildContext context,
    WidgetRef ref,
    ChatThread thread,
    List<CommunityTier> tiers,
  ) async {
    final l10n = AppLocalizations.of(context);
    final slug = thread.slug;
    if (slug == null) return;
    if (tiers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.communityHubCreateTiersFirst)),
      );
      return;
    }

    final selected = {
      for (final t in tiers) t.id: t.permissions.chatChannels.contains(slug),
    };

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocal) => AlertDialog(
          title: Text(
            l10n.communityHubAccessDialogTitle(
              thread.name ?? l10n.communityHubAccessDialogChat,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
                  child: Text(
                    l10n.communityHubAccessDialogBody,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
                for (final t in tiers)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: selected[t.id] ?? false,
                    title: Text(t.name),
                    onChanged: (v) =>
                        setLocal(() => selected[t.id] = v ?? false),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;

    final svc = ref.read(communityServiceProvider);
    try {
      for (final t in tiers) {
        final has = t.permissions.chatChannels.contains(slug);
        final want = selected[t.id] ?? false;
        if (has == want) continue;
        final next = [...t.permissions.chatChannels];
        want ? next.add(slug) : next.remove(slug);
        await svc.updateTier(
          t.id,
          permissions: t.permissions.copyWith(chatChannels: next),
        );
      }
      await ref.read(communityManageProvider.notifier).reloadTiers();
      ref.read(chatThreadsProvider.notifier).reload();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.communityHubChatAccessUpdated)),
        );
      }
    } on CommunityException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(chatThreadsProvider);
    final tiers =
        ref.watch(communityManageProvider).tiers.asData?.value ?? const [];
    return async.when(
      loading: () => const _InlineLoader(),
      error: (e, _) => _InlineError(message: e.toString()),
      data: (threads) {
        final mine = threads
            .where((t) => t.communityId == communityId && t.type.isCommunity)
            .toList();
        final customCount = mine
            .where((t) => t.type == ChatThreadType.communityCustom)
            .length;
        return Column(
          children: [
            if (mine.isEmpty)
              _InlineHint(
                icon: LucideIcons.messageCircle,
                text: l10n.communityHubNoChatsHint(_maxCustom),
              )
            else
              for (final t in mine)
                _ChatRow(
                  thread: t,
                  onManageAccess:
                      t.type == ChatThreadType.communityCustom && t.slug != null
                      ? () => _manageAccess(context, ref, t, tiers)
                      : null,
                  accessLabel: t.type == ChatThreadType.communityCustom
                      ? _accessLabel(l10n, t, tiers)
                      : null,
                ),
            const SizedBox(height: KolabingSpacing.xs),
            if (customCount < _maxCustom)
              _AddTile(
                label: l10n.communityHubCreateChat,
                onTap: () => _create(context, ref),
              )
            else
              _InlineHint(
                icon: LucideIcons.lock,
                text: l10n.communityHubChatLimitReached(_maxCustom),
              ),
          ],
        );
      },
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.thread, this.onManageAccess, this.accessLabel});

  final ChatThread thread;

  /// Custom chats only: opens the "who can access" tier picker. Null for the
  /// main chat (always all members) and member-facing views.
  final VoidCallback? onManageAccess;

  /// Short summary of current access, e.g. "All", "2 tiers".
  final String? accessLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isMain = thread.type == ChatThreadType.communityMain;
    return Padding(
      padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
      child: Material(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => ChatThreadScreen(thread: thread),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.md,
              vertical: KolabingSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(
                  isMain ? LucideIcons.hash : LucideIcons.messageCircle,
                  size: 16,
                  color: context.colors.onSurfaceVariant,
                ),
                const SizedBox(width: KolabingSpacing.sm),
                Expanded(
                  child: Text(
                    thread.name ??
                        (isMain
                            ? l10n.communityHubChatMain
                            : l10n.communityHubChatFallback),
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isMain) _Chip(label: l10n.communityHubChipMain),
                if (!isMain && onManageAccess != null)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: onManageAccess,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: KolabingSpacing.xs,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.lock,
                              size: 13,
                              color: context.colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              accessLabel ?? l10n.communityHubAccess,
                              style: KolabingTextStyles.bodySmall.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (thread.hasUnread) ...[
                  const SizedBox(width: KolabingSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${thread.unreadCount}',
                      style: KolabingTextStyles.bodySmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: context.colors.onPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.community});

  final Community community;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: context.colors.primary.withValues(alpha: 0.2),
            backgroundImage: community.avatarUrl != null
                ? NetworkImage(community.avatarUrl!)
                : null,
            child: community.avatarUrl == null
                ? Icon(LucideIcons.users, color: context.colors.onSurface)
                : null,
          ),
          const SizedBox(width: KolabingSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  community.name,
                  style: KolabingTextStyles.bodyLarge.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  community.memberCount != null
                      ? AppLocalizations.of(context).communityHubTypeAndMembers(
                          community.type.displayName,
                          community.memberCount!,
                        )
                      : community.type.displayName,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            community.joinPolicy.allowsSelfJoin
                ? LucideIcons.globe
                : LucideIcons.lock,
            size: 18,
            color: context.colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _TiersSection extends ConsumerWidget {
  const _TiersSection({required this.communityId});

  final String communityId;

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    CommunityTier? tier,
  }) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TierEditorScreen(communityId: communityId, tier: tier),
      ),
    );
    if (changed ?? false) {
      await ref.read(communityManageProvider.notifier).reloadTiers();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(communityManageProvider).tiers;
    return async.when(
      loading: () => const _InlineLoader(),
      error: (e, _) => _InlineError(message: e.toString()),
      data: (tiers) {
        if (tiers.isEmpty) {
          return Column(
            children: [
              _InlineHint(
                icon: LucideIcons.layers,
                text: l10n.communityHubNoTiersHint,
              ),
              const SizedBox(height: KolabingSpacing.sm),
              _AddTile(
                label: l10n.communityHubAddTier,
                onTap: () => _openEditor(context, ref),
              ),
            ],
          );
        }
        return Column(
          children: [
            for (final t in tiers)
              _TierRow(
                tier: t,
                onTap: () => _openEditor(context, ref, tier: t),
              ),
            const SizedBox(height: KolabingSpacing.xs),
            _AddTile(
              label: l10n.communityHubAddTier,
              onTap: () => _openEditor(context, ref),
            ),
          ],
        );
      },
    );
  }
}

class _TierRow extends StatelessWidget {
  const _TierRow({required this.tier, this.onTap});

  final CommunityTier tier;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Color dot;
    try {
      dot = tier.color != null
          ? Color(int.parse(tier.color!.replaceFirst('#', '0xff')))
          : context.colors.primary;
    } catch (_) {
      dot = context.colors.primary;
    }
    final detail = tier.assignmentRule.isAutomatic && tier.threshold != null
        ? l10n.communityHubTierDetail(
            tier.assignmentRule.displayName,
            tier.threshold!,
            tier.assignmentRule.thresholdUnit,
          )
        : tier.assignmentRule.displayName;
    return Padding(
      padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
      child: Material(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.md,
              vertical: KolabingSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: KolabingSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            tier.name,
                            style: KolabingTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (tier.isDefault) ...[
                            const SizedBox(width: KolabingSpacing.xs),
                            _Chip(label: l10n.communityHubChipDefault),
                          ],
                        ],
                      ),
                      Text(
                        detail,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          fontSize: 12,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.communityHubTierRank(tier.rank),
                  style: KolabingTextStyles.bodySmall.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: KolabingSpacing.xs),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: context.colors.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A dashed "add" affordance used under the Tiers / Members sections.
class _AddTile extends StatelessWidget {
  const _AddTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.md,
          vertical: KolabingSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.colors.outline,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.plus, size: 16, color: context.colors.onSurface),
            const SizedBox(width: KolabingSpacing.xs),
            Text(
              label,
              style: KolabingTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MembersPreview extends ConsumerWidget {
  const _MembersPreview({required this.communityId});

  final String communityId;

  Future<void> _openRoster(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => RosterScreen(communityId: communityId),
      ),
    );
    await ref.read(communityManageProvider.notifier).reloadMembers();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(communityManageProvider).members;
    return async.when(
      loading: () => const _InlineLoader(),
      error: (e, _) => _InlineError(message: e.toString()),
      data: (members) {
        if (members.isEmpty) {
          return Column(
            children: [
              _InlineHint(
                icon: LucideIcons.userPlus,
                text: l10n.communityHubNoMembersHint,
              ),
              const SizedBox(height: KolabingSpacing.sm),
              _AddTile(
                label: l10n.communityHubManageMembers,
                onTap: () => _openRoster(context, ref),
              ),
            ],
          );
        }
        final preview = members.take(5).toList();
        return Column(
          children: [
            for (final m in preview) _MemberRow(member: m),
            const SizedBox(height: KolabingSpacing.xs),
            _AddTile(
              label: members.length > preview.length
                  ? l10n.communityHubManageAllMembers(members.length)
                  : l10n.communityHubManageMembers,
              onTap: () => _openRoster(context, ref),
            ),
          ],
        );
      },
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member});

  final CommunityMember member;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xs),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: context.colors.surfaceContainerHigh,
            backgroundImage: member.memberAvatarUrl != null
                ? NetworkImage(member.memberAvatarUrl!)
                : null,
            child: member.memberAvatarUrl == null
                ? const Icon(LucideIcons.user, size: 16)
                : null,
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: Text(
              member.memberName ?? l10n.communityHubMemberFallback,
              style: KolabingTextStyles.bodyMedium,
            ),
          ),
          if (member.canManage) ...[
            _Chip(label: l10n.communityHubChipAdmin),
            const SizedBox(width: KolabingSpacing.xs),
          ],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Small shared bits
// -----------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: KolabingTextStyles.bodySmall.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: context.colors.onSurfaceVariant,
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: context.colors.primary.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: KolabingTextStyles.bodySmall.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: context.colors.onSurface,
      ),
    ),
  );
}

class _InlineLoader extends StatelessWidget {
  const _InlineLoader();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(KolabingSpacing.md),
    child: Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}

class _InlineHint extends StatelessWidget {
  const _InlineHint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(KolabingSpacing.md),
    decoration: BoxDecoration(
      color: context.colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: context.colors.outlineVariant),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: context.colors.onSurfaceVariant),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) =>
      _InlineHint(icon: LucideIcons.alertCircle, text: message);
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 32,
              color: context.colors.error,
            ),
            const SizedBox(height: KolabingSpacing.md),
            Text(
              l10n.communityHubLoadError,
              style: KolabingTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KolabingSpacing.lg),
            OutlinedButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
          ],
        ),
      ),
    );
  }
}
