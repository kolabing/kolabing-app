import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../opportunity/models/opportunity.dart';

/// Card widget for My Opportunities list
///
/// Shows status badge, title, dates, applications count,
/// and contextual action buttons based on status.
class MyOpportunityCard extends StatelessWidget {
  const MyOpportunityCard({
    required this.opportunity,
    super.key,
    this.onEdit,
    this.onPublish,
    this.onClose,
    this.onDelete,
  });

  final Opportunity opportunity;
  final VoidCallback? onEdit;
  final VoidCallback? onPublish;
  final VoidCallback? onClose;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => DecoratedBox(
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
                        const Icon(LucideIcons.users, size: 14, color: KolabingColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          '${opportunity.applicationsCount} app${opportunity.applicationsCount == 1 ? '' : 's'}',
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: KolabingColors.textTertiary,
                          ),
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
                    : 'Untitled Opportunity',
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: KolabingColors.textPrimary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: KolabingSpacing.xs),

              // Date range and categories
              _buildInfoRow(),
              const SizedBox(height: KolabingSpacing.sm),

              // Action buttons
              _buildActions(),
            ],
          ),
        ),
      );

  Widget _buildInfoRow() {
    final dateFormat = DateFormat('MMM d');
    final dateText =
        '${dateFormat.format(opportunity.availabilityStart)} - ${dateFormat.format(opportunity.availabilityEnd)}';
    final categoriesText = opportunity.categories.take(2).join(', ');

    return Wrap(
      spacing: KolabingSpacing.xs,
      runSpacing: KolabingSpacing.xs,
      children: [
        _InfoPill(
          icon: LucideIcons.calendar,
          label: dateText,
        ),
        if (opportunity.preferredCity.isNotEmpty)
          _InfoPill(
            icon: LucideIcons.mapPin,
            label: opportunity.preferredCity,
          ),
        if (categoriesText.isNotEmpty)
          _InfoPill(
            icon: LucideIcons.tag,
            label: categoriesText,
          ),
      ],
    );
  }

  Widget _buildActions() {
    final status = opportunity.status;
    final actions = <Widget>[];

    // Edit button (draft or published)
    if (status.canEdit && onEdit != null) {
      actions.add(
        _ActionButton(
          label: 'Edit',
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
          label: 'Publish',
          icon: LucideIcons.upload,
          onTap: onPublish!,
          primary: true,
        ),
      );
    }

    // Close button (published only)
    if (status.canClose && onClose != null) {
      actions.add(
        _ActionButton(
          label: 'Close',
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
          label: 'Delete',
          icon: LucideIcons.trash2,
          onTap: onDelete!,
          danger: true,
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      children: actions
          .expand((w) => [Expanded(child: w), const SizedBox(width: KolabingSpacing.xs)])
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
      OpportunityStatus.draft =>
        (KolabingColors.pendingBg, KolabingColors.pendingText),
      OpportunityStatus.published =>
        (KolabingColors.activeBg, KolabingColors.activeText),
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

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
  });

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
              style: GoogleFonts.openSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: KolabingColors.textSecondary,
              ),
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
    if (primary) {
      return SizedBox(
        height: 36,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 14),
          label: Text(
            label.toUpperCase(),
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: KolabingColors.primary,
            foregroundColor: KolabingColors.onPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.sm),
            shape: RoundedRectangleBorder(
              borderRadius: KolabingRadius.borderRadiusSm,
            ),
          ),
        ),
      );
    }

    final color = danger ? KolabingColors.error : KolabingColors.textPrimary;

    return SizedBox(
      height: 36,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        label: Text(
          label.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(
            color: danger
                ? KolabingColors.error.withValues(alpha: 0.5)
                : KolabingColors.border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: KolabingRadius.borderRadiusSm,
          ),
        ),
      ),
    );
  }
}
