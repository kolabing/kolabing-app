import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../config/constants/radius.dart';
import '../config/constants/spacing.dart';
import '../config/theme/colors.dart';
import '../features/discovery/models/discovery_item.dart';
import '../features/event/models/event.dart';
import '../features/event/providers/event_provider.dart';
import '../features/opportunity/models/opportunity.dart';
import 'blurred_identity.dart';
import 'category_icon.dart';

/// Modal bottom sheet displaying full opportunity details.
///
/// Shown when the user taps a card in the Explore tab. Contains scrollable
/// content with creator info, description, offer summary, location details,
/// availability days, and categories. Action buttons are pinned at the bottom.
class ExploreDetailSheet extends ConsumerWidget {
  const ExploreDetailSheet({
    required this.opportunity,
    this.onApply,
    this.onView,
    this.onViewCreatorProfile,
    this.canApply = true,
    this.discoveryItem,
    this.hideCreatorIdentity = false,
    this.onSubscribe,
    super.key,
  });

  final Opportunity opportunity;
  final VoidCallback? onApply;
  final VoidCallback? onView;
  final DiscoveryItem? discoveryItem;
  // C9: optional CTA that opens the creator's public profile so a business
  // viewer can reach the Send-Kolab proposal flow.
  final VoidCallback? onViewCreatorProfile;
  final bool canApply;
  final bool hideCreatorIdentity;
  final VoidCallback? onSubscribe;

  /// Day labels indexed 1..7 (Mon..Sun) matching [Opportunity.recurringDays].
  static const _dayLabels = ['M', 'Tu', 'W', 'Th', 'F', 'Sa', 'Su'];

  /// Shows the detail sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required Opportunity opportunity,
    VoidCallback? onApply,
    VoidCallback? onView,
    VoidCallback? onViewCreatorProfile,
    bool canApply = true,
    DiscoveryItem? discoveryItem,
    bool hideCreatorIdentity = false,
    VoidCallback? onSubscribe,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ExploreDetailSheet(
      opportunity: opportunity,
      onApply: onApply,
      onView: onView,
      onViewCreatorProfile: onViewCreatorProfile,
      canApply: canApply,
      discoveryItem: discoveryItem,
      hideCreatorIdentity: hideCreatorIdentity,
      onSubscribe: onSubscribe,
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.85,
    ),
    decoration: const BoxDecoration(
      color: KolabingColors.surface,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(KolabingRadius.xxl),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drag handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: KolabingSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: KolabingColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Scrollable content
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              KolabingSpacing.lg,
              KolabingSpacing.md,
              KolabingSpacing.lg,
              KolabingSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderRow(context),
                const SizedBox(height: KolabingSpacing.lg),
                _buildTitleSection(),
                const SizedBox(height: KolabingSpacing.lg),
                if (discoveryItem?.isCommunityRequest ?? false) ...[
                  _buildBusinessExploreSummary(),
                  const SizedBox(height: KolabingSpacing.lg),
                ],
                if (opportunity.businessOffer.hasAnyOffer) ...[
                  _buildOfferSummarySection(),
                  const SizedBox(height: KolabingSpacing.lg),
                ],
                _buildLocationAndDetails(),
                if (opportunity.availabilityMode ==
                        AvailabilityMode.recurring &&
                    opportunity.recurringDays.isNotEmpty) ...[
                  const SizedBox(height: KolabingSpacing.lg),
                  _buildAvailabilityDays(),
                ],
                if (opportunity.categories.isNotEmpty) ...[
                  const SizedBox(height: KolabingSpacing.lg),
                  _buildCategoriesSection(),
                ],
                if (!hideCreatorIdentity &&
                    (discoveryItem?.isCommunityRequest ?? false) &&
                    (opportunity.creatorProfile?.id.isNotEmpty ?? false)) ...[
                  const SizedBox(height: KolabingSpacing.lg),
                  _PastEventPhotosSection(
                    profileId: opportunity.creatorProfile!.id,
                  ),
                ],
                // Bottom spacing so content does not sit flush against buttons
                const SizedBox(height: KolabingSpacing.md),
              ],
            ),
          ),
        ),

        // Sticky action buttons
        _buildActionButtons(context),
      ],
    ),
  );

  // ---------------------------------------------------------------------------
  // Header Row
  // ---------------------------------------------------------------------------

  Widget _buildHeaderRow(BuildContext context) {
    final creator = opportunity.creatorProfile;
    // Per ROLES-AND-PERMISSIONS.md §2.5: a free business sees the community's
    // real name + logo BLURRED (not replaced by a placeholder). We therefore
    // render the true values and let [BlurredIdentity] obscure them. Everything
    // else in this sheet stays fully visible.
    final displayName = creator?.displayName ?? 'Unknown';
    final initial = creator?.initial ?? '?';
    final avatarUrl = creator?.avatarUrl;
    final userType = creator?.userType ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Creator avatar (logo) — Gaussian-blurred when identity is hidden.
        BlurredIdentity(
          enabled: hideCreatorIdentity,
          sigma: 14,
          borderRadius: BorderRadius.circular(32),
          child: _buildAvatar(avatarUrl, initial),
        ),
        const SizedBox(width: KolabingSpacing.sm),

        // Creator name + type badge
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BlurredIdentity(
                enabled: hideCreatorIdentity,
                sigma: 8,
                child: Text(
                  displayName,
                  style: GoogleFonts.rubik(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: KolabingColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hideCreatorIdentity) ...[
                const SizedBox(height: KolabingSpacing.xxs),
                Text(
                  'Subscribe to reveal this community',
                  style: GoogleFonts.openSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.textTertiary,
                  ),
                ),
              ],
              const SizedBox(height: KolabingSpacing.xxs),
              _buildTypeBadge(userType),
            ],
          ),
        ),

        // Close button
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(LucideIcons.x),
          style: IconButton.styleFrom(
            foregroundColor: KolabingColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(String? avatarUrl, String initial) => Container(
    width: 64,
    height: 64,
    decoration: BoxDecoration(
      color: KolabingColors.primary.withValues(alpha: 0.1),
      shape: BoxShape.circle,
    ),
    child: avatarUrl != null && avatarUrl.isNotEmpty
        ? ClipOval(
            child: Image.network(
              avatarUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildAvatarFallback(initial),
            ),
          )
        : _buildAvatarFallback(initial),
  );

  Widget _buildAvatarFallback(String initial) => Center(
    child: Text(
      initial,
      style: GoogleFonts.rubik(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: KolabingColors.primary,
      ),
    ),
  );

  Widget _buildTypeBadge(String userType) {
    final label = userType.isNotEmpty
        ? '${userType[0].toUpperCase()}${userType.substring(1)}'
        : 'Creator';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.xs,
        vertical: KolabingSpacing.xxxs,
      ),
      decoration: BoxDecoration(
        color: KolabingColors.activeBg,
        borderRadius: BorderRadius.circular(KolabingRadius.round),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: KolabingColors.activeText,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Title Section
  // ---------------------------------------------------------------------------

  Widget _buildTitleSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        opportunity.title,
        style: GoogleFonts.rubik(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: KolabingColors.textPrimary,
        ),
      ),
      if (opportunity.description.isNotEmpty) ...[
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          opportunity.description,
          style: GoogleFonts.openSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: KolabingColors.textSecondary,
          ),
        ),
      ],
    ],
  );

  Widget _buildBusinessExploreSummary() {
    final request = discoveryItem?.communityRequest;
    if (request == null) {
      return const SizedBox.shrink();
    }

    final sections = <Widget>[
      if (request.needTypeLabels.isNotEmpty)
        _buildSummaryCard(
          icon: LucideIcons.search,
          title: 'What they are looking for',
          value: request.needTypeLabels.join(', '),
        ),
      if (request.offerInReturnLabels.isNotEmpty)
        _buildSummaryCard(
          icon: LucideIcons.gift,
          title: 'What they offer',
          value: request.offerInReturnLabels.join(', '),
        ),
      if (request.communitySize != null || request.typicalAttendance != null)
        _buildSummaryCard(
          icon: LucideIcons.users,
          title: 'Community size',
          value: _buildScaleLabel(request),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          sections[i],
          if (i < sections.length - 1)
            const SizedBox(height: KolabingSpacing.sm),
        ],
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(KolabingSpacing.md),
    decoration: BoxDecoration(
      color: KolabingColors.surfaceVariant,
      borderRadius: KolabingRadius.borderRadiusMd,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: KolabingColors.textSecondary),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: KolabingColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: KolabingColors.textPrimary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  String _buildScaleLabel(CommunityRequestSummary request) {
    final parts = <String>[];
    if (request.communitySize != null) {
      parts.add('${request.communitySize} community');
    }
    if (request.typicalAttendance != null) {
      parts.add('${request.typicalAttendance} expected');
    }
    return parts.join(' · ');
  }

  // ---------------------------------------------------------------------------
  // Offer Summary Section
  // ---------------------------------------------------------------------------

  Widget _buildOfferSummarySection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "What's Offered",
        style: GoogleFonts.openSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: KolabingColors.textPrimary,
        ),
      ),
      const SizedBox(height: KolabingSpacing.xs),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: KolabingColors.success.withValues(alpha: 0.1),
          borderRadius: KolabingRadius.borderRadiusMd,
          border: Border.all(
            color: KolabingColors.success.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.gift,
              size: 18,
              color: KolabingColors.success,
            ),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: Text(
                opportunity.offerSummary,
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: KolabingColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  // ---------------------------------------------------------------------------
  // Location & Details Section
  // ---------------------------------------------------------------------------

  Widget _buildLocationAndDetails() {
    final dateFormat = DateFormat('MMM d');
    final startFormatted = dateFormat.format(opportunity.availabilityStart);
    final endFormatted = dateFormat.format(opportunity.availabilityEnd);

    // Prefer the richer "area, city" label from the discovery item so a
    // community viewing a business sees the business's neighbourhood/area, not
    // just the city. Falls back to the plain city when no area is available.
    final discoveryLocation = discoveryItem?.locationLabel.trim();
    final locationLabel =
        (discoveryLocation != null && discoveryLocation.isNotEmpty)
        ? discoveryLocation
        : opportunity.preferredCity;

    final items = <_DetailItem>[
      if (locationLabel.isNotEmpty)
        _DetailItem(icon: LucideIcons.mapPin, label: locationLabel),
      _DetailItem(
        icon: LucideIcons.building2,
        label: opportunity.venueMode.displayName,
      ),
      _DetailItem(
        icon: LucideIcons.calendar,
        label: '$startFormatted - $endFormatted',
      ),
      _DetailItem(
        icon: LucideIcons.clock,
        label: opportunity.availabilityMode.displayName,
      ),
    ];

    return Wrap(
      spacing: KolabingSpacing.xs,
      runSpacing: KolabingSpacing.xs,
      children: items.map(_buildDetailPill).toList(),
    );
  }

  Widget _buildDetailPill(_DetailItem item) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: KolabingSpacing.sm,
      vertical: KolabingSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: KolabingColors.surfaceVariant,
      borderRadius: BorderRadius.circular(KolabingRadius.round),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, size: 14, color: KolabingColors.textSecondary),
        const SizedBox(width: KolabingSpacing.xxs),
        Flexible(
          child: Text(
            item.label,
            style: GoogleFonts.openSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: KolabingColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  // ---------------------------------------------------------------------------
  // Availability Days (Recurring Mode)
  // ---------------------------------------------------------------------------

  Widget _buildAvailabilityDays() {
    final activeDays = opportunity.recurringDays.toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Days',
          style: GoogleFonts.openSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: KolabingColors.textPrimary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final dayNumber = index + 1; // 1=Mon..7=Sun
            final isAvailable = activeDays.contains(dayNumber);

            return Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isAvailable
                    ? KolabingColors.info
                    : KolabingColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _dayLabels[index],
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isAvailable
                      ? KolabingColors.textOnDark
                      : KolabingColors.textTertiary,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Categories Section
  // ---------------------------------------------------------------------------

  Widget _buildCategoriesSection() => Wrap(
    spacing: KolabingSpacing.xs,
    runSpacing: KolabingSpacing.xs,
    children: opportunity.categories
        .map(
          (category) => Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.sm,
              vertical: KolabingSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: KolabingColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(KolabingRadius.round),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CategoryIcon(name: category, size: 16),
                const SizedBox(width: 4),
                Text(
                  category,
                  style: GoogleFonts.openSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(),
  );

  // ---------------------------------------------------------------------------
  // Action Buttons (Sticky)
  // ---------------------------------------------------------------------------

  Widget _buildActionButtons(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final showsSubscribeAction = !canApply && onSubscribe != null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        KolabingSpacing.md,
        KolabingSpacing.md,
        KolabingSpacing.md,
        KolabingSpacing.md + bottomPadding,
      ),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: canApply ? onApply : onSubscribe,
              icon: Icon(
                showsSubscribeAction ? LucideIcons.crown : LucideIcons.send,
                size: 18,
              ),
              label: Text(
                showsSubscribeAction ? 'UNLOCK TO APPLY' : 'APPLY NOW',
                style: GoogleFonts.rubik(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: KolabingColors.primary,
                foregroundColor: KolabingColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: KolabingRadius.borderRadiusMd,
                ),
              ),
            ),
          ),
          if (onViewCreatorProfile != null && !hideCreatorIdentity) ...[
            const SizedBox(height: KolabingSpacing.xs),
            // C9: secondary link to the creator's public profile. Routes
            // through PublicProfileScreen so a business viewer reaches the
            // Send-Kolab proposal CTA instead of dead-ending here.
            TextButton.icon(
              onPressed: onViewCreatorProfile,
              icon: const Icon(LucideIcons.user, size: 16),
              label: Text(
                'View creator profile',
                style: GoogleFonts.openSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: KolabingColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Internal helper for detail pill items.
class _DetailItem {
  const _DetailItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _PastEventPhotosSection extends StatefulWidget {
  const _PastEventPhotosSection({required this.profileId});

  final String profileId;

  @override
  State<_PastEventPhotosSection> createState() =>
      _PastEventPhotosSectionState();
}

class _PastEventPhotosSectionState extends State<_PastEventPhotosSection> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Consumer(
    builder: (context, ref, _) {
      final asyncEvents = ref.watch(profileEventsProvider(widget.profileId));

      return asyncEvents.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (events) {
          final slides = _buildSlides(events);
          if (slides.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Past event photos',
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: KolabingColors.textPrimary,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              Text(
                'Recent moments from this community',
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: KolabingColors.textSecondary,
                ),
              ),
              const SizedBox(height: KolabingSpacing.sm),
              SizedBox(
                height: 190,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: slides.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) =>
                      _PastEventPhotoCard(slide: slides[index]),
                ),
              ),
              if (slides.length > 1) ...[
                const SizedBox(height: KolabingSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(slides.length, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? KolabingColors.primary
                            : KolabingColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    );
                  }),
                ),
              ],
            ],
          );
        },
      );
    },
  );

  List<_PastEventPhotoSlide> _buildSlides(List<Event> events) {
    final sorted = [...events]..sort((a, b) => b.date.compareTo(a.date));
    return sorted
        .take(5)
        .expand(
          (event) => event.photos.map(
            (photo) => _PastEventPhotoSlide(
              photoUrl: photo.thumbnailUrl ?? photo.url,
              title: event.name,
              subtitle: event.formattedDate,
            ),
          ),
        )
        .take(8)
        .toList();
  }
}

class _PastEventPhotoCard extends StatelessWidget {
  const _PastEventPhotoCard({required this.slide});

  final _PastEventPhotoSlide slide;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: KolabingSpacing.xs),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(KolabingRadius.lg),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            slide.photoUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: KolabingColors.surfaceVariant,
              alignment: Alignment.center,
              child: const Icon(
                LucideIcons.imageOff,
                color: KolabingColors.textTertiary,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.04),
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
          Positioned(
            left: KolabingSpacing.md,
            right: KolabingSpacing.md,
            bottom: KolabingSpacing.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slide.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.rubik(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  slide.subtitle,
                  style: GoogleFonts.openSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _PastEventPhotoSlide {
  const _PastEventPhotoSlide({
    required this.photoUrl,
    required this.title,
    required this.subtitle,
  });

  final String photoUrl;
  final String title;
  final String subtitle;
}
