// lib/features/kolab/widgets/my_kolab_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/glass_button.dart';
import '../../../widgets/glass_icon_button.dart';
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(color: context.colors.hairline),
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
                    kolab.title.isNotEmpty
                        ? kolab.title
                        : l10n.myKolabCardUntitled,
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.colors.onSurface,
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
  }

  Widget _buildActions() {
    Widget? pill;
    final iconBtns = <Widget>[];

    if (kolab.status == 'published') {
      if (onView != null) {
        pill = GlassButton(
          label: 'view',
          onPressed: onView,
          intent: GlassButtonIntent.primary,
          icon: LucideIcons.eye,
        );
      }
      if (kolab.canEdit && onEdit != null) {
        iconBtns.add(GlassIconButton(
          icon: LucideIcons.edit,
          onPressed: onEdit,
          tooltip: 'Edit',
        ));
      }
      if (kolab.canClose && onClose != null) {
        iconBtns.add(GlassIconButton(
          icon: LucideIcons.xCircle,
          onPressed: onClose,
          tooltip: 'Close',
        ));
      }
    } else if (kolab.canEdit) {
      if (onEdit != null) {
        pill = GlassButton(
          label: 'edit',
          onPressed: onEdit,
          intent: GlassButtonIntent.primary,
          icon: LucideIcons.edit,
        );
      }
      if (kolab.canPublish && onPublish != null) {
        iconBtns.add(GlassIconButton(
          icon: LucideIcons.upload,
          onPressed: onPublish,
          tooltip: 'Publish',
        ));
      }
    } else if (kolab.canPublish) {
      if (onPublish != null) {
        pill = GlassButton(
          label: 'publish',
          onPressed: onPublish,
          intent: GlassButtonIntent.primary,
          icon: LucideIcons.upload,
        );
      }
    }

    if (kolab.canDelete && onDelete != null) {
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
