import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/layout.dart';
import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/category_icon.dart';
import '../../../widgets/kolabing_button.dart';
import '../../opportunity/models/opportunity.dart';
import '../../opportunity/opportunity_l10n.dart';

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
    this.isSaved = false,
    this.onToggleSave,
  });

  final Opportunity opportunity;
  final VoidCallback? onView;
  final VoidCallback? onApply;

  /// When [onToggleSave] is provided, a bookmark toggle is shown in the header
  /// (next to the status badge); [isSaved] drives its filled/outline state.
  final bool isSaved;
  final VoidCallback? onToggleSave;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? context.colors.darkSurface : Colors.white,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: isDark ? null : Border.all(color: context.colors.hairline),
        boxShadow: isDark ? null : [KolabingShadows.card],
      ),
      child: Padding(
        padding: const EdgeInsets.all(KolabingSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar, Creator Name, Status
            _buildHeader(context, isDark),
            const SizedBox(height: KolabingSpacing.sm),

            // Title
            Text(
              opportunity.title,
              style: KolabingTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? context.colors.textOnDark
                    : context.colors.onSurface,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: KolabingSpacing.xs),

            // Description
            Text(
              opportunity.description,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: context.colors.onSurfaceVariant,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: KolabingSpacing.sm),

            // Category chips
            if (opportunity.categories.isNotEmpty) ...[
              _buildCategoryChips(context, isDark),
              const SizedBox(height: KolabingSpacing.sm),
            ],

            // Info tags row (city, venue mode, dates)
            _buildInfoTags(context, isDark),
            const SizedBox(height: KolabingSpacing.sm),

            // Offer summary
            if (opportunity.businessOffer.hasAnyOffer) ...[
              _buildOfferSummary(context),
              const SizedBox(height: KolabingSpacing.sm),
            ],

            // Action buttons
            _buildActionButtons(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) => Row(
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
              style: KolabingTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? context.colors.textOnDark
                    : context.colors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              opportunity.creatorProfile?.userType ?? '',
              style: KolabingTextStyles.captionSecondary.copyWith(
                color: isDark
                    ? context.colors.textOnDark.withValues(alpha: 0.5)
                    : context.colors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),

      // Status badge
      _StatusBadge(status: opportunity.status),

      // Optional bookmark toggle (Saved tab) — kept beside the badge so it
      // never overlaps it.
      if (onToggleSave != null) ...[
        const SizedBox(width: KolabingSpacing.xxs),
        GestureDetector(
          onTap: onToggleSave,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              size: 22,
              color: isSaved
                  ? context.colors.primary
                  : context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ],
  );

  Widget _buildCategoryChips(BuildContext context, bool isDark) => Wrap(
    spacing: KolabingSpacing.xxs,
    runSpacing: KolabingSpacing.xxs,
    children: opportunity.categories
        .take(3)
        .map(
          (cat) => Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KolabingSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              borderRadius: KolabingRadius.borderRadiusRound,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CategoryIcon(name: cat, size: 14),
                const SizedBox(width: 4),
                Text(
                  cat,
                  style: KolabingTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? context.colors.textOnDark
                        : context.colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(),
  );

  Widget _buildInfoTags(BuildContext context, bool isDark) {
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
          label: opportunity.venueMode.label(AppLocalizations.of(context)),
          isDark: isDark,
        ),
        _TagPill(icon: LucideIcons.calendar, label: dateText, isDark: isDark),
        _TagPill(
          icon: LucideIcons.clock,
          label: opportunity.availabilityMode.displayName,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildOfferSummary(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: KolabingSpacing.sm,
      vertical: KolabingSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: context.colors.success.withValues(alpha: 0.1),
      borderRadius: KolabingRadius.borderRadiusSm,
      border: Border.all(color: context.colors.success.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.gift, size: 14, color: context.colors.activeText),
        const SizedBox(width: KolabingSpacing.xxs),
        Flexible(
          child: Text(
            opportunity.offerSummary,
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.colors.activeText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  Widget _buildActionButtons(BuildContext context, bool isDark) => Row(
    children: [
      Expanded(
        child: KolabingButton(
          label: 'View',
          onPressed: onView,
          variant: KolabingButtonVariant.secondary,
          size: KolabingButtonSize.compact,
          icon: const Icon(LucideIcons.eye),
        ),
      ),
      const SizedBox(width: KolabingSpacing.sm),
      Expanded(
        child: KolabingButton(
          label: 'Apply',
          onPressed: onApply,
          variant: KolabingButtonVariant.primary,
          size: KolabingButtonSize.compact,
          icon: const Icon(LucideIcons.send),
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
      color: context.colors.primary.withValues(alpha: 0.15),
      shape: BoxShape.circle,
      border: Border.all(
        color: context.colors.primary.withValues(alpha: 0.3),
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
              errorBuilder: (context, error, stackTrace) =>
                  _buildInitial(context),
            ),
          )
        : _buildInitial(context),
  );

  Widget _buildInitial(BuildContext context) => Center(
    child: Text(
      initial,
      style: KolabingTextStyles.bodyLarge.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: isDark ? context.colors.textOnDark : context.colors.onSurface,
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
        status.displayName,
        style: KolabingTextStyles.labelSmall.copyWith(
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
    padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.xs),
    decoration: BoxDecoration(
      color: isDark ? context.colors.darkBorder : context.colors.surfaceVariant,
      borderRadius: KolabingRadius.borderRadiusRound,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: isDark
              ? context.colors.textOnDark.withValues(alpha: 0.5)
              : context.colors.textTertiary,
        ),
        const SizedBox(width: KolabingSpacing.xxs),
        Text(
          label,
          style: KolabingTextStyles.bodySmall.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
