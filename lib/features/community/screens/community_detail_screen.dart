import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/cards/kolabing_cards.dart';
import '../../chat/models/chat_thread.dart';
import '../../chat/providers/chat_providers.dart';
import '../../chat/screens/chat_thread_screen.dart';
import '../../event/models/event.dart';
import '../../event/providers/event_provider.dart';
import '../../event/screens/event_hub_screen.dart';
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
    // Refresh chats/events on open so a newly-granted tier chat (or new event)
    // appears without a manual pull-to-refresh.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(chatThreadsProvider.notifier).reload();
      ref.read(communityUpcomingEventsProvider(_community.id).notifier).reload();
      ref.read(communityPastEventsProvider(_community.id).notifier).reload();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = _community;
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(c.name),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          // App bar is yellow; force dark labels/indicator so the SELECTED tab
          // isn't yellow-on-yellow (brand rule: black text on yellow).
          labelColor: KolabingColors.onSurface,
          unselectedLabelColor:
              KolabingColors.onSurface.withValues(alpha: 0.6),
          indicatorColor: KolabingColors.onSurface,
          tabs: [
            Tab(text: l10n.communityDetailTabChats),
            Tab(text: l10n.communityDetailTabEvents),
            Tab(text: l10n.communityDetailTabMembers),
            Tab(text: l10n.communityDetailTabDetails),
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
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: context.colors.hairline)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: context.colors.primary.withValues(alpha: 0.2),
            backgroundImage:
                c.avatarUrl != null ? NetworkImage(c.avatarUrl!) : null,
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
                  style: KolabingTextStyles.bodyLarge
                      .copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context).communityDetailTypeAndMembers(
                      c.type.displayName, c.memberCount ?? 0),
                  style: KolabingTextStyles.bodySmall
                      .copyWith(color: context.colors.onSurfaceVariant),
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
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(chatThreadsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _TabMessage(
        icon: LucideIcons.alertCircle,
        title: l10n.communityDetailChatsLoadError,
        subtitle: e.toString(),
      ),
      data: (threads) {
        final mine = threads
            .where((t) => t.communityId == communityId)
            .toList();
        if (mine.isEmpty) {
          return _TabMessage(
            icon: LucideIcons.messageCircle,
            title: l10n.communityDetailNoChatsTitle,
            subtitle: l10n.communityDetailNoChatsBody,
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
        backgroundColor: context.colors.primary.withValues(alpha: 0.2),
        child: Icon(
          thread.type == ChatThreadType.event
              ? LucideIcons.calendar
              : LucideIcons.messageCircle,
          size: 18,
          color: context.colors.onSurface,
        ),
      ),
      title: Text(
        thread.name ?? AppLocalizations.of(context).chatThreadFallbackTitle,
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
                color: context.colors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${thread.unreadCount}',
                  style: KolabingTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.colors.onPrimary)),
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
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(communityUpcomingEventsProvider(communityId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      // A backend that hasn't deployed the Phase-3 filter yet errors here —
      // treat it as "no events" rather than a scary error.
      error: (_, __) => _TabMessage(
        icon: LucideIcons.calendar,
        title: l10n.communityDetailNoEventsTitle,
        subtitle: l10n.communityDetailNoEventsBody,
      ),
      data: (events) {
        if (events.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref
                .read(communityUpcomingEventsProvider(communityId).notifier)
                .reload(),
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
          onRefresh: () => ref
              .read(communityUpcomingEventsProvider(communityId).notifier)
              .reload(),
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Tier-gated: a member whose tier is not permitted cannot even open the
    // details. Show a lock and a one-line reason instead of navigating.
    final locked = !event.canAccess;
    final muted = context.colors.onSurfaceVariant;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: locked
            ? muted.withValues(alpha: 0.15)
            : context.colors.primary.withValues(alpha: 0.2),
        child: Icon(locked ? LucideIcons.lock : LucideIcons.calendar,
            size: 18, color: locked ? muted : context.colors.onSurface),
      ),
      title: Text(event.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: KolabingTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: locked ? muted : context.colors.onSurface)),
      subtitle: Text(
          locked
              ? l10n.communityDetailEventLockedSubtitle
              : event.formattedDate,
          style: KolabingTextStyles.bodySmall.copyWith(color: muted)),
      trailing: Icon(locked ? LucideIcons.lock : LucideIcons.chevronRight,
          size: 18, color: locked ? muted : null),
      onTap: locked
          ? () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.communityDetailEventLockedSnack),
                ),
              )
          : () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                    builder: (_) => EventHubScreen(event: event)),
              ),
    );
  }
}

// -----------------------------------------------------------------------------
// Members tab — count + chapter leaderboard
// -----------------------------------------------------------------------------

class _MembersTab extends StatelessWidget {
  const _MembersTab({required this.community});

  final Community community;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(KolabingSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.users,
              size: 40, color: context.colors.onSurfaceVariant),
          const SizedBox(height: KolabingSpacing.md),
          Text(l10n.communityDetailMembersCount(community.memberCount ?? 0),
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
            label: Text(l10n.communityDetailLeaderboardButton),
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
    final l10n = AppLocalizations.of(context);
    final c = membership.community;
    final tier = membership.tier;
    return ListView(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      children: [
        if (c.description != null && c.description!.isNotEmpty) ...[
          _Label(l10n.communityDetailAboutLabel),
          Text(c.description!, style: KolabingTextStyles.bodyMedium),
          const SizedBox(height: KolabingSpacing.lg),
        ],
        _Label(l10n.communityDetailMembershipLabel),
        _Row(l10n.communityDetailRowTier,
            tier?.name ?? l10n.communityDetailTierFallback),
        _Row(l10n.communityDetailRowType, c.type.displayName),
        _Row(l10n.communityDetailRowMembers, '${c.memberCount ?? 0}'),
        if (membership.canManage)
          _Row(l10n.communityDetailRowRole, l10n.communityDetailRoleCanManage),
        const SizedBox(height: KolabingSpacing.lg),
        _Label(l10n.communityDetailGalleryLabel),
        _GallerySection(communityId: c.id),
      ],
    );
  }
}

/// Live gallery + past-events showcase for the Details tab
/// (`GET /events?community_id&time=past`). Photos from every past event are laid
/// out in a horizontal strip, followed by the past events themselves. A backend
/// that hasn't deployed the `time=past` filter errors here — treated as empty,
/// not a scary error (same pattern as [_EventsTab]).
class _GallerySection extends ConsumerWidget {
  const _GallerySection({required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(communityPastEventsProvider(communityId));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: KolabingSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _empty(l10n),
      data: (events) {
        if (events.isEmpty) return _empty(l10n);
        final photos = [for (final e in events) ...e.photos];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photos.isNotEmpty) ...[
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: KolabingSpacing.sm),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(KolabingRadius.md),
                    child: Image.network(
                      photos[i].thumbnailUrl ?? photos[i].url,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 96,
                        height: 96,
                        color: KolabingColors.onSurfaceVariant
                            .withValues(alpha: 0.1),
                        child: const Icon(LucideIcons.imageOff, size: 20),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: KolabingSpacing.md),
            ],
            for (final e in events) _EventTile(event: e),
          ],
        );
      },
    );
  }

  Widget _empty(AppLocalizations l10n) => Text(
        l10n.communityDetailGalleryEmpty,
        style: KolabingTextStyles.bodySmall
            .copyWith(color: KolabingColors.onSurfaceVariant),
      );
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
                color: context.colors.onSurfaceVariant)),
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
                    .copyWith(color: context.colors.onSurfaceVariant)),
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
          child: EmptyStateCard(
            icon: icon,
            title: title,
            message: subtitle,
          ),
        ),
      );
}
