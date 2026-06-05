import 'package:flutter/material.dart';

import '../config/constants/layout.dart';
import '../config/constants/radius.dart';
import '../config/constants/spacing.dart';
import '../config/theme/colors.dart';
import '../config/theme/typography.dart';
import '../features/discovery/models/discovery_item.dart';
import '../l10n/app_localizations.dart';
import 'blurred_identity.dart';

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
      // The card sits inside a full-height vertical PageView; center the
      // compact card and let it size to its content rather than stretch.
      child: Center(
        child: SingleChildScrollView(
          child: RepaintBoundary(
            child: DecoratedBox(
              decoration: BoxDecoration(
                // Kolabing-yellow card surface (fixed brand color in both
                // themes). Content below uses fixed dark ink for legibility.
                color: KolabingColors.primary,
                borderRadius: BorderRadius.circular(KolabingRadius.lg),
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
    aspectRatio: 4 / 3,
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
          context.colors.primary.withValues(alpha: 0.3),
          context.colors.surfaceVariant,
        ],
      ),
    ),
    child: Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.colors.primary.withValues(alpha: 0.15),
          border: Border.all(
            color: context.colors.primary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          !widget.hideCreatorIdentity &&
                  _item.creatorProfile.displayName.isNotEmpty
              ? _item.creatorProfile.displayName[0].toUpperCase()
              : '?',
          style: KolabingTextStyles.cardTitleHero.copyWith(color: context.colors.onSurface.withValues(alpha: 0.6)),
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
      color: context.colors.surfaceVariant,
      child: Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: 2.5,
            color: context.colors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildMatchBadge() {
    final match = _item.match!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: BorderRadius.circular(KolabingRadius.sm),
      ),
      child: Text(
        AppLocalizations.of(context).exploreSwipeCardMatch(match.score),
        style: KolabingTextStyles.bodySmall.copyWith(fontSize: 11, fontWeight: FontWeight.w500, color: KolabingColors.onSurface),
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
    final pastEvents = _item.pastEventsCount;
    final chips = _item.primaryBadges;

    return Padding(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNameRow(),
          const SizedBox(height: 4),
          _buildMetaRow(),
          if (offerLine != null && offerLine.isNotEmpty) ...[
            const SizedBox(height: KolabingSpacing.xs),
            _buildOfferRow(offerLine),
          ],
          if (pastEvents != null && pastEvents > 0) ...[
            const SizedBox(height: KolabingSpacing.xxs),
            _buildMembersRow(pastEvents),
          ],
          if (chips.isNotEmpty) ...[
            const SizedBox(height: KolabingSpacing.xs),
            _buildTagChips(chips),
          ],
          const SizedBox(height: KolabingSpacing.sm),
          Divider(
            height: 1,
            thickness: 1,
            color: KolabingColors.onSurface.withValues(alpha: 0.12),
          ),
          const SizedBox(height: KolabingSpacing.sm),
          _buildViewDetailsRow(),
        ],
      ),
    );
  }

  Widget _buildNameRow() {
    final isHidden = widget.hideCreatorIdentity;
    // Per ROLES-AND-PERMISSIONS.md §2.5: do NOT hide the name behind a
    // placeholder. Render the real community name and Gaussian-blur it so the
    // free business sees there IS an identity to unlock by subscribing.
    final nameText = Text(
      _item.creatorProfile.displayName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: KolabingTextStyles.cardTitleLarge.copyWith(color: KolabingColors.onSurface),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: BlurredIdentity(enabled: isHidden, sigma: 6, child: nameText),
        ),
        // Numeric rating is not yet provided by DiscoveryItem; the star slot is
        // rendered only when a rating is available (see report — future field).
      ],
    );
  }

  Widget _buildMetaRow() {
    final category = _item.primaryBadges.isNotEmpty
        ? _item.primaryBadges.first
        : (_item.isBusinessOffer
              ? AppLocalizations.of(context).exploreSwipeCardBusinessOffer
              : AppLocalizations.of(context).exploreSwipeCardCommunityRequest);
    final city = _item.locationLabel;
    final pastEvents = _item.pastEventsCount;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              if (city.isNotEmpty) ...[
                Flexible(
                  child: Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _secondaryStyle,
                  ),
                ),
                Text(' · ', style: _secondaryStyle),
                Icon(
                  Icons.location_on_outlined,
                  size: 13,
                  color: KolabingColors.onSurfaceVariant,
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
              ] else
                Flexible(
                  child: Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _secondaryStyle,
                  ),
                ),
            ],
          ),
        ),
        if (pastEvents != null && pastEvents > 0) ...[
          const SizedBox(width: KolabingSpacing.xs),
          Text(
            AppLocalizations.of(context).exploreSwipeCardKolabsCount(pastEvents),
            style: _secondaryStyle,
          ),
        ],
      ],
    );
  }

  Widget _buildOfferRow(String offerLine) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.only(top: 1),
        child: Icon(
          Icons.local_offer_outlined,
          size: 14,
          color: KolabingColors.onSurface,
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          offerLine,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: KolabingTextStyles.captionSecondary.copyWith(fontWeight: FontWeight.w700, color: KolabingColors.onSurface, height: 1.25),
        ),
      ),
    ],
  );

  Widget _buildMembersRow(int pastEvents) => Row(
    children: [
      Icon(
        Icons.people_alt_outlined,
        size: 14,
        color: KolabingColors.onSurfaceVariant,
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          AppLocalizations.of(context).exploreSwipeCardPreviousKolabs(pastEvents),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _secondaryStyle,
        ),
      ),
    ],
  );

  Widget _buildTagChips(List<String> chips) {
    // Alternating chip palette using existing design tokens: lavender, sage,
    // and soft yellow. Falls back to surfaceVariant if more chips appear.
    // Subtle dark-tinted chips on the yellow card, with dark ink labels.
    final fills = <Color>[
      KolabingColors.onSurface.withValues(alpha: 0.08),
      KolabingColors.onSurface.withValues(alpha: 0.08),
      KolabingColors.onSurface.withValues(alpha: 0.08),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < chips.length; i++)
          _buildChip(chips[i], fills[i % fills.length]),
      ],
    );
  }

  Widget _buildChip(String label, Color fill) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: KolabingTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600, color: KolabingColors.onSurface),
    ),
  );

  Widget _buildViewDetailsRow() => Row(
    children: [
      Text(
        AppLocalizations.of(context).exploreSwipeCardViewDetails,
        style: KolabingTextStyles.captionSecondary.copyWith(fontWeight: FontWeight.w600, color: KolabingColors.onSurface),
      ),
      const Spacer(),
      Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: KolabingColors.onSurface,
      ),
    ],
  );

  TextStyle get _secondaryStyle => KolabingTextStyles.captionSecondary.copyWith(fontWeight: FontWeight.w500, color: KolabingColors.onSurfaceVariant);
}
