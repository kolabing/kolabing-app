import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../models/place_details_import.dart';

/// Bottom sheet that previews the photos returned from Google Places import
/// and lets the user remove individual ones before they land in onboarding state.
///
/// Returns the set of `resourceName`s the user chose to keep. If the user
/// dismisses the sheet (swipe down / back), the current selection is returned —
/// dismissal is treated as "confirm with what's shown" so we never silently
/// throw away photos the user didn't actively remove.
class GooglePhotosPreviewSheet extends StatefulWidget {
  const GooglePhotosPreviewSheet({required this.photos, super.key});

  final List<ImportedGooglePhoto> photos;

  static Future<Set<String>> show(
    BuildContext context, {
    required List<ImportedGooglePhoto> photos,
  }) async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => GooglePhotosPreviewSheet(photos: photos),
    );
    return result ??
        photos.map((photo) => photo.resourceName).toSet();
  }

  @override
  State<GooglePhotosPreviewSheet> createState() =>
      _GooglePhotosPreviewSheetState();
}

class _GooglePhotosPreviewSheetState extends State<GooglePhotosPreviewSheet> {
  late final Set<String> _kept = widget.photos
      .map((photo) => photo.resourceName)
      .toSet();

  void _toggle(String resourceName) {
    setState(() {
      if (_kept.contains(resourceName)) {
        _kept.remove(resourceName);
      } else {
        _kept.add(resourceName);
      }
    });
  }

  void _confirm() => Navigator.of(context).pop(Set<String>.from(_kept));

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.85;
    final keptCount = _kept.length;
    final buttonLabel = keptCount == 0
        ? 'SKIP PHOTOS'
        : 'ADD $keptCount PHOTO${keptCount == 1 ? '' : 'S'}';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // If the user swipes/backs out without tapping the button, treat as
        // confirm with the current selection rather than discarding everything.
      },
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.darkBorder,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review photos from Google',
                    style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: context.colors.onSurface),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap any photo to remove it before we add it to your venue. You can always edit photos later.',
                    style: KolabingTextStyles.captionSecondary.copyWith(color: context.colors.onSurfaceVariant, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                itemCount: widget.photos.length,
                itemBuilder: (context, index) {
                  final photo = widget.photos[index];
                  final isKept = _kept.contains(photo.resourceName);
                  return _PhotoTile(
                    photo: photo,
                    isKept: isKept,
                    onTap: () => _toggle(photo.resourceName),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                12 + mediaQuery.padding.bottom,
              ),
              decoration: BoxDecoration(
                color: context.colors.surface,
                border: Border(
                  top: BorderSide(color: context.colors.darkBorder),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.info,
                        size: 14,
                        color: context.colors.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Photos from Google. Credits are kept with each photo.',
                          style: KolabingTextStyles.labelSmall.copyWith(color: context.colors.textTertiary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primary,
                        foregroundColor: context.colors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        buttonLabel,
                        style: KolabingTextStyles.button.copyWith(fontSize: 15, letterSpacing: 1),
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
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.isKept,
    required this.onTap,
  });

  final ImportedGooglePhoto photo;
  final bool isKept;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ColorFiltered(
              colorFilter: isKept
                  ? const ColorFilter.mode(
                      Colors.transparent,
                      BlendMode.dst,
                    )
                  : const ColorFilter.matrix(<double>[
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0, 0, 0, 1, 0,
                    ]),
              child: Image.network(
                photo.previewUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: context.colors.surfaceVariant,
                  alignment: Alignment.center,
                  child: Icon(
                    LucideIcons.imageOff,
                    size: 22,
                    color: context.colors.textTertiary,
                  ),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: context.colors.surfaceVariant,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.colors.primary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (!isKept)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isKept ? context.colors.primary : context.colors.error,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                isKept ? LucideIcons.check : LucideIcons.x,
                size: 16,
                color: isKept
                    ? context.colors.onPrimary
                    : context.colors.surface,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
