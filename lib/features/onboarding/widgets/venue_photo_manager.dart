import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../models/onboarding_photo.dart';

class VenuePhotoManager extends StatelessWidget {
  const VenuePhotoManager({
    required this.photos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.onMovePhoto,
    super.key,
    this.isUploading = false,
    this.emptyTitle,
    this.emptyDescription,
  });

  final List<OnboardingPhoto> photos;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onRemovePhoto;
  final void Function(int fromIndex, int toIndex) onMovePhoto;
  final bool isUploading;

  /// Optional empty-state copy overrides. When null the venue strings are used;
  /// the product/service onboarding path passes generic (non-venue) copy.
  final String? emptyTitle;
  final String? emptyDescription;

  @override
  Widget build(BuildContext context) {
    final hasGooglePhotos = photos.any((photo) => photo.isGoogleImported);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isUploading)
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(color: context.colors.primary),
          ),
        if (photos.isEmpty)
          _EmptyPhotoState(
            onAddPhoto: onAddPhoto,
            title: emptyTitle,
            description: emptyDescription,
          )
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
                label: Text(AppLocalizations.of(context).venuePhotoAddPhoto),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.onSurface,
                  side: BorderSide(color: context.colors.darkBorder),
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
            AppLocalizations.of(context).venuePhotoPoweredByGoogle,
            style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.textTertiary),
          ),
        ],
      ],
    );
  }
}

class _EmptyPhotoState extends StatelessWidget {
  const _EmptyPhotoState({
    required this.onAddPhoto,
    this.title,
    this.description,
  });

  final VoidCallback onAddPhoto;
  final String? title;
  final String? description;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: context.colors.surfaceVariant,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.colors.darkBorder),
    ),
    child: Column(
      children: [
        Icon(
          LucideIcons.imagePlus,
          color: context.colors.onSurfaceVariant,
          size: 28,
        ),
        const SizedBox(height: 12),
        Text(
          title ?? AppLocalizations.of(context).venuePhotoEmptyTitle,
          style: KolabingTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: context.colors.onSurface),
        ),
        const SizedBox(height: 6),
        Text(
          description ?? AppLocalizations.of(context).venuePhotoEmptyDescription,
          style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.onSurfaceVariant, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: onAddPhoto,
          icon: const Icon(LucideIcons.plus, size: 18),
          label: Text(AppLocalizations.of(context).venuePhotoAddPhoto),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.colors.primary,
            foregroundColor: context.colors.onPrimary,
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

  String _sourceLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (photo.isGoogleImported) return l10n.venuePhotoSourceGoogle;
    if (photo.isHosted) return l10n.venuePhotoSourceSaved;
    return l10n.venuePhotoSourceUpload;
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.colors.darkBorder),
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
                      AppLocalizations.of(context).venuePhotoPositionLabel(
                        index + 1,
                        total,
                      ),
                      style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: context.colors.onSurface),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: photo.isGoogleImported
                            ? context.colors.softYellow
                            : context.colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _sourceLabel(context),
                        style: KolabingTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurface),
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
                          ? context.colors.textTertiary
                          : context.colors.onSurface,
                      tooltip: AppLocalizations.of(context).venuePhotoMoveEarlier,
                    ),
                    IconButton(
                      onPressed: onMoveRight,
                      icon: const Icon(LucideIcons.arrowRight, size: 18),
                      color: onMoveRight == null
                          ? context.colors.textTertiary
                          : context.colors.onSurface,
                      tooltip: AppLocalizations.of(context).venuePhotoMoveLater,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onRemove,
                      icon: const Icon(LucideIcons.trash2, size: 18),
                      color: context.colors.error,
                      tooltip: AppLocalizations.of(context).venuePhotoRemovePhoto,
                    ),
                  ],
                ),
                if (photo.authorAttributions.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _showCreditsSheet(context, photo),
                    icon: Icon(
                      LucideIcons.info,
                      size: 16,
                      color: context.colors.primary,
                    ),
                    label: Text(
                      AppLocalizations.of(context).venuePhotoCredits,
                      style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.primary),
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
        decoration: BoxDecoration(
          color: context.colors.surface,
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
                    color: context.colors.darkBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).venuePhotoCreditsSheetTitle,
                style: KolabingTextStyles.bodyMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w600, color: context.colors.onSurface),
              ),
              const SizedBox(height: 8),
              for (final item in photo.authorAttributions) ...[
                Text(
                  item.displayName,
                  style: KolabingTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700, color: context.colors.onSurface),
                ),
                if (item.uri != null && item.uri!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: SelectableText(
                      item.uri!,
                      style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.onSurfaceVariant),
                    ),
                  ),
                if (item.photoUri != null && item.photoUri!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: SelectableText(
                      item.photoUri!,
                      style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.onSurfaceVariant),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              Text(
                AppLocalizations.of(context).venuePhotoPoweredByGoogle,
                style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.textTertiary),
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
        errorBuilder: (context, _, _) => _placeholder(context),
      );
    }

    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context) => Container(
    width: 84,
    height: 84,
    color: context.colors.surfaceVariant,
    child: Icon(LucideIcons.imageOff, color: context.colors.textTertiary),
  );
}
