/// The Luma-style event row, and the date-grouped timeline built from it.
///
/// One row widget, three surfaces: the member/leader community page, the public
/// attendee-facing community profile (IF-31), and the attendee feed (#161).
/// Keeping it in one place is what stops "an event" from looking like three
/// different things depending on where the reader found it.
///
/// The row shows only fields the API actually sends. Where a field is absent
/// the line is absent — never a placeholder, and never a computed number that
/// reads as data (the old attendee feed rendered `distance_km` as "0 m" on
/// every card because city discovery sends no coordinates).
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/color_tokens.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/event.dart';
import 'event_feed_card.dart';

// =============================================================================
// Timeline
// =============================================================================

/// How each event inside the timeline is drawn.
enum EventTimelineVariant {
  /// A compact row: 72px thumbnail, host, title, when, where, chips. The
  /// default, and right where a page holds many events and the reader is
  /// scanning a schedule.
  row,

  /// The photo card the Explore feed uses — same anatomy, so the app's two
  /// browsing surfaces look like one product.
  card,
}

/// Upcoming events grouped under a "Today / Sunday" date header, in the
/// caller's locale. Bare rows on the page background, Luma-style — no cards.
class EventTimeline extends StatelessWidget {
  const EventTimeline({
    super.key,
    required this.events,
    required this.onOpen,
    this.onLocked,
    this.showHost = false,
    this.showVisibility = true,
    this.variant = EventTimelineVariant.row,
  });

  final List<Event> events;
  final void Function(Event event) onOpen;

  /// Tapped an event the viewer cannot access (tier/members gated).
  final void Function(Event event)? onLocked;

  /// Name the host above each title. On a community page the host is the page
  /// you are standing on, so it stays off; on a city-wide feed it is the single
  /// line that tells you whose event this is.
  final bool showHost;

  /// Show the Public / Members / Tier chip. Off on surfaces that only ever list
  /// public events — a chip that reads the same on every row is noise.
  final bool showVisibility;

  /// Row or card. See [EventTimelineVariant].
  final EventTimelineVariant variant;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final weekdayFormat = DateFormat('EEEE', locale);

    final groups = <DateTime, List<Event>>{};
    for (final event in events) {
      final when = event.startsAt ?? event.date;
      final day = DateTime(when.year, when.month, when.day);
      groups.putIfAbsent(day, () => <Event>[]).add(event);
    }
    final days = groups.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final day in days) ...[
          Padding(
            padding: const EdgeInsets.only(
              top: KolabingSpacing.md,
              bottom: KolabingSpacing.sm,
            ),
            child: Row(
              children: [
                Text(
                  eventDayLabel(context, day),
                  style: KolabingTextStyles.titleMedium.copyWith(
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(width: KolabingSpacing.xs),
                // Flexible, not fixed: a long localised weekday (miércoles,
                // dimecres) at a large text scale otherwise overflows the row.
                Flexible(
                  child: Text(
                    '/ ${weekdayFormat.format(day)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KolabingTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w400,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final event in groups[day]!)
            switch (variant) {
              EventTimelineVariant.row => EventTimelineRow(
                event: event,
                locale: locale,
                showHost: showHost,
                showVisibility: showVisibility,
                onTap: () => event.canAccess
                    ? onOpen(event)
                    : (onLocked ?? onOpen)(event),
              ),
              EventTimelineVariant.card => EventFeedCard(
                event: event,
                locale: locale,
                showHost: showHost,
                showVisibility: showVisibility,
                onTap: () => event.canAccess
                    ? onOpen(event)
                    : (onLocked ?? onOpen)(event),
              ),
            },
        ],
      ],
    );
  }
}

// =============================================================================
// Row
// =============================================================================

/// One event, as a bare row: thumbnail, host, title, when, where, status.
///
/// Used inside [EventTimeline] (where the day is already in the header, so
/// [showDay] stays off) and standalone in the attendee feed's "Your events"
/// section (where it carries its own "Today, 19:30").
class EventTimelineRow extends StatelessWidget {
  const EventTimelineRow({
    super.key,
    required this.event,
    required this.locale,
    required this.onTap,
    this.showDay = false,
    this.showHost = false,
    this.showVisibility = true,
  });

  final Event event;
  final String locale;
  final VoidCallback onTap;

  /// Prefix the time with the day ("Today, 19:30"). For rows that do not sit
  /// under a date header.
  final bool showDay;

  final bool showHost;
  final bool showVisibility;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locked = !event.canAccess;
    final muted = context.colors.onSurfaceVariant;
    final pictureUrl = event.coverPhotoUrl ?? event.partner.profilePhoto;
    final startsAt = event.startsAt;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KolabingRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(KolabingRadius.md),
              child: SizedBox(
                width: 72,
                height: 72,
                child: pictureUrl != null
                    ? Image.network(
                        pictureUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            EventThumbPlaceholder(locked: locked),
                      )
                    : EventThumbPlaceholder(locked: locked),
              ),
            ),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showHost) _HostLine(event: event),
                  Text(
                    event.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: KolabingTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: locked ? muted : context.colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: KolabingSpacing.xxs),
                  if (locked)
                    EventMetaLine(
                      icon: LucideIcons.lock,
                      text: l10n.communityDetailEventLockedSubtitle,
                    )
                  else ...[
                    if (startsAt != null)
                      EventMetaLine(
                        icon: LucideIcons.clock,
                        text: _whenText(context, startsAt),
                      ),
                    if (event.location != null && event.location!.isNotEmpty)
                      EventMetaLine(
                        icon: LucideIcons.mapPin,
                        text: event.location!,
                      ),
                  ],
                  const SizedBox(height: KolabingSpacing.xxs),
                  Wrap(
                    spacing: KolabingSpacing.xxs,
                    runSpacing: KolabingSpacing.xxs,
                    children: [
                      if (event.isGoing)
                        EventMiniChip(
                          label: l10n.communityEventBadgeGoing,
                          fill: context.colors.activeBg,
                          ink: context.colors.activeText,
                        ),
                      if (event.isWaitlisted)
                        EventMiniChip(
                          label: l10n.communityEventBadgeWaitlisted,
                          fill: context.colors.pendingBg,
                          ink: context.colors.pendingText,
                        ),
                      if (eventCapacityBadge(l10n, event) case final badge?)
                        EventMiniChip(
                          label: badge,
                          fill: context.colors.surfaceContainerHigh,
                          ink: context.colors.onSurfaceVariant,
                        ),
                      if (showVisibility)
                        EventVisibilityChip(visibility: event.visibility),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "19:30" under a date header, "Today, 19:30" without one.
  String _whenText(BuildContext context, DateTime startsAt) {
    final time = DateFormat.Hm(locale).format(startsAt);
    if (!showDay) return time;
    final day = DateTime(startsAt.year, startsAt.month, startsAt.day);
    return AppLocalizations.of(
      context,
    ).eventWhenDayTime(eventDayLabel(context, day), time);
  }
}

/// The host community's logo and name, above the title.
///
/// Falls back to the partner name: `community_name` only arrives when the API
/// payload loaded the relation.
class _HostLine extends StatelessWidget {
  const _HostLine({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final name = (event.communityName?.isNotEmpty ?? false)
        ? event.communityName!
        : event.partner.name;
    if (name.isEmpty) return const SizedBox.shrink();
    final logo = event.partner.profilePhoto;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 16,
              height: 16,
              child: logo != null
                  ? Image.network(
                      logo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _HostLogoFallback(name: name),
                    )
                  : _HostLogoFallback(name: name),
            ),
          ),
          const SizedBox(width: KolabingSpacing.xxs),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KolabingTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HostLogoFallback extends StatelessWidget {
  const _HostLogoFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.colors.surfaceContainerHigh,
    child: Center(
      child: Text(
        name.characters.first.toUpperCase(),
        style: KolabingTextStyles.bodySmall.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ),
  );
}

// =============================================================================
// Pieces
// =============================================================================

/// "Today" / "Tomorrow" / "6 September", in the caller's locale.
///
/// The two relative labels are what make a feed readable at a glance: a reader
/// scanning for tonight should not have to work out whether "24 August" is
/// today.
String eventDayLabel(BuildContext context, DateTime day) {
  final l10n = AppLocalizations.of(context);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(day.year, day.month, day.day);
  final delta = target.difference(today).inDays;
  if (delta == 0) return l10n.eventDateToday;
  if (delta == 1) return l10n.eventDateTomorrow;
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat('d MMMM', locale).format(day);
}

/// How full an event is, in three words or fewer.
///
/// Null for an uncapped event: "unlimited" is not news, and a badge on every
/// row would stop any of them meaning anything.
String? eventCapacityBadge(AppLocalizations l10n, Event event) {
  final capacity = event.capacity;
  if (capacity == null) return null;
  final left = event.spotsLeft ?? 0;
  if (left <= 0) return l10n.eventCapacityFull;
  if (left <= (capacity * 0.2).ceil()) return l10n.eventCapacityNearly;
  return l10n.eventCapacityLeft(left);
}

/// An icon and a line of text: the row's "when" and "where".
class EventMetaLine extends StatelessWidget {
  const EventMetaLine({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 1),
    child: Row(
      children: [
        Icon(icon, size: 13, color: context.colors.onSurfaceVariant),
        const SizedBox(width: KolabingSpacing.xxs),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Stands in for a cover photo the event does not have.
class EventThumbPlaceholder extends StatelessWidget {
  const EventThumbPlaceholder({super.key, required this.locked});

  final bool locked;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.colors.surfaceContainerHigh,
    child: Icon(
      locked ? LucideIcons.lock : LucideIcons.calendar,
      size: 22,
      color: context.colors.onSurfaceVariant,
    ),
  );
}

/// Small soft pill used for event status.
class EventMiniChip extends StatelessWidget {
  const EventMiniChip({
    super.key,
    required this.label,
    required this.fill,
    required this.ink,
    this.icon,
  });

  final String label;
  final Color fill;
  final Color ink;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(KolabingRadius.round),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: ink),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: KolabingTextStyles.bodySmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
      ],
    ),
  );
}

/// Who can see an event: Public / Members / Tier.
class EventVisibilityChip extends StatelessWidget {
  const EventVisibilityChip({super.key, this.visibility});

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
    return EventMiniChip(
      label: label,
      icon: icon,
      fill: context.colors.surfaceContainerHigh,
      ink: context.colors.onSurfaceVariant,
    );
  }
}
