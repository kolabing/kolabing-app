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
  const PublicGallerySection({
    required this.photos,
    super.key,
  });

  final List<GalleryPhoto> photos;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      decoration: BoxDecoration(
        color: KolabingColors.surface,
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
              const Icon(
                LucideIcons.image,
                size: 20,
                color: KolabingColors.primary,
              ),
              const SizedBox(width: KolabingSpacing.xs),
              Text(
                'Gallery',
                style: KolabingTextStyles.titleMedium.copyWith(
                  color: KolabingColors.textPrimary,
                ),
              ),
              const SizedBox(width: KolabingSpacing.xs),
              Text(
                '${photos.length}',
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: KolabingColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: KolabingSpacing.md),

          // Photo grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: KolabingSpacing.xs,
              mainAxisSpacing: KolabingSpacing.xs,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return GestureDetector(
                onTap: () => PhotoViewerDialog.show(
                  context,
                  photos: photos,
                  initialIndex: index,
                ),
                child: ClipRRect(
                  borderRadius: KolabingRadius.borderRadiusSm,
                  child: photo.url.isEmpty
                      ? Container(
                          color: KolabingColors.surfaceVariant,
                          child: const Icon(
                            LucideIcons.imageOff,
                            size: 24,
                            color: KolabingColors.textTertiary,
                          ),
                        )
                      : Image.network(
                          photo.url,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: KolabingColors.surfaceVariant,
                              child: const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: KolabingColors.primary,
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            color: KolabingColors.surfaceVariant,
                            child: const Icon(
                              LucideIcons.imageOff,
                              size: 24,
                              color: KolabingColors.textTertiary,
                            ),
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
