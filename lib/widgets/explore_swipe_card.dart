import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/constants/layout.dart';
import '../config/constants/radius.dart';
import '../config/constants/spacing.dart';
import '../config/theme/colors.dart';
import '../config/theme/typography.dart';
import '../features/discovery/models/discovery_item.dart';
import '../features/discovery/models/explore_feed_item.dart';
import '../l10n/app_localizations.dart';
import 'blurred_identity.dart';
import 'category_chip.dart';
import 'explore_card_data.dart';

/// The one Explore offer card. Renders every kind of feed item — ordinary
/// Kolab offers and open Multi-Kolab partner roles alike — from the shared
/// [ExploreCardData] view model, so a Multi-Kolab role is visually and
/// interactively an ordinary offer card plus a small badge.
class ExploreSwipeCard extends StatefulWidget {
  const ExploreSwipeCard({
    required this.item,
    this.onTap,
    this.showKolabFirst = false,
    this.hideCreatorIdentity = false,
    super.key,
  });

  /// Convenience constructor for the many call sites that still hold a bare
  /// [DiscoveryItem].
  ExploreSwipeCard.offer({
    required DiscoveryItem offer,
    VoidCallback? onTap,
    bool showKolabFirst = false,
    bool hideCreatorIdentity = false,
    Key? key,
  }) : this(
         item: ExploreOfferItem(offer),
         onTap: onTap,
         showKolabFirst: showKolabFirst,
         hideCreatorIdentity: hideCreatorIdentity,
         key: key,
       );

  final ExploreFeedItem item;
  final VoidCallback? onTap;
  final bool showKolabFirst;

  /// Blurs the creator identity behind the business paywall. Only ever
  /// meaningful for ordinary community offers; Multi-Kolab role cards carry
  /// no creator identity to hide.
  final bool hideCreatorIdentity;

  @override
  State<ExploreSwipeCard> createState() => _ExploreSwipeCardState();
}

class _ExploreSwipeCardState extends State<ExploreSwipeCard> {
  late final PageController _imagePageController;
  int _currentImagePage = 0;

  ExploreCardData _data(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (widget.item) {
      ExploreOfferItem(:final offer) => ExploreCardData.fromOffer(
        offer,
        l10n: l10n,
        showKolabFirst: widget.showKolabFirst,
        hideCreatorIdentity: widget.hideCreatorIdentity,
      ),
      ExploreMultiKolabRoleItem(:final role) =>
        ExploreCardData.fromMultiKolabRole(role, l10n: l10n),
    };
  }

  /// Identity blurring only ever applies to ordinary offers.
  bool get _hideCreatorIdentity =>
      widget.hideCreatorIdentity && widget.item is ExploreOfferItem;

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
  Widget build(BuildContext context) {
    final data = _data(context);
    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.md,
          vertical: KolabingSpacing.xs,
        ),
        child: Center(
          child: SingleChildScrollView(
            child: RepaintBoundary(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(KolabingRadius.lg),
                  border: Border.all(color: KolabingColors.hairline),
                  boxShadow: const [KolabingShadows.card],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(KolabingRadius.lg),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPhotoSection(data),
                      _buildContentSection(data),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Photo section
  // ---------------------------------------------------------------------------

  Widget _buildPhotoSection(ExploreCardData data) => AspectRatio(
    aspectRatio: 16 / 10,
    child: Stack(
      fit: StackFit.expand,
      children: [
        _buildImageArea(data),
        if (data.imageUrls.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: KolabingSpacing.xs,
            child: Center(child: _buildDotIndicators(data)),
          ),
        // Secondary to the role title by design: small, low-contrast chip
        // in the photo corner opposite the match badge.
        if (data.showMultiKolabBadge)
          Positioned(
            top: KolabingSpacing.xs,
            left: KolabingSpacing.xs,
            child: _buildMultiKolabBadge(),
          ),
        if (data.matchScore case final score?)
          Positioned(
            top: KolabingSpacing.xs,
            right: KolabingSpacing.xs,
            child: _buildMatchBadge(score),
          ),
      ],
    ),
  );

  Widget _buildImageArea(ExploreCardData data) {
    final urls = data.imageUrls;
    if (urls.isEmpty) return _buildGradientFallback(data);

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
              _buildGradientFallback(data),
          loadingBuilder:
              (BuildContext context, Widget child, ImageChunkEvent? progress) {
                if (progress == null) return child;
                return _buildImagePlaceholder(progress);
              },
        );

        return BlurredIdentity(
          enabled:
              _hideCreatorIdentity &&
              data.identityLogoUrl != null &&
              url == data.identityLogoUrl,
          sigma: 18,
          showLockHint: true,
          child: image,
        );
      },
    );
  }

  Widget _buildGradientFallback(ExploreCardData data) => Builder(
    builder: (BuildContext context) {
      final colors = context.colors;
      return DecoratedBox(
        decoration: BoxDecoration(color: colors.surfaceVariant),
        child: Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.7),
              border: Border.all(color: colors.hairline, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              _hideCreatorIdentity ? '?' : data.fallbackInitial,
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: KolabingColors.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      );
    },
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
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: 2,
            color: KolabingColors.onSurface.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  /// The small "Multi-Kolab" chip. Deliberately understated so it reads as
  /// secondary to the role title.
  Widget _buildMultiKolabBadge() => Container(
    key: const Key('explore-card-multi-kolab-badge'),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: context.colors.primary,
      borderRadius: BorderRadius.circular(KolabingRadius.round),
    ),
    child: Text(
      AppLocalizations.of(context).multiKolabExploreCardBadge,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        // Design system: always black text on the yellow primary.
        color: KolabingColors.onSurface,
        letterSpacing: 0.1,
      ),
    ),
  );

  Widget _buildMatchBadge(int score) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: context.colors.ink,
      borderRadius: BorderRadius.circular(KolabingRadius.round),
    ),
    child: Text(
      AppLocalizations.of(context).exploreSwipeCardMatch(score),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.1,
      ),
    ),
  );

  Widget _buildDotIndicators(ExploreCardData data) {
    final count = data.imageUrls.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(KolabingRadius.round),
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

  // ---------------------------------------------------------------------------
  // Content section
  // ---------------------------------------------------------------------------

  Widget _buildContentSection(ExploreCardData data) {
    final offerLine = data.offerLine;
    final chips = data.chips;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNameRow(data),
          const SizedBox(height: 3),
          _buildMetaRow(data),
          if (offerLine != null && offerLine.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildOfferRow(offerLine),
          ],
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildTagChips(chips),
          ],
          const SizedBox(height: 10),
          const Divider(
            height: 1,
            thickness: 1,
            color: KolabingColors.hairline,
          ),
          const SizedBox(height: 10),
          _buildViewDetailsRow(),
        ],
      ),
    );
  }

  Widget _buildNameRow(ExploreCardData data) {
    final isHidden = _hideCreatorIdentity;
    final nameText = Text(
      data.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: KolabingColors.onSurface,
        letterSpacing: -0.3,
        height: 1.2,
      ),
    );

    return BlurredIdentity(enabled: isHidden, sigma: 6, child: nameText);
  }

  Widget _buildMetaRow(ExploreCardData data) {
    final category = data.metaPrimary;
    final city = data.metaLocation;

    return Row(
      children: [
        if (category != null && category.isNotEmpty)
          Flexible(
            child: Text(
              category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _secondaryStyle,
            ),
          ),
        if (city.isNotEmpty) ...[
          if (category != null && category.isNotEmpty)
            Text(' · ', style: _secondaryStyle),
          const Icon(
            Icons.location_on_outlined,
            size: 12,
            color: KolabingColors.textTertiary,
          ),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              city,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _secondaryStyle,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOfferRow(String offerLine) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 1),
        child: Icon(
          Icons.local_offer_outlined,
          size: 13,
          color: KolabingColors.onSurface,
        ),
      ),
      const SizedBox(width: 5),
      Expanded(
        child: Text(
          offerLine,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: KolabingColors.onSurface,
            height: 1.3,
          ),
        ),
      ),
    ],
  );

  Widget _buildTagChips(List<String> chips) => Wrap(
    spacing: 6,
    runSpacing: 6,
    // This card's body is unconditionally white (see the DecoratedBox above),
    // so its chips have to be light-palette too or dark mode puts near-black
    // pills with light text on a white card.
    children: [
      for (final chip in chips)
        CategoryChip(label: chip, forceLightSurface: true),
    ],
  );

  Widget _buildViewDetailsRow() => Row(
    children: [
      Text(
        AppLocalizations.of(context).exploreSwipeCardViewDetails,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: KolabingColors.onSurface,
        ),
      ),
      const Spacer(),
      const Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: KolabingColors.onSurface,
      ),
    ],
  );

  TextStyle get _secondaryStyle => KolabingTextStyles.captionSecondary.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: KolabingColors.textTertiary,
  );
}
