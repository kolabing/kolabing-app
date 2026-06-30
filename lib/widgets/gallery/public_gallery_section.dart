import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/constants/radius.dart';
import '../../config/constants/spacing.dart';
import '../../config/theme/colors.dart';
import '../../config/theme/typography.dart';
import '../../features/profile/providers/gallery_provider.dart';
import 'photo_viewer_dialog.dart';

/// Read-only gallery section for viewing another user's photos.
///
/// Unlike [ProfileGallerySection], this does not allow adding or deleting photos.
class PublicGallerySection extends StatelessWidget {
  const PublicGallerySection({required this.photos, super.key});

  final List<GalleryPhoto> photos;

  /// Square thumbnail edge for the horizontal strip.
  static const double _thumbSize = 112;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: KolabingRadius.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(LucideIcons.image, size: 20, color: context.colors.primary),
              const SizedBox(width: KolabingSpacing.xs),
              Text(
                'Gallery',
                style: KolabingTextStyles.titleMedium.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(width: KolabingSpacing.xs),
              Text(
                '${photos.length}',
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: context.colors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: KolabingSpacing.md),

          // Horizontal thumbnail strip — sizes to its content so 1–2 photos
          // never leave a sparse 3-column grid with empty rows/columns; more
          // photos scroll horizontally. Matches the own-profile gallery.
          SizedBox(
            height: _thumbSize,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: photos.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: KolabingSpacing.xs),
              itemBuilder: (context, index) {
                final photo = photos[index];
                return GestureDetector(
                  onTap: () => PhotoViewerDialog.show(
                    context,
                    photos: photos,
                    initialIndex: index,
                  ),
                  child: ClipRRect(
                    borderRadius: KolabingRadius.borderRadiusMd,
                    child: SizedBox(
                      width: _thumbSize,
                      height: _thumbSize,
                      child: photo.url.isEmpty
                          ? Container(
                              color: context.colors.surfaceVariant,
                              child: Icon(
                                LucideIcons.imageOff,
                                size: 24,
                                color: context.colors.textTertiary,
                              ),
                            )
                          : Image.network(
                              photo.url,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: context.colors.surfaceVariant,
                                      child: Center(
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: context.colors.primary,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                              errorBuilder: (_, __, ___) => Container(
                                color: context.colors.surfaceVariant,
                                child: Icon(
                                  LucideIcons.imageOff,
                                  size: 24,
                                  color: context.colors.textTertiary,
                                ),
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
