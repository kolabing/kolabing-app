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

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/color_tokens.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/hero_circle_action.dart';
import '../../../widgets/social_links_row.dart';
import '../../profile/providers/gallery_provider.dart';
import '../../../widgets/gallery/photo_viewer_dialog.dart';

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
    this.coverUrl,
    this.showBack = true,
    this.actions = const <Widget>[],
    this.onTapCover,
    this.onTapLogo,
  });

  /// Tapping the cover band. Null on the pages where the viewer owns nothing
  /// here, which is every page except the leader's own (#174).
  final VoidCallback? onTapCover;

  /// Tapping the logo tile.
  final VoidCallback? onTapLogo;

  /// Cover band height, before the logo overhang.
  static const double coverHeight = 168;

  /// Edge of the square logo tile.
  static const double logoSize = 96;

  /// How far the logo tile sits below the cover band.
  static const double overhang = 44;

  final String name;
  final String? avatarUrl;

  /// A real photograph for the cover band — the community's curated gallery or,
  /// failing that, one of its own event photos. Without one the band falls back
  /// to the blurred avatar, and without that to the brand gradient.
  final String? coverUrl;

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
          child: _Tappable(
            onTap: onTapCover,
            child: _Cover(coverUrl: coverUrl),
          ),
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
                  if (showBack) const HeroBackButton(),
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
          child: _Tappable(
            onTap: onTapLogo,
            // A pencil badge only where the tap exists, so the affordance and
            // the capability cannot disagree.
            badge: onTapLogo != null,
            child: _LogoTile(name: name, avatarUrl: avatarUrl),
          ),
        ),
      ],
    ),
  );
}

/// Wraps a hero element in a tap target, and only then advertises it.
///
/// With no `onTap` this is the bare child — the attendee-facing page and the
/// member's view render exactly as before.
class _Tappable extends StatelessWidget {
  const _Tappable({required this.child, this.onTap, this.badge = false});

  final Widget child;
  final VoidCallback? onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return child;

    // No Positioned.fill and no ClipRRect here. Both elements are already
    // placed by the hero's own Stack, so filling swallowed the logo tile's
    // geometry entirely and the rounding leaked onto the cover band.
    // This wrapper must be size-neutral: it adds a gesture, nothing else.
    final tappable = Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: child),
    );
    if (!badge) return tappable;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        tappable,
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: context.colors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: context.colors.outlineVariant),
            ),
            child: Icon(
              LucideIcons.pencil,
              size: 13,
              color: context.colors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({this.coverUrl});

  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    // A real photo is shown as a photo: sharp, filling the band, with a scrim
    // so the white controls stay readable over whatever was uploaded.
    if (coverUrl != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            coverUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const _BrandCover(),
          ),
          ColoredBox(color: Colors.black.withValues(alpha: 0.22)),
        ],
      );
    }
    // No cover set: the brand band, NOT a blurred copy of the logo.
    //
    // The blur used to stand in because there was no cover-photo field to read
    // — which meant every community's "background" was its own avatar, with no
    // way to change it. `community_profiles.cover_photo` exists now
    // (kolabing-v2#239), so an absent cover should look absent rather than
    // quietly reuse the one picture the community did set.
    return const _BrandCover();
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
    this.instagram,
    this.tiktok,
    this.website,
  });

  final String name;
  final String? description;
  final String? metaText;
  final IconData metaIcon;

  /// The community owner's handles. They have existed on `community_profiles`
  /// all along; this page rendered a `SizedBox.shrink()` where they belong.
  final String? instagram;
  final String? tiktok;
  final String? website;

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
          Padding(
            padding: const EdgeInsets.only(top: KolabingSpacing.xs),
            child: SocialLinksRow(
              instagram: instagram,
              tiktok: tiktok,
              website: website,
            ),
          ),
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
  const CommunityTagChip({
    super.key,
    required this.label,
    this.count,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final int? count;

  /// Filled when this chip is the active filter.
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.sm,
        vertical: KolabingSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: selected ? context.colors.primary : context.colors.surface,
        borderRadius: BorderRadius.circular(KolabingRadius.round),
        border: Border.all(
          color: selected ? context.colors.primary : context.colors.hairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: selected
                  ? context.colors.onPrimary
                  : context.colors.onSurface,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: KolabingSpacing.xs),
            Text(
              '$count',
              style: KolabingTextStyles.bodySmall.copyWith(
                color: selected
                    ? context.colors.onPrimary
                    : context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return chip;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KolabingRadius.round),
      child: chip,
    );
  }
}

// =============================================================================
// Photos
// =============================================================================

/// The community's photographs.
///
/// Fed by `communityPhotosProvider`: the owner's curated gallery when there is
/// one, the community's own event photos when there is not. Renders nothing at
/// all when there are neither — an empty "Photos" heading is worse than no
/// heading.
class CommunityPhotoStrip extends StatelessWidget {
  const CommunityPhotoStrip({super.key, required this.photos});

  final List<GalleryPhoto> photos;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommunitySectionLabel(l10n.communityPagePhotosTitle),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: KolabingSpacing.xs),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => PhotoViewerDialog.show(
                context,
                photos: photos,
                initialIndex: i,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(KolabingRadius.md),
                child: Image.network(
                  photos[i].url,
                  width: 104,
                  height: 104,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 104,
                    height: 104,
                    color: context.colors.surfaceContainerHigh,
                    child: Icon(
                      LucideIcons.image,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Event filters
// =============================================================================

/// What the timeline is showing.
enum CommunityEventFilter { upcoming, past, publicOnly, membersOnly }

/// Luma puts category chips with counts above its event list. We have no event
/// categories, so these are the honest equivalents — when it is, and who it is
/// for — and unlike a decoration, they filter.
class CommunityFilterChips extends StatelessWidget {
  const CommunityFilterChips({
    super.key,
    required this.counts,
    required this.selected,
    required this.onSelect,
  });

  final Map<CommunityEventFilter, int> counts;
  final CommunityEventFilter selected;
  final ValueChanged<CommunityEventFilter> onSelect;

  String _label(AppLocalizations l10n, CommunityEventFilter filter) =>
      switch (filter) {
        CommunityEventFilter.upcoming => l10n.communityPageFilterUpcoming,
        CommunityEventFilter.past => l10n.communityPageFilterPast,
        CommunityEventFilter.publicOnly => l10n.communityEventVisibilityPublic,
        CommunityEventFilter.membersOnly =>
          l10n.communityEventVisibilityMembers,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // A filter nothing would match is a dead end; only offer what has rows.
    final available = CommunityEventFilter.values
        .where((f) => f == selected || (counts[f] ?? 0) > 0)
        .toList();
    if (available.length < 2) return const SizedBox.shrink();

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: available.length,
        separatorBuilder: (_, _) => const SizedBox(width: KolabingSpacing.xs),
        itemBuilder: (_, i) {
          final filter = available[i];
          return CommunityTagChip(
            label: _label(l10n, filter),
            count: counts[filter] ?? 0,
            selected: filter == selected,
            onTap: () => onSelect(filter),
          );
        },
      ),
    );
  }
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
