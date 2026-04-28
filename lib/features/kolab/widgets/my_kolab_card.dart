import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../enums/intent_type.dart';
import '../models/kolab.dart';
import '../providers/my_kolabs_provider.dart';

class MyKolabCard extends StatelessWidget {
  const MyKolabCard({
    required this.kolab,
    super.key,
    this.onEdit,
    this.onPublish,
    this.onClose,
    this.onDelete,
  });

  final Kolab kolab;
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
          Row(
            children: [
              _StatusBadge(status: kolab.status),
              const Spacer(),
              _InfoPill(icon: kolab.intentType.icon, label: kolab.typeLabel),
            ],
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            kolab.title.isNotEmpty ? kolab.title : 'Untitled Kolab',
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
          Wrap(
            spacing: KolabingSpacing.xs,
            runSpacing: KolabingSpacing.xs,
            children: [
              if (kolab.preferredCity.isNotEmpty)
                _InfoPill(icon: LucideIcons.mapPin, label: kolab.preferredCity),
              if (_availabilityLabel.isNotEmpty)
                _InfoPill(
                  icon: LucideIcons.calendar,
                  label: _availabilityLabel,
                ),
              if (_secondaryLabel.isNotEmpty)
                _InfoPill(icon: LucideIcons.tag, label: _secondaryLabel),
            ],
          ),
          const SizedBox(height: KolabingSpacing.sm),
          _buildActions(),
        ],
      ),
    ),
  );

  String get _availabilityLabel {
    final start = kolab.availabilityStart;
    final end = kolab.availabilityEnd;
    if (start == null) {
      return '';
    }

    final formatter = DateFormat('MMM d');
    if (end != null) {
      return '${formatter.format(start)} - ${formatter.format(end)}';
    }
    return formatter.format(start);
  }

  String get _secondaryLabel {
    if (kolab.intentType == IntentType.communitySeeking) {
      final types = kolab.communityTypes.take(2).join(', ');
      return types;
    }

    if (kolab.intentType == IntentType.venuePromotion) {
      return kolab.venueName ?? '';
    }

    return kolab.productName ?? '';
  }

  Widget _buildActions() {
    final actions = <Widget>[];

    if (kolab.canEdit && onEdit != null) {
      actions.add(
        _ActionButton(
          label: 'Edit',
          icon: LucideIcons.edit,
          onTap: onEdit!,
          outlined: true,
        ),
      );
    }

    if (kolab.canPublish && onPublish != null) {
      actions.add(
        _ActionButton(
          label: 'Publish',
          icon: LucideIcons.upload,
          onTap: onPublish!,
          primary: true,
        ),
      );
    }

    if (kolab.canClose && onClose != null) {
      actions.add(
        _ActionButton(
          label: 'Close',
          icon: LucideIcons.xCircle,
          onTap: onClose!,
          outlined: true,
        ),
      );
    }

    if (kolab.canDelete && onDelete != null) {
      actions.add(
        _ActionButton(
          label: 'Delete',
          icon: LucideIcons.trash2,
          onTap: onDelete!,
          danger: true,
        ),
      );
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children:
          actions
              .expand(
                (widget) => [
                  Expanded(child: widget),
                  const SizedBox(width: KolabingSpacing.xs),
                ],
              )
              .toList()
            ..removeLast(),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, textColor, label) = switch (status) {
      'published' => (
        KolabingColors.activeBg,
        KolabingColors.activeText,
        'PUBLISHED',
      ),
      'closed' => (
        KolabingColors.completedBg,
        KolabingColors.completedText,
        'CLOSED',
      ),
      'completed' => (
        KolabingColors.completedBg,
        KolabingColors.completedText,
        'COMPLETED',
      ),
      _ => (KolabingColors.pendingBg, KolabingColors.pendingText, 'DRAFT'),
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
        label,
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
        icon: Icon(icon, size: 14, color: color),
        label: Text(
          label.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: color,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: danger ? KolabingColors.errorBg : KolabingColors.border,
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
