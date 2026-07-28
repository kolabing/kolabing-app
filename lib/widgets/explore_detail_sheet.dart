import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../config/constants/radius.dart';
import '../config/constants/spacing.dart';
import '../config/theme/colors.dart';
import '../config/theme/typography.dart';
import '../features/application/widgets/apply_modal.dart'
    show opportunityApplicationsOpen;
import '../features/discovery/models/discovery_item.dart';
import '../features/event/models/event.dart';
import '../features/event/providers/event_provider.dart';
import '../features/opportunity/models/opportunity.dart';
import '../features/opportunity/opportunity_l10n.dart';
import '../l10n/app_localizations.dart';
import 'blurred_identity.dart';
import 'kolabing_button.dart';
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
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: const BorderRadius.vertical(
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
              color: context.colors.darkBorder,
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
                _buildTitleSection(context),
                const SizedBox(height: KolabingSpacing.lg),
                if (discoveryItem?.isCommunityRequest ?? false) ...[
                  _buildBusinessExploreSummary(context),
                  const SizedBox(height: KolabingSpacing.lg),
                ],
                if (opportunity.businessOffer.hasAnyOffer) ...[
                  _buildOfferSummarySection(context),
                  const SizedBox(height: KolabingSpacing.lg),
                ],
                _buildLocationAndDetails(context),
                if (opportunity.availabilityMode ==
                        AvailabilityMode.recurring &&
                    opportunity.recurringDays.isNotEmpty) ...[
                  const SizedBox(height: KolabingSpacing.lg),
                  _buildAvailabilityDays(context),
                ],
                if (opportunity.categories.isNotEmpty) ...[
                  const SizedBox(height: KolabingSpacing.lg),
                  _buildCategoriesSection(context),
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
    final displayName =
        creator?.displayName ??
        AppLocalizations.of(context).exploreDetailUnknownCreator;
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
          child: _buildAvatar(context, avatarUrl, initial),
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
                  style: KolabingTextStyles.bodyLarge.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.colors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hideCreatorIdentity) ...[
                const SizedBox(height: KolabingSpacing.xxs),
                Text(
                  AppLocalizations.of(context).exploreDetailSubscribeToReveal,
                  style: KolabingTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.textTertiary,
                  ),
                ),
              ],
              const SizedBox(height: KolabingSpacing.xxs),
              _buildTypeBadge(context, userType),
            ],
          ),
        ),

        // Close button
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(LucideIcons.x),
          style: IconButton.styleFrom(
            foregroundColor: context.colors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    String? avatarUrl,
    String initial,
  ) => Container(
    width: 64,
    height: 64,
    decoration: BoxDecoration(
      color: context.colors.primary.withValues(alpha: 0.1),
      shape: BoxShape.circle,
    ),
    child: avatarUrl != null && avatarUrl.isNotEmpty
        ? ClipOval(
            child: Image.network(
              avatarUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildAvatarFallback(context, initial),
            ),
          )
        : _buildAvatarFallback(context, initial),
  );

  Widget _buildAvatarFallback(BuildContext context, String initial) => Center(
    child: Text(
      initial,
      style: KolabingTextStyles.headlineMedium.copyWith(
        color: context.colors.primary,
      ),
    ),
  );

  Widget _buildTypeBadge(BuildContext context, String userType) {
    final label = userType.isNotEmpty
        ? '${userType[0].toUpperCase()}${userType.substring(1)}'
        : AppLocalizations.of(context).exploreDetailCreatorBadge;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.xs,
        vertical: KolabingSpacing.xxxs,
      ),
      decoration: BoxDecoration(
        color: context.colors.categoryOrangeBg,
        borderRadius: BorderRadius.circular(KolabingRadius.round),
      ),
      child: Text(
        label,
        style: KolabingTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
          color: context.colors.categoryOrangeText,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Title Section
  // ---------------------------------------------------------------------------

  Widget _buildTitleSection(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        opportunity.title,
        style: KolabingTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: context.colors.onSurface,
        ),
      ),
      if (opportunity.description.isNotEmpty) ...[
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          opportunity.description,
          style: KolabingTextStyles.bodySmall.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    ],
  );

  Widget _buildBusinessExploreSummary(BuildContext context) {
    final request = discoveryItem?.communityRequest;
    if (request == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final sections = <Widget>[
      if (request.needTypeLabels.isNotEmpty)
        _buildSummaryCard(
          context,
          icon: LucideIcons.search,
          title: l10n.exploreDetailLookingFor,
          value: request.needTypeLabels.join(', '),
        ),
      if (request.offerInReturnLabels.isNotEmpty)
        _buildSummaryCard(
          context,
          icon: LucideIcons.gift,
          title: l10n.exploreDetailWhatTheyOffer,
          value: request.offerInReturnLabels.join(', '),
        ),
      if (request.communitySize != null || request.typicalAttendance != null)
        _buildSummaryCard(
          context,
          icon: LucideIcons.users,
          title: l10n.exploreDetailCommunitySize,
          value: _buildScaleLabel(context, request),
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

  Widget _buildSummaryCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(KolabingSpacing.md),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: KolabingRadius.borderRadiusMd,
      border: Border.all(color: context.colors.hairline),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: context.colors.categoryOrangeBg,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              size: 16,
              color: context.colors.categoryOrangeText,
            ),
          ),
        ),
        const SizedBox(width: KolabingSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: KolabingTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: context.colors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                  color: context.colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  String _buildScaleLabel(
    BuildContext context,
    CommunityRequestSummary request,
  ) {
    final l10n = AppLocalizations.of(context);
    final parts = <String>[];
    if (request.communitySize != null) {
      parts.add(l10n.exploreDetailScaleCommunity(request.communitySize!));
    }
    if (request.typicalAttendance != null) {
      parts.add(l10n.exploreDetailScaleExpected(request.typicalAttendance!));
    }
    return parts.join(' · ');
  }

  // ---------------------------------------------------------------------------
  // Offer Summary Section
  // ---------------------------------------------------------------------------

  Widget _buildOfferSummarySection(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        AppLocalizations.of(context).exploreDetailWhatsOffered,
        style: KolabingTextStyles.labelLarge.copyWith(
          color: context.colors.onSurface,
        ),
      ),
      const SizedBox(height: KolabingSpacing.xs),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.primary,
          borderRadius: KolabingRadius.borderRadiusMd,
          border: Border.all(color: context.colors.primaryDark),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.gift, size: 18, color: context.colors.onPrimary),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: Text(
                opportunity.offerSummary,
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.onPrimary,
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

  Widget _buildLocationAndDetails(BuildContext context) {
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
        _DetailItem(
          icon: LucideIcons.mapPin,
          label: locationLabel,
          kind: _DetailPillKind.sand,
        ),
      _DetailItem(
        icon: LucideIcons.building2,
        label: opportunity.venueMode.label(AppLocalizations.of(context)),
        kind: _DetailPillKind.sand,
      ),
      _DetailItem(
        icon: LucideIcons.calendar,
        label: '$startFormatted - $endFormatted',
        kind: _DetailPillKind.sage,
      ),
      _DetailItem(
        icon: LucideIcons.clock,
        label: opportunity.availabilityMode.displayName,
        kind: _DetailPillKind.sage,
      ),
    ];

    return Wrap(
      spacing: KolabingSpacing.xs,
      runSpacing: KolabingSpacing.xs,
      children: items.map((item) => _buildDetailPill(context, item)).toList(),
    );
  }

  Widget _buildDetailPill(BuildContext context, _DetailItem item) {
    // Both sand and sage now use warm amber for visual consistency
    final (bg, fg) = switch (item.kind) {
      _DetailPillKind.sand => (
        context.colors.amberChipContainer,
        context.colors.amberChipText,
      ),
      _DetailPillKind.sage => (
        context.colors.amberChipContainer,
        context.colors.amberChipText,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.sm,
        vertical: KolabingSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(KolabingRadius.round),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 14, color: fg),
          const SizedBox(width: KolabingSpacing.xxs),
          Flexible(
            child: Text(
              item.label,
              style: KolabingTextStyles.labelMedium.copyWith(color: fg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Availability Days (Recurring Mode)
  // ---------------------------------------------------------------------------

  Widget _buildAvailabilityDays(BuildContext context) {
    final activeDays = opportunity.recurringDays.toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).exploreDetailAvailableDays,
          style: KolabingTextStyles.labelLarge.copyWith(
            color: context.colors.onSurface,
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
                    ? context.colors.primary
                    : context.colors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _dayLabels[index],
                style: KolabingTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isAvailable
                      ? context.colors.onPrimary
                      : context.colors.textTertiary,
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

  Widget _buildCategoriesSection(BuildContext context) => Wrap(
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
              color: context.colors.accentOrange,
              borderRadius: BorderRadius.circular(KolabingRadius.round),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CategoryIcon(
                  name: category,
                  size: 14,
                  color: context.colors.accentOrangeText,
                ),
                const SizedBox(width: 4),
                Text(
                  category,
                  style: KolabingTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.accentOrangeText,
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
    // Applications closed (opportunity closed/completed or no date left): the
    // Apply CTA is disabled and never falls through to the paywall.
    final applicationsOpen = opportunityApplicationsOpen(opportunity);
    final showsSubscribeAction =
        applicationsOpen && !canApply && onSubscribe != null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        KolabingSpacing.md,
        KolabingSpacing.md,
        KolabingSpacing.md,
        KolabingSpacing.md + bottomPadding,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
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
          if (!applicationsOpen)
            KolabingButton(
              label: AppLocalizations.of(context).exploreApplicationsClosed,
              onPressed: null,
              variant: KolabingButtonVariant.primary,
              icon: const Icon(LucideIcons.calendarX),
              height: 52,
            )
          else
            KolabingButton(
              label: showsSubscribeAction
                  ? AppLocalizations.of(context).exploreDetailUnlockToApply
                  : AppLocalizations.of(context).exploreDetailApplyNow,
              onPressed: canApply ? onApply : onSubscribe,
              variant: KolabingButtonVariant.primary,
              icon: Icon(
                showsSubscribeAction ? LucideIcons.crown : LucideIcons.send,
              ),
              height: 52,
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
                AppLocalizations.of(context).exploreDetailViewCreatorProfile,
                style: KolabingTextStyles.labelLarge.copyWith(fontSize: 13),
              ),
              style: TextButton.styleFrom(
                foregroundColor: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _DetailPillKind { sand, sage }

/// Internal helper for detail pill items.
class _DetailItem {
  const _DetailItem({
    required this.icon,
    required this.label,
    this.kind = _DetailPillKind.sand,
  });

  final IconData icon;
  final String label;
  final _DetailPillKind kind;
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
                AppLocalizations.of(context).exploreDetailPastEventPhotos,
                style: KolabingTextStyles.labelLarge.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              Text(
                AppLocalizations.of(context).exploreDetailRecentMoments,
                style: KolabingTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w400,
                  color: context.colors.onSurfaceVariant,
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
                            ? context.colors.primary
                            : context.colors.darkBorder,
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
              color: context.colors.surfaceVariant,
              alignment: Alignment.center,
              child: Icon(
                LucideIcons.imageOff,
                color: context.colors.textTertiary,
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
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.textOnDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  slide.subtitle,
                  style: KolabingTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.textOnDark.withValues(alpha: 0.85),
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
