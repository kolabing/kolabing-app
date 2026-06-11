import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/cards/kolabing_cards.dart';
import '../models/chat_thread.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_management.dart';
import 'chat_thread_screen.dart';

/// The chat inbox. The backend role-scopes which threads come back (business =
/// active collaboration chats only; community = main + custom + event + kolabs;
/// attendee = main + tier-granted + RSVP'd event chats). The app just groups
/// whatever it receives by type.
class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key, this.embedded = false});

  /// When true, render as a bottom-nav tab body — no Scaffold/AppBar, since the
  /// role shell already supplies the KolabingAppBar (NF-12). When false, it's a
  /// standalone pushed screen with its own "Chats" app bar.
  final bool embedded;

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  @override
  void initState() {
    super.initState();
    // FX-9: always refetch when the inbox opens. The thread/unread providers
    // are kept-alive and can still hold the PREVIOUS account's data after a
    // switch (the reported "stale on first load, correct on manual refresh",
    // e.g. a community's kolab chat showing for an attendee). Forcing a reload
    // on mount makes every open behave like the pull-to-refresh that already
    // returns the correct, current-session data.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(chatThreadsProvider.notifier).reload();
      ref.read(chatUnreadProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(chatThreadsProvider);
    // Communities the viewer can manage — drives the create-chat affordance.
    final manageable = async.maybeWhen(
      data: _manageableCommunities,
      orElse: () => const <_ManageableCommunity>[],
    );
    final body = async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(
        message: e.toString(),
        onRetry: () => ref.read(chatThreadsProvider.notifier).reload(),
      ),
      data: (threads) {
        final joinable = threads.where((t) => t.canJoin).toList();
        final manageable = _manageableCommunities(threads);
        if (threads.isEmpty && manageable.isEmpty) {
          return _EmptyChats(onCreate: _onCreateChat(manageable));
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(chatThreadsProvider.notifier).reload(),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.sm),
            children: [
              ..._sections(l10n, threads).expand((s) => [
                    _SectionLabel(s.title),
                    ...s.threads.map((t) => _ThreadTile(thread: t)),
                    const SizedBox(height: KolabingSpacing.sm),
                  ]),
              if (joinable.isNotEmpty) ...[
                _SectionLabel(l10n.chatJoinSectionTitle),
                ...joinable.map((t) => _JoinableTile(thread: t)),
                const SizedBox(height: KolabingSpacing.sm),
              ],
            ],
          ),
        );
      },
    );

    // Managers can create a chat from the inbox itself (not only the community
    // profile). The FAB picks the community first when more than one is managed.
    final fab = manageable.isEmpty
        ? null
        : FloatingActionButton.extended(
            onPressed: _onCreateChat(manageable),
            backgroundColor: KolabingColors.primary,
            foregroundColor: KolabingColors.onPrimary,
            icon: const Icon(LucideIcons.plus),
            label: Text(l10n.chatManageCreateChat),
          );

    // As a nav tab the role shell already provides the app bar; render the body
    // in a transparent Scaffold so the create FAB still has a home. As a pushed
    // screen, wrap with our own Scaffold + "Chats" app bar.
    if (widget.embedded) {
      return Scaffold(
        backgroundColor: KolabingColors.background,
        floatingActionButton: fab,
        body: body,
      );
    }
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(title: Text(l10n.chatsTitle)),
      floatingActionButton: fab,
      body: body,
    );
  }

  /// The communities the viewer can manage, derived from the thread list: any
  /// community that has a `can_manage` thread. The main chat (or first thread)
  /// supplies a display label.
  List<_ManageableCommunity> _manageableCommunities(List<ChatThread> threads) {
    final byCommunity = <String, _ManageableCommunity>{};
    for (final t in threads) {
      final id = t.communityId;
      if (id == null || !t.canManage || !t.type.isCommunity) continue;
      final existing = byCommunity[id];
      // Prefer the main chat's name as the community label.
      final isMain = t.type == ChatThreadType.communityMain;
      if (existing == null || (isMain && existing.label == null)) {
        byCommunity[id] = _ManageableCommunity(
          id: id,
          label: isMain ? t.name : existing?.label,
        );
      }
    }
    return byCommunity.values.toList();
  }

  /// Returns a create handler: directly creates when one community is managed,
  /// otherwise shows a community picker first.
  VoidCallback? _onCreateChat(List<_ManageableCommunity> manageable) {
    if (manageable.isEmpty) return null;
    return () async {
      String communityId;
      if (manageable.length == 1) {
        communityId = manageable.single.id;
      } else {
        final chosen = await _pickCommunity(manageable);
        if (chosen == null) return;
        communityId = chosen;
      }
      if (!mounted) return;
      await ChatManagement.createCustomChat(context, ref,
          communityId: communityId);
    };
  }

  Future<String?> _pickCommunity(List<_ManageableCommunity> manageable) {
    final l10n = AppLocalizations.of(context);
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: KolabingColors.surface,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(KolabingSpacing.md, 0,
                  KolabingSpacing.md, KolabingSpacing.sm),
              child: Text(l10n.chatManageWhichCommunity,
                  style: Theme.of(sheetContext).textTheme.titleMedium),
            ),
            for (final c in manageable)
              ListTile(
                leading: const Icon(LucideIcons.users),
                title: Text(c.label ?? l10n.chatSectionMain),
                onTap: () => Navigator.of(sheetContext).pop(c.id),
              ),
          ],
        ),
      ),
    );
  }

  /// Group threads by type into labelled sections (only non-empty ones).
  List<_Section> _sections(AppLocalizations l10n, List<ChatThread> threads) {
    List<ChatThread> of(ChatThreadType t) =>
        threads.where((x) => x.type == t).toList();
    final groups = <_Section>[
      _Section(l10n.chatSectionMain, of(ChatThreadType.communityMain)),
      _Section(
          l10n.chatSectionCommunityChats, of(ChatThreadType.communityCustom)),
      _Section(l10n.chatSectionEvents, of(ChatThreadType.event)),
      _Section(l10n.chatSectionKolabs, of(ChatThreadType.collaboration)),
    ];
    return groups.where((s) => s.threads.isNotEmpty).toList();
  }
}

class _Section {
  const _Section(this.title, this.threads);
  final String title;
  final List<ChatThread> threads;
}

class _ThreadTile extends ConsumerWidget {
  const _ThreadTile({required this.thread});

  final ChatThread thread;

  String _titleFor(AppLocalizations l10n) {
    if (thread.name != null && thread.name!.isNotEmpty) return thread.name!;
    if (thread.participants.isNotEmpty) {
      return thread.participants.map((p) => p.name).join(', ');
    }
    return l10n.chatThreadFallbackTitle;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.xxs,
      ),
      child: CompactListCard(
        padding: EdgeInsets.zero,
        onTap: () async {
          // Phase 1: collaboration (Kolab) chats reuse the existing
          // application-backed chat screen. Community/event threads (later
          // phases) use the generic thread screen.
          if (thread.type == ChatThreadType.collaboration &&
              thread.applicationId != null) {
            await context.push('/application/${thread.applicationId}/chat');
          } else {
            await Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                  builder: (_) => ChatThreadScreen(thread: thread)),
            );
          }
          // Refresh the inbox + badge after returning (read state may have moved).
          ref.read(chatThreadsProvider.notifier).reload();
          ref.read(chatUnreadProvider.notifier).refresh();
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: context.colors.primary.withValues(alpha: 0.2),
            child: Icon(
              thread.type == ChatThreadType.event
                  ? LucideIcons.calendar
                  : thread.type == ChatThreadType.collaboration
                      ? LucideIcons.briefcase
                      : LucideIcons.messageCircle,
              size: 18,
              color: context.colors.onSurface,
            ),
          ),
          title: Text(_titleFor(l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KolabingTextStyles.bodyMedium.copyWith(
                  fontWeight:
                      thread.hasUnread ? FontWeight.w700 : FontWeight.w600)),
          subtitle: Text(
            thread.hasMessages
                ? l10n.chatThreadTapToOpen
                : l10n.chatThreadNoMessagesYet,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KolabingTextStyles.bodySmall
                .copyWith(color: context.colors.onSurfaceVariant),
          ),
          trailing: _trailing(context, ref, l10n),
        ),
      ),
    );
  }

  Widget? _trailing(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final badge = thread.hasUnread
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: KolabingColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${thread.unreadCount}',
                style: KolabingTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: KolabingColors.onPrimary)),
          )
        : null;

    // Managers get inline rename / delete on custom + event chats.
    final canManage = thread.canManage && (thread.isRenamable || thread.isDeletable);
    if (!canManage) return badge;

    final menu = PopupMenuButton<String>(
      icon: const Icon(LucideIcons.moreVertical,
          size: 18, color: KolabingColors.onSurfaceVariant),
      onSelected: (value) {
        switch (value) {
          case 'rename':
            ChatManagement.renameChat(context, ref, thread);
          case 'delete':
            ChatManagement.deleteChat(context, ref, thread);
        }
      },
      itemBuilder: (_) => [
        if (thread.isRenamable)
          PopupMenuItem<String>(
            value: 'rename',
            child: Row(children: [
              const Icon(LucideIcons.pencil, size: 16),
              const SizedBox(width: KolabingSpacing.sm),
              Text(l10n.chatManageRename),
            ]),
          ),
        if (thread.isDeletable)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(children: [
              const Icon(LucideIcons.trash2,
                  size: 16, color: KolabingColors.error),
              const SizedBox(width: KolabingSpacing.sm),
              Text(l10n.chatManageDelete,
                  style: const TextStyle(color: KolabingColors.error)),
            ]),
          ),
      ],
    );

    if (badge == null) return menu;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [badge, menu],
    );
  }
}

/// A community the viewer can manage (id + a display label, when known).
class _ManageableCommunity {
  const _ManageableCommunity({required this.id, this.label});
  final String id;
  final String? label;
}

/// An open chat the viewer can join (Join button, no unread/manage affordances).
class _JoinableTile extends ConsumerWidget {
  const _JoinableTile({required this.thread});

  final ChatThread thread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.xxs,
      ),
      child: CompactListCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: KolabingColors.primary.withValues(alpha: 0.2),
            child: const Icon(LucideIcons.messageCircle,
                size: 18, color: KolabingColors.onSurface),
          ),
          title: Text(thread.name ?? l10n.chatThreadFallbackTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KolabingTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          trailing: OutlinedButton(
            onPressed: () => ChatManagement.joinChat(context, ref, thread),
            child: Text(l10n.chatJoinAction),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(KolabingSpacing.md,
            KolabingSpacing.md, KolabingSpacing.md, KolabingSpacing.xs),
        child: Text(text.toUpperCase(),
            style: KolabingTextStyles.bodySmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: context.colors.onSurfaceVariant)),
      );
}

class _EmptyChats extends StatelessWidget {
  const _EmptyChats({this.onCreate});

  /// When set (manager with no chats yet), shows a create-chat button.
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.xl),
        child: EmptyStateCard(
          icon: LucideIcons.messageCircle,
          title: l10n.chatInboxEmptyTitle,
          message: l10n.chatInboxEmptyBody,
          action: onCreate == null
              ? null
              : FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: Text(l10n.chatManageCreateChat),
                ),
        ),
      ),
    );
  }
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
              Icon(LucideIcons.alertCircle,
                  size: 32, color: context.colors.error),
              const SizedBox(height: KolabingSpacing.md),
              Text(message,
                  textAlign: TextAlign.center,
                  style: KolabingTextStyles.bodySmall
                      .copyWith(color: context.colors.onSurfaceVariant)),
              const SizedBox(height: KolabingSpacing.lg),
              OutlinedButton(
                  onPressed: onRetry,
                  child: Text(AppLocalizations.of(context).commonRetry)),
            ],
          ),
        ),
      );
}
