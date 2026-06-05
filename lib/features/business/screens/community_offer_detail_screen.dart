import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/routes/routes.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/blurred_identity.dart';
import '../../application/widgets/apply_modal.dart';
import '../../application/widgets/apply_success_sheet.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../event/models/event.dart';
import '../../event/providers/event_provider.dart';
import '../../event/widgets/event_card.dart';
import '../../opportunity/models/opportunity.dart';
import '../../opportunity/providers/opportunity_provider.dart';
import '../providers/profile_provider.dart';

/// Detail screen for an opportunity
///
/// Shows full details including:
/// - Creator info header
/// - Business offer section
/// - Community deliverables section
/// - Location & availability details
/// - Categories
/// - Apply action (or management actions if own)
class CommunityOfferDetailScreen extends ConsumerStatefulWidget {
  const CommunityOfferDetailScreen({
    required this.offerId,
    this.offer,
    super.key,
  });

  /// The ID of the opportunity to display
  final String offerId;

  /// Optional pre-loaded opportunity data (for navigation optimization)
  final Opportunity? offer;

  @override
  ConsumerState<CommunityOfferDetailScreen> createState() =>
      _CommunityOfferDetailScreenState();
}

class _CommunityOfferDetailScreenState
    extends ConsumerState<CommunityOfferDetailScreen> {
  Future<void> _handleApply(Opportunity opportunity) async {
    final result = await ApplyModal.show(context, opportunity);

    if (result != true || !mounted) return;

    // Refresh detail so the bottom action flips to "ALREADY APPLIED".
    ref.invalidate(opportunityDetailProvider(widget.offerId));

    await ApplySuccessSheet.show(
      context,
      opportunity: opportunity,
      onViewApplications: () {
        if (!mounted) return;
        final route =
            GoRouterState.of(context).uri.path.startsWith('/community')
            ? KolabingRoutes.communityApplications
            : KolabingRoutes.businessApplications;
        context.go(route);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(opportunityDetailProvider(widget.offerId));
    final user = ref.watch(authProvider).user;
    // Subscription is a Business concern only; communities are never gated.
    final isSubscribed = ref.watch(profileProvider).isSubscribed;

    return detailAsync.when(
      loading: () {
        // Show pre-loaded data while refreshing, otherwise shimmer
        if (widget.offer != null) {
          return _buildContent(
            widget.offer!,
            isPreviewMode: _isPreviewMode(user, widget.offer!),
            hideCreatorIdentity: _shouldHideIdentity(
              user,
              widget.offer!,
              isSubscribed,
            ),
          );
        }
        return _buildLoadingState();
      },
      error: (error, _) {
        // Show pre-loaded data on error, otherwise error state
        if (widget.offer != null) {
          return _buildContent(
            widget.offer!,
            isPreviewMode: _isPreviewMode(user, widget.offer!),
            hideCreatorIdentity: _shouldHideIdentity(
              user,
              widget.offer!,
              isSubscribed,
            ),
          );
        }
        return _buildErrorState(error.toString());
      },
      data: (opportunity) => _buildContent(
        opportunity,
        isPreviewMode: _isPreviewMode(user, opportunity),
        hideCreatorIdentity: _shouldHideIdentity(
          user,
          opportunity,
          isSubscribed,
        ),
      ),
    );
  }

  /// Blur the community identity (name + logo) only when a free (non-subscribed)
  /// BUSINESS is viewing a COMMUNITY-authored post. Communities and subscribed
  /// businesses always see the real identity. Mirrors the Explore rule
  /// (ROLES-AND-PERMISSIONS.md golden rules 4 & 5, §2.5).
  bool _shouldHideIdentity(
    UserModel? user,
    Opportunity opportunity,
    bool isSubscribed,
  ) {
    if (user == null || !user.isBusiness || isSubscribed) return false;
    final creator = opportunity.creatorProfile;
    if (creator == null) return false;
    // Case-insensitive creator-role check (API casing may vary).
    final creatorIsCommunity = creator.userType.toLowerCase() == 'community';
    return creatorIsCommunity;
  }

  bool _isPreviewMode(UserModel? user, Opportunity opportunity) {
    final communityProfileId = user?.communityProfile?.id;
    if (user == null || !user.isCommunity || communityProfileId == null) {
      return false;
    }

    if (opportunity.status != OpportunityStatus.published) {
      return false;
    }

    return opportunity.isOwn == true ||
        opportunity.creatorProfile?.id == communityProfileId;
  }

  Widget _buildContent(
    Opportunity opportunity, {
    required bool isPreviewMode,
    bool hideCreatorIdentity = false,
  }) => Scaffold(
    backgroundColor: context.colors.background,
    body: Stack(
      children: [
        CustomScrollView(
          slivers: [
            // App bar with back button
            SliverAppBar(
              backgroundColor: context.colors.primary,
              expandedHeight: 200,
              pinned: true,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.arrowLeft,
                    color: context.colors.onSurface,
                    size: 20,
                  ),
                ),
                onPressed: () => context.pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeroHeader(
                  opportunity,
                  hideCreatorIdentity: hideCreatorIdentity,
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPreviewMode) ...[
                      const _PreviewModeBanner(),
                      const SizedBox(height: KolabingSpacing.md),
                    ],

                    // Details card
                    _buildDetailsCard(opportunity),

                    // Categories
                    if (opportunity.categories.isNotEmpty)
                      _buildCategoriesSection(opportunity),

                    // Business offer section
                    if (opportunity.businessOffer.hasAnyOffer)
                      _buildBusinessOfferSection(opportunity),

                    // Community deliverables section
                    if (opportunity.communityDeliverables.hasAnyDeliverable)
                      _buildDeliverablesSection(opportunity),

                    // Location & availability
                    _buildLocationSection(opportunity),

                    if (opportunity.creatorProfile != null)
                      _CommunityPastEventsSection(
                        profileId: opportunity.creatorProfile!.id,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Fixed bottom button
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomAction(opportunity, isPreviewMode: isPreviewMode),
        ),
      ],
    ),
  );

  Widget _buildHeroHeader(
    Opportunity opportunity, {
    bool hideCreatorIdentity = false,
  }) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          context.colors.primary,
          context.colors.primary.withValues(alpha: 0.7),
        ],
      ),
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          KolabingSpacing.md,
          60,
          KolabingSpacing.md,
          KolabingSpacing.md,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  // When the identity is blurred (free business viewing a
                  // community post) the profile is not yet unlocked, so the
                  // tap-through to the public profile is disabled.
                  onTap:
                      opportunity.creatorProfile != null && !hideCreatorIdentity
                      ? () => context.push(
                          '/profile/${opportunity.creatorProfile!.id}',
                          extra: opportunity.creatorProfile,
                        )
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Community LOGO — Gaussian-blurred when hidden.
                      BlurredIdentity(
                        enabled: hideCreatorIdentity,
                        sigma: 14,
                        borderRadius: BorderRadius.circular(28),
                        child: _CreatorAvatar(
                          avatarUrl: opportunity.creatorProfile?.avatarUrl,
                          initial: opportunity.creatorProfile?.initial ?? '?',
                          size: 56,
                        ),
                      ),
                      const SizedBox(width: KolabingSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Community NAME — Gaussian-blurred when hidden.
                          BlurredIdentity(
                            enabled: hideCreatorIdentity,
                            sigma: 8,
                            child: Text(
                              opportunity.creatorProfile?.displayName ??
                                  AppLocalizations.of(
                                    context,
                                  ).communityOfferDetailUnknown,
                              style: KolabingTextStyles.bodyLarge.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: context.colors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            hideCreatorIdentity
                                ? AppLocalizations.of(
                                    context,
                                  ).communityOfferDetailSubscribeToReveal
                                : (opportunity.creatorProfile?.userType ?? ''),
                            style: KolabingTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w500,
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _StatusBadge(status: opportunity.status),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildDetailsCard(Opportunity opportunity) => Container(
    margin: const EdgeInsets.all(KolabingSpacing.md),
    padding: const EdgeInsets.all(KolabingSpacing.md),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: KolabingRadius.borderRadiusLg,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          opportunity.title,
          style: KolabingTextStyles.bodyLarge.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: context.colors.onSurface,
            height: 1.3,
          ),
        ),
        const SizedBox(height: KolabingSpacing.sm),

        // Availability mode badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: KolabingSpacing.sm,
            vertical: KolabingSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: context.colors.primary.withValues(alpha: 0.15),
            borderRadius: KolabingRadius.borderRadiusRound,
          ),
          child: Text(
            opportunity.availabilityMode.displayName.toUpperCase(),
            style: KolabingTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.onSurface,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: KolabingSpacing.md),

        // H2: Offer headline (pinned right below the title for at-a-glance
        // scanning).
        if (opportunity.offerHeadline != null &&
            opportunity.offerHeadline!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.sm,
              vertical: 8,
            ),
            margin: const EdgeInsets.only(bottom: KolabingSpacing.md),
            decoration: BoxDecoration(
              color: context.colors.softYellow,
              borderRadius: BorderRadius.circular(KolabingRadius.sm),
              border: Border.all(
                color: context.colors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.zap,
                  size: 16,
                  color: context.colors.onSurface,
                ),
                const SizedBox(width: KolabingSpacing.xs),
                Expanded(
                  child: Text(
                    opportunity.offerHeadline!,
                    style: KolabingTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Description
        Text(
          opportunity.description,
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontSize: 15,
            color: context.colors.onSurfaceVariant,
            height: 1.6,
          ),
        ),

        // H3 (writer-side public copy): base offer goes here so every
        // viewer sees the full offer text, not just the headline.
        if (opportunity.baseOffer != null &&
            opportunity.baseOffer!.isNotEmpty) ...[
          const SizedBox(height: KolabingSpacing.md),
          _BaseOfferCard(text: opportunity.baseOffer!),
        ],

        // H3 (reader-side gated): negotiation triggers only arrive after
        // the viewer has applied. Backend gates the field — if it's
        // empty, we render nothing.
        if (opportunity.negotiationTriggers.isNotEmpty) ...[
          const SizedBox(height: KolabingSpacing.md),
          _NegotiationTriggersSection(
            triggers: opportunity.negotiationTriggers,
          ),
        ],

        // Applications count
        if (opportunity.applicationsCount != null &&
            opportunity.applicationsCount! > 0) ...[
          const SizedBox(height: KolabingSpacing.md),
          Row(
            children: [
              Icon(
                LucideIcons.users,
                size: 16,
                color: context.colors.textTertiary,
              ),
              const SizedBox(width: KolabingSpacing.xxs),
              Text(
                AppLocalizations.of(
                  context,
                ).communityOfferDetailApplicationsCount(
                  opportunity.applicationsCount!,
                ),
                style: KolabingTextStyles.captionSecondary.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.colors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  Widget _buildCategoriesSection(Opportunity opportunity) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).communityOfferDetailCategories,
          style: KolabingTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colors.onSurface,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: KolabingSpacing.sm),
        Wrap(
          spacing: KolabingSpacing.xs,
          runSpacing: KolabingSpacing.xs,
          children: opportunity.categories
              .map(
                (cat) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KolabingSpacing.sm,
                    vertical: KolabingSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.1),
                    borderRadius: KolabingRadius.borderRadiusRound,
                  ),
                  child: Text(
                    cat,
                    style: KolabingTextStyles.captionSecondary.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: KolabingSpacing.md),
      ],
    ),
  );

  Widget _buildBusinessOfferSection(Opportunity opportunity) => Container(
    margin: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
    padding: const EdgeInsets.all(KolabingSpacing.md),
    decoration: BoxDecoration(
      color: context.colors.success.withValues(alpha: 0.05),
      borderRadius: KolabingRadius.borderRadiusLg,
      border: Border.all(color: context.colors.success.withValues(alpha: 0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.gift,
              size: 18,
              color: context.colors.activeText,
            ),
            const SizedBox(width: KolabingSpacing.xs),
            Text(
              AppLocalizations.of(context).communityOfferDetailBusinessOffer,
              style: KolabingTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colors.activeText,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: KolabingSpacing.sm),

        if (opportunity.businessOffer.venue)
          _buildOfferItem(
            LucideIcons.building2,
            AppLocalizations.of(context).communityOfferDetailVenueProvided,
          ),
        if (opportunity.businessOffer.foodDrink)
          _buildOfferItem(
            LucideIcons.coffee,
            AppLocalizations.of(context).communityOfferDetailFoodDrink,
          ),
        if (opportunity.businessOffer.discount.enabled)
          _buildOfferItem(
            LucideIcons.percent,
            opportunity.businessOffer.discount.percentage != null
                ? AppLocalizations.of(context).communityOfferDetailDiscountPct(
                    opportunity.businessOffer.discount.percentage!,
                  )
                : AppLocalizations.of(
                    context,
                  ).communityOfferDetailDiscountOffered,
          ),
        if (opportunity.businessOffer.products.isNotEmpty)
          ...opportunity.businessOffer.products.map(
            (p) => _buildOfferItem(LucideIcons.box, p),
          ),
        if (opportunity.businessOffer.other?.isNotEmpty ?? false)
          _buildOfferItem(LucideIcons.plus, opportunity.businessOffer.other!),
      ],
    ),
  );

  Widget _buildOfferItem(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
    child: Row(
      children: [
        Icon(icon, size: 16, color: context.colors.activeText),
        const SizedBox(width: KolabingSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: context.colors.onSurface,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildDeliverablesSection(Opportunity opportunity) {
    final del = opportunity.communityDeliverables;
    return Container(
      margin: const EdgeInsets.all(KolabingSpacing.md),
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(color: context.colors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.checkCircle,
                size: 18,
                color: context.colors.onSurface,
              ),
              const SizedBox(width: KolabingSpacing.xs),
              Text(
                AppLocalizations.of(
                  context,
                ).communityOfferDetailExpectedDeliverables,
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.onSurface,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: KolabingSpacing.sm),
          if (del.socialMediaContent)
            _buildDeliverableItem(
              LucideIcons.instagram,
              AppLocalizations.of(context).communityOfferDetailSocialMedia,
            ),
          if (del.eventActivation)
            _buildDeliverableItem(
              LucideIcons.megaphone,
              AppLocalizations.of(context).communityOfferDetailEventActivation,
            ),
          if (del.productPlacement)
            _buildDeliverableItem(
              LucideIcons.package,
              AppLocalizations.of(context).communityOfferDetailProductPlacement,
            ),
          if (del.communityReach)
            _buildDeliverableItem(
              LucideIcons.users,
              AppLocalizations.of(context).communityOfferDetailCommunityReach,
            ),
          if (del.reviewFeedback)
            _buildDeliverableItem(
              LucideIcons.star,
              AppLocalizations.of(context).communityOfferDetailReviewFeedback,
            ),
          if (del.other?.isNotEmpty ?? false)
            _buildDeliverableItem(LucideIcons.plus, del.other!),
        ],
      ),
    );
  }

  Widget _buildDeliverableItem(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
    child: Row(
      children: [
        Icon(icon, size: 16, color: context.colors.textTertiary),
        const SizedBox(width: KolabingSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: context.colors.onSurface,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildLocationSection(Opportunity opportunity) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final dateText =
        '${dateFormat.format(opportunity.availabilityStart)} - ${dateFormat.format(opportunity.availabilityEnd)}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: KolabingSpacing.md),
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).communityOfferDetailLocationTitle,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.onSurface,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),

          _buildInfoRow(
            icon: LucideIcons.mapPin,
            label: AppLocalizations.of(context).communityOfferDetailCity,
            value: opportunity.preferredCity.isNotEmpty
                ? opportunity.preferredCity
                : AppLocalizations.of(context).communityOfferDetailNotSpecified,
          ),
          const SizedBox(height: KolabingSpacing.sm),
          _buildInfoRow(
            icon: LucideIcons.building2,
            label: AppLocalizations.of(context).communityOfferDetailVenue,
            value: opportunity.venueMode.displayName,
          ),
          if (opportunity.address?.isNotEmpty ?? false) ...[
            const SizedBox(height: KolabingSpacing.sm),
            _buildInfoRow(
              icon: LucideIcons.home,
              label: AppLocalizations.of(context).communityOfferDetailAddress,
              value: opportunity.address!,
            ),
          ],
          const SizedBox(height: KolabingSpacing.sm),
          _buildInfoRow(
            icon: LucideIcons.calendar,
            label: AppLocalizations.of(context).communityOfferDetailDates,
            value: dateText,
          ),
          const SizedBox(height: KolabingSpacing.sm),
          _buildInfoRow(
            icon: LucideIcons.clock,
            label: AppLocalizations.of(context).communityOfferDetailMode,
            value: opportunity.availabilityMode.displayName,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) => Row(
    children: [
      Icon(icon, size: 18, color: context.colors.textTertiary),
      const SizedBox(width: KolabingSpacing.xs),
      Text(
        '$label: ',
        style: KolabingTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w500,
          color: context.colors.textTertiary,
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: KolabingTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.onSurface,
          ),
        ),
      ),
    ],
  );

  Widget _buildBottomAction(
    Opportunity opportunity, {
    required bool isPreviewMode,
  }) {
    // Self-apply detection happens on the backend — the client cannot reliably
    // compare user_id vs profile_id since the API uses different ID spaces.
    // Always show APPLY NOW to authenticated viewers; the server returns a
    // friendly error if the user attempts to apply to their own opportunity.

    if (isPreviewMode) {
      return _buildBottomButtonShell(
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colors.surfaceVariant,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.eye, size: 18),
              const SizedBox(width: KolabingSpacing.xs),
              Text(
                AppLocalizations.of(context).communityOfferDetailPreviewMode,
                style: KolabingTextStyles.button.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: context.colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If user has already applied
    if (opportunity.hasApplied == true) {
      return _buildBottomButtonShell(
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colors.surfaceVariant,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: KolabingRadius.borderRadiusMd,
            ),
          ),
          child: Text(
            AppLocalizations.of(context).communityOfferDetailAlreadyApplied,
            style: KolabingTextStyles.button.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: context.colors.textTertiary,
            ),
          ),
        ),
      );
    }

    return _buildBottomButtonShell(
      child: ElevatedButton(
        onPressed: () => _handleApply(opportunity),
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colors.primary,
          foregroundColor: context.colors.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: KolabingRadius.borderRadiusMd,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.send, size: 18),
            const SizedBox(width: KolabingSpacing.xs),
            Text(
              AppLocalizations.of(context).communityOfferDetailApplyNow,
              style: KolabingTextStyles.button.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtonShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(width: double.infinity, height: 52, child: child),
      ),
    );
  }

  Widget _buildLoadingState() => Scaffold(
    backgroundColor: context.colors.background,
    appBar: AppBar(
      backgroundColor: context.colors.primary,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        onPressed: () => context.pop(),
      ),
    ),
    body: Shimmer.fromColors(
      baseColor: context.colors.surfaceVariant,
      highlightColor: context.colors.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 24,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: KolabingRadius.borderRadiusSm,
              ),
            ),
            const SizedBox(height: KolabingSpacing.md),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: KolabingRadius.borderRadiusLg,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildErrorState(String error) => Scaffold(
    backgroundColor: context.colors.background,
    appBar: AppBar(
      backgroundColor: context.colors.primary,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        onPressed: () => context.pop(),
      ),
      title: Text(
        AppLocalizations.of(context).communityOfferDetailTitle,
        style: KolabingTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: context.colors.onSurface,
        ),
      ),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.colors.errorBg,
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 80,
                height: 80,
                child: Icon(
                  LucideIcons.alertCircle,
                  size: 36,
                  color: context.colors.error,
                ),
              ),
            ),
            const SizedBox(height: KolabingSpacing.lg),
            Text(
              AppLocalizations.of(context).communityOfferDetailNotFound,
              style: KolabingTextStyles.bodyMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              error,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KolabingSpacing.lg),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(opportunityDetailProvider(widget.offerId));
              },
              icon: const Icon(LucideIcons.rotateCcw, size: 16),
              label: Text(AppLocalizations.of(context).commonRetry),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: context.colors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PreviewModeBanner extends StatelessWidget {
  const _PreviewModeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        KolabingSpacing.md,
        KolabingSpacing.md,
        KolabingSpacing.md,
        0,
      ),
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.12),
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(
          color: context.colors.primary.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.eye, color: context.colors.primary, size: 18),
          const SizedBox(width: KolabingSpacing.sm),
          Expanded(
            child: Text(
              AppLocalizations.of(context).communityOfferDetailPreviewBanner,
              style: KolabingTextStyles.captionSecondary.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityPastEventsSection extends ConsumerWidget {
  const _CommunityPastEventsSection({required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEvents = ref.watch(profileEventsProvider(profileId));

    return asyncEvents.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (events) {
        final visibleEvents = _sortedVisibleEvents(events);
        if (visibleEvents.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(
            KolabingSpacing.md,
            0,
            KolabingSpacing.md,
            KolabingSpacing.md,
          ),
          padding: const EdgeInsets.all(KolabingSpacing.md),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: KolabingRadius.borderRadiusLg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).communityOfferDetailPastEvents,
                style: KolabingTextStyles.bodyMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              Text(
                AppLocalizations.of(
                  context,
                ).communityOfferDetailPastEventsSubtitle,
                style: KolabingTextStyles.captionSecondary.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: KolabingSpacing.md),
              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: visibleEvents.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: KolabingSpacing.sm),
                  itemBuilder: (context, index) {
                    final event = visibleEvents[index];
                    return EventCard(
                      event: event,
                      onTap: () => context.push(
                        KolabingRoutes.buildEventDetailPath(event.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Event> _sortedVisibleEvents(List<Event> events) {
    final sorted = [...events]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(5).toList();
  }
}

/// Creator avatar widget
class _CreatorAvatar extends StatelessWidget {
  const _CreatorAvatar({
    required this.avatarUrl,
    required this.initial,
    this.size = 48,
  });

  final String? avatarUrl;
  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: context.colors.surface,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: avatarUrl != null
        ? ClipOval(
            child: Image.network(
              avatarUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildInitial(context),
            ),
          )
        : _buildInitial(context),
  );

  Widget _buildInitial(BuildContext context) => Center(
    child: Text(
      initial,
      style: KolabingTextStyles.bodyMedium.copyWith(
        fontSize: size * 0.4,
        fontWeight: FontWeight.w600,
        color: context.colors.onSurface,
      ),
    ),
  );
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final OpportunityStatus status;

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, textColor) = switch (status) {
      OpportunityStatus.published => (
        context.colors.activeBg,
        context.colors.activeText,
      ),
      OpportunityStatus.draft => (
        context.colors.pendingBg,
        context.colors.pendingText,
      ),
      OpportunityStatus.closed => (
        context.colors.completedBg,
        context.colors.completedText,
      ),
      OpportunityStatus.completed => (
        context.colors.completedBg,
        context.colors.completedText,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.sm,
        vertical: KolabingSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: KolabingRadius.borderRadiusRound,
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: KolabingTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// =============================================================================
// H3: Base offer + Negotiation triggers
// =============================================================================

class _BaseOfferCard extends StatelessWidget {
  const _BaseOfferCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(KolabingSpacing.md),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(KolabingRadius.md),
      border: Border.all(color: context.colors.darkBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.gift,
              size: 16,
              color: context.colors.primary,
            ),
            const SizedBox(width: KolabingSpacing.xs),
            Text(
              AppLocalizations.of(context).communityOfferDetailTheOffer,
              style: KolabingTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: context.colors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          text,
          style: KolabingTextStyles.bodySmall.copyWith(
            color: context.colors.onSurface,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

class _NegotiationTriggersSection extends StatelessWidget {
  const _NegotiationTriggersSection({required this.triggers});

  final List<NegotiationTrigger> triggers;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(KolabingSpacing.md),
    decoration: BoxDecoration(
      // Slightly different background so it reads as "extra terms unlocked
      // for you" rather than the standard public offer card.
      color: context.colors.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(KolabingRadius.md),
      border: Border.all(color: context.colors.primary.withValues(alpha: 0.25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.unlock,
              size: 16,
              color: context.colors.primary,
            ),
            const SizedBox(width: KolabingSpacing.xs),
            Text(
              AppLocalizations.of(context).communityOfferDetailExtraTerms,
              style: KolabingTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: context.colors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          AppLocalizations.of(context).communityOfferDetailExtraTermsSubtitle,
          style: KolabingTextStyles.bodySmall.copyWith(
            fontSize: 12,
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: KolabingSpacing.sm),
        ...triggers.map((trigger) => _buildTriggerRow(context, trigger)),
      ],
    ),
  );

  Widget _buildTriggerRow(BuildContext context, NegotiationTrigger trigger) =>
      Padding(
    padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: KolabingTextStyles.bodySmall.copyWith(
            color: context.colors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(
                  context,
                ).communityOfferDetailTriggerCondition(trigger.condition),
                style: KolabingTextStyles.labelSmall.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: context.colors.textTertiary,
                ),
              ),
              Text(
                trigger.additionalOffer,
                style: KolabingTextStyles.captionSecondary.copyWith(
                  color: context.colors.onSurface,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
