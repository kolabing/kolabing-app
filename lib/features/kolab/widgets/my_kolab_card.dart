// lib/features/kolab/widgets/my_kolab_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
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
        color: Colors.white,
        borderRadius: KolabingRadius.borderRadiusLg,
        border: Border.all(color: context.colors.hairline, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: KolabingRadius.borderRadiusLg,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left content ──────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KolabStatusBadge(status: kolab.status),
                      const SizedBox(height: 7),
                      Text(
                        kolab.title.isNotEmpty
                            ? kolab.title
                            : l10n.myKolabCardUntitled,
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
                          if (_availabilityLabel.isNotEmpty)
                            KolabChip(
                              label: _availabilityLabel,
                              variant: KolabChipVariant.sage,
                              icon: LucideIcons.calendar,
                            ),
                          if (kolab.preferredCity.isNotEmpty)
                            KolabChip(
                              label: kolab.preferredCity,
                              variant: KolabChipVariant.amber,
                              icon: LucideIcons.mapPin,
                            ),
                          if (_secondaryLabel.isNotEmpty)
                            KolabChip(
                              label: _secondaryLabel,
                              variant: KolabChipVariant.lavender,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildActions(context),
                    ],
                  ),
                ),
              ),
              // ── Right image with fade ─────────────────────────────────────
              _KolabFadeImage(imageUrl: _imageUrl, initials: _initials),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    _ActionSpec? primary;
    final secondaryIcons = <Widget>[];

    if (kolab.status == 'published') {
      if (onView != null) {
        primary = _ActionSpec(
          label: 'VIEW',
          icon: LucideIcons.eye,
          onPressed: onView,
          isPrimary: true,
        );
      }
      if (kolab.canEdit && onEdit != null) {
        secondaryIcons.add(GlassIconButton(
          icon: LucideIcons.edit,
          onPressed: onEdit,
          tooltip: 'Edit',
        ));
      }
      if (kolab.canClose && onClose != null) {
        secondaryIcons.add(GlassIconButton(
          icon: LucideIcons.xCircle,
          onPressed: onClose,
          tooltip: 'Close',
        ));
      }
    } else if (kolab.canEdit) {
      if (onEdit != null) {
        primary = _ActionSpec(
          label: 'EDIT',
          icon: LucideIcons.edit,
          onPressed: onEdit,
          isPrimary: true,
        );
      }
      if (kolab.canPublish && onPublish != null) {
        secondaryIcons.add(GlassIconButton(
          icon: LucideIcons.upload,
          onPressed: onPublish,
          tooltip: 'Publish',
        ));
      }
    } else if (kolab.canPublish) {
      if (onPublish != null) {
        primary = _ActionSpec(
          label: 'PUBLISH',
          icon: LucideIcons.upload,
          onPressed: onPublish,
          isPrimary: true,
        );
      }
    }

    if (kolab.canDelete && onDelete != null) {
      if (primary == null) {
        primary = _ActionSpec(
          label: 'DELETE',
          icon: LucideIcons.trash2,
          onPressed: onDelete,
          isPrimary: false,
        );
      } else {
        secondaryIcons.add(GlassIconButton(
          icon: LucideIcons.trash2,
          onPressed: onDelete,
          tooltip: 'Delete',
        ));
      }
    }

    if (primary == null && secondaryIcons.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        if (primary != null)
          Expanded(
            child: _PrimaryActionButton(spec: primary),
          ),
        if (primary != null && secondaryIcons.isNotEmpty)
          const SizedBox(width: 8),
        ...secondaryIcons.expand((btn) => [btn, const SizedBox(width: 6)]).toList()
          ..removeLast(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting types & private widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ActionSpec {
  const _ActionSpec({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isPrimary,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({required this.spec});
  final _ActionSpec spec;

  @override
  Widget build(BuildContext context) {
    final isDestructive = !spec.isPrimary;
    final bg = isDestructive
        ? context.colors.glassDestructiveInk.withValues(alpha: 0.08)
        : const Color(0xFFFFD861);
    final borderColor = isDestructive
        ? context.colors.glassDestructiveInk.withValues(alpha: 0.30)
        : const Color(0xFFE8C43A);
    final ink = isDestructive
        ? context.colors.glassDestructiveInk
        : const Color(0xFF1A1200);

    return GestureDetector(
      onTap: spec.onPressed,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(spec.icon, size: 16, color: ink),
            const SizedBox(width: 7),
            Text(
              spec.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KolabFadeImage extends StatelessWidget {
  const _KolabFadeImage({required this.initials, this.imageUrl});

  final String? imageUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    const width = 90.0;

    Widget imageWidget;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageWidget = Image.network(
        imageUrl!,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(width),
      );
    } else {
      imageWidget = _placeholder(width);
    }

    return SizedBox(
      width: width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,
          // Left-to-right fade: white → transparent, so content blends in
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: const [0.0, 0.45, 1.0],
                  colors: [
                    Colors.white,
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(double width) => Container(
        width: width,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF9E6), Color(0xFFFFE28C)],
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF5C4A12),
          ),
        ),
      );
}
