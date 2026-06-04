import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../models/chat_thread.dart';
import '../providers/chat_providers.dart';
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
    final async = ref.watch(chatThreadsProvider);
    final body = async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(
        message: e.toString(),
        onRetry: () => ref.read(chatThreadsProvider.notifier).reload(),
      ),
      data: (threads) {
        if (threads.isEmpty) return const _EmptyChats();
        return RefreshIndicator(
          onRefresh: () => ref.read(chatThreadsProvider.notifier).reload(),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.sm),
            children: _sections(threads)
                .expand((s) => [
                      _SectionLabel(s.title),
                      ...s.threads.map((t) => _ThreadTile(thread: t)),
                      const SizedBox(height: KolabingSpacing.sm),
                    ])
                .toList(),
          ),
        );
      },
    );

    // As a nav tab the role shell already provides the app bar; render the body
    // only. As a pushed screen, wrap with our own Scaffold + "Chats" app bar.
    if (widget.embedded) {
      return Container(color: KolabingColors.background, child: body);
    }
    return Scaffold(
      backgroundColor: KolabingColors.background,
      appBar: AppBar(title: const Text('Chats')),
      body: body,
    );
  }

  /// Group threads by type into labelled sections (only non-empty ones).
  List<_Section> _sections(List<ChatThread> threads) {
    List<ChatThread> of(ChatThreadType t) =>
        threads.where((x) => x.type == t).toList();
    final groups = <_Section>[
      _Section('Main', of(ChatThreadType.communityMain)),
      _Section('Community chats', of(ChatThreadType.communityCustom)),
      _Section('Events', of(ChatThreadType.event)),
      _Section('Kolabs', of(ChatThreadType.collaboration)),
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

  String get _title {
    if (thread.name != null && thread.name!.isNotEmpty) return thread.name!;
    if (thread.participants.isNotEmpty) {
      return thread.participants.map((p) => p.name).join(', ');
    }
    return 'Chat';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
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
      leading: CircleAvatar(
        backgroundColor: KolabingColors.primary.withValues(alpha: 0.2),
        child: Icon(
          thread.type == ChatThreadType.event
              ? LucideIcons.calendar
              : thread.type == ChatThreadType.collaboration
                  ? LucideIcons.briefcase
                  : LucideIcons.messageCircle,
          size: 18,
          color: KolabingColors.onSurface,
        ),
      ),
      title: Text(_title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: KolabingTextStyles.bodyMedium.copyWith(
              fontWeight:
                  thread.hasUnread ? FontWeight.w700 : FontWeight.w600)),
      subtitle: Text(
        thread.hasMessages ? 'Tap to open' : 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: KolabingTextStyles.bodySmall
            .copyWith(color: KolabingColors.onSurfaceVariant),
      ),
      trailing: thread.hasUnread
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
          : null,
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
                color: KolabingColors.onSurfaceVariant)),
      );
}

class _EmptyChats extends StatelessWidget {
  const _EmptyChats();

  @override
  Widget build(BuildContext context) => Center(
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
                child: const Icon(LucideIcons.messageCircle,
                    size: 32, color: KolabingColors.onSurface),
              ),
              const SizedBox(height: KolabingSpacing.lg),
              Text('No chats yet',
                  style: KolabingTextStyles.bodyLarge
                      .copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: KolabingSpacing.sm),
              Text(
                'Conversations show up here once a Kolab, community, or event '
                'chat gets going.',
                textAlign: TextAlign.center,
                style: KolabingTextStyles.bodySmall
                    .copyWith(color: KolabingColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
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
