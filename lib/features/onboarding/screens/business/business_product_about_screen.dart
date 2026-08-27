import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/routes/routes.dart';
import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/onboarding_header.dart';
import '../../widgets/venue_photo_manager.dart';

/// Product path step 3: optional "what you offer" + photos + about/contact.
///
/// All fields are optional. Photos are stored in [OnboardingData.venuePhotos]
/// and submitted as `offer_photos` for the product path (see
/// [OnboardingData.toBusinessPayload]). Continues to `/onboarding/business/final`.
class BusinessProductAboutScreen extends ConsumerStatefulWidget {
  const BusinessProductAboutScreen({super.key});

  @override
  ConsumerState<BusinessProductAboutScreen> createState() =>
      _BusinessProductAboutScreenState();
}

class _BusinessProductAboutScreenState
    extends ConsumerState<BusinessProductAboutScreen> {
  final _picker = ImagePicker();
  final _offeringController = TextEditingController();
  final _aboutController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instagramController = TextEditingController();
  final _websiteController = TextEditingController();

  bool _isPickingPhoto = false;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _configureSystemUI();
    _hydrateControllers();
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

  void _hydrateControllers() {
    final data = ref.read(onboardingProvider);
    _offeringController.text = data?.offering ?? '';
    _aboutController.text = data?.about ?? '';
    _phoneController.text = _normalizePhoneNumber(data?.phone ?? '');
    _instagramController.text = data?.instagram ?? '';
    _websiteController.text = data?.website?.replaceFirst('https://', '') ?? '';
  }

  @override
  void dispose() {
    _offeringController.dispose();
    _aboutController.dispose();
    _phoneController.dispose();
    _instagramController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _saveData() {
    final notifier = ref.read(onboardingProvider.notifier);
    notifier.updateOffering(_offeringController.text);
    notifier.updateAbout(_aboutController.text);
    notifier.updatePhone(_normalizePhoneNumber(_phoneController.text));
    notifier.updateInstagram(_instagramController.text);
    notifier.updateWebsite(_websiteController.text);
  }

  void _handleBack() {
    _saveData();
    context.pop();
  }

  void _handleContinue() {
    if (_phoneError != null) return;
    _saveData();
    context.push(KolabingRoutes.businessOnboardingFinal);
  }

  Future<void> _pickPhoto() async {
    if (_isPickingPhoto) return;
    setState(() => _isPickingPhoto = true);
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
        'photo_access_denied' ||
        'photo_access_restricted' => l10n.businessStep2PhotoAccessDenied,
        _ => l10n.businessStep2PhotoLibraryError,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: context.colors.error),
      );
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  void _validatePhone(String value) {
    if (value.isEmpty) {
      setState(() => _phoneError = null);
      return;
    }
    final l10n = AppLocalizations.of(context);
    if (!value.startsWith('+')) {
      setState(() => _phoneError = l10n.businessStep2PhoneMustStartPlus);
      return;
    }
    final afterPlus = value.substring(1);
    if (!RegExp(r'^\d*$').hasMatch(afterPlus)) {
      setState(() => _phoneError = l10n.businessStep2PhoneDigitsOnly);
      return;
    }
    if (afterPlus.length < 9) {
      setState(() => _phoneError = l10n.businessStep2PhoneTooShort);
      return;
    }
    if (afterPlus.length > 14) {
      setState(() => _phoneError = l10n.businessStep2PhoneTooLong);
      return;
    }
    setState(() => _phoneError = null);
  }

  String _normalizePhoneNumber(String value) {
    if (value.isEmpty) return '';
    String normalized = value.replaceAll(RegExp(r'[^\d+]'), '');
    if (normalized.contains('+')) {
      normalized = '+${normalized.replaceAll('+', '')}';
    }
    if (!normalized.startsWith('+')) {
      if (normalized.startsWith('00')) {
        normalized = '+${normalized.substring(2)}';
      } else {
        normalized = '+34$normalized';
      }
    }
    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingHeader(
              currentStep: 4,
              totalSteps: 4,
              onBack: _handleBack,
              showSkip: false,
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    Center(
                      child: Text(
                        l10n.businessProductAboutTitle,
                        style: KolabingTextStyles.bodyLarge.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: context.colors.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        l10n.businessProductAboutSubtitle,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _FieldLabel(label: l10n.businessProductOfferingLabel),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _offeringController,
                      minLines: 2,
                      maxLines: 4,
                      maxLength: 500,
                      onChanged: notifier.updateOffering,
                      decoration: _inputDecoration(
                        context,
                        hint: l10n.businessProductOfferingHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FieldLabel(label: l10n.businessProductPhotosLabel),
                    const SizedBox(height: 8),
                    VenuePhotoManager(
                      photos: data?.venuePhotos ?? const [],
                      isUploading: _isPickingPhoto,
                      emptyTitle: l10n.businessProductPhotosEmptyTitle,
                      emptyDescription:
                          l10n.businessProductPhotosEmptyDescription,
                      onAddPhoto: _pickPhoto,
                      onRemovePhoto: notifier.removeVenuePhoto,
                      onMovePhoto: notifier.moveVenuePhoto,
                    ),
                    const SizedBox(height: 24),
                    _FieldLabel(label: l10n.businessStep2AboutLabel),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _aboutController,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 1000,
                      onChanged: notifier.updateAbout,
                      decoration: _inputDecoration(
                        context,
                        hint: l10n.businessStep2AboutHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FieldLabel(label: l10n.businessStep2PhoneLabel),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      onChanged: (value) {
                        _validatePhone(value);
                        notifier.updatePhone(_normalizePhoneNumber(value));
                      },
                      decoration: _inputDecoration(
                        context,
                        hint: '+34612345678',
                        prefixIcon: LucideIcons.phone,
                        errorText: _phoneError,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel(label: l10n.businessStep2InstagramLabel),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _instagramController,
                      onChanged: notifier.updateInstagram,
                      decoration: _inputDecoration(
                        context,
                        hint: '@yourbusiness',
                        prefixIcon: LucideIcons.instagram,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel(label: l10n.businessStep2WebsiteLabel),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _websiteController,
                      keyboardType: TextInputType.url,
                      onChanged: notifier.updateWebsite,
                      decoration: _inputDecoration(
                        context,
                        hint: 'yourbusiness.com',
                        prefixIcon: LucideIcons.globe,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                  onPressed: _phoneError == null ? _handleContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.onPrimary,
                    disabledBackgroundColor: context.colors.primary.withValues(
                      alpha: 0.5,
                    ),
                    disabledForegroundColor: context.colors.onPrimary
                        .withValues(alpha: 0.5),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.commonContinue,
                    style: KolabingTextStyles.button.copyWith(
                      fontSize: 16,
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: KolabingTextStyles.bodySmall.copyWith(
      fontWeight: FontWeight.w700,
      color: context.colors.onSurface,
    ),
  );
}

InputDecoration _inputDecoration(
  BuildContext context, {
  required String hint,
  IconData? prefixIcon,
  String? errorText,
}) => InputDecoration(
  hintText: hint,
  hintStyle: KolabingTextStyles.bodyMedium.copyWith(
    color: context.colors.textTertiary,
  ),
  prefixIcon: prefixIcon == null
      ? null
      : Icon(prefixIcon, size: 20, color: context.colors.textTertiary),
  errorText: errorText,
  filled: true,
  fillColor: context.colors.surfaceContainerLow,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: context.colors.outlineVariant),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: context.colors.outlineVariant),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: context.colors.primary, width: 1.5),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: context.colors.error),
  ),
);
