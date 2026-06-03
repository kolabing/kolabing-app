import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/upload_service.dart';
import '../../../../utils/image_picker_normalize.dart';
import '../../../../utils/remote_media_url.dart';
import '../../../event/providers/event_provider.dart';
import '../../../profile/providers/gallery_provider.dart';
import '../../models/kolab.dart';
import '../../providers/kolab_form_provider.dart';
import '../../widgets/existing_photo_picker_sheet.dart';

/// Community step 4: "ADD A PHOTO"
///
/// Lets the user choose to use their community profile photo or upload a new
/// one. The uploaded photo will appear on the kolab card in Explore.
class PhotoScreen extends ConsumerStatefulWidget {
  const PhotoScreen({super.key});

  @override
  ConsumerState<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends ConsumerState<PhotoScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final galleryState = ref.read(galleryProvider);
      if (!galleryState.isLoading && galleryState.photos.isEmpty) {
        ref.read(galleryProvider.notifier).loadGallery();
      }
      // Ensure the community's past-event photos are available to surface as
      // selectable thumbnails (eventsProvider auto-loads on first build, but
      // re-trigger if it's empty and idle, e.g. after a reset).
      final eventsState = ref.read(eventsProvider);
      if (!eventsState.isLoading && eventsState.events.isEmpty) {
        ref.read(eventsProvider.notifier).loadEvents();
      }
    });
  }

  /// Collect de-duplicated past-event photo URLs from the community's events so
  /// they can be offered alongside the profile gallery in the picker.
  List<String> _pastEventPhotoUrls() {
    final events = ref.read(eventsProvider).events;
    final urls = <String>[];
    final seen = <String>{};
    for (final event in events) {
      for (final photo in event.photos) {
        final url = normalizeRemoteMediaUrl(photo.url);
        if (url.isEmpty || !seen.add(url)) continue;
        urls.add(url);
      }
    }
    return urls;
  }

  Future<void> _pickAndUploadPhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      // C10: normalize to a readable local path before upload.
      final localPath = await normalizePickedImage(image);
      final uploadService = ref.read(uploadServiceProvider);
      final url = await uploadService.upload(
        filePath: localPath,
        folder: 'kolabs',
      );
      ref.read(kolabFormProvider.notifier).updateMedia([
        // Backend rejects 'photo' (B7). Use 'image' consistently.
        KolabMedia(url: url, type: 'image', sortOrder: 0),
      ]);
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).photoUploadFailed(e.toString()),
            ),
            backgroundColor: KolabingColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _selectExistingPhoto() async {
    final l10n = AppLocalizations.of(context);
    final selectedPhotos = await ExistingPhotoPickerSheet.show(
      context,
      title: l10n.photoPickerSheetTitle,
      confirmLabel: l10n.photoPickerConfirmLabel,
      maxSelection: 1,
      initiallySelectedUrls: ref
          .read(kolabFormProvider)
          .kolab
          .media
          .map((media) => media.url)
          .toSet(),
      // Surface the community's past-event photos in addition to the profile
      // gallery. The picker merges these into the same selectable grid.
      fallbackUrls: _pastEventPhotoUrls(),
    );
    if (!mounted || selectedPhotos == null || selectedPhotos.isEmpty) {
      return;
    }

    ref.read(kolabFormProvider.notifier).updateMedia([
      KolabMedia(url: selectedPhotos.first.url, type: 'image', sortOrder: 0),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(kolabFormProvider);
    final galleryState = ref.watch(galleryProvider);
    final eventsState = ref.watch(eventsProvider);
    final useProfilePhoto = state.kolab.media.isEmpty;
    final uploadedPhoto = state.kolab.media.isNotEmpty
        ? state.kolab.media.first
        : null;
    final hasPastEventPhotos = eventsState.events.any(
      (event) => event.photos.isNotEmpty,
    );
    // Offer the library picker when either the profile gallery or past-event
    // photos are (or are still being) loaded.
    final showGalleryChoice =
        galleryState.isLoading ||
        galleryState.photos.isNotEmpty ||
        eventsState.isLoading ||
        hasPastEventPhotos;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Text(
            l10n.photoAddHeader,
            style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: KolabingColors.onSurfaceVariant, letterSpacing: 1.0),
          ),
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            l10n.photoAddSubtitle,
            style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.onSurfaceVariant),
          ),

          const SizedBox(height: KolabingSpacing.lg),

          // Option 1: Use profile photo
          GestureDetector(
            onTap: () {
              // Clear any uploaded media so we fall back to profile photo
              ref.read(kolabFormProvider.notifier).updateMedia([]);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(KolabingSpacing.md),
              decoration: BoxDecoration(
                color: useProfilePhoto
                    ? KolabingColors.softYellow
                    : KolabingColors.surface,
                borderRadius: KolabingRadius.borderRadiusMd,
                border: Border.all(
                  color: useProfilePhoto
                      ? KolabingColors.primary
                      : KolabingColors.darkBorder,
                  width: useProfilePhoto ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: useProfilePhoto
                          ? KolabingColors.primary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: useProfilePhoto
                            ? KolabingColors.primary
                            : KolabingColors.darkBorder,
                        width: 2,
                      ),
                    ),
                    child: useProfilePhoto
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: KolabingColors.onPrimary,
                          )
                        : null,
                  ),
                  const SizedBox(width: KolabingSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.photoUseProfilePhoto,
                      style: KolabingTextStyles.bodySmall.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: KolabingColors.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: KolabingSpacing.md),

          // Divider with "OR"
          Row(
            children: [
              const Expanded(child: Divider(color: KolabingColors.darkBorder)),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KolabingSpacing.sm,
                ),
                child: Text(
                  l10n.photoDividerOr,
                  style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: KolabingColors.textTertiary),
                ),
              ),
              const Expanded(child: Divider(color: KolabingColors.darkBorder)),
            ],
          ),

          const SizedBox(height: KolabingSpacing.md),

          if (showGalleryChoice && uploadedPhoto == null) ...[
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _selectExistingPhoto,
              icon: const Icon(LucideIcons.imagePlus, size: 18),
              label: Text(l10n.photoChooseFromGallery),
            ),
            const SizedBox(height: KolabingSpacing.md),
          ],

          if (_isUploading) ...[
            const LinearProgressIndicator(color: KolabingColors.primary),
            const SizedBox(height: KolabingSpacing.md),
          ],

          // Option 2: Upload a photo
          if (uploadedPhoto == null)
            GestureDetector(
              onTap: _isUploading ? null : _pickAndUploadPhoto,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: KolabingColors.surface,
                  borderRadius: KolabingRadius.borderRadiusMd,
                  border: Border.all(color: KolabingColors.darkBorder, width: 1),
                ),
                child: CustomPaint(
                  painter: _DashedBorderPainter(
                    color: KolabingColors.textTertiary,
                    borderRadius: KolabingRadius.md,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(KolabingSpacing.md),
                        decoration: const BoxDecoration(
                          color: KolabingColors.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.camera,
                          size: 32,
                          color: KolabingColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: KolabingSpacing.sm),
                      Text(
                        l10n.photoUploadTitle,
                        style: KolabingTextStyles.bodySmall.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: KolabingColors.onSurface),
                      ),
                      const SizedBox(height: KolabingSpacing.xxs),
                      Text(
                        l10n.photoUploadMaxSize,
                        style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: KolabingColors.textTertiary),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            _UploadedPhotoCard(
              photo: uploadedPhoto,
              isUploading: _isUploading,
              onReplace: _pickAndUploadPhoto,
              onRemove: () {
                ref.read(kolabFormProvider.notifier).updateMedia([]);
              },
            ),
        ],
      ),
    );
  }
}

class _UploadedPhotoCard extends StatelessWidget {
  const _UploadedPhotoCard({
    required this.photo,
    required this.isUploading,
    required this.onReplace,
    required this.onRemove,
  });

  final KolabMedia photo;
  final bool isUploading;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  bool get _isLocalFile =>
      photo.url.isNotEmpty && !photo.url.startsWith('http');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(KolabingSpacing.sm),
    decoration: BoxDecoration(
      color: KolabingColors.surface,
      borderRadius: KolabingRadius.borderRadiusMd,
      border: Border.all(color: KolabingColors.primary, width: 1.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: KolabingRadius.borderRadiusMd,
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: _isLocalFile
                ? Image.file(File(photo.url), fit: BoxFit.cover)
                : Image.network(
                    photo.url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: KolabingColors.surfaceVariant,
                      alignment: Alignment.center,
                      child: const Icon(
                        LucideIcons.imageOff,
                        color: KolabingColors.textTertiary,
                        size: 28,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: KolabingSpacing.sm),
        Text(
          l10n.photoUploadedSelectedTitle,
          style: KolabingTextStyles.bodySmall.copyWith(fontSize: 15, fontWeight: FontWeight.w700, color: KolabingColors.onSurface),
        ),
        const SizedBox(height: KolabingSpacing.xxs),
        Text(
          l10n.photoUploadedSelectedSubtitle,
          style: KolabingTextStyles.captionSecondary.copyWith(color: KolabingColors.onSurfaceVariant),
        ),
        const SizedBox(height: KolabingSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isUploading ? null : onRemove,
                child: Text(l10n.photoUseProfilePhotoButton),
              ),
            ),
            const SizedBox(width: KolabingSpacing.sm),
            Expanded(
              child: ElevatedButton(
                onPressed: isUploading ? null : onReplace,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KolabingColors.primary,
                  foregroundColor: KolabingColors.onPrimary,
                ),
                child: Text(l10n.photoReplacePhotoButton),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  }
}

/// Paints a dashed rounded rectangle border.
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.borderRadius});

  final Color color;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final path = Path()..addRRect(rrect);
    final dashPath = _createDashedPath(path);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source) {
    const dashWidth = 8.0;
    const dashSpace = 4.0;
    final dest = Path();

    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = distance + dashWidth;
        dest.addPath(
          metric.extractPath(distance, end.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = end + dashSpace;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color || borderRadius != oldDelegate.borderRadius;
}
