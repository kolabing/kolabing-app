// lib/features/kolab/widgets/my_kolab_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../widgets/kolab_chip.dart';
import '../../../widgets/kolab_status_badge.dart';
import '../enums/intent_type.dart';
import '../models/kolab.dart';
import '../providers/my_kolabs_provider.dart';

class MyKolabCard extends StatelessWidget {
  const MyKolabCard({
    required this.kolab,
    super.key,
    this.onView,
    this.onEdit,
    this.onPublish,
    this.onClose,
    this.onDelete,
  });

  final Kolab kolab;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onPublish;
  final VoidCallback? onClose;
  final VoidCallback? onDelete;

  String? get _imageUrl =>
      kolab.media.isNotEmpty ? kolab.media.first.url : null;

  String get _initials {
    final t = kolab.title.trim();
    return t.isNotEmpty ? t[0].toUpperCase() : 'K';
  }

  String get _availabilityLabel {
    final start = kolab.availabilityStart;
    final end = kolab.availabilityEnd;
    if (start == null) return '';
    final fmt = DateFormat('MMM d');
    return end != null
        ? '${fmt.format(start)} – ${fmt.format(end)}'
        : fmt.format(start);
  }

  String get _secondaryLabel {
    if (kolab.intentType == IntentType.communitySeeking) {
      return kolab.communityTypeLabels.take(2).join(', ');
    }
    if (kolab.intentType == IntentType.venuePromotion) {
      return kolab.venueName ?? '';
    }
    return kolab.productName ?? '';
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
                KolabStatusBadge(status: kolab.status),
                const SizedBox(height: 6),
                Text(
                  kolab.title.isNotEmpty ? kolab.title : 'Untitled Kolab',
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
                    if (kolab.preferredCity.isNotEmpty)
                      KolabChip(
                        label: kolab.preferredCity,
                        variant: KolabChipVariant.amber,
                        icon: LucideIcons.mapPin,
                      ),
                    if (_availabilityLabel.isNotEmpty)
                      KolabChip(
                        label: _availabilityLabel,
                        variant: KolabChipVariant.sage,
                        icon: LucideIcons.calendar,
                      ),
                    if (_secondaryLabel.isNotEmpty)
                      KolabChip(
                        label: _secondaryLabel,
                        variant: KolabChipVariant.lavender,
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
    final actions = <Widget>[];

    if (kolab.status == 'published' && onView != null) {
      actions.add(
        _ActionBtn(
          label: 'VIEW',
          icon: LucideIcons.eye,
          onTap: onView!,
          primary: true,
        ),
      );
    }
    if (kolab.canEdit && onEdit != null) {
      actions.add(
        _ActionBtn(
          label: 'EDIT',
          icon: LucideIcons.edit,
          onTap: onEdit!,
          outlined: true,
        ),
      );
    }
    if (kolab.canPublish && onPublish != null) {
      actions.add(
        _ActionBtn(
          label: 'PUBLISH',
          icon: LucideIcons.upload,
          onTap: onPublish!,
          primary: true,
        ),
      );
    }
    if (kolab.canClose && onClose != null) {
      actions.add(
        _ActionBtn(
          label: 'CLOSE',
          icon: LucideIcons.xCircle,
          onTap: onClose!,
          outlined: true,
        ),
      );
    }
    if (kolab.canDelete && onDelete != null) {
      actions.add(
        _ActionBtn(
          label: 'DELETE',
          icon: LucideIcons.trash2,
          onTap: onDelete!,
          danger: true,
        ),
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
