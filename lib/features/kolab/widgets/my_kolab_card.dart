// lib/features/kolab/widgets/my_kolab_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/glass_icon_button.dart';
import '../../../widgets/kolab_card_shell.dart';
import '../../../widgets/kolab_chip.dart';
import '../../../widgets/kolab_status_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../enums/intent_type.dart';
import '../models/kolab.dart';
import '../providers/my_kolabs_provider.dart';

class MyKolabCard extends ConsumerWidget {
  const MyKolabCard({
    required this.kolab,
    super.key,
    this.onView,
    this.onEdit,
    this.onPublish,
    this.onClose,
    this.onDelete,
    this.onShare,
  });

  final Kolab kolab;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onPublish;
  final VoidCallback? onClose;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;

  /// Thumbnail priority for a kolab/offer card:
  /// 1. the photo posted for the kolab itself,
  /// 2. else the owner's profile photo (these are the user's own offers, so
  ///    there is no counterpart to show yet — fall back to their brand),
  /// 3. else the first photo from the owner's gallery.
  /// Falls through to the initials placeholder only when none exist.
  String? _resolveImageUrl(WidgetRef ref) {
    final offer = kolab.offerPhoto;
    if (offer != null && offer.isNotEmpty) return offer;
    if (kolab.media.isNotEmpty) return kolab.media.first.url;

    final user = ref.watch(authProvider).user;
    final ownerPhoto = user?.profilePhotoUrl;
    if (ownerPhoto != null && ownerPhoto.isNotEmpty) return ownerPhoto;

    final gallery = user?.businessProfile?.primaryVenue?.photos ?? const [];
    if (gallery.isNotEmpty) return gallery.first;

    return null;
  }

  String get _initials {
    // Strip leading non-letters so "[TEST] ..." yields "T", not "[".
    final cleaned = kolab.title.replaceAll(RegExp(r'^[^A-Za-z0-9]+'), '').trim();
    return cleaned.isNotEmpty ? cleaned[0].toUpperCase() : 'K';
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final (primaryAction, secondaryActions) = _buildActions(context);

    return KolabCardShell(
      imageUrl: _resolveImageUrl(ref),
      initials: _initials,
      primaryAction: primaryAction,
      secondaryActions: secondaryActions,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KolabStatusBadge(status: kolab.status),
          const SizedBox(height: 7),
          Text(
            kolab.title.isNotEmpty ? kolab.title : l10n.myKolabCardUntitled,
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
        ],
      ),
    );
  }

  (Widget?, List<Widget>) _buildActions(BuildContext context) {
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
        secondaryIcons.add(
          GlassIconButton(
            icon: LucideIcons.edit,
            onPressed: onEdit,
            tooltip: 'Edit',
            size: 48,
          ),
        );
      }
      if (onShare != null) {
        secondaryIcons.add(
          GlassIconButton(
            icon: LucideIcons.share2,
            onPressed: onShare,
            tooltip: 'Share',
            size: 48,
          ),
        );
      }
      if (kolab.canClose && onClose != null) {
        secondaryIcons.add(
          GlassIconButton(
            icon: LucideIcons.xCircle,
            onPressed: onClose,
            tooltip: 'Close',
            size: 48,
          ),
        );
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
        secondaryIcons.add(
          GlassIconButton(
            icon: LucideIcons.upload,
            onPressed: onPublish,
            tooltip: 'Publish',
            size: 48,
          ),
        );
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
        secondaryIcons.add(
          GlassIconButton(
            icon: LucideIcons.trash2,
            onPressed: onDelete,
            tooltip: 'Delete',
            size: 48,
          ),
        );
      }
    }

    final primaryWidget = primary != null
        ? _PrimaryActionButton(spec: primary)
        : null;
    return (primaryWidget, secondaryIcons);
  }
}

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
        width: double.infinity,
        height: 48,
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
            Icon(spec.icon, size: 17, color: ink),
            const SizedBox(width: 7),
            Text(
              spec.label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
