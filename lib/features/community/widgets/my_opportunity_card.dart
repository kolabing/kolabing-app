import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../opportunity/models/opportunity.dart';

/// Card widget for My Opportunities list
///
/// Shows status badge, title, dates, applications count,
/// and contextual action buttons based on status.
class MyOpportunityCard extends StatelessWidget {
  const MyOpportunityCard({
    required this.opportunity,
    super.key,
    this.onView,
    this.onEdit,
    this.onPublish,
    this.onShare,
    this.onClose,
    this.onDelete,
  });

  final Opportunity opportunity;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onPublish;
  final VoidCallback? onShare;
  final VoidCallback? onClose;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
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
    child: Padding(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge and applications count
          Row(
            children: [
              _StatusBadge(status: opportunity.status),
              const Spacer(),
              if (opportunity.applicationsCount != null &&
                  opportunity.applicationsCount! > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.users,
                      size: 14,
                      color: KolabingColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.myOpportunityCardApplicationsCount(
                        opportunity.applicationsCount!,
                      ),
                      style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: KolabingColors.textTertiary),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: KolabingSpacing.sm),

          // Title
          Text(
            opportunity.title.isNotEmpty
                ? opportunity.title
                : l10n.myOpportunityCardUntitled,
            style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: KolabingColors.onSurface, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: KolabingSpacing.xs),

          // Date range and categories
          _buildInfoRow(),
          const SizedBox(height: KolabingSpacing.sm),

          // Action buttons
          _buildActions(l10n),
        ],
      ),
    ),
  );
  }

  Widget _buildInfoRow() {
    final dateFormat = DateFormat('MMM d');
    final dateText =
        '${dateFormat.format(opportunity.availabilityStart)} - ${dateFormat.format(opportunity.availabilityEnd)}';
    final categoriesText = opportunity.categories.take(2).join(', ');

    return Wrap(
      spacing: KolabingSpacing.xs,
      runSpacing: KolabingSpacing.xs,
      children: [
        _InfoPill(icon: LucideIcons.calendar, label: dateText),
        if (opportunity.preferredCity.isNotEmpty)
          _InfoPill(icon: LucideIcons.mapPin, label: opportunity.preferredCity),
        if (categoriesText.isNotEmpty)
          _InfoPill(icon: LucideIcons.tag, label: categoriesText),
      ],
    );
  }

  Widget _buildActions(AppLocalizations l10n) {
    final status = opportunity.status;
    final actions = <Widget>[];

    if (status == OpportunityStatus.published && onView != null) {
      actions.add(
        _ActionButton(
          label: l10n.myOpportunityCardActionView,
          icon: LucideIcons.eye,
          onTap: onView!,
          primary: true,
        ),
      );
    }

    // Edit button (draft or published)
    if (status.canEdit && onEdit != null) {
      actions.add(
        _ActionButton(
          label: l10n.myOpportunityCardActionEdit,
          icon: LucideIcons.edit,
          onTap: onEdit!,
          outlined: true,
        ),
      );
    }

    // Publish button (draft only)
    if (status.canPublish && onPublish != null) {
      actions.add(
        _ActionButton(
          label: l10n.myOpportunityCardActionPublish,
          icon: LucideIcons.upload,
          onTap: onPublish!,
          primary: true,
        ),
      );
    }

    if (status == OpportunityStatus.published && onShare != null) {
      actions.add(
        _ActionButton(
          label: l10n.myOpportunityCardActionShare,
          icon: LucideIcons.share2,
          onTap: onShare!,
          outlined: true,
        ),
      );
    }

    // Close button (published only)
    if (status.canClose && onClose != null) {
      actions.add(
        _ActionButton(
          label: l10n.myOpportunityCardActionClose,
          icon: LucideIcons.xCircle,
          onTap: onClose!,
          outlined: true,
        ),
      );
    }

    // Delete button (draft with no applications)
    if (status.canDelete &&
        (opportunity.applicationsCount ?? 0) == 0 &&
        onDelete != null) {
      actions.add(
        _ActionButton(
          label: l10n.myOpportunityCardActionDelete,
          icon: LucideIcons.trash2,
          onTap: onDelete!,
          danger: true,
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      children:
          actions
              .expand(
                (w) => [
                  Expanded(child: w),
                  const SizedBox(width: KolabingSpacing.xs),
                ],
              )
              .toList()
            ..removeLast(), // Remove trailing spacer
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final OpportunityStatus status;

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, textColor) = switch (status) {
      OpportunityStatus.draft => (
        KolabingColors.pendingBg,
        KolabingColors.pendingText,
      ),
      OpportunityStatus.published => (
        KolabingColors.activeBg,
        KolabingColors.activeText,
      ),
      OpportunityStatus.closed => (
        KolabingColors.completedBg,
        KolabingColors.completedText,
      ),
      OpportunityStatus.completed => (
        KolabingColors.completedBg,
        KolabingColors.completedText,
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
        style: KolabingTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700, color: textColor, letterSpacing: 0.5),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 26,
    padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.xs),
    decoration: BoxDecoration(
      color: KolabingColors.surfaceVariant,
      borderRadius: KolabingRadius.borderRadiusRound,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: KolabingColors.textTertiary),
        const SizedBox(width: KolabingSpacing.xxs),
        Text(
          label,
          style: KolabingTextStyles.labelSmall.copyWith(color: KolabingColors.onSurfaceVariant),
        ),
      ],
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
    this.outlined = false,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  final bool outlined;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = primary
        ? KolabingColors.onPrimary
        : danger
        ? KolabingColors.error
        : KolabingColors.onSurface;

    if (primary) {
      return SizedBox(
        height: 36,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: KolabingColors.primary,
            foregroundColor: KolabingColors.onPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.xs),
            shape: RoundedRectangleBorder(
              borderRadius: KolabingRadius.borderRadiusSm,
            ),
          ),
          child: _ActionButtonContent(
            icon: icon,
            label: label,
            color: foregroundColor,
          ),
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor,
          side: BorderSide(
            color: danger
                ? KolabingColors.error.withValues(alpha: 0.5)
                : KolabingColors.darkBorder,
          ),
          padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.xs),
          shape: RoundedRectangleBorder(
            borderRadius: KolabingRadius.borderRadiusSm,
          ),
        ),
        child: _ActionButtonContent(
          icon: icon,
          label: label,
          color: foregroundColor,
        ),
      ),
    );
  }
}

class _ActionButtonContent extends StatelessWidget {
  const _ActionButtonContent({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: KolabingSpacing.xxs),
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
            style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: color, letterSpacing: 1.0),
          ),
        ),
      ),
    ],
  );
}
