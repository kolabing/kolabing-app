/// The attendee feed's sections, above the city discovery list.
///
/// The feed reads top to bottom in order of how much the reader already cares
/// about what it is showing them (#161):
///
///   your events  →  the communities you follow  →  what is on in your city
///
/// Each section renders nothing at all when it has nothing to say. An empty
/// "Your events" heading would push the part of the page that does have
/// something down the screen to say so.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/color_tokens.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../event/widgets/event_timeline.dart';
import '../providers/my_events_provider.dart';

/// How many of the viewer's own events the feed shows before deferring to the
/// "View all" screen.
const int kFeedMyEventsPreviewCount = 3;

// =============================================================================
// Section header
// =============================================================================

/// A section's name, and optionally one action on the right.
///
/// Same eyebrow treatment as `CommunitySectionLabel` on the community pages, so
/// a section reads the same wherever the reader meets it.
class FeedSectionHeader extends StatelessWidget {
  const FeedSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// An arbitrary trailing widget (the city chip). Ignored when [actionLabel]
  /// is given — a heading gets one affordance, not two.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(KolabingRadius.round),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.xs,
                vertical: 2,
              ),
              child: Row(
                children: [
                  Text(
                    actionLabel!,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurface,
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 15,
                    color: context.colors.onSurface,
                  ),
                ],
              ),
            ),
          )
        else if (trailing != null)
          trailing!,
      ],
    ),
  );
}

// =============================================================================
// Points strip
// =============================================================================

/// The attendee's points and event count, on one line.
///
/// Replaces the three stat cards that used to open the feed. They showed the
/// same numbers the profile already shows around the avatar, and they took the
/// top third of the screen to do it — so the events, which are the reason the
/// page exists, started below the fold.
class AttendeePointsStrip extends StatelessWidget {
  const AttendeePointsStrip({
    super.key,
    required this.points,
    required this.eventsAttended,
    this.onTap,
  });

  final int points;
  final int eventsAttended;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final number = NumberFormat.decimalPattern(locale);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KolabingRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.sm,
          vertical: KolabingSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(KolabingRadius.md),
          border: Border.all(color: context.colors.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.trophy,
              size: 16,
              color: context.colors.primaryDark,
            ),
            const SizedBox(width: KolabingSpacing.xs),
            Expanded(
              child: Text(
                l10n.attendeeFeedPointsStrip(
                  number.format(points),
                  eventsAttended,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.onSurface,
                ),
              ),
            ),
            if (onTap != null)
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: context.colors.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Your events
// =============================================================================

/// The events the viewer said they were going to, soonest first.
///
/// Each row carries its own day, because these are not grouped under a date
/// header: "Today, 19:30" is the whole point of the section.
class YourEventsSection extends ConsumerWidget {
  const YourEventsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final events = ref.watch(myUpcomingEventsProvider).value;
    if (events == null || events.isEmpty) return const SizedBox.shrink();

    final locale = Localizations.localeOf(context).toLanguageTag();
    final shown = events.take(kFeedMyEventsPreviewCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FeedSectionHeader(
          title: l10n.attendeeFeedYourEvents,
          actionLabel: events.length > shown.length
              ? l10n.attendeeFeedViewAll
              : null,
          onAction: events.length > shown.length
              ? () => context.push(KolabingRoutes.myEvents)
              : null,
        ),
        for (final event in shown)
          EventTimelineRow(
            event: event,
            locale: locale,
            showDay: true,
            showHost: true,
            // Your own sign-ups: you already have access, so "Members" on
            // every row would say nothing.
            showVisibility: false,
            onTap: () =>
                context.push(KolabingRoutes.buildEventDetailPath(event.id)),
          ),
      ],
    );
  }
}

// =============================================================================
// Communities you follow
