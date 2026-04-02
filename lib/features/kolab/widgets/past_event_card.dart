import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../models/kolab.dart';

/// Card for displaying or adding a past event in the Kolab creation flow.
///
/// When [event] is `null`, an "add" card with a dashed border and plus icon is
/// rendered. When an event is provided, it shows the event details with a
/// remove button.
class PastEventCard extends StatelessWidget {
  const PastEventCard({
    required this.onAdd,
    super.key,
    this.event,
    this.onRemove,
  });

  /// The past event data. When `null` the card renders in "add" mode.
  final PastEvent? event;

  /// Called when the add card is tapped.
  final VoidCallback onAdd;

  /// Called when the remove button is tapped on an existing event card.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) =>
      event == null ? _buildAddCard() : _buildEventCard();

  // ---------------------------------------------------------------------------
  // Add mode — dashed border placeholder
  // ---------------------------------------------------------------------------

  Widget _buildAddCard() => GestureDetector(
      onTap: onAdd,
      child: CustomPaint(
        painter: const _DashedBorderPainter(
          color: KolabingColors.border,
          radius: KolabingRadius.md,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: KolabingColors.background,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.plus,
                  size: 20,
                  color: KolabingColors.textTertiary,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              Text(
                'Add a past event',
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: KolabingColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

  // ---------------------------------------------------------------------------
  // Existing event card
  // ---------------------------------------------------------------------------

  Widget _buildEventCard() {
    final e = event!;
    final formattedDate = DateFormat('MMM dd, yyyy').format(e.date);

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
        borderRadius: KolabingRadius.borderRadiusMd,
        border: Border.all(color: KolabingColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event icon
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: KolabingColors.softYellow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.calendar,
              size: 18,
              color: KolabingColors.textPrimary,
            ),
          ),
          const SizedBox(width: KolabingSpacing.sm),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.name,
                  style: GoogleFonts.rubik(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: KolabingSpacing.xxxs),
                Text(
                  formattedDate,
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    color: KolabingColors.textSecondary,
                  ),
                ),
                if (e.partnerName != null && e.partnerName!.isNotEmpty) ...[
                  const SizedBox(height: KolabingSpacing.xxxs),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.users,
                        size: 13,
                        color: KolabingColors.textTertiary,
                      ),
                      const SizedBox(width: KolabingSpacing.xxs),
                      Expanded(
                        child: Text(
                          e.partnerName!,
                          style: GoogleFonts.openSans(
                            fontSize: 13,
                            color: KolabingColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (e.photos.isNotEmpty) ...[
                  const SizedBox(height: KolabingSpacing.xxs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KolabingSpacing.xs,
                      vertical: KolabingSpacing.xxxs,
                    ),
                    decoration: BoxDecoration(
                      color: KolabingColors.background,
                      borderRadius: KolabingRadius.borderRadiusXs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.image,
                          size: 12,
                          color: KolabingColors.textTertiary,
                        ),
                        const SizedBox(width: KolabingSpacing.xxs),
                        Text(
                          '${e.photos.length} photo${e.photos.length == 1 ? '' : 's'}',
                          style: GoogleFonts.openSans(
                            fontSize: 11,
                            color: KolabingColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Remove button
          if (onRemove != null)
            GestureDetector(
              onTap: onRemove,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: KolabingColors.errorBg,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(
                    LucideIcons.x,
                    size: 14,
                    color: KolabingColors.error,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashed border painter
// ---------------------------------------------------------------------------

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  static const double _strokeWidth = 1.5;
  static const double _dashLength = 6;
  static const double _gapLength = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + _dashLength).clamp(0.0, metric.length);
        final segment = metric.extractPath(distance, end);
        canvas.drawPath(segment, paint);
        distance += _dashLength + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color || radius != oldDelegate.radius;
}
