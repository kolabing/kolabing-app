import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../models/kolab.dart';

/// A grid for managing media attachments in the Kolab creation flow.
///
/// Displays existing [KolabMedia] items as placeholder thumbnails with a remove
/// overlay, plus an "add" button when the count is below [maxItems].
class MediaPickerGrid extends StatelessWidget {
  const MediaPickerGrid({
    required this.media,
    required this.onAdd,
    required this.onRemove,
    super.key,
    this.maxItems = 5,
  });

  /// Currently attached media items.
  final List<KolabMedia> media;

  /// Maximum number of media items allowed.
  final int maxItems;

  /// Called when the user taps the add slot.
  final VoidCallback onAdd;

  /// Called with the index of the media item to remove.
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    final totalSlots = media.length < maxItems
        ? media.length + 1 // existing + add button
        : media.length;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: KolabingSpacing.xs,
        crossAxisSpacing: KolabingSpacing.xs,
      ),
      itemCount: totalSlots,
      itemBuilder: (context, index) {
        // Add button slot
        if (index == media.length && media.length < maxItems) {
          return _AddSlot(
            onTap: onAdd,
            remaining: maxItems - media.length,
          );
        }

        // Existing media slot
        return _MediaSlot(
          media: media[index],
          onRemove: () => onRemove(index),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Existing media thumbnail with remove button
// ---------------------------------------------------------------------------

class _MediaSlot extends StatelessWidget {
  const _MediaSlot({
    required this.media,
    required this.onRemove,
  });

  final KolabMedia media;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: KolabingRadius.borderRadiusSm,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Placeholder or network image
            if (media.url.isNotEmpty)
              Image.network(
                media.url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildPlaceholder(),
              )
            else
              _buildPlaceholder(),
            // Video overlay icon
            if (media.type == 'video')
              Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.play,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            // Remove button
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.x,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildPlaceholder() => const ColoredBox(
        color: KolabingColors.surfaceVariant,
        child: Center(
          child: Icon(
            LucideIcons.image,
            size: 24,
            color: KolabingColors.textTertiary,
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Add slot with camera icon
// ---------------------------------------------------------------------------

class _AddSlot extends StatelessWidget {
  const _AddSlot({
    required this.onTap,
    required this.remaining,
  });

  final VoidCallback onTap;
  final int remaining;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: KolabingColors.background,
            borderRadius: KolabingRadius.borderRadiusSm,
            border: Border.all(color: KolabingColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.camera,
                size: 22,
                color: KolabingColors.textTertiary,
              ),
              const SizedBox(height: KolabingSpacing.xxs),
              Text(
                '$remaining left',
                style: GoogleFonts.openSans(
                  fontSize: 10,
                  color: KolabingColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
}
