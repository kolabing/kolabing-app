import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/constants/radius.dart';
import '../../../../config/constants/spacing.dart';
import '../../../../config/theme/colors.dart';
import '../../../../services/upload_service.dart';
import '../../models/kolab.dart';
import '../../providers/kolab_form_provider.dart';

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
      final uploadService = ref.read(uploadServiceProvider);
      final url = await uploadService.upload(
        filePath: image.path,
        folder: 'kolabs',
      );
      ref.read(kolabFormProvider.notifier).updateMedia([
            KolabMedia(url: url, type: 'photo', sortOrder: 0),
          ]);
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kolabFormProvider);
    final useProfilePhoto = state.kolab.media.isEmpty;
    final uploadedPhoto = state.kolab.media.isNotEmpty
        ? state.kolab.media.first
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KolabingSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Text(
            'ADD A PHOTO',
            style: GoogleFonts.rubik(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: KolabingColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: KolabingSpacing.xxs),
          Text(
            'This will appear on your kolab card in Explore.',
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: KolabingColors.textSecondary,
            ),
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
                      : KolabingColors.border,
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
                            : KolabingColors.border,
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
                      'Use your community profile photo',
                      style: GoogleFonts.openSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: KolabingColors.textPrimary,
                      ),
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
              const Expanded(child: Divider(color: KolabingColors.border)),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: KolabingSpacing.sm),
                child: Text(
                  'OR',
                  style: GoogleFonts.openSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: KolabingColors.textTertiary,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: KolabingColors.border)),
            ],
          ),

          const SizedBox(height: KolabingSpacing.md),

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
                  border: Border.all(
                    color: KolabingColors.border,
                    width: 1,
                  ),
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
                        'Upload a photo',
                        style: GoogleFonts.openSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: KolabingColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: KolabingSpacing.xxs),
                      Text(
                        'Max 5MB',
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          color: KolabingColors.textTertiary,
                        ),
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

  bool get _isLocalFile => photo.url.isNotEmpty && !photo.url.startsWith('http');

  @override
  Widget build(BuildContext context) => Container(
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
                    ? Image.file(
                        File(photo.url),
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        photo.url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
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
              'Uploaded photo selected',
              style: GoogleFonts.openSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: KolabingColors.textPrimary,
              ),
            ),
            const SizedBox(height: KolabingSpacing.xxs),
            Text(
              'This image will appear on your kolab card in Explore.',
              style: GoogleFonts.openSans(
                fontSize: 13,
                color: KolabingColors.textSecondary,
              ),
            ),
            const SizedBox(height: KolabingSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isUploading ? null : onRemove,
                    child: const Text('Use profile photo'),
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
                    child: const Text('Replace photo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

/// Paints a dashed rounded rectangle border.
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
  });

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
