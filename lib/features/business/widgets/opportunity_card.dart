import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../opportunity/models/opportunity.dart';

/// Card widget for displaying an opportunity in the explore list
///
/// Shows creator info, opportunity details, category tags, offer summary,
/// and action buttons.
class OpportunityCard extends StatelessWidget {
  const OpportunityCard({
    required this.opportunity,
    super.key,
    this.onView,
    this.onApply,
  });

  final Opportunity opportunity;
  final VoidCallback? onView;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? KolabingColors.darkSurface : KolabingColors.surface,
          borderRadius: KolabingRadius.borderRadiusLg,
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar, Creator Name, Status
              _buildHeader(isDark),
              const SizedBox(height: KolabingSpacing.sm),

              // Title
              Text(
                opportunity.title,
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? KolabingColors.textOnDark
                      : KolabingColors.textPrimary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: KolabingSpacing.xs),

              // Description
              Text(
                opportunity.description,
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: KolabingColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: KolabingSpacing.sm),

              // Category chips
              if (opportunity.categories.isNotEmpty) ...[
                _buildCategoryChips(isDark),
                const SizedBox(height: KolabingSpacing.sm),
              ],

              // Info tags row (city, venue mode, dates)
              _buildInfoTags(isDark),
              const SizedBox(height: KolabingSpacing.sm),

              // Offer summary
              if (opportunity.businessOffer.hasAnyOffer) ...[
                _buildOfferSummary(),
                const SizedBox(height: KolabingSpacing.sm),
              ],

              // Action buttons
              _buildActionButtons(isDark),
            ],
          ),
        ),
      );
  }

  Widget _buildHeader(bool isDark) => Row(
        children: [
          // Creator avatar
          _CreatorAvatar(
            avatarUrl: opportunity.creatorProfile?.avatarUrl,
            initial: opportunity.creatorProfile?.initial ?? '?',
            isDark: isDark,
          ),
          const SizedBox(width: KolabingSpacing.sm),

          // Creator name and type
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opportunity.creatorProfile?.displayName ?? 'Unknown',
                  style: GoogleFonts.openSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? KolabingColors.textOnDark
                        : KolabingColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  opportunity.creatorProfile?.userType ?? '',
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? KolabingColors.textOnDark.withValues(alpha: 0.5)
                        : KolabingColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Status badge
          _StatusBadge(status: opportunity.status),
        ],
      );

  Widget _buildCategoryChips(bool isDark) => Wrap(
        spacing: KolabingSpacing.xxs,
        runSpacing: KolabingSpacing.xxs,
        children: opportunity.categories
            .take(3)
            .map((cat) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KolabingSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: KolabingColors.primary.withValues(alpha: 0.1),
                    borderRadius: KolabingRadius.borderRadiusRound,
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.openSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? KolabingColors.textOnDark
                          : KolabingColors.textPrimary,
                    ),
                  ),
                ))
            .toList(),
      );

  Widget _buildInfoTags(bool isDark) {
    final dateFormat = DateFormat('MMM d');
    final dateText =
        '${dateFormat.format(opportunity.availabilityStart)} - ${dateFormat.format(opportunity.availabilityEnd)}';

    return Wrap(
      spacing: KolabingSpacing.xs,
      runSpacing: KolabingSpacing.xs,
      children: [
        if (opportunity.preferredCity.isNotEmpty)
          _TagPill(
            icon: LucideIcons.mapPin,
            label: opportunity.preferredCity,
            isDark: isDark,
          ),
        _TagPill(
          icon: LucideIcons.building2,
          label: opportunity.venueMode.displayName,
          isDark: isDark,
        ),
        _TagPill(
          icon: LucideIcons.calendar,
          label: dateText,
          isDark: isDark,
        ),
        _TagPill(
          icon: LucideIcons.clock,
          label: opportunity.availabilityMode.displayName,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildOfferSummary() => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.sm,
          vertical: KolabingSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: KolabingColors.success.withValues(alpha: 0.1),
          borderRadius: KolabingRadius.borderRadiusSm,
          border: Border.all(
            color: KolabingColors.success.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.gift,
              size: 14,
              color: KolabingColors.activeText,
            ),
            const SizedBox(width: KolabingSpacing.xxs),
            Flexible(
              child: Text(
                opportunity.offerSummary,
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: KolabingColors.activeText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  Widget _buildActionButtons(bool isDark) => Row(
        children: [
          // View button (outlined)
          Expanded(
            child: OutlinedButton(
              onPressed: onView,
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark
                    ? KolabingColors.textOnDark
                    : KolabingColors.textPrimary,
                side: BorderSide(
                  color: isDark
                      ? KolabingColors.darkBorder
                      : KolabingColors.border,
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: KolabingSpacing.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: KolabingRadius.borderRadiusMd,
                ),
              ),
              child: Text(
                'VIEW',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),

          // Apply button (primary)
          Expanded(
            child: ElevatedButton(
              onPressed: onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: KolabingColors.primary,
                foregroundColor: KolabingColors.onPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  vertical: KolabingSpacing.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: KolabingRadius.borderRadiusMd,
                ),
              ),
              child: Text(
                'APPLY',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      );
}

/// Circular avatar for creator with fallback initial
class _CreatorAvatar extends StatelessWidget {
  const _CreatorAvatar({
    required this.avatarUrl,
    required this.initial,
    this.isDark = false,
  });

  final String? avatarUrl;
  final String initial;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: KolabingColors.primary.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: KolabingColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: avatarUrl != null
            ? ClipOval(
                child: Image.network(
                  avatarUrl!,
                  width: 48,
                  height: 48,
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
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark
                ? KolabingColors.textOnDark
                : KolabingColors.textPrimary,
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
        status.displayName,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Tag pill widget for info display
class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.icon,
    required this.label,
    this.isDark = false,
  });

  final IconData icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Container(
        height: 28,
        padding: const EdgeInsets.symmetric(
          horizontal: KolabingSpacing.xs,
        ),
        decoration: BoxDecoration(
          color:
              isDark ? KolabingColors.darkBorder : KolabingColors.surfaceVariant,
          borderRadius: KolabingRadius.borderRadiusRound,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isDark
                  ? KolabingColors.textOnDark.withValues(alpha: 0.5)
                  : KolabingColors.textTertiary,
            ),
            const SizedBox(width: KolabingSpacing.xxs),
            Text(
              label,
              style: GoogleFonts.openSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: KolabingColors.textSecondary,
              ),
            ),
          ],
        ),
      );
}
