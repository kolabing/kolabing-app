import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../config/constants/radius.dart';
import '../config/constants/spacing.dart';
import '../config/theme/colors.dart';
import '../features/opportunity/models/opportunity.dart';

/// A full-screen Tinder/Hinge-style swipe card for the Explore tab.
///
/// Displays an [Opportunity] with an image slideshow (or gradient fallback),
/// overlaid creator info, category chips, description, and availability row.
/// Designed to be placed inside a vertical PageView.
class ExploreSwipeCard extends StatefulWidget {
  const ExploreSwipeCard({
    required this.opportunity,
    this.onTap,
    super.key,
  });

  final Opportunity opportunity;
  final VoidCallback? onTap;

  @override
  State<ExploreSwipeCard> createState() => _ExploreSwipeCardState();
}

class _ExploreSwipeCardState extends State<ExploreSwipeCard> {
  late final PageController _imagePageController;
  int _currentImagePage = 0;

  Opportunity get _opp => widget.opportunity;

  /// Collect all available image URLs for the slideshow.
  /// Priority: offerPhoto first, then creator avatar as full-bleed image.
  List<String> get _imageUrls {
    final urls = <String>[];
    final photo = _opp.offerPhoto;
    if (photo != null && photo.isNotEmpty) urls.add(photo);
    final avatar = _opp.creatorProfile?.avatarUrl;
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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

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
                // Layer 1 -- Image slideshow or gradient fallback
                _buildImageArea(),

                // Layer 2 -- Bottom gradient overlay
                _buildGradientOverlay(),

                // Layer 3 -- Overlaid content
                _buildOverlaidContent(),

                // Layer 4 -- Dot indicators (only when multiple images)
                if (_imageUrls.length > 1) _buildDotIndicators(),
              ],
            ),
          ),
        ),
      );

  // ---------------------------------------------------------------------------
  // Image area
  // ---------------------------------------------------------------------------

  Widget _buildImageArea() {
    final urls = _imageUrls;

    if (urls.isEmpty) {
      return _buildGradientFallback();
    }

    return PageView.builder(
      controller: _imagePageController,
      itemCount: urls.length,
      onPageChanged: (index) => setState(() => _currentImagePage = index),
      itemBuilder: (context, index) => Image.network(
        urls[index],
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _buildGradientFallback(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildImagePlaceholder(loadingProgress);
        },
      ),
    );
  }

  /// Gradient fallback shown when no images are available at all.
  Widget _buildGradientFallback() {
    final initial = _opp.creatorProfile?.initial ?? '?';
    return DecoratedBox(
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
            initial,
            style: GoogleFonts.rubik(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: KolabingColors.textPrimary.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  /// Placeholder shown while an image is loading.
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

  // ---------------------------------------------------------------------------
  // Gradient overlay
  // ---------------------------------------------------------------------------

  Widget _buildGradientOverlay() {
    final hasImages = _imageUrls.isNotEmpty;
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.4, 1.0],
              colors: hasImages
                  ? [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.85),
                    ]
                  : [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.7),
                    ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dot indicators
  // ---------------------------------------------------------------------------

  Widget _buildDotIndicators() {
    final count = _imageUrls.length;
    return Positioned(
      left: 0,
      right: 0,
      // Place dots at roughly the 65% mark (above the gradient content area)
      child: Align(
        alignment: const Alignment(0, 0.25),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(count, (index) {
            final isActive = index == _currentImagePage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 8 : 6,
              height: isActive ? 8 : 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.4),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Overlaid content
  // ---------------------------------------------------------------------------

  Widget _buildOverlaidContent() => Positioned(
        left: KolabingSpacing.md,
        right: KolabingSpacing.md,
        bottom: KolabingSpacing.md +
            MediaQuery.of(context).padding.bottom * 0.2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Creator type badge
            _buildCreatorTypeBadge(),
            const SizedBox(height: KolabingSpacing.xs),

            // Creator name
            _buildCreatorName(),
            const SizedBox(height: KolabingSpacing.xs),

            // Category chips
            _buildCategoryChips(),
            const SizedBox(height: KolabingSpacing.xs),

            // Description
            _buildDescription(),
            const SizedBox(height: KolabingSpacing.xs),

            // Availability row
            _buildAvailabilityRow(),
          ],
        ),
      );

  // ---------------------------------------------------------------------------
  // Creator type badge
  // ---------------------------------------------------------------------------

  Widget _buildCreatorTypeBadge() {
    final userType = _opp.creatorProfile?.userType ?? '';
    if (userType.isEmpty) return const SizedBox.shrink();

    return Text(
      userType,
      style: GoogleFonts.openSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.6),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Creator name
  // ---------------------------------------------------------------------------

  Widget _buildCreatorName() {
    final name = _opp.creatorProfile?.displayName ?? _opp.title;

    return Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.rubik(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Category chips
  // ---------------------------------------------------------------------------

  Widget _buildCategoryChips() {
    final categories = _opp.categories;
    if (categories.isEmpty) return const SizedBox.shrink();

    // Show at most 3 categories
    final visible = categories.take(3).toList();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: visible.map((category) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: KolabingColors.primary,
          borderRadius: BorderRadius.circular(KolabingRadius.round),
        ),
        child: Text(
          category,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      )).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Description
  // ---------------------------------------------------------------------------

  Widget _buildDescription() {
    final description = _opp.description;
    if (description.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final textStyle = GoogleFonts.openSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.white.withValues(alpha: 0.8),
        );

        final textSpan = TextSpan(text: description, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
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

  // ---------------------------------------------------------------------------
  // Availability row
  // ---------------------------------------------------------------------------

  Widget _buildAvailabilityRow() {
    if (_opp.availabilityMode == AvailabilityMode.recurring) {
      return _buildRecurringDays();
    }
    return _buildDateRangeText();
  }

  /// Day chips for recurring availability: M Tu W Th F Sa Su
  Widget _buildRecurringDays() {
    const dayLabels = ['M', 'Tu', 'W', 'Th', 'F', 'Sa', 'Su'];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (index) {
        final dayNumber = index + 1; // 1=Mon .. 7=Sun
        final isAvailable = _opp.recurringDays.contains(dayNumber);

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

  /// Date range text for one-time or flexible availability.
  Widget _buildDateRangeText() => Text(
        '${DateFormat('MMM d').format(_opp.availabilityStart)}'
        ' - '
        '${DateFormat('MMM d').format(_opp.availabilityEnd)}'
        '  ·  '
        '${_opp.availabilityMode.displayName}',
        style: GoogleFonts.openSans(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      );
}
