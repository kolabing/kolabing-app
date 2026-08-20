// lib/features/kolab/widgets/my_kolab_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/category_chip.dart';
import '../../../widgets/kolab_card_shell.dart';
import '../../../widgets/kolab_chip.dart';
import '../../../widgets/kolab_status_badge.dart';
import '../../../widgets/kolabing_button.dart';
import '../../../widgets/kolabing_card_action_bar.dart';
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
    final cleaned = kolab.title.replaceAll(RegExp('^[^A-Za-z0-9]+'), '').trim();
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

  /// Community-type labels are a taxonomy, so they render as [CategoryChip]s.
  /// Venue/product names are plain metadata and keep the neutral [KolabChip].
  List<String> get _communityTypeLabels =>
      kolab.intentType == IntentType.communitySeeking
      ? kolab.communityTypeLabels.take(2).toList()
      : const <String>[];

  String get _secondaryLabel {
    if (kolab.intentType == IntentType.communitySeeking) {
      return '';
    }
    if (kolab.intentType == IntentType.venuePromotion) {
      return kolab.venueName ?? '';
    }
    return kolab.productName ?? '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actionRow = _buildActionRow(context);

    return KolabCardShell(
      imageUrl: _resolveImageUrl(ref),
      initials: _initials,
      primaryAction: actionRow,
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
              ..._communityTypeLabels.map((c) => CategoryChip(label: c)),
              if (_secondaryLabel.isNotEmpty)
                KolabChip(
                  label: _secondaryLabel,
                  variant: KolabChipVariant.neutral,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Published kolabs use the canonical VIEW + edit/share/close action bar
  /// (per the Bolder spec). Draft/other statuses keep their existing
  /// primary-action + icon-pill combinations (publish/delete), now rendered
  /// with the same unified pill family instead of floating circles.
  Widget? _buildActionRow(BuildContext context) {
    if (kolab.status == 'published') {
      if (onView == null &&
          !(kolab.canEdit && onEdit != null) &&
          onShare == null &&
          !(kolab.canClose && onClose != null)) {
        return null;
      }
      return KolabingCardActionBar(
        onView: onView,
        onEdit: kolab.canEdit ? onEdit : null,
        onShare: onShare,
        onClose: kolab.canClose ? onClose : null,
      );
    }

    _ActionSpec? primary;
    final secondaryIcons = <(IconData, String, VoidCallback?)>[];

    if (kolab.canEdit && onEdit != null) {
      primary = _ActionSpec(
        label: 'EDIT',
        icon: LucideIcons.edit,
        onPressed: onEdit,
        isPrimary: true,
      );
      if (kolab.canPublish && onPublish != null) {
        secondaryIcons.add((LucideIcons.upload, 'Publish', onPublish));
      }
    } else if (kolab.canPublish && onPublish != null) {
      primary = _ActionSpec(
        label: 'PUBLISH',
        icon: LucideIcons.upload,
        onPressed: onPublish,
        isPrimary: true,
      );
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
        secondaryIcons.add((LucideIcons.trash2, 'Delete', onDelete));
      }
    }

    if (primary == null && secondaryIcons.isEmpty) return null;

    return SizedBox(
      height: 52,
      child: Row(
        children: [
          if (primary != null)
            Expanded(flex: 21, child: _PrimaryActionButton(spec: primary)),
          for (final (icon, label, onTap) in secondaryIcons) ...[
            const SizedBox(width: 10),
            Expanded(
              flex: 13,
              child: KolabingIconPillButton(
                icon: icon,
                onTap: onTap,
                semanticLabel: label,
              ),
            ),
          ],
        ],
      ),
    );
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

    if (isDestructive) {
      // Destructive variant — glass-style: error-tinted fill, pill radius,
      // token colors (no hardcoded values).
      final c = context.colors;
      return GestureDetector(
        onTap: spec.onPressed,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: c.glassDestructiveInk.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(KolabingRadius.pill),
            border: Border.all(
              color: c.glassDestructiveInk.withValues(alpha: 0.30),
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(spec.icon, size: 17, color: c.glassDestructiveInk),
              const SizedBox(width: 7),
              Text(
                spec.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KolabingTextStyles.buttonLabelMd.copyWith(
                  color: c.glassDestructiveInk,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Primary variant — canonical yellow pill CTA.
    return KolabingButton(
      label: spec.label,
      onPressed: spec.onPressed,
      variant: KolabingButtonVariant.primary,
      size: KolabingButtonSize.compact,
      height: 52,
      icon: Icon(spec.icon, size: 16),
    );
  }
}
