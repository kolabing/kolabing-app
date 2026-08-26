import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../config/constants/api.dart';
import '../config/constants/radius.dart';
import '../config/constants/spacing.dart';
import '../config/theme/colors.dart';
import '../config/theme/typography.dart';

/// A single photo entry rendered by [ImportedPhotoGrid].
class ImportedPhotoItem {
  const ImportedPhotoItem({required this.id, required this.url});

  /// Stable identifier used by the delete callback (e.g. a Google
  /// `resource_name` or the photo URL itself).
  final String id;

  /// Source URL. May be relative; the grid resolves it against the API base.
  final String url;
}

/// Renders a grid of imported photos (e.g. from a Google Places import) as
/// thumbnails, each with an "X" control to delete it from the selection before
/// the user continues.
///
/// Lives in the shared widgets layer so onboarding screens can preview imported
/// photos inline without depending on feature-internal widgets. Relative URLs
/// are made absolute against [ApiConfig.baseUrl]; broken images fall back to a
/// neutral placeholder via [Image.network]'s `errorBuilder`.
class ImportedPhotoGrid extends StatelessWidget {
  const ImportedPhotoGrid({
    required this.photos,
    required this.onRemove,
    super.key,
    this.crossAxisCount = 3,
  });

  final List<ImportedPhotoItem> photos;

  /// Called with the [ImportedPhotoItem.id] of the photo to remove.
  final ValueChanged<String> onRemove;

  final int crossAxisCount;

  /// Resolves a possibly-relative URL to an absolute one against the API base.
  static String resolveUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return '';

    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) {
      return trimmed;
    }

    final origin = Uri.parse('${ApiConfig.baseUrl}/');
    return origin.resolve(trimmed).toString();
  }

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photos.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: KolabingSpacing.sm,
        mainAxisSpacing: KolabingSpacing.sm,
      ),
      itemBuilder: (context, index) {
        final photo = photos[index];
        final resolvedUrl = resolveUrl(photo.url);

        return ClipRRect(
          borderRadius: KolabingRadius.borderRadiusMd,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (resolvedUrl.isEmpty)
                _placeholder(context)
              else
                Image.network(
                  resolvedUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _placeholder(context),
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
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => onRemove(photo.id),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: context.colors.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _placeholder(BuildContext context) => Container(
    color: context.colors.surfaceVariant,
    alignment: Alignment.center,
    child: Icon(
      LucideIcons.imageOff,
      color: context.colors.textTertiary,
      size: 22,
    ),
  );
}

/// A small "Powered by Google" attribution label to display under a grid of
/// imported Google photos.
class GoogleAttributionLabel extends StatelessWidget {
  const GoogleAttributionLabel({super.key});

  @override
  Widget build(BuildContext context) => Text(
    'Powered by Google',
    style: KolabingTextStyles.bodySmall.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: context.colors.textTertiary,
    ),
  );
}
