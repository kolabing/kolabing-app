import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../config/constants/radius.dart';
import '../config/constants/spacing.dart';
import '../config/theme/colors.dart';
import '../features/discovery/models/discovery_item.dart';
import '../features/opportunity/models/opportunity.dart';
import 'match_breakdown.dart';

class ExploreSwipeCard extends StatefulWidget {
  const ExploreSwipeCard({required this.item, this.onTap, super.key});

  final DiscoveryItem item;
  final VoidCallback? onTap;

  @override
  State<ExploreSwipeCard> createState() => _ExploreSwipeCardState();
}

class _ExploreSwipeCardState extends State<ExploreSwipeCard> {
  late final PageController _imagePageController;
  int _currentImagePage = 0;

  DiscoveryItem get _item => widget.item;

  List<String> get _imageUrls {
    final urls = <String>[];
    final cover = _item.coverPhotoUrl;
    if (cover != null && cover.isNotEmpty) urls.add(cover);
    final avatar = _item.creatorProfile.avatarUrl;
    if (avatar != null && avatar.isNotEmpty) urls.add(avatar);
    return urls;
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
      itemBuilder: (BuildContext context, int index) => Image.network(
        urls[index],
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildGradientFallback(),
        loadingBuilder:
            (BuildContext context, Widget child, ImageChunkEvent? progress) {
              if (progress == null) return child;
              return _buildImagePlaceholder(progress);
            },
      ),
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
        _buildCreatorName(),
        const SizedBox(height: KolabingSpacing.xs),
        _buildPrimaryBadges(),
        if (_item.fitReasonLabels.isNotEmpty) ...[
          const SizedBox(height: KolabingSpacing.xs),
          _buildFitReasonBadges(),
        ],
        const SizedBox(height: KolabingSpacing.xs),
        _buildDescription(),
        const SizedBox(height: KolabingSpacing.xs),
        _buildAvailabilityRow(),
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
    final label = _item.isBusinessOffer
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

  Widget _buildPrimaryBadges() {
    final badges = _item.primaryBadges;
    if (badges.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: badges
          .map(
            (String badge) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: KolabingColors.primary,
                borderRadius: BorderRadius.circular(KolabingRadius.round),
              ),
              child: Text(
                badge,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFitReasonBadges() {
    final reasons = _item.fitReasonLabels.take(2).toList();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: reasons
          .map(
            (String reason) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(KolabingRadius.round),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Text(
                reason,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDescription() {
    final description = _item.description;
    if (description.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final textStyle = GoogleFonts.openSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.white.withValues(alpha: 0.82),
        );

        final textPainter = TextPainter(
          text: TextSpan(text: description, style: textStyle),
          maxLines: 2,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = textPainter.didExceedMaxLines;

        return RichText(
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: textStyle,
            children: [
              TextSpan(text: description),
              if (isOverflowing)
                TextSpan(
                  text: ' show more',
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvailabilityRow() {
    final availability = _item.availability;
    if (availability.toOpportunityAvailabilityMode() ==
        AvailabilityMode.recurring) {
      return _buildRecurringDays(availability.recurringDays);
    }

    return Text(
      '${DateFormat('MMM d').format(availability.start)}'
      ' - '
      '${DateFormat('MMM d').format(availability.end)}'
      '  ·  '
      '${availability.toOpportunityAvailabilityMode().displayName}',
      style: GoogleFonts.openSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: Colors.white.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildRecurringDays(List<int> recurringDays) {
    const dayLabels = <String>['M', 'Tu', 'W', 'Th', 'F', 'Sa', 'Su'];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (int index) {
        final dayNumber = index + 1;
        final isAvailable = recurringDays.contains(dayNumber);

        return Padding(
          padding: EdgeInsets.only(right: index < 6 ? 6.0 : 0),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isAvailable
                  ? KolabingColors.info
                  : Colors.white.withValues(alpha: 0.15),
            ),
            child: Text(
              dayLabels[index],
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isAvailable
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ),
        );
      }),
    );
  }
}
