import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/theme/colors.dart';
import '../models/onboarding_photo.dart';

class VenuePhotoManager extends StatelessWidget {
  const VenuePhotoManager({
    required this.photos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.onMovePhoto,
    super.key,
    this.isUploading = false,
  });

  final List<OnboardingPhoto> photos;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onRemovePhoto;
  final void Function(int fromIndex, int toIndex) onMovePhoto;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    final hasGooglePhotos = photos.any((photo) => photo.isGoogleImported);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isUploading)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(color: KolabingColors.primary),
          ),
        if (photos.isEmpty)
          _EmptyPhotoState(onAddPhoto: onAddPhoto)
        else
          Column(
            children: [
              for (int index = 0; index < photos.length; index++) ...[
                _VenuePhotoCard(
                  photo: photos[index],
                  index: index,
                  total: photos.length,
                  onMoveLeft: index == 0
                      ? null
                      : () => onMovePhoto(index, index - 1),
                  onMoveRight: index == photos.length - 1
                      ? null
                      : () => onMovePhoto(index, index + 1),
                  onRemove: () => onRemovePhoto(index),
                ),
                if (index != photos.length - 1) const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onAddPhoto,
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Add photo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: KolabingColors.onSurface,
                  side: const BorderSide(color: KolabingColors.darkBorder),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        if (hasGooglePhotos) ...[
          const SizedBox(height: 12),
          Text(
            'Powered by Google',
            style: GoogleFonts.openSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: KolabingColors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyPhotoState extends StatelessWidget {
  const _EmptyPhotoState({required this.onAddPhoto});

  final VoidCallback onAddPhoto;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: KolabingColors.surfaceVariant,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: KolabingColors.darkBorder),
    ),
    child: Column(
      children: [
        const Icon(
          LucideIcons.imagePlus,
          color: KolabingColors.onSurfaceVariant,
          size: 28,
        ),
        const SizedBox(height: 12),
        Text(
          'Add venue photos',
          style: GoogleFonts.rubik(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: KolabingColors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Keep imported Google photos, upload your own, remove what you do not want, and set the final order here.',
          style: GoogleFonts.openSans(
            fontSize: 13,
            color: KolabingColors.onSurfaceVariant,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: onAddPhoto,
          icon: const Icon(LucideIcons.plus, size: 18),
          label: const Text('Add photo'),
          style: ElevatedButton.styleFrom(
            backgroundColor: KolabingColors.primary,
            foregroundColor: KolabingColors.onPrimary,
          ),
        ),
      ],
    ),
  );
}

class _VenuePhotoCard extends StatelessWidget {
  const _VenuePhotoCard({
    required this.photo,
    required this.index,
    required this.total,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.onRemove,
  });

  final OnboardingPhoto photo;
  final int index;
  final int total;
  final VoidCallback? onMoveLeft;
  final VoidCallback? onMoveRight;
  final VoidCallback onRemove;

  String get _sourceLabel {
    if (photo.isGoogleImported) return 'Google import';
    if (photo.isHosted) return 'Saved photo';
    return 'Upload';
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: KolabingColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: KolabingColors.darkBorder),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _PhotoPreview(photo: photo),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Photo ${index + 1} of $total',
                      style: GoogleFonts.rubik(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: KolabingColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: photo.isGoogleImported
                            ? KolabingColors.softYellow
                            : KolabingColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _sourceLabel,
                        style: GoogleFonts.openSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: KolabingColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: onMoveLeft,
                      icon: const Icon(LucideIcons.arrowLeft, size: 18),
                      color: onMoveLeft == null
                          ? KolabingColors.textTertiary
                          : KolabingColors.onSurface,
                      tooltip: 'Move earlier',
                    ),
                    IconButton(
                      onPressed: onMoveRight,
                      icon: const Icon(LucideIcons.arrowRight, size: 18),
                      color: onMoveRight == null
                          ? KolabingColors.textTertiary
                          : KolabingColors.onSurface,
                      tooltip: 'Move later',
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onRemove,
                      icon: const Icon(LucideIcons.trash2, size: 18),
                      color: KolabingColors.error,
                      tooltip: 'Remove photo',
                    ),
                  ],
                ),
                if (photo.authorAttributions.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _showCreditsSheet(context, photo),
                    icon: const Icon(
                      LucideIcons.info,
                      size: 16,
                      color: KolabingColors.primary,
                    ),
                    label: Text(
                      'Photo credits',
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: KolabingColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  void _showCreditsSheet(BuildContext context, OnboardingPhoto photo) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: KolabingColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: KolabingColors.darkBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Google photo credits',
                style: GoogleFonts.rubik(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: KolabingColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              for (final item in photo.authorAttributions) ...[
                Text(
                  item.displayName,
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: KolabingColors.onSurface,
                  ),
                ),
                if (item.uri != null && item.uri!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: SelectableText(
                      item.uri!,
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        color: KolabingColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                if (item.photoUri != null && item.photoUri!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: SelectableText(
                      item.photoUri!,
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        color: KolabingColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              Text(
                'Powered by Google',
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: KolabingColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.photo});

  final OnboardingPhoto photo;

  @override
  Widget build(BuildContext context) {
    final memoryBytes = photo.memoryBytes;
    if (memoryBytes != null) {
      return Image.memory(
        memoryBytes,
        width: 84,
        height: 84,
        fit: BoxFit.cover,
      );
    }

    final imageUrl = photo.previewUrl ?? photo.remoteUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: 84,
        height: 84,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() => Container(
    width: 84,
    height: 84,
    color: KolabingColors.surfaceVariant,
    child: const Icon(LucideIcons.imageOff, color: KolabingColors.textTertiary),
  );
}
