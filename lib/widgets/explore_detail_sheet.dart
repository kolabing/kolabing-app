import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../config/constants/radius.dart';
import '../config/constants/spacing.dart';
import '../config/theme/colors.dart';
import '../features/opportunity/models/opportunity.dart';

/// Modal bottom sheet displaying full opportunity details.
///
/// Shown when the user taps a card in the Explore tab. Contains scrollable
/// content with creator info, description, offer summary, location details,
/// availability days, and categories. Action buttons are pinned at the bottom.
class ExploreDetailSheet extends StatelessWidget {
  const ExploreDetailSheet({
    required this.opportunity,
    this.onApply,
    this.onView,
    this.canApply = true,
    super.key,
  });

  final Opportunity opportunity;
  final VoidCallback? onApply;
  final VoidCallback? onView;
  final bool canApply;

  /// Day labels indexed 1..7 (Mon..Sun) matching [Opportunity.recurringDays].
  static const _dayLabels = ['M', 'Tu', 'W', 'Th', 'F', 'Sa', 'Su'];

  /// Shows the detail sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required Opportunity opportunity,
    VoidCallback? onApply,
    VoidCallback? onView,
    bool canApply = true,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ExploreDetailSheet(
          opportunity: opportunity,
          onApply: onApply,
          onView: onView,
          canApply: canApply,
        ),
      );

  @override
  Widget build(BuildContext context) => Container(
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
    final displayName = creator?.displayName ?? 'Unknown';
    final initial = creator?.initial ?? '?';
    final avatarUrl = creator?.avatarUrl;
    final userType = creator?.userType ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Creator avatar
        _buildAvatar(avatarUrl, initial),
        const SizedBox(width: KolabingSpacing.sm),

        // Creator name + type badge
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: GoogleFonts.rubik(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: KolabingColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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

    final items = <_DetailItem>[
      if (opportunity.preferredCity.isNotEmpty)
        _DetailItem(
          icon: LucideIcons.mapPin,
          label: opportunity.preferredCity,
        ),
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
          Icon(
            item.icon,
            size: 14,
            color: KolabingColors.textSecondary,
          ),
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
            .map((category) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KolabingSpacing.sm,
                    vertical: KolabingSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: KolabingColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(KolabingRadius.round),
                  ),
                  child: Text(
                    category,
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: KolabingColors.textPrimary,
                    ),
                  ),
                ))
            .toList(),
      );

  // ---------------------------------------------------------------------------
  // Action Buttons (Sticky)
  // ---------------------------------------------------------------------------

  Widget _buildActionButtons(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

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
          if (canApply)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KolabingColors.primary,
                  foregroundColor: KolabingColors.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: KolabingRadius.borderRadiusMd,
                  ),
                ),
                child: Text(
                  "YES, I'D LIKE TO KOLAB",
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          if (canApply) const SizedBox(height: KolabingSpacing.xs),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: onView ?? () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: KolabingColors.textPrimary,
                side: const BorderSide(color: KolabingColors.border),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: KolabingRadius.borderRadiusMd,
                ),
              ),
              child: Text(
                'NOT RIGHT NOW',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal helper for detail pill items.
class _DetailItem {
  const _DetailItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}
