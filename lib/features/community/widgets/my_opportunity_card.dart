// lib/features/community/widgets/my_opportunity_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/glass_button.dart';
import '../../../widgets/glass_icon_button.dart';
import '../../../widgets/kolab_card_shell.dart';
import '../../../widgets/kolab_chip.dart';
import '../../../widgets/kolab_status_badge.dart';
import '../../opportunity/models/opportunity.dart';

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

  String? get _imageUrl {
    final p = opportunity.offerPhoto;
    return (p != null && p.isNotEmpty) ? p : null;
  }

  String get _initials {
    final t = opportunity.title.trim();
    return t.isNotEmpty ? t[0].toUpperCase() : 'O';
  }

  String get _dateLabel {
    final fmt = DateFormat('MMM d');
    return '${fmt.format(opportunity.availabilityStart)} – ${fmt.format(opportunity.availabilityEnd)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (primaryAction, secondaryActions) = _buildActions(l10n);

    return KolabCardShell(
      imageUrl: _imageUrl,
      initials: _initials,
      primaryAction: primaryAction,
      secondaryActions: secondaryActions,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              KolabStatusBadge(status: opportunity.status.name),
              if (opportunity.applicationsCount != null &&
                  opportunity.applicationsCount! > 0) ...[
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.users,
                      size: 12,
                      color: context.colors.textTertiary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      l10n.myOpportunityCardApplicationsCount(
                        opportunity.applicationsCount!,
                      ),
                      style: KolabingTextStyles.labelSmall.copyWith(
                        color: context.colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 7),
          Text(
            opportunity.title.isNotEmpty
                ? opportunity.title
                : l10n.myOpportunityCardUntitled,
            style: KolabingTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.onSurface,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: KolabingSpacing.xs,
            runSpacing: KolabingSpacing.xs,
            children: [
              KolabChip(
                label: _dateLabel,
                variant: KolabChipVariant.green,
                icon: LucideIcons.calendar,
              ),
              if (opportunity.preferredCity.isNotEmpty)
                KolabChip(
                  label: opportunity.preferredCity,
                  variant: KolabChipVariant.yellow,
                  icon: LucideIcons.mapPin,
                ),
              ...opportunity.categories
                  .take(2)
                  .map(
                    (c) => KolabChip(label: c, variant: kolabChipVariantFor(c)),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  (Widget?, List<Widget>) _buildActions(AppLocalizations l10n) {
    final status = opportunity.status;
    Widget? pill;
    final iconBtns = <Widget>[];

    if (status == OpportunityStatus.published) {
      if (onView != null) {
        pill = GlassButton(
          label: l10n.myOpportunityCardActionView,
          onPressed: onView,
          intent: GlassButtonIntent.primary,
          icon: LucideIcons.eye,
        );
      }
      if (status.canEdit && onEdit != null) {
        iconBtns.add(
          GlassIconButton(
            icon: LucideIcons.edit,
            onPressed: onEdit,
            tooltip: l10n.myOpportunityCardActionEdit,
            size: 36,
          ),
        );
      }
      if (onShare != null) {
        iconBtns.add(
          GlassIconButton(
            icon: LucideIcons.share2,
            onPressed: onShare,
            tooltip: l10n.myOpportunityCardActionShare,
            size: 36,
          ),
        );
      }
      if (status.canClose && onClose != null) {
        iconBtns.add(
          GlassIconButton(
            icon: LucideIcons.xCircle,
            onPressed: onClose,
            tooltip: l10n.myOpportunityCardActionClose,
            size: 36,
          ),
        );
      }
    } else if (status.canEdit) {
      if (onEdit != null) {
        pill = GlassButton(
          label: l10n.myOpportunityCardActionEdit,
          onPressed: onEdit,
          intent: GlassButtonIntent.primary,
          icon: LucideIcons.edit,
        );
      }
      if (status.canPublish && onPublish != null) {
        iconBtns.add(
          GlassIconButton(
            icon: LucideIcons.upload,
            onPressed: onPublish,
            tooltip: l10n.myOpportunityCardActionPublish,
            size: 36,
          ),
        );
      }
    } else if (status.canPublish) {
      if (onPublish != null) {
        pill = GlassButton(
          label: l10n.myOpportunityCardActionPublish,
          onPressed: onPublish,
          intent: GlassButtonIntent.primary,
          icon: LucideIcons.upload,
        );
      }
    }

    if (status.canDelete &&
        (opportunity.applicationsCount ?? 0) == 0 &&
        onDelete != null) {
      if (pill == null) {
        pill = GlassButton(
          label: l10n.myOpportunityCardActionDelete,
          onPressed: onDelete,
          intent: GlassButtonIntent.destructive,
          icon: LucideIcons.trash2,
        );
      } else {
        iconBtns.add(
          GlassIconButton(
            icon: LucideIcons.trash2,
            onPressed: onDelete,
            tooltip: l10n.myOpportunityCardActionDelete,
            size: 36,
          ),
        );
      }
    }

    final primary = pill != null
        ? SizedBox(width: double.infinity, child: pill)
        : null;
    return (primary, iconBtns);
  }
}
