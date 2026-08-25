/// Building blocks for the one event page.
///
/// Same vocabulary as `community_page_sections.dart` — cover hero, identity,
/// nav rows, uppercase section labels — so an event and the community that runs
/// it read as one app. Every value here comes from a field `GET /events/{id}`
/// already returns; nothing is invented, and nothing is faked when absent (a
/// missing venue renders no row rather than "No location").
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/color_tokens.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/social_links_row.dart';
import '../models/event.dart';

// =============================================================================
// Hero
// =============================================================================

/// The cover: a photo carousel with dots, or the brand band when an event has
/// no photos. Used as the background of the screen's [SliverAppBar] so the back
/// button stays reachable however far the page scrolls.
class EventHeroBackground extends StatelessWidget {
  const EventHeroBackground({
    super.key,
    required this.photos,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  });

  final List<EventPhoto> photos;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      if (photos.isEmpty)
        _BrandBand()
      else
        PageView.builder(
          controller: controller,
          itemCount: photos.length,
          onPageChanged: onPageChanged,
          itemBuilder: (_, i) => Image.network(
            photos[i].url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _BrandBand(),
          ),
        ),

      // Scrim: the controls sit on top of whatever photo someone uploaded.
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.35),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),

      if (photos.length > 1)
        Positioned(
          bottom: KolabingSpacing.md,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < photos.length; i++)
                Container(
                  width: currentIndex == i ? 20 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: currentIndex == i
                        ? context.colors.primary
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ),
    ],
  );
}

class _BrandBand extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [context.colors.primary, context.colors.softYellow],
      ),
    ),
    child: const SizedBox.expand(),
  );
}

// =============================================================================
// Title block
// =============================================================================

/// Name, then the two facts that decide whether someone comes: when, and where.
///
/// The where-line is one tap to a maps app when the backend has coordinates or
/// an address — the old page printed an address that could not be acted on.
class EventTitleBlock extends StatelessWidget {
  const EventTitleBlock({
    super.key,
    required this.event,
    this.onDirections,
    this.statusLine,
  });

  final Event event;
  final VoidCallback? onDirections;

  /// The demoted RSVP state ("Going · tap to leave"), when there is one. It
  /// used to be the biggest control on the page while only ever *undoing* the
  /// thing the reader had already decided.
  final Widget? statusLine;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final where = _whereLine(event);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KolabingSpacing.md,
        KolabingSpacing.md,
        KolabingSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.name,
            style: KolabingTextStyles.headlineMedium.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          _Line(
            icon: LucideIcons.calendar,
            text: formatEventWhen(event, locale),
          ),
          if (where != null)
            _Line(
              icon: LucideIcons.mapPin,
              text: where,
              trailingIcon: onDirections == null
                  ? null
                  : LucideIcons.cornerUpRight,
              onTap: onDirections,
              semanticAction: l10n.eventPageDirections,
            ),
          const SizedBox(height: KolabingSpacing.xs),
          Wrap(
            spacing: KolabingSpacing.xs,
            runSpacing: KolabingSpacing.xs,
            children: [
              EventChip(
                icon: _visibilityIcon(event.visibility),
                label: visibilityLabel(l10n, event.visibility),
              ),
              if (event.isRecurring)
                EventChip(
                  icon: LucideIcons.repeat,
                  label: event.occurrenceIndex == null
                      ? l10n.eventPageRecurring
                      : l10n.eventPageSeriesOccurrence(event.occurrenceIndex!),
                ),
            ],
          ),
          if (statusLine != null) ...[
            const SizedBox(height: KolabingSpacing.xs),
            statusLine!,
          ],
        ],
      ),
    );
  }
}

/// "Mon 24 Aug · 18:00–20:00", or without the span when `ends_at` is absent.
String formatEventWhen(Event event, String locale) {
  final start = event.startsAt ?? event.date;
  final day = DateFormat('EEE d MMM', locale).format(start.toLocal());
  if (event.startsAt == null) return day;

  final from = DateFormat.Hm(locale).format(start.toLocal());
  final ends = event.endsAt;
  if (ends == null) return '$day · $from';
  return '$day · $from–${DateFormat.Hm(locale).format(ends.toLocal())}';
}

/// The venue's name and its city, skipping whichever the backend didn't send.
/// [Event.location] is the venue *name*, [Event.address] the street — printing
/// one under the other's label is how you send someone to the wrong door.
String? _whereLine(Event event) {
  final parts = <String>[
    if (event.location != null && event.location!.isNotEmpty) event.location!,
    if (event.address != null && event.address!.isNotEmpty) event.address!,
    if (event.cityName != null && event.cityName!.isNotEmpty) event.cityName!,
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

IconData _visibilityIcon(String? visibility) =>
    switch (visibility ?? 'members') {
      'public' => LucideIcons.globe,
      'tier' => LucideIcons.layers,
      _ => LucideIcons.users,
    };

String visibilityLabel(AppLocalizations l10n, String? visibility) =>
    switch (visibility ?? 'members') {
      'public' => l10n.communityEventVisibilityPublic,
      'tier' => l10n.communityEventVisibilityTier,
      _ => l10n.communityEventVisibilityMembers,
    };

class _Line extends StatelessWidget {
  const _Line({
    required this.icon,
    required this.text,
    this.trailingIcon,
    this.onTap,
    this.semanticAction,
  });

  final IconData icon;
  final String text;
  final IconData? trailingIcon;
  final VoidCallback? onTap;
  final String? semanticAction;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.colors.onSurfaceVariant),
          const SizedBox(width: KolabingSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: KolabingTextStyles.bodyMedium.copyWith(
                color: context.colors.inkBody,
              ),
            ),
          ),
          if (trailingIcon != null)
            Icon(
              trailingIcon,
              size: 16,
              color: context.colors.onSurfaceVariant,
              semanticLabel: semanticAction,
            ),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KolabingRadius.md),
      child: row,
    );
  }
}

/// Small outlined pill for event facts.
class EventChip extends StatelessWidget {
  const EventChip({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: KolabingSpacing.xs,
      vertical: 4,
    ),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(KolabingRadius.round),
      border: Border.all(color: context.colors.hairline),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: context.colors.onSurfaceVariant),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: KolabingTextStyles.bodySmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: context.colors.onSurface,
          ),
        ),
      ],
    ),
  );
}

// =============================================================================
// Host card
// =============================================================================

/// Who is running this, and how to reach them anywhere else.
///
/// The socials are the host's `community_profiles` handles — instagram, tiktok,
/// website, which is all that table stores. Each is self-gated: absent handles
/// render nothing rather than a dead icon.
class EventHostCard extends StatelessWidget {
  const EventHostCard({
    super.key,
    required this.hostName,
    required this.typeLabel,
    this.avatarUrl,
    this.about,
    this.instagram,
    this.tiktok,
    this.website,
    this.onOpen,
  });

  final String hostName;
  final String typeLabel;
  final String? avatarUrl;
  final String? about;
  final String? instagram;
  final String? tiktok;
  final String? website;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final aboutText = about?.trim();
    final card = Container(
      padding: const EdgeInsets.all(KolabingSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(KolabingRadius.lg),
        border: Border.all(color: context.colors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(name: hostName, url: avatarUrl),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hostName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KolabingTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colors.onSurface,
                      ),
                    ),
                    Text(
                      typeLabel,
                      style: KolabingTextStyles.bodySmall.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onOpen != null)
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: context.colors.onSurfaceVariant,
                ),
            ],
          ),
          if (aboutText != null && aboutText.isNotEmpty) ...[
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              aboutText,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.inkBody,
                height: 1.4,
              ),
            ),
          ],
          SocialLinksRow(
            instagram: instagram,
            tiktok: tiktok,
            website: website,
          ),
        ],
      ),
    );

    if (onOpen == null) return _pad(card);
    return _pad(
      InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(KolabingRadius.lg),
        child: card,
      ),
    );
  }

  Widget _pad(Widget child) => Padding(
    padding: const EdgeInsets.fromLTRB(
      KolabingSpacing.md,
      KolabingSpacing.md,
      KolabingSpacing.md,
      0,
    ),
    child: child,
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.url});

  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: context.colors.softYellow,
    ),
    child: ClipOval(
      child: url != null
          ? Image.network(url!, fit: BoxFit.cover, errorBuilder: _initial)
          : _initial(context, null, null),
    ),
  );

  Widget _initial(BuildContext context, Object? _, StackTrace? __) => Center(
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: KolabingTextStyles.bodyLarge.copyWith(
        fontWeight: FontWeight.w800,
        color: context.colors.onSurface,
      ),
    ),
  );
}

// =============================================================================
// Details
// =============================================================================

/// The facts the page used to throw away: how full it is, where the reader
/// stands in the queue, and who is allowed in at all.
class EventDetailsSection extends StatelessWidget {
  const EventDetailsSection({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spots = event.spotsLeft;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KolabingSpacing.md,
        KolabingSpacing.lg,
        KolabingSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EventSectionLabel(l10n.eventPageDetailsTitle),
          _Line(icon: LucideIcons.users, text: _capacityLine(l10n, spots)),
          if (event.isWaitlisted && event.waitlistPosition != null)
            _Line(
              icon: LucideIcons.clock,
              text: l10n.eventHubWaitlistPosition(event.waitlistPosition!),
            ),
          if (event.waitlistCount > 0 && !event.isWaitlisted)
            _Line(
              icon: LucideIcons.clock,
              text: l10n.eventHubWaitlistCount(event.waitlistCount),
            ),
          _Line(
            icon: _visibilityIcon(event.visibility),
            text: _whoCanSee(l10n, event),
          ),
        ],
      ),
    );
  }

  String _capacityLine(AppLocalizations l10n, int? spots) {
    final going = l10n.eventHubGoingCount(event.goingCount);
    if (event.capacity == null) return '$going · ${l10n.eventHubUnlimited}';
    return '$going · ${l10n.eventHubCapacity(event.capacity!)} · '
        '${l10n.eventHubSpotsLeft(spots ?? 0)}';
  }

  /// Tier-gating is stricter than the visibility flag, so it wins the sentence
  /// — a "members" event with a tier gate is not open to every member.
  String _whoCanSee(AppLocalizations l10n, Event event) {
    if (event.isTierGated) return l10n.eventPageWhoCanSeeTier;
    return switch (event.visibility ?? 'members') {
      'public' => l10n.eventPageWhoCanSeePublic,
      'tier' => l10n.eventPageWhoCanSeeTier,
      _ => l10n.eventPageWhoCanSeeMembers,
    };
  }
}

// =============================================================================
// Shared bits
// =============================================================================

/// Uppercase tracked-out section label, matching the community pages.
class EventSectionLabel extends StatelessWidget {
  const EventSectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text.toUpperCase(),
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

/// Full-width tappable row: chat, challenges, the attendee roster.
class EventNavRow extends StatelessWidget {
  const EventNavRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.busy = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      KolabingSpacing.md,
      KolabingSpacing.xs,
      KolabingSpacing.md,
      0,
    ),
    child: Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(KolabingRadius.lg),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(KolabingRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(KolabingSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KolabingRadius.lg),
            border: Border.all(color: context.colors.hairline),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: busy
                    ? const Padding(
                        padding: EdgeInsets.all(9),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(icon, size: 18, color: context.colors.onSurface),
              ),
              const SizedBox(width: KolabingSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: KolabingTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colors.onSurface,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: context.colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// =============================================================================
// Action bar
// =============================================================================

/// The sticky bottom bar. Holds at most two actions, because a door is not the
/// place to choose between five.
class EventActionBar extends StatelessWidget {
  const EventActionBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.sm),
          child: Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: KolabingSpacing.xs),
                Expanded(child: children[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One action in [EventActionBar].
///
/// `minimumSize` is bounded on purpose: the theme gives every button an
/// infinite minimum width for full-width forms, which inside a Row starves its
/// siblings to zero (see FX-48 and the rule-4 guardrail in
/// `test/lints/button_style_lint_test.dart`).
class EventActionButton extends StatelessWidget {
  const EventActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.filled,
    this.onTap,
    this.busy = false,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon, size: 18);
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: KolabingTextStyles.bodyMedium.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );

    if (filled) {
      return FilledButton.icon(
        onPressed: busy ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: context.colors.primary,
          foregroundColor: context.colors.onPrimary,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.sm),
        ),
        icon: child,
        label: text,
      );
    }
    return OutlinedButton.icon(
      onPressed: busy ? null : onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: context.colors.onSurface,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.sm),
      ),
      icon: child,
      label: text,
    );
  }
}

/// The RSVP state, demoted from a slab to a line of text with a quiet undo.
class EventStatusLine extends StatelessWidget {
  const EventStatusLine({
    super.key,
    required this.label,
    required this.icon,
    required this.fill,
    required this.ink,
    this.onUndo,
    this.busy = false,
  });

  final String label;
  final IconData icon;
  final Color fill;
  final Color ink;
  final VoidCallback? onUndo;
  final bool busy;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: KolabingSpacing.xs,
      vertical: 5,
    ),
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(KolabingRadius.round),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (busy)
          SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(strokeWidth: 2, color: ink),
          )
        else
          Icon(icon, size: 14, color: ink),
        const SizedBox(width: KolabingSpacing.xxs),
        Text(
          label,
          style: KolabingTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
        if (onUndo != null) ...[
          const SizedBox(width: KolabingSpacing.xxs),
          InkWell(
            onTap: busy ? null : onUndo,
            borderRadius: BorderRadius.circular(KolabingRadius.round),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(LucideIcons.x, size: 13, color: ink),
            ),
          ),
        ],
      ],
    ),
  );
}
