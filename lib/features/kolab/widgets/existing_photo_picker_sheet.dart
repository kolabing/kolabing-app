import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../features/profile/providers/gallery_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/remote_media_url.dart';

class ExistingPhotoPickerSheet extends ConsumerStatefulWidget {
  const ExistingPhotoPickerSheet({
    required this.title,
    required this.confirmLabel,
    required this.maxSelection,
    this.initiallySelectedUrls = const <String>{},
    this.fallbackUrls = const <String>[],
    super.key,
  });

  final String title;
  final String confirmLabel;
  final int maxSelection;
  final Set<String> initiallySelectedUrls;
  final List<String> fallbackUrls;

  static Future<List<GalleryPhoto>?> show(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    required int maxSelection,
    Set<String> initiallySelectedUrls = const <String>{},
    List<String> fallbackUrls = const <String>[],
  }) => showModalBottomSheet<List<GalleryPhoto>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ExistingPhotoPickerSheet(
      title: title,
      confirmLabel: confirmLabel,
      maxSelection: maxSelection,
      initiallySelectedUrls: initiallySelectedUrls,
      fallbackUrls: fallbackUrls,
    ),
  );

  @override
  ConsumerState<ExistingPhotoPickerSheet> createState() =>
      _ExistingPhotoPickerSheetState();
}

class _ExistingPhotoPickerSheetState
    extends ConsumerState<ExistingPhotoPickerSheet> {
  late Set<String> _selectedUrls;

  @override
  void initState() {
    super.initState();
    _selectedUrls = Set<String>.from(widget.initiallySelectedUrls);
    Future.microtask(() {
      final galleryState = ref.read(galleryProvider);
      if (!galleryState.isLoading && galleryState.photos.isEmpty) {
        ref.read(galleryProvider.notifier).loadGallery();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final galleryState = ref.watch(galleryProvider);
    final mergedPhotos = _buildMergedPhotos(galleryState.photos);
    final selectedPhotos = mergedPhotos
        .where((photo) => _selectedUrls.contains(photo.url))
        .toList(growable: false);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 48),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: KolabingColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(KolabingRadius.lg),
            ),
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.72,
            child: Padding(
              padding: const EdgeInsets.all(KolabingSpacing.md),
              child: Column(
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
                  const SizedBox(height: KolabingSpacing.md),
                  Text(
                    widget.title,
                    style: KolabingTextStyles.bodyMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w700, color: KolabingColors.onSurface),
                  ),
                  const SizedBox(height: KolabingSpacing.xxs),
                  Text(
                    l10n.existingPhotoPickerSubtitle(widget.maxSelection),
                    style: KolabingTextStyles.captionSecondary.copyWith(color: KolabingColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: KolabingSpacing.md),
                  Expanded(
                    child: _buildBody(
                      context: context,
                      galleryState: galleryState,
                      mergedPhotos: mergedPhotos,
                    ),
                  ),
                  const SizedBox(height: KolabingSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l10n.commonCancel),
                        ),
                      ),
                      const SizedBox(width: KolabingSpacing.sm),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: selectedPhotos.isEmpty
                              ? null
                              : () => Navigator.of(context).pop(selectedPhotos),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KolabingColors.primary,
                            foregroundColor: KolabingColors.onPrimary,
                          ),
                          child: Text(widget.confirmLabel),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required GalleryState galleryState,
    required List<GalleryPhoto> mergedPhotos,
  }) {
    if (galleryState.isLoading && mergedPhotos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: KolabingColors.primary),
      );
    }

    if (mergedPhotos.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).existingPhotoPickerEmpty,
          style: KolabingTextStyles.bodySmall.copyWith(color: KolabingColors.onSurfaceVariant),
        ),
      );
    }

    return GridView.builder(
      itemCount: mergedPhotos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: KolabingSpacing.sm,
        mainAxisSpacing: KolabingSpacing.sm,
      ),
      itemBuilder: (context, index) {
        final photo = mergedPhotos[index];
        final isSelected = _selectedUrls.contains(photo.url);
        return GestureDetector(
          onTap: () => _toggleSelection(photo.url),
          child: ClipRRect(
            borderRadius: KolabingRadius.borderRadiusMd,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  photo.url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: KolabingColors.surfaceVariant,
                    alignment: Alignment.center,
                    child: const Icon(
                      LucideIcons.imageOff,
                      color: KolabingColors.textTertiary,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? KolabingColors.primary
                          : Colors.transparent,
                      width: 3,
                    ),
                    color: isSelected
                        ? KolabingColors.primary.withValues(alpha: 0.14)
                        : Colors.transparent,
                  ),
                ),
                if (isSelected)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: KolabingColors.primary,
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: KolabingColors.onPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<GalleryPhoto> _buildMergedPhotos(List<GalleryPhoto> galleryPhotos) {
    final photos = <GalleryPhoto>[...galleryPhotos];
    final seenUrls = photos.map((photo) => photo.url).toSet();

    for (var index = 0; index < widget.fallbackUrls.length; index++) {
      final normalizedUrl = normalizeRemoteMediaUrl(widget.fallbackUrls[index]);
      if (normalizedUrl.isEmpty || seenUrls.contains(normalizedUrl)) {
        continue;
      }

      photos.add(
        GalleryPhoto.fromUrl(
          id: '__fallback_photo__$index',
          rawUrl: normalizedUrl,
          sortOrder: photos.length,
        ),
      );
      seenUrls.add(normalizedUrl);
    }

    return photos;
  }

  void _toggleSelection(String url) {
    setState(() {
      if (_selectedUrls.contains(url)) {
        _selectedUrls.remove(url);
        return;
      }

      if (widget.maxSelection == 1) {
        _selectedUrls = <String>{url};
        return;
      }

      if (_selectedUrls.length >= widget.maxSelection) {
        return;
      }

      _selectedUrls.add(url);
    });
  }
}
