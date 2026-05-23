import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../config/constants/radius.dart';
import '../config/constants/spacing.dart';
import '../config/theme/colors.dart';
import '../features/discovery/models/discovery_item.dart';
import '../features/opportunity/models/opportunity.dart';
import 'blurred_identity.dart';
import 'match_breakdown.dart';

class ExploreSwipeCard extends StatefulWidget {
  const ExploreSwipeCard({
    required this.item,
    this.onTap,
    this.showKolabFirst = false,
    this.hideCreatorIdentity = false,
    super.key,
  });

  final DiscoveryItem item;
  final VoidCallback? onTap;
  final bool showKolabFirst;
  final bool hideCreatorIdentity;

  @override
  State<ExploreSwipeCard> createState() => _ExploreSwipeCardState();
}

class _ExploreSwipeCardState extends State<ExploreSwipeCard> {
  late final PageController _imagePageController;
  int _currentImagePage = 0;

  DiscoveryItem get _item => widget.item;
  bool get _isBusinessExploreCommunityCard =>
      widget.showKolabFirst && _item.isCommunityRequest;

  List<String> get _imageUrls {
    final urls = <String>[];
    final cover = _item.coverPhotoUrl;
    if (cover != null && cover.isNotEmpty) urls.add(cover);
    // Fall back to the creator's logo/avatar only when there is no Kolab cover
    // photo. We now keep it even when identity is hidden, because the blur (not
    // removal) is what protects the community logo — see [_isIdentityLogo].
    if (urls.isEmpty) {
      final avatar = _item.creatorProfile.avatarUrl;
      if (avatar != null && avatar.isNotEmpty) urls.add(avatar);
    }
    return urls;
  }

  /// The community LOGO (creator avatar) used as the fallback hero image. The
  /// Kolab cover photo is Kolab content and is NEVER blurred; only this logo is.
  bool _isIdentityLogo(String url) {
    final avatar = _item.creatorProfile.avatarUrl;
    final cover = _item.coverPhotoUrl;
    final usingAvatarFallback = cover == null || cover.isEmpty;
    return usingAvatarFallback &&
        avatar != null &&
        avatar.isNotEmpty &&
        url == avatar;
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
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.xs,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(KolabingRadius.xl),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImageArea(),
            _buildGradientOverlay(),
            _buildOverlaidContent(),
          ],
        ),
      ),
    ),
  );

  Widget _buildImageArea() {
    final urls = _imageUrls;

    if (urls.isEmpty) {
      return _buildGradientFallback();
    }

    return PageView.builder(
      controller: _imagePageController,
      itemCount: urls.length,
      onPageChanged: (int index) => setState(() => _currentImagePage = index),
      itemBuilder: (BuildContext context, int index) {
        final url = urls[index];
        final image = Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) =>
              _buildGradientFallback(),
          loadingBuilder:
              (BuildContext context, Widget child, ImageChunkEvent? progress) {
                if (progress == null) return child;
                return _buildImagePlaceholder(progress);
              },
        );

        // Blur ONLY the community logo (avatar fallback) for a free business.
        // Kolab cover photos stay sharp so all Kolab details remain visible.
        return BlurredIdentity(
          enabled: widget.hideCreatorIdentity && _isIdentityLogo(url),
          sigma: 18,
          showLockHint: true,
          child: image,
        );
      },
    );
  }

  Widget _buildGradientFallback() => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          KolabingColors.primary.withValues(alpha: 0.3),
          KolabingColors.surfaceVariant,
        ],
      ),
    ),
    child: Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: KolabingColors.primary.withValues(alpha: 0.15),
          border: Border.all(
            color: KolabingColors.primary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          !widget.hideCreatorIdentity &&
                  _item.creatorProfile.displayName.isNotEmpty
              ? _item.creatorProfile.displayName[0].toUpperCase()
              : '?',
          style: GoogleFonts.rubik(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: KolabingColors.textPrimary.withValues(alpha: 0.6),
          ),
        ),
      ),
    ),
  );

  Widget _buildImagePlaceholder(ImageChunkEvent progress) {
    final expectedBytes = progress.expectedTotalBytes;
    final value = expectedBytes != null
        ? progress.cumulativeBytesLoaded / expectedBytes
        : null;

    return ColoredBox(
      color: KolabingColors.surfaceVariant,
      child: Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: 2.5,
            color: KolabingColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    final hasImages = _imageUrls.isNotEmpty;
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.42, 1.0],
              colors: hasImages
                  ? <Color>[
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.32),
                      Colors.black.withValues(alpha: 0.9),
                    ]
                  : <Color>[
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.72),
                    ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDotIndicators() {
    final count = _imageUrls.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (int index) {
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
  }

  Widget _buildOverlaidContent() => Positioned(
    left: KolabingSpacing.md,
    right: KolabingSpacing.md,
    bottom: KolabingSpacing.md + MediaQuery.of(context).padding.bottom * 0.2,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderRow(),
        const SizedBox(height: KolabingSpacing.xs),
        if (_imageUrls.length > 1) ...[
          _buildDotIndicators(),
          const SizedBox(height: KolabingSpacing.xs),
        ],
        if (_isBusinessExploreCommunityCard) ...[
          _buildKolabTitle(),
          const SizedBox(height: KolabingSpacing.xs),
          _buildCreatorIdentity(),
          // Concrete offer banner — mirrors the community-side headline banner
          // so both feeds present the offer with the same clean treatment
          // (e.g. "Social Media · 30+ people") instead of a plain text row.
          if (_item.communityOfferLine case final offerLine?) ...[
            const SizedBox(height: KolabingSpacing.sm),
            _buildHeadlineBanner(offerLine),
          ],
          const SizedBox(height: KolabingSpacing.sm),
          _buildBusinessExploreHighlights(),
        ] else ...[
          _buildStandardInfoPanel(),
        ],
      ],
    ),
  );

  Widget _buildHeaderRow() => Row(
    children: [
      _buildCreatorTypeBadge(),
      const Spacer(),
      if (_item.match != null) _buildFitBadge(),
    ],
  );

  Widget _buildCreatorTypeBadge() {
    final label = _isBusinessExploreCommunityCard
        ? 'Kolab'
        : _item.isBusinessOffer
        ? 'Business Offer'
        : 'Community Request';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.xs,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(KolabingRadius.round),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFitBadge() {
    final match = _item.match!;
    final hasBreakdown = match.breakdown.isNotEmpty;

    // H1: when we have a breakdown, render the % + mini-bars stacked. Falls
    // back to the legacy single-pill badge for backward compatibility.
    if (!hasBreakdown) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.xs,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: KolabingColors.softYellow.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(KolabingRadius.round),
        ),
        child: Text(
          '${match.score}% fit',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 160),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.sm,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: KolabingColors.softYellow.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(KolabingRadius.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${match.score}% match',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            MatchBreakdown(
              signals: match.breakdown,
              compact: true,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKolabTitle() => Text(
    _item.title,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: GoogleFonts.rubik(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      height: 1.15,
    ),
  );

  Widget _buildCreatorName() => Text(
    _item.creatorProfile.displayName,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: GoogleFonts.rubik(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
  );

  Widget _buildStandardInfoPanel() {
    final headline = _item.displayHeadline;
    final activityBadge = _item.activityBadgeLabel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(KolabingRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCreatorName(),
          if (_item.locationLabel.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildLocationRow(),
          ],
          if (headline != null) ...[
            const SizedBox(height: KolabingSpacing.sm),
            _buildHeadlineBanner(headline),
          ],
          const SizedBox(height: KolabingSpacing.sm),
          _buildMetaChips(activityBadge: activityBadge),
          const SizedBox(height: KolabingSpacing.sm),
          _buildAvailabilityRow(),
        ],
      ),
    );
  }

  Widget _buildCreatorIdentity() {
    final isHidden = widget.hideCreatorIdentity;
    // Per ROLES-AND-PERMISSIONS.md §2.5: do NOT hide the name behind a
    // placeholder. Render the real community name and Gaussian-blur it so the
    // free business sees there IS an identity to unlock by subscribing.
    final nameText = Text(
      _item.creatorProfile.displayName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.openSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.82),
      ),
    );

    return Row(
      children: [
        Icon(
          isHidden ? Icons.lock_outline_rounded : Icons.groups_rounded,
          size: 14,
          color: Colors.white.withValues(alpha: 0.78),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: BlurredIdentity(
            enabled: isHidden,
            sigma: 6,
            // Lock hint already provided by the leading icon + the card sheet
            // CTA; keep the inline text clean.
            child: nameText,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow() => Row(
    children: [
      Icon(
        Icons.location_on_outlined,
        size: 14,
        color: Colors.white.withValues(alpha: 0.78),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          _item.locationLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.openSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.84),
          ),
        ),
      ),
    ],
  );

  Widget _buildHeadlineBanner(String headline) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: KolabingSpacing.sm,
      vertical: 10,
    ),
    decoration: BoxDecoration(
      color: KolabingColors.softYellow.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(KolabingRadius.md),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.bolt_rounded, size: 16, color: Colors.black),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            headline,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: Colors.black,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildMetaChips({required String? activityBadge}) {
    final badges = _item.primaryBadges.take(2).toList();
    final chips = <Widget>[
      if (activityBadge != null)
        _buildMetaChip(label: activityBadge, filled: true),
      ...badges.map(
        (String badge) => _buildMetaChip(label: badge, filled: false),
      ),
    ];

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }

  Widget _buildMetaChip({required String label, required bool filled}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: filled
              ? Colors.white.withValues(alpha: 0.16)
              : KolabingColors.primary.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(KolabingRadius.round),
          border: Border.all(
            color: filled
                ? Colors.white.withValues(alpha: 0.14)
                : KolabingColors.primary.withValues(alpha: 0.32),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: filled ? Colors.white : Colors.black,
          ),
        ),
      );

  Widget _buildBusinessExploreHighlights() {
    final request = _item.communityRequest;
    if (request == null) {
      return const SizedBox.shrink();
    }

    final rows = <Widget>[
      if (request.needTypeLabels.isNotEmpty)
        _buildHighlightRow(
          icon: Icons.search_rounded,
          label: 'Looking for',
          value: request.needTypeLabels.join(', '),
        ),
      // "They offer" is now surfaced concretely in the headline banner above
      // (see [DiscoveryItem.communityOfferLine]); only show the detail row here
      // when the banner could not be built, so we never lose the data.
      if (_item.communityOfferLine == null &&
          request.offerInReturnLabels.isNotEmpty)
        _buildHighlightRow(
          icon: Icons.redeem_rounded,
          label: 'They offer',
          value: request.offerInReturnLabels.join(', '),
        ),
      if (request.communitySize != null || request.typicalAttendance != null)
        _buildHighlightRow(
          icon: Icons.people_alt_rounded,
          label: 'Size',
          value: _buildScaleText(request),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          rows[i],
          if (i < rows.length - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _buildHighlightRow({
    required IconData icon,
    required String label,
    required String value,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.72)),
      const SizedBox(width: 6),
      Expanded(
        child: RichText(
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: [
              TextSpan(
                text: '$label: ',
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              TextSpan(
                text: value,
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  String _buildScaleText(CommunityRequestSummary request) {
    final parts = <String>[];
    if (request.communitySize != null) {
      parts.add('${request.communitySize} community');
    }
    if (request.typicalAttendance != null) {
      parts.add('${request.typicalAttendance} expected');
    }
    return parts.join(' · ');
  }

  Widget _buildAvailabilityRow() {
    final label = _availabilityLabel;
    if (label.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(
          Icons.calendar_today_rounded,
          size: 13,
          color: Colors.white.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.openSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ),
      ],
    );
  }

  String get _availabilityLabel {
    final availability = _item.availability;
    final mode = availability.toOpportunityAvailabilityMode();
    final dateLabel = _formatDateRange(availability.start, availability.end);

    if (mode == AvailabilityMode.recurring) {
      final dayLabels = <String>[
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ];
      final recurringLabel = availability.recurringDays
          .where((int day) => day >= 1 && day <= 7)
          .map((int day) => dayLabels[day - 1])
          .join(', ');
      if (recurringLabel.isNotEmpty) {
        return '$recurringLabel · $dateLabel';
      }
      return '$dateLabel · ${mode.displayName}';
    }

    return '$dateLabel · ${mode.displayName}';
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final startLabel = DateFormat('MMM d').format(start);
    final endLabel = DateFormat('MMM d').format(end);
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return startLabel;
    }
    return '$startLabel - $endLabel';
  }
}
