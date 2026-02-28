import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../application/widgets/apply_modal.dart';
import '../../auth/providers/auth_provider.dart';
import '../../opportunity/models/opportunity.dart';
import '../../opportunity/providers/opportunity_provider.dart';

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

    if (result == true && mounted) {
      // Refresh the opportunity detail to update hasApplied status
      ref.invalidate(opportunityDetailProvider(widget.offerId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(opportunityDetailProvider(widget.offerId));

    return detailAsync.when(
      loading: () {
        // Show pre-loaded data while refreshing, otherwise shimmer
        if (widget.offer != null) {
          return _buildContent(widget.offer!);
        }
        return _buildLoadingState();
      },
      error: (error, _) {
        // Show pre-loaded data on error, otherwise error state
        if (widget.offer != null) {
          return _buildContent(widget.offer!);
        }
        return _buildErrorState(error.toString());
      },
      data: (opportunity) => _buildContent(opportunity),
    );
  }

  Widget _buildContent(Opportunity opportunity) => Scaffold(
        backgroundColor: KolabingColors.background,
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // App bar with back button
                SliverAppBar(
                  backgroundColor: KolabingColors.primary,
                  expandedHeight: 200,
                  pinned: true,
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.arrowLeft,
                        color: KolabingColors.textPrimary,
                        size: 20,
                      ),
                    ),
                    onPressed: () => context.pop(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildHeroHeader(opportunity),
                  ),
                ),

                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
              child: _buildBottomAction(opportunity),
            ),
          ],
        ),
      );

  Widget _buildHeroHeader(Opportunity opportunity) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              KolabingColors.primary,
              KolabingColors.primary.withValues(alpha: 0.7),
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
                      onTap: opportunity.creatorProfile != null
                          ? () => context.push(
                                '/profile/${opportunity.creatorProfile!.id}',
                                extra: opportunity.creatorProfile,
                              )
                          : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _CreatorAvatar(
                            avatarUrl: opportunity.creatorProfile?.avatarUrl,
                            initial:
                                opportunity.creatorProfile?.initial ?? '?',
                            size: 56,
                          ),
                          const SizedBox(width: KolabingSpacing.sm),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opportunity.creatorProfile?.displayName ??
                                    'Unknown',
                                style: GoogleFonts.rubik(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: KolabingColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                opportunity.creatorProfile?.userType ?? '',
                                style: GoogleFonts.openSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: KolabingColors.textSecondary,
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
          color: KolabingColors.surface,
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
              style: GoogleFonts.rubik(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: KolabingColors.textPrimary,
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
                color: KolabingColors.primary.withValues(alpha: 0.15),
                borderRadius: KolabingRadius.borderRadiusRound,
              ),
              child: Text(
                opportunity.availabilityMode.displayName.toUpperCase(),
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: KolabingSpacing.md),

            // Description
            Text(
              opportunity.description,
              style: GoogleFonts.openSans(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: KolabingColors.textSecondary,
                height: 1.6,
              ),
            ),

            // Applications count
            if (opportunity.applicationsCount != null &&
                opportunity.applicationsCount! > 0) ...[
              const SizedBox(height: KolabingSpacing.md),
              Row(
                children: [
                  const Icon(LucideIcons.users, size: 16, color: KolabingColors.textTertiary),
                  const SizedBox(width: KolabingSpacing.xxs),
                  Text(
                    '${opportunity.applicationsCount} application${opportunity.applicationsCount == 1 ? '' : 's'}',
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: KolabingColors.textTertiary,
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
              'CATEGORIES',
              style: GoogleFonts.rubik(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: KolabingColors.textPrimary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            Wrap(
              spacing: KolabingSpacing.xs,
              runSpacing: KolabingSpacing.xs,
              children: opportunity.categories
                  .map((cat) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: KolabingSpacing.sm,
                          vertical: KolabingSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: KolabingColors.primary.withValues(alpha: 0.1),
                          borderRadius: KolabingRadius.borderRadiusRound,
                        ),
                        child: Text(
                          cat,
                          style: GoogleFonts.openSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: KolabingColors.textPrimary,
                          ),
                        ),
                      ))
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
          color: KolabingColors.success.withValues(alpha: 0.05),
          borderRadius: KolabingRadius.borderRadiusLg,
          border: Border.all(
            color: KolabingColors.success.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.gift, size: 18, color: KolabingColors.activeText),
                const SizedBox(width: KolabingSpacing.xs),
                Text(
                  'BUSINESS OFFER',
                  style: GoogleFonts.rubik(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: KolabingColors.activeText,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: KolabingSpacing.sm),

            if (opportunity.businessOffer.venue)
              _buildOfferItem(LucideIcons.building2, 'Venue provided'),
            if (opportunity.businessOffer.foodDrink)
              _buildOfferItem(LucideIcons.coffee, 'Food & Drink included'),
            if (opportunity.businessOffer.discount.enabled)
              _buildOfferItem(
                LucideIcons.percent,
                opportunity.businessOffer.discount.percentage != null
                    ? '${opportunity.businessOffer.discount.percentage}% Discount'
                    : 'Discount offered',
              ),
            if (opportunity.businessOffer.products.isNotEmpty)
              ...opportunity.businessOffer.products
                  .map((p) => _buildOfferItem(LucideIcons.box, p)),
            if (opportunity.businessOffer.other?.isNotEmpty ?? false)
              _buildOfferItem(
                  LucideIcons.plus, opportunity.businessOffer.other!),
          ],
        ),
      );

  Widget _buildOfferItem(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
        child: Row(
          children: [
            Icon(icon, size: 16, color: KolabingColors.activeText),
            const SizedBox(width: KolabingSpacing.xs),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: KolabingColors.textPrimary,
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
        color: KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(color: KolabingColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.checkCircle, size: 18, color: KolabingColors.textPrimary),
              const SizedBox(width: KolabingSpacing.xs),
              Text(
                'EXPECTED DELIVERABLES',
                style: GoogleFonts.rubik(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.textPrimary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: KolabingSpacing.sm),
          if (del.socialMediaContent)
            _buildDeliverableItem(LucideIcons.instagram, 'Social Media Content'),
          if (del.eventActivation)
            _buildDeliverableItem(LucideIcons.megaphone, 'Event Activation'),
          if (del.productPlacement)
            _buildDeliverableItem(LucideIcons.package, 'Product Placement'),
          if (del.communityReach)
            _buildDeliverableItem(LucideIcons.users, 'Community Reach'),
          if (del.reviewFeedback)
            _buildDeliverableItem(LucideIcons.star, 'Review & Feedback'),
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
            Icon(icon, size: 16, color: KolabingColors.textTertiary),
            const SizedBox(width: KolabingSpacing.xs),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: KolabingColors.textPrimary,
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
        color: KolabingColors.surface,
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
            'LOCATION & AVAILABILITY',
            style: GoogleFonts.rubik(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: KolabingColors.textPrimary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: KolabingSpacing.md),

          _buildInfoRow(
            icon: LucideIcons.mapPin,
            label: 'City',
            value: opportunity.preferredCity.isNotEmpty
                ? opportunity.preferredCity
                : 'Not specified',
          ),
          const SizedBox(height: KolabingSpacing.sm),
          _buildInfoRow(
            icon: LucideIcons.building2,
            label: 'Venue',
            value: opportunity.venueMode.displayName,
          ),
          if (opportunity.address?.isNotEmpty ?? false) ...[
            const SizedBox(height: KolabingSpacing.sm),
            _buildInfoRow(
              icon: LucideIcons.home,
              label: 'Address',
              value: opportunity.address!,
            ),
          ],
          const SizedBox(height: KolabingSpacing.sm),
          _buildInfoRow(
            icon: LucideIcons.calendar,
            label: 'Dates',
            value: dateText,
          ),
          const SizedBox(height: KolabingSpacing.sm),
          _buildInfoRow(
            icon: LucideIcons.clock,
            label: 'Mode',
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
  }) =>
      Row(
        children: [
          Icon(icon, size: 18, color: KolabingColors.textTertiary),
          const SizedBox(width: KolabingSpacing.xs),
          Text(
            '$label: ',
            style: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: KolabingColors.textTertiary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.openSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: KolabingColors.textPrimary,
              ),
            ),
          ),
        ],
      );

  Widget _buildBottomAction(Opportunity opportunity) {
    // If user owns this opportunity, don't show apply button
    final currentUserId = ref.read(authProvider).user?.id;
    final isOwn = currentUserId != null &&
        opportunity.creatorProfile?.id == currentUserId;
    if (isOwn) {
      return Container(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: KolabingColors.surface,
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
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: KolabingColors.surfaceVariant,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: KolabingRadius.borderRadiusMd,
                ),
              ),
              child: Text(
                'YOUR OPPORTUNITY',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: KolabingColors.textTertiary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // If user has already applied
    if (opportunity.hasApplied == true) {
      return Container(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        decoration: BoxDecoration(
          color: KolabingColors.surface,
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
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: KolabingColors.surfaceVariant,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: KolabingRadius.borderRadiusMd,
                ),
              ),
              child: Text(
                'ALREADY APPLIED',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: KolabingColors.textTertiary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
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
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => _handleApply(opportunity),
            style: ElevatedButton.styleFrom(
              backgroundColor: KolabingColors.primary,
              foregroundColor: KolabingColors.onPrimary,
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
                  'APPLY NOW',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() => Scaffold(
        backgroundColor: KolabingColors.background,
        appBar: AppBar(
          backgroundColor: KolabingColors.primary,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => context.pop(),
          ),
        ),
        body: Shimmer.fromColors(
          baseColor: KolabingColors.surfaceVariant,
          highlightColor: KolabingColors.surface,
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
        backgroundColor: KolabingColors.background,
        appBar: AppBar(
          backgroundColor: KolabingColors.primary,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Opportunity Details',
            style: GoogleFonts.rubik(
              fontWeight: FontWeight.w600,
              color: KolabingColors.textPrimary,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(KolabingSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: KolabingColors.errorBg,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Icon(
                      LucideIcons.alertCircle,
                      size: 36,
                      color: KolabingColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: KolabingSpacing.lg),
                Text(
                  'Opportunity Not Found',
                  style: GoogleFonts.rubik(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.textPrimary,
                  ),
                ),
                const SizedBox(height: KolabingSpacing.xs),
                Text(
                  error,
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    color: KolabingColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: KolabingSpacing.lg),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(opportunityDetailProvider(widget.offerId));
                  },
                  icon: const Icon(LucideIcons.rotateCcw, size: 16),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KolabingColors.primary,
                    foregroundColor: KolabingColors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
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
          color: KolabingColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
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
                  errorBuilder: (context, error, stackTrace) => _buildInitial(),
                ),
              )
            : _buildInitial(),
      );

  Widget _buildInitial() => Center(
        child: Text(
          initial,
          style: GoogleFonts.rubik(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
            color: KolabingColors.textPrimary,
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
      OpportunityStatus.published =>
        (KolabingColors.activeBg, KolabingColors.activeText),
      OpportunityStatus.draft =>
        (KolabingColors.pendingBg, KolabingColors.pendingText),
      OpportunityStatus.closed =>
        (KolabingColors.completedBg, KolabingColors.completedText),
      OpportunityStatus.completed =>
        (KolabingColors.completedBg, KolabingColors.completedText),
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
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
