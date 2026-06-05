import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/onboarding_photo.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/onboarding_header.dart';

/// Business onboarding step 3: collect reusable venue photos.
class BusinessStep3Screen extends ConsumerStatefulWidget {
  const BusinessStep3Screen({super.key});

  @override
  ConsumerState<BusinessStep3Screen> createState() =>
      _BusinessStep3ScreenState();
}

class _BusinessStep3ScreenState extends ConsumerState<BusinessStep3Screen> {
  final _picker = ImagePicker();
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _configureSystemUI();
  }

  void _configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: KolabingColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  Future<void> _pickPhoto() async {
    if (_isPicking) return;

    setState(() => _isPicking = true);
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        await ref
            .read(onboardingProvider.notifier)
            .addVenuePhoto(File(image.path));
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final message = switch (e.code) {
        'photo_access_denied' || 'photo_access_restricted' =>
          l10n.businessStep3PhotoAccessDenied,
        _ => l10n.businessStep3PhotoLibraryError,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: context.colors.error),
      );
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  void _handleBack() {
    context.pop();
  }

  void _handleContinue() {
    final data = ref.read(onboardingProvider);
    if (data == null || data.venuePhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).businessStep3NoPhotosError,
          ),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }

    context.push('/onboarding/business/step5');
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);
    final photos = data?.venuePhotos ?? const [];
    final notifier = ref.read(onboardingProvider.notifier);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingHeader(
              currentStep: 2,
              totalSteps: 3,
              onBack: _handleBack,
              showSkip: false,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    Text(
                      AppLocalizations.of(context).businessStep3Title,
                      style: KolabingTextStyles.bodyLarge.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: context.colors.onSurface),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).businessStep3Subtitle,
                      style: KolabingTextStyles.bodySmall.copyWith(color: context.colors.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (_isPicking)
                      Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: LinearProgressIndicator(
                          color: context.colors.primary,
                        ),
                      ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (int i = 0; i < photos.length; i++)
                          _VenuePhotoTile(
                            photo: photos[i],
                            onRemove: () => notifier.removeVenuePhoto(i),
                          ),
                        if (photos.length < 5) _AddPhotoTile(onTap: _pickPhoto),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: photos.isNotEmpty ? _handleContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.onPrimary,
                    disabledBackgroundColor: context.colors.primary.withValues(
                      alpha: 0.5,
                    ),
                    disabledForegroundColor: context.colors.onPrimary
                        .withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    AppLocalizations.of(context).commonContinue,
                    style: KolabingTextStyles.button.copyWith(fontSize: 16, letterSpacing: 1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.darkBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.plus, color: context.colors.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).businessStep3AddPhoto,
            style: KolabingTextStyles.bodySmall.copyWith(fontSize: 12, color: context.colors.onSurfaceVariant),
          ),
        ],
      ),
    ),
  );
}

class _VenuePhotoTile extends StatelessWidget {
  const _VenuePhotoTile({required this.photo, required this.onRemove});

  final OnboardingPhoto photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _buildImage(),
      ),
      Positioned(
        top: 6,
        right: 6,
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: context.colors.error,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.x, size: 14, color: Colors.white),
          ),
        ),
      ),
    ],
  );

  Widget _buildImage() {
    final memoryBytes = photo.memoryBytes;
    if (memoryBytes != null) {
      return Image.memory(
        memoryBytes,
        width: 104,
        height: 104,
        fit: BoxFit.cover,
      );
    }

    final previewUrl = photo.previewUrl;
    if (previewUrl != null && previewUrl.isNotEmpty) {
      return Image.network(
        previewUrl,
        width: 104,
        height: 104,
        fit: BoxFit.cover,
      );
    }

    return const SizedBox(width: 104, height: 104);
  }
}
