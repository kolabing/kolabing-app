import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../chat/models/chat_thread.dart';
import '../../chat/providers/chat_providers.dart';
import '../../chat/screens/chat_thread_screen.dart';
import '../../chat/services/chat_service.dart';
import '../../event/providers/event_provider.dart';
import '../../event/screens/create_event_screen.dart';
import '../../event/screens/event_hub_screen.dart';
import '../models/community.dart';
import '../models/community_member.dart';
import '../models/community_tier.dart';
import '../providers/community_providers.dart';
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
                color: KolabingColors.primary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.users,
                  size: 32, color: KolabingColors.onSurface),
            ),
            const SizedBox(height: KolabingSpacing.lg),
            Text(
              'Start your community',
              style: KolabingTextStyles.bodyLarge
                  .copyWith(fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.sm),
            Text(
              'Create a community to build a member roster and set up your own '
              'tiers. Your first community is free.',
              style: KolabingTextStyles.bodySmall
                  .copyWith(color: KolabingColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onCreate,
                style: FilledButton.styleFrom(
                  backgroundColor: KolabingColors.primary,
                  foregroundColor: KolabingColors.onPrimary,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('CREATE COMMUNITY'),
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
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(communityManageProvider.notifier).reloadCommunities(),
      child: ListView(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        children: [
          _Header(community: community),
          const SizedBox(height: KolabingSpacing.lg),
          _SectionLabel('Tiers'),
          const SizedBox(height: KolabingSpacing.sm),
          _TiersSection(communityId: community.id),
          const SizedBox(height: KolabingSpacing.lg),
          _SectionLabel('Members'),
          const SizedBox(height: KolabingSpacing.sm),
          _MembersPreview(communityId: community.id),
          const SizedBox(height: KolabingSpacing.lg),
          _SectionLabel('Events'),
          const SizedBox(height: KolabingSpacing.sm),
          _EventsSection(
              communityId: community.id, communityName: community.name),
          const SizedBox(height: KolabingSpacing.lg),
          _SectionLabel('Chats'),
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
                  leading: const Icon(LucideIcons.calendar,
                      color: KolabingColors.onSurface),
                  title: Text(e.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KolabingTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text(e.formattedDate,
                      style: KolabingTextStyles.bodySmall.copyWith(
                          color: KolabingColors.onSurfaceVariant)),
                  trailing: const Icon(LucideIcons.chevronRight, size: 18),
                  onTap: () async {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => EventHubScreen(
                          event: e,
                          isLeader: true,
                          communityName: communityName,
                        ),
                      ),
                    );
                    ref
                        .read(communityUpcomingEventsProvider(communityId)
                            .notifier)
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
          label: const Text('Create event'),
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
          'No upcoming events yet.',
          style: KolabingTextStyles.bodySmall
              .copyWith(color: KolabingColors.onSurfaceVariant),
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
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New chat'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Chat name',
            hintText: 'e.g. Exec, Socials, Philanthropy',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Create'),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('"$name" created')));
      }
    } on ChatException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.isChatLimitReached
                ? 'You can have up to $_maxCustom chats'
                : e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(chatThreadsProvider);
    return async.when(
      loading: () => const _InlineLoader(),
      error: (e, _) => _InlineError(message: e.toString()),
      data: (threads) {
        final mine = threads
            .where((t) => t.communityId == communityId && t.type.isCommunity)
            .toList();
        final customCount =
            mine.where((t) => t.type == ChatThreadType.communityCustom).length;
        return Column(
          children: [
            if (mine.isEmpty)
              _InlineHint(
                icon: LucideIcons.messageCircle,
                text: 'No chats yet. Your main chat + up to '
                    '$_maxCustom custom chats live here.',
              )
            else
              for (final t in mine) _ChatRow(thread: t),
            const SizedBox(height: KolabingSpacing.xs),
            if (customCount < _maxCustom)
              _AddTile(
                label: 'Create chat',
                onTap: () => _create(context, ref),
              )
            else
              _InlineHint(
                icon: LucideIcons.lock,
                text: 'Chat limit reached ($_maxCustom custom chats).',
              ),
          ],
        );
      },
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.thread});

  final ChatThread thread;

  @override
  Widget build(BuildContext context) {
    final isMain = thread.type == ChatThreadType.communityMain;
    return Padding(
      padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
      child: Material(
        color: KolabingColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
                builder: (_) => ChatThreadScreen(thread: thread)),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.md, vertical: KolabingSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: KolabingColors.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(isMain ? LucideIcons.hash : LucideIcons.messageCircle,
                    size: 16, color: KolabingColors.onSurfaceVariant),
                const SizedBox(width: KolabingSpacing.sm),
                Expanded(
                  child: Text(thread.name ?? (isMain ? 'Main' : 'Chat'),
                      style: KolabingTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
                if (isMain) _Chip(label: 'MAIN'),
                if (thread.hasUnread) ...[
                  const SizedBox(width: KolabingSpacing.xs),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: KolabingColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${thread.unreadCount}',
                        style: KolabingTextStyles.bodySmall.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: KolabingColors.onPrimary)),
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
        color: KolabingColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KolabingColors.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: KolabingColors.primary.withValues(alpha: 0.2),
            backgroundImage: community.avatarUrl != null
                ? NetworkImage(community.avatarUrl!)
                : null,
            child: community.avatarUrl == null
                ? const Icon(LucideIcons.users, color: KolabingColors.onSurface)
                : null,
          ),
          const SizedBox(width: KolabingSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  community.name,
                  style: KolabingTextStyles.bodyLarge
                      .copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${community.type.displayName}'
                  '${community.memberCount != null ? '  ·  ${community.memberCount} members' : ''}',
                  style: KolabingTextStyles.bodySmall
                      .copyWith(color: KolabingColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Icon(
            community.joinPolicy.allowsSelfJoin
                ? LucideIcons.globe
                : LucideIcons.lock,
            size: 18,
            color: KolabingColors.onSurfaceVariant,
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
        builder: (_) =>
            TierEditorScreen(communityId: communityId, tier: tier),
      ),
    );
    if (changed ?? false) {
      await ref.read(communityManageProvider.notifier).reloadTiers();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                text:
                    'No tiers yet. Add tiers to give members a status ladder.',
              ),
              const SizedBox(height: KolabingSpacing.sm),
              _AddTile(
                label: 'Add tier',
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
              label: 'Add tier',
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
    Color dot;
    try {
      dot = tier.color != null
          ? Color(int.parse(tier.color!.replaceFirst('#', '0xff')))
          : KolabingColors.primary;
    } catch (_) {
      dot = KolabingColors.primary;
    }
    final detail = tier.assignmentRule.isAutomatic && tier.threshold != null
        ? '${tier.assignmentRule.displayName} · ${tier.threshold} ${tier.assignmentRule.thresholdUnit}'
        : tier.assignmentRule.displayName;
    return Padding(
      padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
      child: Material(
        color: KolabingColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.md, vertical: KolabingSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: KolabingColors.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(color: dot, shape: BoxShape.circle)),
                const SizedBox(width: KolabingSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(tier.name,
                              style: KolabingTextStyles.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w700)),
                          if (tier.isDefault) ...[
                            const SizedBox(width: KolabingSpacing.xs),
                            _Chip(label: 'DEFAULT'),
                          ],
                        ],
                      ),
                      Text(detail,
                          style: KolabingTextStyles.bodySmall.copyWith(
                              fontSize: 12,
                              color: KolabingColors.onSurfaceVariant)),
                    ],
                  ),
                ),
                Text('#${tier.rank}',
                    style: KolabingTextStyles.bodySmall
                        .copyWith(color: KolabingColors.onSurfaceVariant)),
                if (onTap != null) ...[
                  const SizedBox(width: KolabingSpacing.xs),
                  const Icon(LucideIcons.chevronRight,
                      size: 16, color: KolabingColors.onSurfaceVariant),
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
                horizontal: KolabingSpacing.md, vertical: KolabingSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: KolabingColors.outline,
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.plus,
                    size: 16, color: KolabingColors.onSurface),
                const SizedBox(width: KolabingSpacing.xs),
                Text(label,
                    style: KolabingTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
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
          builder: (_) => RosterScreen(communityId: communityId)),
    );
    await ref.read(communityManageProvider.notifier).reloadMembers();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                text: 'No members yet. Invite people or share your join link.',
              ),
              const SizedBox(height: KolabingSpacing.sm),
              _AddTile(
                label: 'Manage members',
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
                  ? 'Manage all ${members.length} members'
                  : 'Manage members',
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xs),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: KolabingColors.surfaceContainerHigh,
            backgroundImage: member.memberAvatarUrl != null
                ? NetworkImage(member.memberAvatarUrl!)
                : null,
            child: member.memberAvatarUrl == null
                ? const Icon(LucideIcons.user, size: 16)
                : null,
          ),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: Text(member.memberName ?? 'Member',
                style: KolabingTextStyles.bodyMedium),
          ),
          if (member.canManage) ...[
            _Chip(label: 'ADMIN'),
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
          color: KolabingColors.onSurfaceVariant,
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
          color: KolabingColors.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: KolabingTextStyles.bodySmall.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: KolabingColors.onSurface)),
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
              child: CircularProgressIndicator(strokeWidth: 2)),
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
          color: KolabingColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KolabingColors.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: KolabingColors.onSurfaceVariant),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: Text(text,
                  style: KolabingTextStyles.bodySmall
                      .copyWith(color: KolabingColors.onSurfaceVariant)),
            ),
          ],
        ),
      );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => _InlineHint(
        icon: LucideIcons.alertCircle,
        text: message,
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.alertCircle,
                  size: 32, color: KolabingColors.error),
              const SizedBox(height: KolabingSpacing.md),
              Text("Couldn't load your community",
                  style: KolabingTextStyles.bodyLarge
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: KolabingSpacing.xs),
              Text(message,
                  textAlign: TextAlign.center,
                  style: KolabingTextStyles.bodySmall
                      .copyWith(color: KolabingColors.onSurfaceVariant)),
              const SizedBox(height: KolabingSpacing.lg),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}
