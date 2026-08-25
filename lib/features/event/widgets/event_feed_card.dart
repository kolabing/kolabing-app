import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/color_tokens.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/blurred_identity.dart';
import '../models/event.dart';
import 'event_timeline.dart';

/// One event, as the same card a business or community meets in Explore.
///
/// Deliberately the same anatomy as `ExploreSwipeCard`: a 16:10 photo area with
/// a swipeable carousel and dot indicators, then a content block of
/// byline → headline → meta → chips → divider → "View Details ›". Explore and
/// the events feed are the two browsing surfaces in the app and there was no
/// reason for an event to be a 72px thumbnail row while a Kolab was a
/// photograph.
///
/// **What is not copied:** Explore's card body is unconditionally white, which
/// forces its chips to `forceLightSurface` or dark mode puts near-black pills on
/// a white card. This one paints `context.colors.surface`, so it is theme-correct
/// and its chips need no override.
///
/// **Hierarchy differs from Explore's on purpose.** Explore leads with the
/// creator, because there you are evaluating *who*. Here the event's own name is
/// the headline and the host is the byline above it, because you are choosing
/// *what to go to* — and that is also the order the timeline row already used.
class EventFeedCard extends StatefulWidget {
  const EventFeedCard({
    required this.event,
    required this.locale,
    required this.onTap,
    this.showHost = true,
    this.showVisibility = false,
    super.key,
  });

  final Event event;
  final String locale;
  final VoidCallback onTap;

  /// The host's logo and name above the title. Off on a community's own page,
  /// where every event has the same host.
  final bool showHost;

  /// City discovery only ever returns public events, so a "Public" chip on every
  /// row says nothing. On community surfaces it is the point.
  final bool showVisibility;

  @override
  State<EventFeedCard> createState() => _EventFeedCardState();
}

class _EventFeedCardState extends State<EventFeedCard> {
  late final PageController _imagePageController;
  int _currentImagePage = 0;

  Event get _event => widget.event;

  bool get _locked => !_event.canAccess;

  /// Every photo, falling back to the host's logo so a photoless event is still
  /// a card rather than a grey rectangle.
  List<String> get _imageUrls {
    final urls = <String>[
      for (final photo in _event.photos)
        if (photo.url.isNotEmpty) photo.url,
    ];
    if (urls.isEmpty) {
      final logo = _event.partner.profilePhoto;
      if (logo != null && logo.isNotEmpty) urls.add(logo);
    }
    return urls;
  }

  String get _hostName {
    final community = _event.communityName;
    if (community != null && community.isNotEmpty) return community;
    return _event.partner.name;
  }

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.xs),
    child: Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(KolabingRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KolabingRadius.lg),
            border: Border.all(color: context.colors.hairline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_buildPhotoSection(), _buildContentSection(context)],
          ),
        ),
      ),
    ),
  );

  // ---------------------------------------------------------------------------
  // Photo section
  // ---------------------------------------------------------------------------

  Widget _buildPhotoSection() => AspectRatio(
    aspectRatio: 16 / 10,
    child: Stack(
      fit: StackFit.expand,
      children: [
        _buildImageArea(),
        if (_imageUrls.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: KolabingSpacing.xs,
            child: Center(child: _buildDotIndicators()),
          ),
      ],
    ),
  );

  Widget _buildImageArea() {
    final urls = _imageUrls;
    if (urls.isEmpty) return EventThumbPlaceholder(locked: _locked);

    return PageView.builder(
      controller: _imagePageController,
      itemCount: urls.length,
      onPageChanged: (int index) => setState(() => _currentImagePage = index),
      itemBuilder: (BuildContext context, int index) {
        final image = Image.network(
          urls[index],
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => EventThumbPlaceholder(locked: _locked),
        );
        // A members-only event a stranger can see the existence of but not the
        // inside of: the picture is the thing to withhold, and the lock hint
        // says why rather than leaving a blurred rectangle unexplained.
        if (!_locked) return image;
        return BlurredIdentity(
          enabled: true,
          sigma: 18,
          showLockHint: true,
          child: image,
        );
      },
    );
  }

  Widget _buildDotIndicators() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(KolabingRadius.round),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_imageUrls.length, (int index) {
        final isActive = index == _currentImagePage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 9 : 7,
          height: isActive ? 9 : 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? Colors.white
                : Colors.white.withValues(alpha: 0.45),
          ),
        );
      }),
    ),
  );

  // ---------------------------------------------------------------------------
  // Content section
  // ---------------------------------------------------------------------------

  Widget _buildContentSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muted = context.colors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHost) ...[
            _buildHostRow(context),
            const SizedBox(height: 5),
          ],
          Text(
            _event.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: KolabingTextStyles.bodyLarge.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.3,
              color: _locked ? muted : context.colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          _buildMetaRow(context, l10n),
          if (_chips(context, l10n) case final chips when chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: KolabingSpacing.xxs,
              runSpacing: KolabingSpacing.xxs,
              children: chips,
            ),
          ],
          const SizedBox(height: 10),
          Divider(height: 1, thickness: 1, color: context.colors.hairline),
          const SizedBox(height: 10),
          _buildViewDetailsRow(context, l10n),
        ],
      ),
    );
  }

  Widget _buildHostRow(BuildContext context) {
    final logo = _event.partner.profilePhoto;
    final name = _hostName;

    return Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: 18,
            height: 18,
            child: logo != null && logo.isNotEmpty
                ? Image.network(
                    logo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _HostInitial(name: name),
                  )
                : _HostInitial(name: name),
          ),
        ),
        const SizedBox(width: KolabingSpacing.xxs),
        Flexible(
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
    );
  }

  /// `18:00 · Eixample 46` — Explore's one-line meta row rather than the
  /// timeline's stacked icon lines, because on a card the width is there.
  Widget _buildMetaRow(BuildContext context, AppLocalizations l10n) {
    final style = KolabingTextStyles.bodySmall.copyWith(
      color: context.colors.textTertiary,
    );

    if (_locked) {
      return Row(
        children: [
          Icon(LucideIcons.lock, size: 12, color: context.colors.textTertiary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              l10n.communityDetailEventLockedSubtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      );
    }

    final startsAt = _event.startsAt;
    final venue = _event.location ?? _event.address;
    final hasVenue = venue != null && venue.isNotEmpty;

    return Row(
      children: [
        if (startsAt != null) ...[
          Icon(LucideIcons.clock, size: 12, color: context.colors.textTertiary),
          const SizedBox(width: 4),
          Text(DateFormat.Hm(widget.locale).format(startsAt), style: style),
        ],
        if (startsAt != null && hasVenue) Text(' · ', style: style),
        if (hasVenue) ...[
          Icon(LucideIcons.mapPin, size: 12, color: context.colors.textTertiary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              venue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _chips(BuildContext context, AppLocalizations l10n) => [
    if (_event.isGoing)
      EventMiniChip(
        label: l10n.communityEventBadgeGoing,
        fill: context.colors.activeBg,
        ink: context.colors.activeText,
      ),
    if (_event.isWaitlisted)
      EventMiniChip(
        label: l10n.communityEventBadgeWaitlisted,
        fill: context.colors.pendingBg,
        ink: context.colors.pendingText,
      ),
    if (eventCapacityBadge(l10n, _event) case final badge?)
      EventMiniChip(
        label: badge,
        fill: context.colors.surfaceContainerHigh,
        ink: context.colors.onSurfaceVariant,
      ),
    if (widget.showVisibility)
      EventVisibilityChip(visibility: _event.visibility),
  ];

  Widget _buildViewDetailsRow(BuildContext context, AppLocalizations l10n) =>
      Row(
        children: [
          Text(
            l10n.exploreSwipeCardViewDetails,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.onSurface,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: context.colors.onSurface,
          ),
        ],
      );
}

class _HostInitial extends StatelessWidget {
  const _HostInitial({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.colors.surfaceContainerHigh,
    child: Center(
      child: Text(
        name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
        style: KolabingTextStyles.bodySmall.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ),
  );
}
