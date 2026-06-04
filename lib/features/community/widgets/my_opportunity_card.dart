// lib/features/community/widgets/my_opportunity_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../widgets/glass_button.dart';
import '../../../widgets/glass_icon_button.dart';
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
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: KolabingRadius.borderRadiusLg,
      border: Border.all(color: KolabingColors.hairline),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
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
                          const Icon(
                            LucideIcons.users,
                            size: 12,
                            color: KolabingColors.textTertiary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${opportunity.applicationsCount} app${opportunity.applicationsCount == 1 ? '' : 's'}',
                            style: KolabingTextStyles.labelSmall.copyWith(
                              color: KolabingColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  opportunity.title.isNotEmpty
                      ? opportunity.title
                      : 'Untitled Opportunity',
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: KolabingColors.onSurface,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: KolabingSpacing.xs,
                  runSpacing: KolabingSpacing.xs,
                  children: [
                    KolabChip(
                      label: _dateLabel,
                      variant: KolabChipVariant.sage,
                      icon: LucideIcons.calendar,
                    ),
                    if (opportunity.preferredCity.isNotEmpty)
                      KolabChip(
                        label: opportunity.preferredCity,
                        variant: KolabChipVariant.amber,
                        icon: LucideIcons.mapPin,
                      ),
                    ...opportunity.categories.take(2).map(
                      (c) => KolabChip(
                        label: c,
                        variant: kolabChipVariantFor(c),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildActions(),
              ],
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          _KolabSquareImage(imageUrl: _imageUrl, initials: _initials),
        ],
      ),
    ),
  );

  Widget _buildActions() {
    final status = opportunity.status;
    Widget? pill;
    final iconBtns = <Widget>[];

    if (status == OpportunityStatus.published) {
      if (onView != null) {
        pill = GlassButton(
          label: 'view',
          onPressed: onView,
          intent: GlassButtonIntent.primary,
          icon: LucideIcons.eye,
        );
      }
      if (status.canEdit && onEdit != null) {
        iconBtns.add(GlassIconButton(
          icon: LucideIcons.edit,
          onPressed: onEdit,
          tooltip: 'Edit',
        ));
      }
      if (onShare != null) {
        iconBtns.add(GlassIconButton(
          icon: LucideIcons.share2,
          onPressed: onShare,
          tooltip: 'Share',
        ));
      }
      if (status.canClose && onClose != null) {
        iconBtns.add(GlassIconButton(
          icon: LucideIcons.xCircle,
          onPressed: onClose,
          tooltip: 'Close',
        ));
      }
    } else if (status.canEdit) {
      if (onEdit != null) {
        pill = GlassButton(
          label: 'edit',
          onPressed: onEdit,
          intent: GlassButtonIntent.primary,
          icon: LucideIcons.edit,
        );
      }
      if (status.canPublish && onPublish != null) {
        iconBtns.add(GlassIconButton(
          icon: LucideIcons.upload,
          onPressed: onPublish,
          tooltip: 'Publish',
        ));
      }
    } else if (status.canPublish) {
      if (onPublish != null) {
        pill = GlassButton(
          label: 'publish',
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
          label: 'delete',
          onPressed: onDelete,
          intent: GlassButtonIntent.destructive,
          icon: LucideIcons.trash2,
        );
      } else {
        iconBtns.add(GlassIconButton(
          icon: LucideIcons.trash2,
          onPressed: onDelete,
          tooltip: 'Delete',
        ));
      }
    }

    if (pill == null && iconBtns.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        if (pill != null) Expanded(child: pill),
        ...iconBtns.expand((btn) => [
          const SizedBox(width: 9),
          btn,
        ]),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _KolabSquareImage extends StatelessWidget {
  const _KolabSquareImage({required this.initials, this.imageUrl});

  final String? imageUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    const size = 68.0;
    const radius = 14.0;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(size, radius),
        ),
      );
    }
    return _placeholder(size, radius);
  }

  Widget _placeholder(double size, double radius) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF4C2), Color(0xFFFFE28C)],
      ),
    ),
    alignment: Alignment.center,
    child: Text(
      initials,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Color(0xFF5C4A12),
      ),
    ),
  );
}
