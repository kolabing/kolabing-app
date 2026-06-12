import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../services/upload_service.dart';
import '../../../../utils/image_picker_normalize.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../business/providers/profile_provider.dart';
import '../../../profile/providers/gallery_provider.dart';
import '../../enums/intent_type.dart';
import '../../models/kolab.dart';
import '../../providers/kolab_form_provider.dart';
import '../../widgets/existing_photo_picker_sheet.dart';

/// Step 1 (both venue and product flows): Media upload.
///
/// Title varies based on intent type:
///   - venuePromotion  -> "SHOW OFF YOUR VENUE"
///   - productPromotion -> "SHOW YOUR PRODUCT"
///
/// Displays a grid of photo placeholders (min 1, max 5) and an optional
/// video section. This is a plain widget -- the parent provides Scaffold,
/// AppBar, step indicator, and action bar.
class MediaScreen extends ConsumerStatefulWidget {
  const MediaScreen({super.key});

  @override
  ConsumerState<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends ConsumerState<MediaScreen> {
  bool _isUploading = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final galleryState = ref.read(galleryProvider);
      if (!galleryState.isLoading && galleryState.photos.isEmpty) {
        ref.read(galleryProvider.notifier).loadGallery();
      }
    });
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
      // C10: Google Photos / iCloud picks can return content URIs that
      // dart:io can't read. Normalize to a real temp file before upload.
      final localPath = await normalizePickedImage(image);
      final uploadService = ref.read(uploadServiceProvider);
      final url = await uploadService.upload(
        filePath: localPath,
        folder: 'kolabs',
      );
      final notifier = ref.read(kolabFormProvider.notifier);
      final kolab = ref.read(kolabFormProvider).kolab;
      // Use max-existing-sort + 1 to guarantee uniqueness even after a slot
      // was removed (count-based formula could collide with a surviving entry).
      // Backend expects `image` / `video` — `photo` was rejected on publish
      // (B7). Use `image` consistently across upload + filter.
      final existingPhotos =
          kolab.media.where((m) => m.type == 'image');
      final nextSort = existingPhotos.isEmpty
          ? 0
          : existingPhotos
                  .map((m) => m.sortOrder)
                  .reduce((a, b) => a > b ? a : b) +
              1;
      notifier.addMedia(
        KolabMedia(url: url, type: 'image', sortOrder: nextSort),
      );
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).mediaUploadFailed(e.toString())), backgroundColor: context.colors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _selectExistingPhotos() async {
    final profile = ref.read(profileProvider).profile;
    final venuePhotoUrls =
        profile?.businessProfile?.primaryVenue?.photos ?? const <String>[];
    final existing = ref.read(kolabFormProvider).kolab.media;
    final existingUrls = existing.map((m) => m.url).toSet();
    final maxToAdd = 5 - existing.length;
    if (maxToAdd <= 0) return;

    final selectedPhotos = await ExistingPhotoPickerSheet.show(
      context,
      title: AppLocalizations.of(context).mediaSelectExistingTitle,
      confirmLabel: maxToAdd == 1
          ? AppLocalizations.of(context).mediaUsePhoto
          : AppLocalizations.of(context).mediaUsePhotos,
      maxSelection: maxToAdd,
      fallbackUrls: venuePhotoUrls,
    );
    if (!mounted || selectedPhotos == null || selectedPhotos.isEmpty) {
      return;
    }

    final notifier = ref.read(kolabFormProvider.notifier);
    final nextSortStart = existing.isEmpty
        ? 0
        : existing.map((m) => m.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
    final toAdd = selectedPhotos
        .where((photo) => photo.url.isNotEmpty && !existingUrls.contains(photo.url))
        .take(maxToAdd)
        .toList(growable: false);

    if (toAdd.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).mediaPhotosAlreadyAdded,
              style: KolabingTextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: context.colors.onSurfaceVariant,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    for (var i = 0; i < toAdd.length; i++) {
      notifier.addMedia(
        KolabMedia(
          url: toAdd[i].url,
          type: 'image',
          sortOrder: nextSortStart + i,
        ),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).mediaPhotosAdded(toAdd.length),
            style: KolabingTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: context.colors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(kolabFormProvider);
    final kolab = formState.kolab;
    final errors = formState.fieldErrors;
    final notifier = ref.read(kolabFormProvider.notifier);

    final l10n = AppLocalizations.of(context);
    final isVenue = formState.intentType == IntentType.venuePromotion;
    final title = isVenue ? l10n.mediaTitleVenue : l10n.mediaTitleProduct;

    // C7: surface a "Use venue photos" CTA only on venue promotion when the
    // business profile actually has photos to reuse.
    final venuePhotoUrls = ref.watch(
      profileProvider.select((s) => s.profile?.businessProfile?.primaryVenue?.photos),
    );
    final galleryState = ref.watch(galleryProvider);
    final showReuseCta = kolab.media.length < 5 &&
        (galleryState.isLoading ||
            galleryState.photos.isNotEmpty ||
            (isVenue && (venuePhotoUrls?.isNotEmpty ?? false)));

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.lg,
      ),
      children: [
        Text(
          title,
          style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurfaceVariant, letterSpacing: 1.0),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          l10n.mediaSubtitle,
          style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
        ),
        const SizedBox(height: KolabingSpacing.md),

        if (errors.containsKey('media'))
          Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
            child: Text(errors['media']!, style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.error)),
          ),

        // Reuse previously uploaded profile gallery photos, plus venue fallback.
        if (showReuseCta) ...[
          OutlinedButton.icon(
            onPressed: _isUploading ? null : _selectExistingPhotos,
            icon: const Icon(LucideIcons.imagePlus, size: 18),
            label: Text(
              l10n.mediaSelectFromLibrary,
              style: KolabingTextStyles.button.copyWith(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.primary,
              side: BorderSide(
                color: context.colors.primary.withValues(alpha: 0.5),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: KolabingSpacing.md,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: KolabingSpacing.sm),
        ],

        // Upload progress
        if (_isUploading)
          Padding(
            padding: EdgeInsets.only(bottom: KolabingSpacing.sm),
            child: LinearProgressIndicator(color: context.colors.primary),
          ),

        _PhotoGrid(
          media: kolab.media,
          onAdd: _isUploading ? () {} : _pickAndUploadPhoto,
          onRemove: notifier.removeMedia,
        ),
        const SizedBox(height: KolabingSpacing.lg),
      ],
    );
  }
}

// =============================================================================
// Photo Grid
// =============================================================================

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.media,
    required this.onAdd,
    required this.onRemove,
  });

  final List<KolabMedia> media;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    final photos = media.where((m) => m.type == 'image').toList();
    final canAdd = photos.length < 5;

    return Wrap(
      spacing: KolabingSpacing.sm,
      runSpacing: KolabingSpacing.sm,
      children: [
        // Existing photos
        for (int i = 0; i < photos.length; i++)
          _PhotoSlot(
            index: i,
            url: photos[i].url,
            onRemove: () {
              // Find the actual index in the full media list
              final actualIndex = media.indexOf(photos[i]);
              if (actualIndex >= 0) onRemove(actualIndex);
            },
          ),

        // Add button
        if (canAdd)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
                borderRadius: KolabingRadius.borderRadiusMd,
                border: Border.all(
                  color: context.colors.darkBorder,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.plus,
                    size: 24,
                    color: context.colors.onSurfaceVariant,
                  ),
                  const SizedBox(height: KolabingSpacing.xxs),
                  Text(
                    AppLocalizations.of(context).mediaAddPhoto,
                    style: KolabingTextStyles.labelSmall.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.index,
    required this.url,
    required this.onRemove,
  });

  final int index;
  final String url;
  final VoidCallback onRemove;

  bool get _isLocalFile => !url.startsWith('http');

  @override
  Widget build(BuildContext context) => Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: context.colors.softYellow,
            borderRadius: KolabingRadius.borderRadiusMd,
            border: Border.all(color: context.colors.softYellowBorder),
          ),
          child: ClipRRect(
            borderRadius: KolabingRadius.borderRadiusMd,
            child: _isLocalFile
                ? Image.file(
                    File(url),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholder(context),
                  )
                : Image.network(
                    url,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholder(context),
                  ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: context.colors.error,
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
    );

  Widget _buildPlaceholder(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.image, size: 24, color: context.colors.onSurfaceVariant),
            const SizedBox(height: KolabingSpacing.xxs),
            Text(
              AppLocalizations.of(context).mediaPhotoSlot(index + 1),
              style: KolabingTextStyles.labelSmall.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ],
        ),
      );
}
