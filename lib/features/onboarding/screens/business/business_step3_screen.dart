import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/theme/colors.dart';
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
      const SystemUiOverlayStyle(
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
      final message = switch (e.code) {
        'photo_access_denied' || 'photo_access_restricted' =>
          'Please allow Photos access in Settings to add venue images.',
        _ => 'We could not open your photo library. Please try again.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: KolabingColors.error),
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
        const SnackBar(
          content: Text('Add at least one venue photo to continue'),
          backgroundColor: KolabingColors.error,
        ),
      );
      return;
    }

    context.push('/onboarding/business/step4');
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);
    final photos = data?.venuePhotos ?? const [];
    final notifier = ref.read(onboardingProvider.notifier);

    return Scaffold(
      backgroundColor: KolabingColors.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingHeader(
              currentStep: 2,
              totalSteps: 4,
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
                      'ADD VENUE PHOTOS',
                      style: GoogleFonts.rubik(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: KolabingColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'These become your reusable venue gallery, so you won’t need to upload them again every time you create a venue Kolab.',
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        color: KolabingColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (_isPicking)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: LinearProgressIndicator(
                          color: KolabingColors.primary,
                        ),
                      ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (int i = 0; i < photos.length; i++)
                          _VenuePhotoTile(
                            base64: photos[i].base64,
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
                    backgroundColor: KolabingColors.primary,
                    foregroundColor: KolabingColors.onPrimary,
                    disabledBackgroundColor: KolabingColors.primary.withValues(
                      alpha: 0.5,
                    ),
                    disabledForegroundColor: KolabingColors.onPrimary
                        .withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'CONTINUE',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
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
        color: KolabingColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KolabingColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.plus, color: KolabingColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            'Add Photo',
            style: GoogleFonts.openSans(
              fontSize: 12,
              color: KolabingColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}

class _VenuePhotoTile extends StatelessWidget {
  const _VenuePhotoTile({required this.base64, required this.onRemove});

  final String base64;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          base64Decode(base64),
          width: 104,
          height: 104,
          fit: BoxFit.cover,
        ),
      ),
      Positioned(
        top: 6,
        right: 6,
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: KolabingColors.error,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.x, size: 14, color: Colors.white),
          ),
        ),
      ),
    ],
  );
}
