import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/constants/layout.dart';
import '../config/constants/radius.dart';
import '../config/constants/spacing.dart';
import '../config/theme/colors.dart';
import '../config/theme/typography.dart';
import '../features/discovery/models/discovery_item.dart';
import '../l10n/app_localizations.dart';
import 'blurred_identity.dart';
import 'category_chip.dart';

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
    if (urls.isEmpty) {
      final avatar = _item.creatorProfile.avatarUrl;
      if (avatar != null && avatar.isNotEmpty) urls.add(avatar);
    }
    return urls;
  }

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
                  children: [_buildPhotoSection(), _buildContentSection()],
                ),
              ),
            ),
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
        if (_item.match != null)
          Positioned(
            top: KolabingSpacing.xs,
            right: KolabingSpacing.xs,
            child: _buildMatchBadge(),
          ),
      ],
    ),
  );

  Widget _buildImageArea() {
    final urls = _imageUrls;
    if (urls.isEmpty) return _buildGradientFallback();

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

        return BlurredIdentity(
          enabled: widget.hideCreatorIdentity && _isIdentityLogo(url),
          sigma: 18,
          showLockHint: true,
          child: image,
        );
      },
    );
  }

  Widget _buildGradientFallback() => Builder(
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
              !widget.hideCreatorIdentity &&
                      _item.creatorProfile.displayName.isNotEmpty
                  ? _item.creatorProfile.displayName[0].toUpperCase()
                  : '?',
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

  Widget _buildMatchBadge() {
    final match = _item.match!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.colors.ink,
        borderRadius: BorderRadius.circular(KolabingRadius.round),
      ),
      child: Text(
        AppLocalizations.of(context).exploreSwipeCardMatch(match.score),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.1,
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

  Widget _buildContentSection() {
    final offerLine = _isBusinessExploreCommunityCard
        ? _item.communityOfferLine
        : _item.displayHeadline;
    final chips = _item.primaryBadges;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNameRow(),
          const SizedBox(height: 3),
          _buildMetaRow(),
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

  Widget _buildNameRow() {
    final isHidden = widget.hideCreatorIdentity;
    final nameText = Text(
      _item.creatorProfile.displayName,
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

  Widget _buildMetaRow() {
    final category = _item.primaryBadges.isNotEmpty
        ? _item.primaryBadges.first
        : (_item.isBusinessOffer
              ? AppLocalizations.of(context).exploreSwipeCardBusinessOffer
              : AppLocalizations.of(context).exploreSwipeCardCommunityRequest);
    final city = _item.locationLabel;

    return Row(
      children: [
        Flexible(
          child: Text(
            category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _secondaryStyle,
          ),
        ),
        if (city.isNotEmpty) ...[
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
    children: [for (final chip in chips) CategoryChip(label: chip)],
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
