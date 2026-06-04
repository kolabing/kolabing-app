import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../chat/models/chat_thread.dart';
import '../../chat/providers/chat_providers.dart';
import '../../chat/screens/chat_thread_screen.dart';
import '../../event/models/event.dart';
import '../../event/providers/event_provider.dart';
import '../../gamification/screens/leaderboard_screen.dart';
import '../models/community.dart';
import '../models/community_membership.dart';

/// Tabbed Community detail (NF-12): Chats · Events · Members · Details.
///
/// Opened by tapping a community the user belongs to (`my_communities_screen`).
/// Chats + Members + Details are wired to existing data; Events is a placeholder
/// until the Phase-3 events lifecycle ships (NF-11, backend `events` filters +
/// RSVP). See docs/tickets/2026-06-04-chat-phase3-events-rsvp-realtime-backend.md.
class CommunityDetailScreen extends ConsumerStatefulWidget {
  const CommunityDetailScreen({super.key, required this.membership});

  final CommunityMembership membership;

  @override
  ConsumerState<CommunityDetailScreen> createState() =>
      _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends ConsumerState<CommunityDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  Community get _community => widget.membership.community;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _community;
    return Scaffold(
      backgroundColor: KolabingColors.background,
      appBar: AppBar(
        title: Text(c.name),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'Events'),
            Tab(text: 'Members'),
            Tab(text: 'Details'),
          ],
        ),
      ),
      body: Column(
        children: [
          _Header(membership: widget.membership),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _ChatsTab(communityId: c.id),
                _EventsTab(communityId: c.id),
                _MembersTab(community: c),
                _DetailsTab(membership: widget.membership),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Header (logo + name + type + member count)
// -----------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.membership});

  final CommunityMembership membership;

  @override
  Widget build(BuildContext context) {
    final c = membership.community;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KolabingSpacing.md),
      color: KolabingColors.surfaceContainerLow,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: KolabingColors.primary.withValues(alpha: 0.2),
            backgroundImage:
                c.avatarUrl != null ? NetworkImage(c.avatarUrl!) : null,
            child: c.avatarUrl == null
                ? const Icon(LucideIcons.flag, color: KolabingColors.onSurface)
                : null,
          ),
          const SizedBox(width: KolabingSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: KolabingTextStyles.bodyLarge
                      .copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${c.type.displayName} · ${c.memberCount ?? 0} members',
                  style: KolabingTextStyles.bodySmall
                      .copyWith(color: KolabingColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Chats tab — this community's threads (main + custom), from chatThreadsProvider
// -----------------------------------------------------------------------------

class _ChatsTab extends ConsumerWidget {
  const _ChatsTab({required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(chatThreadsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _TabMessage(
        icon: LucideIcons.alertCircle,
        title: 'Could not load chats',
        subtitle: e.toString(),
      ),
      data: (threads) {
        final mine = threads
            .where((t) => t.communityId == communityId)
            .toList();
        if (mine.isEmpty) {
          return const _TabMessage(
            icon: LucideIcons.messageCircle,
            title: 'No chats yet',
            subtitle: 'This community’s conversations show up here.',
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(chatThreadsProvider.notifier).reload(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.sm),
            itemCount: mine.length,
            itemBuilder: (_, i) => _ThreadTile(thread: mine[i]),
          ),
        );
      },
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread});

  final ChatThread thread;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: KolabingColors.primary.withValues(alpha: 0.2),
        child: Icon(
          thread.type == ChatThreadType.event
              ? LucideIcons.calendar
              : LucideIcons.messageCircle,
          size: 18,
          color: KolabingColors.onSurface,
        ),
      ),
      title: Text(
        thread.name ?? 'Chat',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: KolabingTextStyles.bodyMedium.copyWith(
          fontWeight: thread.hasUnread ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      trailing: thread.hasUnread
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
          : null,
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
            builder: (_) => ChatThreadScreen(thread: thread)),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Events tab — placeholder until Phase 3 (events lifecycle + RSVP) ships
// -----------------------------------------------------------------------------

class _EventsTab extends ConsumerWidget {
  const _EventsTab({required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(communityUpcomingEventsProvider(communityId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      // A backend that hasn't deployed the Phase-3 filter yet errors here —
      // treat it as "no events" rather than a scary error.
      error: (_, __) => const _TabMessage(
        icon: LucideIcons.calendar,
        title: 'No upcoming events',
        subtitle: 'Events created for this community will show here.',
      ),
      data: (events) {
        if (events.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(communityUpcomingEventsProvider(communityId)),
            child: ListView(
              children: const [
                SizedBox(height: 120),
                _TabMessage(
                  icon: LucideIcons.calendar,
                  title: 'No upcoming events',
                  subtitle:
                      'Events created for this community will show here.',
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(communityUpcomingEventsProvider(communityId)),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.sm),
            itemCount: events.length,
            itemBuilder: (_, i) => _EventTile(event: events[i]),
          ),
        );
      },
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: CircleAvatar(
          backgroundColor: KolabingColors.primary.withValues(alpha: 0.2),
          child: const Icon(LucideIcons.calendar,
              size: 18, color: KolabingColors.onSurface),
        ),
        title: Text(event.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KolabingTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(event.formattedDate,
            style: KolabingTextStyles.bodySmall
                .copyWith(color: KolabingColors.onSurfaceVariant)),
      );
}

// -----------------------------------------------------------------------------
// Members tab — count + chapter leaderboard
// -----------------------------------------------------------------------------

class _MembersTab extends StatelessWidget {
  const _MembersTab({required this.community});

  final Community community;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.users,
              size: 40, color: KolabingColors.onSurfaceVariant),
          const SizedBox(height: KolabingSpacing.md),
          Text('${community.memberCount ?? 0} members',
              style: KolabingTextStyles.bodyLarge
                  .copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: KolabingSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => LeaderboardScreen(
                  communityId: community.id,
                  communityName: community.name,
                ),
              ),
            ),
            icon: const Icon(LucideIcons.trophy, size: 18),
            label: const Text('Chapter leaderboard'),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Details tab — the community profile (about, your tier; gallery/past TBD)
// -----------------------------------------------------------------------------

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({required this.membership});

  final CommunityMembership membership;

  @override
  Widget build(BuildContext context) {
    final c = membership.community;
    final tier = membership.tier;
    return ListView(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      children: [
        if (c.description != null && c.description!.isNotEmpty) ...[
          _Label('About'),
          Text(c.description!, style: KolabingTextStyles.bodyMedium),
          const SizedBox(height: KolabingSpacing.lg),
        ],
        _Label('Your membership'),
        _Row('Tier', tier?.name ?? 'Member'),
        _Row('Type', c.type.displayName),
        _Row('Members', '${c.memberCount ?? 0}'),
        if (membership.canManage) _Row('Role', 'Can manage'),
        const SizedBox(height: KolabingSpacing.lg),
        _Label('Gallery & past events'),
        Text(
          'Photos and past events will live here once the events lifecycle '
          'ships (Phase 3).',
          style: KolabingTextStyles.bodySmall
              .copyWith(color: KolabingColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
        child: Text(text.toUpperCase(),
            style: KolabingTextStyles.bodySmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: KolabingColors.onSurfaceVariant)),
      );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xs),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: KolabingTextStyles.bodyMedium
                    .copyWith(color: KolabingColors.onSurfaceVariant)),
            Text(value,
                style: KolabingTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w700)),
          ],
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: KolabingColors.onSurfaceVariant),
              const SizedBox(height: KolabingSpacing.md),
              Text(title,
                  style: KolabingTextStyles.bodyLarge
                      .copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: KolabingSpacing.sm),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: KolabingTextStyles.bodySmall
                      .copyWith(color: KolabingColors.onSurfaceVariant)),
            ],
          ),
        ),
      );
}
