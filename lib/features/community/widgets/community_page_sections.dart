/// Shared building blocks for the two community pages.
///
/// Both the member/leader page ([CommunityDetailScreen]) and the public
/// attendee-facing profile ([AttendeeCommunityProfileScreen]) are one
/// uninterrupted scroll built from these pieces, in this order:
///
///   cover hero  →  identity (name · about · meta)  →  a nav row (membership,
///   points, members)  →  tag chips  →  events grouped by date  →  sections
///
/// The layout follows Luma's community page; the palette stays Kolabing's
/// (cream page, white surfaces, ink text, yellow accents). Nothing here invents
/// data: there is no cover-photo or social-handle field on `Community` today,
/// so the hero paints the community avatar blurred (falling back to the brand
/// gradient) rather than showing a placeholder for a field that does not exist.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/color_tokens.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../event/models/event.dart';

// =============================================================================
// Cover hero
// =============================================================================

/// Full-bleed cover band with the community logo tile overlapping its lower
/// edge, plus the back button and any trailing circle actions.
class CommunityCoverHero extends StatelessWidget {
  const CommunityCoverHero({
    super.key,
    required this.name,
    this.avatarUrl,
    this.showBack = true,
    this.actions = const <Widget>[],
  });

  /// Cover band height, before the logo overhang.
  static const double coverHeight = 168;

  /// Edge of the square logo tile.
  static const double logoSize = 96;

  /// How far the logo tile sits below the cover band.
  static const double overhang = 44;

  final String name;
  final String? avatarUrl;

  /// False for the leader's embedded COMMUNITY tab, which is not a pushed route.
  final bool showBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: coverHeight + overhang,
    child: Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: coverHeight,
          child: _Cover(avatarUrl: avatarUrl),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(KolabingSpacing.xs),
              child: Row(
                children: [
                  if (showBack)
                    CommunityHeroAction(
                      icon: LucideIcons.arrowLeft,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  const Spacer(),
                  ...actions,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: KolabingSpacing.md,
          bottom: 0,
          child: _LogoTile(name: name, avatarUrl: avatarUrl),
        ),
      ],
    ),
  );
}

/// Translucent circular icon button for use on top of the cover band.
class CommunityHeroAction extends StatelessWidget {
  const CommunityHeroAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.only(left: KolabingSpacing.xs),
      child: Material(
        color: Colors.black.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
    return tooltip == null ? child : Tooltip(message: tooltip!, child: child);
  }
}

class _Cover extends StatelessWidget {
  const _Cover({this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl == null) return const _BrandCover();
    return Stack(
      fit: StackFit.expand,
      children: [
        // No cover-photo field exists yet, so the avatar stands in — blurred
        // hard enough to read as a band of colour, not a stretched logo.
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(
            sigmaX: 28,
            sigmaY: 28,
            tileMode: TileMode.clamp,
          ),
          child: Image.network(
            avatarUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const _BrandCover(),
          ),
        ),
        ColoredBox(color: Colors.black.withValues(alpha: 0.16)),
      ],
    );
  }
}

class _BrandCover extends StatelessWidget {
  const _BrandCover();

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

class _LogoTile extends StatelessWidget {
  const _LogoTile({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) => Container(
    width: CommunityCoverHero.logoSize,
    height: CommunityCoverHero.logoSize,
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(KolabingRadius.xl),
      border: Border.all(color: context.colors.surface, width: 3),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(KolabingRadius.xl - 3),
      child: avatarUrl != null
          ? Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _Initial(name: name),
            )
          : _Initial(name: name),
    ),
  );
}

class _Initial extends StatelessWidget {
  const _Initial({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.colors.softYellow,
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: KolabingTextStyles.displaySmall.copyWith(
          color: context.colors.onSurface,
        ),
      ),
    ),
  );
}

// =============================================================================
// Identity block
// =============================================================================

/// Name, about text and the meta line, left-aligned under the logo tile.
class CommunityIdentityBlock extends StatelessWidget {
  const CommunityIdentityBlock({
    super.key,
    required this.name,
    this.description,
    this.metaText,
    this.metaIcon = LucideIcons.users,
  });

  final String name;
  final String? description;
  final String? metaText;
  final IconData metaIcon;

  @override
  Widget build(BuildContext context) {
    final about = description?.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KolabingSpacing.md,
        KolabingSpacing.sm,
        KolabingSpacing.md,
        KolabingSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: KolabingTextStyles.headlineMedium.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          if (about != null && about.isNotEmpty) ...[
            const SizedBox(height: KolabingSpacing.xs),
            _ExpandableText(text: about),
          ],
          if (metaText != null) ...[
            const SizedBox(height: KolabingSpacing.xs),
            Row(
              children: [
                Icon(
                  metaIcon,
                  size: 15,
                  color: context.colors.onSurfaceVariant,
                ),
                const SizedBox(width: KolabingSpacing.xxs),
                Expanded(
                  child: Text(
                    metaText!,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Three lines of about text, tap to expand. Long community descriptions used
/// to push everything else off the first screen.
class _ExpandableText extends StatefulWidget {
  const _ExpandableText({required this.text});

  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => _expanded = !_expanded),
    child: Text(
      widget.text,
      maxLines: _expanded ? null : 3,
      overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
      style: KolabingTextStyles.bodyMedium.copyWith(
        color: context.colors.inkBody,
        height: 1.4,
      ),
    ),
  );
}

// =============================================================================
// Nav row — the membership / points / roster rows
// =============================================================================

/// Full-width tappable row with a tinted icon puck, title, subtitle and
/// chevron. Luma's "Membership pending" row; here also points/tier and roster.
class CommunityNavRow extends StatelessWidget {
  const CommunityNavRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tint = iconColor ?? context.colors.primary;
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: context.colors.onSurface),
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
          if (trailing != null) trailing!,
          if (onTap != null)
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: context.colors.onSurfaceVariant,
            ),
        ],
      ),
    );

    final bordered = DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          top: BorderSide(color: context.colors.hairline),
          bottom: BorderSide(color: context.colors.hairline),
        ),
      ),
      child: row,
    );

    if (onTap == null) return bordered;
    return Material(
      color: context.colors.surface,
      child: InkWell(onTap: onTap, child: bordered),
    );
  }
}

// =============================================================================
// Chips + section labels
// =============================================================================

/// Outlined pill: a category with an optional count ("Wellness 1").
class CommunityTagChip extends StatelessWidget {
  const CommunityTagChip({super.key, required this.label, this.count});

  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: KolabingSpacing.sm,
      vertical: KolabingSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(KolabingRadius.round),
      border: Border.all(color: context.colors.hairline),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: KolabingTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colors.onSurface,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: KolabingSpacing.xs),
          Text(
            '$count',
            style: KolabingTextStyles.bodySmall.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    ),
  );
}

/// Uppercase tracked-out section label ("REWARDS").
class CommunitySectionLabel extends StatelessWidget {
  const CommunitySectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
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

// =============================================================================
// Event timeline
// =============================================================================

/// Upcoming events grouped under a "6 September / Sunday" date header, in the
/// caller's locale. Bare rows on the page background, Luma-style — no cards.
class CommunityEventTimeline extends StatelessWidget {
  const CommunityEventTimeline({
    super.key,
    required this.events,
    required this.onOpen,
    this.onLocked,
  });

  final List<Event> events;
  final void Function(Event event) onOpen;

  /// Tapped an event the viewer cannot access (tier/members gated).
  final void Function(Event event)? onLocked;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dayFormat = DateFormat('d MMMM', locale);
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
                  dayFormat.format(day),
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
            _EventRow(
              event: event,
              locale: locale,
              onTap: () =>
                  event.canAccess ? onOpen(event) : (onLocked ?? onOpen)(event),
            ),
        ],
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.locale,
    required this.onTap,
  });

  final Event event;
  final String locale;
  final VoidCallback onTap;

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
                            _EventThumbPlaceholder(locked: locked),
                      )
                    : _EventThumbPlaceholder(locked: locked),
              ),
            ),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    _MetaLine(
                      icon: LucideIcons.lock,
                      text: l10n.communityDetailEventLockedSubtitle,
                    )
                  else ...[
                    if (startsAt != null)
                      _MetaLine(
                        icon: LucideIcons.clock,
                        text: DateFormat.Hm(locale).format(startsAt),
                      ),
                    if (event.location != null && event.location!.isNotEmpty)
                      _MetaLine(
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
                        CommunityMiniChip(
                          label: l10n.communityEventBadgeGoing,
                          fill: context.colors.activeBg,
                          ink: context.colors.activeText,
                        ),
                      if (event.isWaitlisted)
                        CommunityMiniChip(
                          label: l10n.communityEventBadgeWaitlisted,
                          fill: context.colors.pendingBg,
                          ink: context.colors.pendingText,
                        ),
                      CommunityEventVisibilityChip(
                        visibility: event.visibility,
                      ),
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
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

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

class _EventThumbPlaceholder extends StatelessWidget {
  const _EventThumbPlaceholder({required this.locked});

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
class CommunityMiniChip extends StatelessWidget {
  const CommunityMiniChip({
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
class CommunityEventVisibilityChip extends StatelessWidget {
  const CommunityEventVisibilityChip({super.key, this.visibility});

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
    return CommunityMiniChip(
      label: label,
      icon: icon,
      fill: context.colors.surfaceContainerHigh,
      ink: context.colors.onSurfaceVariant,
    );
  }
}
