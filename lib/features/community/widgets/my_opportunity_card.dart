// lib/features/community/widgets/my_opportunity_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
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
    final actions = <Widget>[];

    if (status == OpportunityStatus.published && onView != null) {
      actions.add(
        _ActionBtn(label: 'VIEW', icon: LucideIcons.eye, onTap: onView!, primary: true),
      );
    }
    if (status.canEdit && onEdit != null) {
      actions.add(
        _ActionBtn(label: 'EDIT', icon: LucideIcons.edit, onTap: onEdit!, outlined: true),
      );
    }
    if (status.canPublish && onPublish != null) {
      actions.add(
        _ActionBtn(label: 'PUBLISH', icon: LucideIcons.upload, onTap: onPublish!, primary: true),
      );
    }
    if (status == OpportunityStatus.published && onShare != null) {
      actions.add(
        _ActionBtn(label: 'SHARE', icon: LucideIcons.share2, onTap: onShare!, outlined: true),
      );
    }
    if (status.canClose && onClose != null) {
      actions.add(
        _ActionBtn(label: 'CLOSE', icon: LucideIcons.xCircle, onTap: onClose!, outlined: true),
      );
    }
    if (status.canDelete &&
        (opportunity.applicationsCount ?? 0) == 0 &&
        onDelete != null) {
      actions.add(
        _ActionBtn(label: 'DELETE', icon: LucideIcons.trash2, onTap: onDelete!, danger: true),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      children: actions
          .expand(
            (w) => [
              Expanded(child: w),
              const SizedBox(width: KolabingSpacing.xs),
            ],
          )
          .toList()
        ..removeLast(),
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

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
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
    final fgColor = primary
        ? KolabingColors.onYellowButton
        : danger
        ? KolabingColors.error
        : KolabingColors.onSurface;

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 13, color: fgColor),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: KolabingTextStyles.labelSmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fgColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );

    if (primary) {
      return SizedBox(
        height: 36,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: KolabingColors.primary,
            foregroundColor: KolabingColors.onYellowButton,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.xs),
            shape: RoundedRectangleBorder(
              borderRadius: KolabingRadius.borderRadiusSm,
            ),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: danger ? KolabingColors.errorBg : KolabingColors.hairline,
          ),
          foregroundColor: fgColor,
          padding: const EdgeInsets.symmetric(horizontal: KolabingSpacing.xs),
          shape: RoundedRectangleBorder(
            borderRadius: KolabingRadius.borderRadiusSm,
          ),
        ),
        child: child,
      ),
    );
  }
}
