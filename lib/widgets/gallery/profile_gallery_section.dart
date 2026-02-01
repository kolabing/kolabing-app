import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../config/constants/radius.dart';
import '../../config/constants/spacing.dart';
import '../../config/theme/colors.dart';
import '../../config/theme/typography.dart';
import '../../features/profile/providers/gallery_provider.dart';
import 'photo_viewer_dialog.dart';

/// Gallery section widget for profile screens
///
/// Shows a grid of uploaded photos with add/delete/view capabilities.
/// Uses the shared [galleryProvider] for state management.
class ProfileGallerySection extends ConsumerStatefulWidget {
  const ProfileGallerySection({super.key});

  @override
  ConsumerState<ProfileGallerySection> createState() =>
      _ProfileGallerySectionState();
}

class _ProfileGallerySectionState extends ConsumerState<ProfileGallerySection> {
  @override
  void initState() {
    super.initState();
    // Load gallery when section first appears
    Future.microtask(
      () => ref.read(galleryProvider.notifier).loadGallery(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final galleryState = ref.watch(galleryProvider);

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
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
              if (!galleryState.isLoading && galleryState.photos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: KolabingSpacing.xs),
                  child: Text(
                    '${galleryState.photos.length}/${GalleryState.maxPhotos}',
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: KolabingColors.textTertiary,
                    ),
                  ),
                ),
              const Spacer(),
              if (galleryState.canAddMore && !galleryState.isLoading)
                GestureDetector(
                  onTap: () => _showAddPhotoSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KolabingSpacing.sm,
                      vertical: KolabingSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: KolabingColors.primary.withValues(alpha: 0.1),
                      borderRadius: KolabingRadius.borderRadiusRound,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.plus,
                          size: 14,
                          color: KolabingColors.textPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Add',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: KolabingColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: KolabingSpacing.md),

          // Gallery content
          if (galleryState.isLoading)
            _buildLoadingState()
          else if (galleryState.isUploading)
            _buildUploadingIndicator()
          else if (galleryState.isEmpty)
            _buildEmptyState(context)
          else
            _buildPhotoGrid(context, galleryState),

          // Error message
          if (galleryState.error != null) ...[
            const SizedBox(height: KolabingSpacing.xs),
            Text(
              galleryState.error!,
              style: KolabingTextStyles.bodySmall.copyWith(
                color: KolabingColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddPhotoSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: KolabingColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: KolabingSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: KolabingColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: KolabingSpacing.lg),
              Text(
                'Add Gallery Photo',
                style: KolabingTextStyles.titleMedium.copyWith(
                  color: KolabingColors.textPrimary,
                ),
              ),
              const SizedBox(height: KolabingSpacing.lg),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: KolabingColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.camera,
                    color: KolabingColors.primary,
                  ),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use your camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: KolabingColors.info.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.image,
                    color: KolabingColors.info,
                  ),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select an existing photo'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: KolabingSpacing.md),
            ],
          ),
        ),
      ),
    ).then((source) {
      if (source != null) {
        ref.read(galleryProvider.notifier).addPhoto(source);
      }
    });
  }

  Widget _buildLoadingState() => Container(
        height: 120,
        decoration: BoxDecoration(
          color: KolabingColors.surfaceVariant,
          borderRadius: KolabingRadius.borderRadiusMd,
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: KolabingColors.primary,
            ),
          ),
        ),
      );

  Widget _buildUploadingIndicator() => Container(
        height: 120,
        decoration: BoxDecoration(
          color: KolabingColors.surfaceVariant,
          borderRadius: KolabingRadius.borderRadiusMd,
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: KolabingColors.primary,
                ),
              ),
              SizedBox(height: 8),
              Text('Uploading photo...'),
            ],
          ),
        ),
      );

  Widget _buildEmptyState(BuildContext context) => GestureDetector(
        onTap: () => _showAddPhotoSheet(context),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: KolabingRadius.borderRadiusMd,
            border: Border.all(
              color: KolabingColors.border,
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.camera,
                  size: 32,
                  color: KolabingColors.textTertiary,
                ),
                const SizedBox(height: KolabingSpacing.xs),
                Text(
                  'Add your first photo',
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    color: KolabingColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildPhotoGrid(
    BuildContext context,
    GalleryState galleryState,
  ) {
    final photos = galleryState.photos;

    return GridView.builder(
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
        return _GalleryThumbnail(
          photo: photo,
          onTap: () => PhotoViewerDialog.show(
            context,
            photos: photos,
            initialIndex: index,
          ),
          onDelete: () => _confirmDelete(context, photo),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, GalleryPhoto photo) {
    HapticFeedback.mediumImpact();
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to remove this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: KolabingColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        ref.read(galleryProvider.notifier).removePhoto(photo.id);
      }
    });
  }
}

// =============================================================================
// Gallery Thumbnail
// =============================================================================

class _GalleryThumbnail extends StatelessWidget {
  const _GalleryThumbnail({
    required this.photo,
    required this.onTap,
    required this.onDelete,
  });

  final GalleryPhoto photo;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: KolabingRadius.borderRadiusSm,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo
              if (photo.url.isEmpty)
                Container(
                  color: KolabingColors.surfaceVariant,
                  child: const Icon(
                    LucideIcons.imageOff,
                    size: 24,
                    color: KolabingColors.textTertiary,
                  ),
                )
              else
                Image.network(
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
                  errorBuilder: (_, error, __) {
                    debugPrint('Gallery thumbnail error for ${photo.url}: $error');
                    return Container(
                      color: KolabingColors.surfaceVariant,
                      child: const Icon(
                        LucideIcons.imageOff,
                        size: 24,
                        color: KolabingColors.textTertiary,
                      ),
                    );
                  },
                ),

              // Delete button
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
