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
import '../../enums/intent_type.dart';
import '../../models/kolab.dart';
import '../../providers/kolab_form_provider.dart';

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
      final notifier = ref.read(kolabFormProvider.notifier);
      final kolab = ref.read(kolabFormProvider).kolab;
      notifier.addMedia(
        KolabMedia(
          url: url,
          type: 'photo',
          sortOrder: kolab.media.where((m) => m.type == 'photo').length,
        ),
      );
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: KolabingColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(kolabFormProvider);
    final kolab = formState.kolab;
    final errors = formState.fieldErrors;
    final notifier = ref.read(kolabFormProvider.notifier);

    final isVenue = formState.intentType == IntentType.venuePromotion;
    final title = isVenue ? 'SHOW OFF YOUR VENUE' : 'SHOW YOUR PRODUCT';

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: KolabingSpacing.md,
        vertical: KolabingSpacing.lg,
      ),
      children: [
        Text(
          title,
          style: GoogleFonts.rubik(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: KolabingColors.textSecondary,
          ),
        ),
        const SizedBox(height: KolabingSpacing.xs),
        Text(
          "Add photos so communities can see what you're offering. (Min 1, Max 5)",
          style: GoogleFonts.openSans(fontSize: 14, color: KolabingColors.textSecondary),
        ),
        const SizedBox(height: KolabingSpacing.md),

        if (errors.containsKey('media'))
          Padding(
            padding: const EdgeInsets.only(bottom: KolabingSpacing.xs),
            child: Text(errors['media']!, style: GoogleFonts.openSans(fontSize: 12, color: KolabingColors.error)),
          ),

        // Upload progress
        if (_isUploading)
          const Padding(
            padding: EdgeInsets.only(bottom: KolabingSpacing.sm),
            child: LinearProgressIndicator(color: KolabingColors.primary),
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
    final photos = media.where((m) => m.type == 'photo').toList();
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
                color: KolabingColors.surfaceVariant,
                borderRadius: KolabingRadius.borderRadiusMd,
                border: Border.all(
                  color: KolabingColors.border,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.plus,
                    size: 24,
                    color: KolabingColors.textSecondary,
                  ),
                  const SizedBox(height: KolabingSpacing.xxs),
                  Text(
                    'Add Photo',
                    style: GoogleFonts.openSans(
                      fontSize: 11,
                      color: KolabingColors.textSecondary,
                    ),
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
            color: KolabingColors.softYellow,
            borderRadius: KolabingRadius.borderRadiusMd,
            border: Border.all(color: KolabingColors.softYellowBorder),
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
                        _buildPlaceholder(),
                  )
                : Image.network(
                    url,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholder(),
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
              decoration: const BoxDecoration(
                color: KolabingColors.error,
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

  Widget _buildPlaceholder() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.image, size: 24, color: KolabingColors.textSecondary),
            const SizedBox(height: KolabingSpacing.xxs),
            Text(
              'Photo ${index + 1}',
              style: GoogleFonts.openSans(fontSize: 11, color: KolabingColors.textSecondary),
            ),
          ],
        ),
      );
}
