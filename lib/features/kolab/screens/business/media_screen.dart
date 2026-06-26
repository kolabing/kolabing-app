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
/// A business can either upload a real photo or pick a Kolabing-designed
/// default cover — both satisfy the "at least 1 photo" requirement. This
/// replaces the old forced-upload feel: the screen never shows a hard error
/// on first load, only after an explicit Next attempt with nothing chosen.
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
      requestFullMetadata: false,
    );
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final localPath = await normalizePickedImage(image);
      final uploadService = ref.read(uploadServiceProvider);
      final url = await uploadService.upload(
        filePath: localPath,
        folder: 'kolabs',
      );
      final notifier = ref.read(kolabFormProvider.notifier);
      final kolab = ref.read(kolabFormProvider).kolab;

      // Replace a sole default-cover placeholder with the real photo rather
      // than appending — keeps the "replace it later" promise literal.
      final isOnlyDefaultCover =
          kolab.media.length == 1 && kolab.media.single.isDefaultCover;
      if (isOnlyDefaultCover) {
        notifier.removeMedia(0);
      }

      final existingPhotos = (isOnlyDefaultCover ? const <KolabMedia>[] : kolab.media)
          .where((m) => m.type == 'image');
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

  void _useDefaultCover(IntentType intent) {
    ref.read(kolabFormProvider.notifier).useDefaultCover(intent);
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

    final isVenue = formState.intentType == IntentType.venuePromotion;
    final intent = formState.intentType ?? IntentType.productPromotion;

    final venuePhotoUrls = ref.watch(
      profileProvider.select((s) => s.profile?.businessProfile?.primaryVenue?.photos),
    );
    final galleryState = ref.watch(galleryProvider);
    final hasUsableDefault = galleryState.photos.isNotEmpty ||
        (isVenue && (venuePhotoUrls?.isNotEmpty ?? false));
    final showReuseCta =
        kolab.media.length < 5 && (galleryState.isLoading || hasUsableDefault);
    final hasNoChoiceYet = kolab.media.isEmpty;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.lg,
      ),
      children: [
        Text(
          'ADD PHOTOS',
          style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w800, color: context.colors.onSurfaceVariant, letterSpacing: 1.0),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          'Kolabs need a cover image. You can upload your own or use a Kolabing default.',
          style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
        ),
        const SizedBox(height: KolabingSpacing.md),

        if (errors.containsKey('media'))
          Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
            child: Text(
              errors['media']!,
              style: KolabingTextStyles.bodySmall.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.colors.orange,
              ),
            ),
          ),

        if (hasNoChoiceYet) ...[
          _ChoiceCard(
            icon: LucideIcons.upload,
            title: 'Upload my photo',
            helper: 'Best if you have a real product, venue, food, or event image.',
            onTap: _isUploading ? null : _pickAndUploadPhoto,
          ),
          const SizedBox(height: KolabingSpacing.sm),
          _ChoiceCard(
            icon: LucideIcons.imagePlus,
            title: 'Use default cover',
            helper: "We'll use a designed Kolabing cover for this type of Kolab.",
            previewAssetPath:
                'assets/images/defaults/${intent == IntentType.venuePromotion ? 'venue_1' : 'product_cover_1'}.png',
            onTap: _isUploading ? null : () => _useDefaultCover(intent),
          ),
          const SizedBox(height: KolabingSpacing.xs),
          Text(
            'You can replace it later with your own photo.',
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 12,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          if (showReuseCta) ...[
            const SizedBox(height: KolabingSpacing.sm),
            Center(
              child: TextButton(
                onPressed: _isUploading ? null : _selectExistingPhotos,
                child: Text(
                  isVenue ? 'Or use business photo / choose existing' : 'Or choose an existing photo',
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.primary,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: KolabingSpacing.md),
        ] else ...[
          // Standing tip — encouragement, not a precondition, only shown
          // once a choice has already been made.
          Container(
            margin: const EdgeInsets.only(bottom: KolabingSpacing.sm),
            padding: const EdgeInsets.all(KolabingSpacing.sm),
            decoration: BoxDecoration(
              color: context.colors.yellowTint,
              borderRadius: KolabingRadius.borderRadiusOptionCard,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.info, size: 16, color: context.colors.amber),
                const SizedBox(width: KolabingSpacing.xs),
                Expanded(
                  child: Text(
                    'Kolabs with strong visuals usually get more interest.',
                    style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.onSurface, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          if (showReuseCta) ...[
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _selectExistingPhotos,
              icon: const Icon(LucideIcons.imagePlus, size: 18),
              label: Text(
                isVenue ? 'Use business photo or choose existing' : 'Choose existing photo',
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

          if (_isUploading)
            Padding(
              padding: const EdgeInsets.only(bottom: KolabingSpacing.sm),
              child: LinearProgressIndicator(color: context.colors.primary),
            ),

          _PhotoGrid(
            media: kolab.media,
            onAdd: _isUploading ? () {} : _pickAndUploadPhoto,
            onRemove: notifier.removeMedia,
          ),
          const SizedBox(height: KolabingSpacing.sm),
          Text(
            '${kolab.media.where((m) => m.type == 'image').length} of 5 added',
            style: KolabingTextStyles.bodySmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.colors.muted,
            ),
          ),
        ],
        const SizedBox(height: KolabingSpacing.lg),
      ],
    );
  }
}

// =============================================================================
// Choice Card
// =============================================================================

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.helper,
    required this.onTap,
    this.previewAssetPath,
  });

  final IconData icon;
  final String title;
  final String helper;
  final VoidCallback? onTap;
  final String? previewAssetPath;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: KolabingRadius.borderRadiusOptionCard,
          child: Container(
            padding: const EdgeInsets.all(KolabingSpacing.md),
            decoration: BoxDecoration(
              color: context.colors.softYellow,
              borderRadius: KolabingRadius.borderRadiusOptionCard,
              border: Border.all(color: context.colors.softYellowBorder),
            ),
            child: Row(
              children: [
                previewAssetPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          previewAssetPath!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: context.colors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, size: 20, color: context.colors.ink),
                          ),
                        ),
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 20, color: context.colors.ink),
                      ),
                const SizedBox(width: KolabingSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        helper,
                        style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
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
        for (int i = 0; i < photos.length; i++)
          _PhotoSlot(
            index: i,
            url: photos[i].url,
            isDefaultCover: photos[i].isDefaultCover,
            onRemove: () {
              final actualIndex = media.indexOf(photos[i]);
              if (actualIndex >= 0) onRemove(actualIndex);
            },
          ),

        if (canAdd)
          GestureDetector(
            onTap: onAdd,
            child: SizedBox(
              width: 120,
              height: 120,
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: context.colors.navInactiveSubtle,
                  borderRadius: KolabingRadius.thumbnail,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: context.colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.plus,
                        size: 18,
                        color: context.colors.ink,
                      ),
                    ),
                    const SizedBox(height: KolabingSpacing.xs),
                    Text(
                      AppLocalizations.of(context).mediaAddPhoto,
                      style: KolabingTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colors.onSurface,
                      ),
                    ),
                  ],
                ),
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
    required this.isDefaultCover,
    required this.onRemove,
  });

  final int index;
  final String url;
  final bool isDefaultCover;
  final VoidCallback onRemove;

  bool get _isLocalFile => !url.startsWith('http');

  @override
  Widget build(BuildContext context) => Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: context.colors.softYellow,
            borderRadius: KolabingRadius.borderRadiusThumbnail,
            border: Border.all(color: context.colors.softYellowBorder),
          ),
          child: ClipRRect(
            borderRadius: KolabingRadius.borderRadiusThumbnail,
            child: _isLocalFile
                ? Image.file(
                    File(url),
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholder(context),
                  )
                : Image.network(
                    url,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholder(context),
                  ),
          ),
        ),
        if (isDefaultCover)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Default',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
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

/// Paints a dashed rounded-rectangle border for the "Add Photo" tile.
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.borderRadius});

  final Color color;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final dashPath = _createDashedPath(Path()..addRRect(rrect));
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source) {
    const dashWidth = 6.0;
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
