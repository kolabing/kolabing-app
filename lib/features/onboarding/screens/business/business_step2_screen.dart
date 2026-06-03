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
import '../../../auth/models/user_model.dart';
import '../../../kolab/enums/venue_type.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/onboarding_header.dart';
import '../../widgets/photo_upload_widget.dart';
import '../../widgets/type_selection_card.dart';
import '../../widgets/venue_photo_manager.dart';

/// Business onboarding step 2: review imported data, complete required fields,
/// and curate the reusable primary venue gallery.
class BusinessStep2Screen extends ConsumerStatefulWidget {
  const BusinessStep2Screen({super.key});

  @override
  ConsumerState<BusinessStep2Screen> createState() =>
      _BusinessStep2ScreenState();
}

class _BusinessStep2ScreenState extends ConsumerState<BusinessStep2Screen> {
  final _picker = ImagePicker();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();
  final _aboutController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instagramController = TextEditingController();
  final _websiteController = TextEditingController();

  bool _isPickingVenuePhoto = false;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _configureSystemUI();
    _hydrateControllers();
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

  void _hydrateControllers() {
    final data = ref.read(onboardingProvider);
    _nameController.text = data?.name ?? '';
    _capacityController.text = data?.venueCapacity != null
        ? '${data!.venueCapacity}'
        : '';
    _aboutController.text = data?.about ?? '';
    _phoneController.text = _normalizePhoneNumber(data?.phone ?? '');
    _instagramController.text = data?.instagram ?? '';
    _websiteController.text = data?.website?.replaceFirst('https://', '') ?? '';
    _validatePhone(_phoneController.text);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _aboutController.dispose();
    _phoneController.dispose();
    _instagramController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _handleBack() {
    _saveData();
    context.pop();
  }

  void _handleChangeVenue() {
    _saveData();
    context.go('/onboarding/business/step5');
  }

  void _saveData() {
    final notifier = ref.read(onboardingProvider.notifier);
    notifier.updateName(_nameController.text);
    notifier.updateVenueCapacity(int.tryParse(_capacityController.text.trim()));
    notifier.updateAbout(_aboutController.text);
    notifier.updatePhone(_normalizePhoneNumber(_phoneController.text));
    notifier.updateInstagram(_instagramController.text);
    notifier.updateWebsite(_websiteController.text);
  }

  Future<void> _pickVenuePhoto() async {
    if (_isPickingVenuePhoto) return;

    setState(() => _isPickingVenuePhoto = true);
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
          l10n.businessStep2PhotoAccessDenied,
        _ => l10n.businessStep2PhotoLibraryError,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: KolabingColors.error),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingVenuePhoto = false);
      }
    }
  }

  void _handleContinue() {
    _saveData();
    final data = ref.read(onboardingProvider);
    if (data == null ||
        !data.isStep2Complete ||
        data.venuePhotos.isEmpty ||
        _phoneError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).businessStep2IncompleteError,
          ),
          backgroundColor: KolabingColors.error,
        ),
      );
      return;
    }
    context.push('/onboarding/business/final');
  }

  void _validatePhone(String value) {
    if (value.isEmpty) {
      setState(() => _phoneError = null);
      return;
    }
    if (!value.startsWith('+')) {
      setState(
        () => _phoneError = AppLocalizations.of(
          context,
        ).businessStep2PhoneMustStartPlus,
      );
      return;
    }
    final afterPlus = value.substring(1);
    if (!RegExp(r'^\d*$').hasMatch(afterPlus)) {
      setState(
        () => _phoneError = AppLocalizations.of(
          context,
        ).businessStep2PhoneDigitsOnly,
      );
      return;
    }
    if (afterPlus.length < 9) {
      setState(
        () => _phoneError = AppLocalizations.of(
          context,
        ).businessStep2PhoneTooShort,
      );
      return;
    }
    if (afterPlus.length > 14) {
      setState(
        () =>
            _phoneError = AppLocalizations.of(context).businessStep2PhoneTooLong,
      );
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
    final data = ref.watch(onboardingProvider);

    if (data == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(onboardingProvider.notifier).initialize(UserType.business);
        context.go('/onboarding/business/step5');
      });
      return const SizedBox.shrink();
    }

    if (data.location == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/onboarding/business/step5');
      });
      return const SizedBox.shrink();
    }

    final businessTypes = ref.watch(businessTypesProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final selectedTypeIds = businessTypes.maybeWhen(
      data: (types) => types
          .where((type) => data.selectedBusinessTypeSlugs.contains(type.slug))
          .map((type) => type.id)
          .toList(growable: false),
      orElse: () => data.selectedBusinessTypeIds,
    );
    final selectedVenueType = data.venueType;
    final canContinue =
        data.isStep2Complete &&
        data.venuePhotos.isNotEmpty &&
        _phoneError == null;

    return Scaffold(
      backgroundColor: KolabingColors.background,
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
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    Center(
                      child: Text(
                        AppLocalizations.of(context).businessStep2Title,
                        style: KolabingTextStyles.bodyLarge.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: KolabingColors.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        AppLocalizations.of(context).businessStep2Subtitle,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: KolabingColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (data.importedPlaceId != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: KolabingColors.softYellow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: KolabingColors.softYellowBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.sparkles,
                              size: 18,
                              color: KolabingColors.primaryDark,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).businessStep2ImportedBanner,
                                style: KolabingTextStyles.captionSecondary.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: KolabingColors.primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    PhotoUploadWidget(
                      photoBase64: data.photoBase64,
                      onPhotoSelected: notifier.updatePhoto,
                      onPhotoRemoved: notifier.clearPhoto,
                      // E5: this slot is the business brand logo, not a venue
                      // photo. Venue photos use VenuePhotoManager below.
                      addLabel: AppLocalizations.of(
                        context,
                      ).businessStep2AddLogo,
                    ),
                    const SizedBox(height: 24),
                    _FieldLabel(
                      label: AppLocalizations.of(
                        context,
                      ).businessStep2VenueAddressLabel,
                    ),
                    const SizedBox(height: 8),
                    _VenueAddressCard(
                      address: data.location!.formattedAddress,
                      city: data.location!.city,
                      onChangeVenue: _handleChangeVenue,
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel(
                      label: AppLocalizations.of(
                        context,
                      ).businessStep2BusinessNameLabel,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      maxLength: 255,
                      onChanged: notifier.updateName,
                      decoration: _inputDecoration(
                        hint: AppLocalizations.of(
                          context,
                        ).businessStep2BusinessNameHint,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel(
                      label: AppLocalizations.of(
                        context,
                      ).businessStep2BusinessTypeLabel,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).businessStep2BusinessTypeHint,
                      style: KolabingTextStyles.captionSecondary.copyWith(
                        color: KolabingColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    businessTypes.when(
                      data: (types) => GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.9,
                            ),
                        itemCount: types.length,
                        itemBuilder: (context, index) {
                          final type = types[index];
                          return TypeSelectionCard(
                            id: type.id,
                            name: type.name,
                            icon: type.icon,
                            isSelected: selectedTypeIds.contains(type.id),
                            onTap: () => notifier.toggleBusinessType(type),
                          );
                        },
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: KolabingColors.primary,
                        ),
                      ),
                      error: (_, __) => Text(
                        AppLocalizations.of(
                          context,
                        ).businessStep2BusinessTypesLoadError,
                        style: KolabingTextStyles.bodySmall.copyWith(
                          color: KolabingColors.error,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _FieldLabel(
                      label: AppLocalizations.of(
                        context,
                      ).businessStep2VenueTypeLabel,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: VenueType.values.map((type) {
                        final isSelected =
                            selectedVenueType == type.toApiValue();
                        return GestureDetector(
                          onTap: () =>
                              notifier.updateVenueType(type.toApiValue()),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? KolabingColors.primary
                                  : KolabingColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? KolabingColors.primary
                                    : KolabingColors.darkBorder,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  type.icon,
                                  size: 16,
                                  color: isSelected
                                      ? KolabingColors.onPrimary
                                      : KolabingColors.onSurface,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  type.displayName,
                                  style: KolabingTextStyles.bodySmall.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? KolabingColors.onPrimary
                                        : KolabingColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel(
                      label: AppLocalizations.of(
                        context,
                      ).businessStep2CapacityLabel,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).businessStep2CapacityHelper,
                      style: KolabingTextStyles.captionSecondary.copyWith(
                        color: KolabingColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _capacityController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) =>
                          notifier.updateVenueCapacity(int.tryParse(value)),
                      decoration: _inputDecoration(
                        hint: AppLocalizations.of(
                          context,
                        ).businessStep2CapacityHint,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _FieldLabel(
                      label: AppLocalizations.of(
                        context,
                      ).businessStep2VenuePhotosLabel,
                    ),
                    const SizedBox(height: 8),
                    VenuePhotoManager(
                      photos: data.venuePhotos,
                      isUploading: _isPickingVenuePhoto,
                      onAddPhoto: _pickVenuePhoto,
                      onRemovePhoto: notifier.removeVenuePhoto,
                      onMovePhoto: notifier.moveVenuePhoto,
                    ),
                    const SizedBox(height: 24),
                    _FieldLabel(
                      label: AppLocalizations.of(
                        context,
                      ).businessStep2AboutLabel,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _aboutController,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 1000,
                      onChanged: notifier.updateAbout,
                      decoration: _inputDecoration(
                        hint: AppLocalizations.of(context).businessStep2AboutHint,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel(
                      label: AppLocalizations.of(
                        context,
                      ).businessStep2PhoneLabel,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: const [_E164PhoneInputFormatter()],
                      onChanged: (value) {
                        _validatePhone(value);
                        notifier.updatePhone(_normalizePhoneNumber(value));
                      },
                      decoration: _inputDecoration(
                        hint: '+34612345678',
                        prefixIcon: LucideIcons.phone,
                        errorText: _phoneError,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel(
                      label: AppLocalizations.of(
                        context,
                      ).businessStep2InstagramLabel,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _instagramController,
                      onChanged: notifier.updateInstagram,
                      decoration: _inputDecoration(
                        hint: '@yourbusiness',
                        prefixIcon: LucideIcons.instagram,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel(
                      label: AppLocalizations.of(
                        context,
                      ).businessStep2WebsiteLabel,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _websiteController,
                      keyboardType: TextInputType.url,
                      onChanged: notifier.updateWebsite,
                      decoration: _inputDecoration(
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
                  onPressed: canContinue ? _handleContinue : null,
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
                    AppLocalizations.of(context).commonContinue,
                    style: KolabingTextStyles.button.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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

class _E164PhoneInputFormatter extends TextInputFormatter {
  const _E164PhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawText = newValue.text;
    if (rawText.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    var sanitized = rawText.replaceAll(RegExp(r'[^\d+]'), '');
    if (sanitized.contains('+')) {
      sanitized = '+${sanitized.replaceAll('+', '')}';
    }

    final caretOffset = sanitized.length.clamp(0, sanitized.length);
    return TextEditingValue(
      text: sanitized,
      selection: TextSelection.collapsed(offset: caretOffset),
      composing: TextRange.empty,
    );
  }
}

class _VenueAddressCard extends StatelessWidget {
  const _VenueAddressCard({
    required this.address,
    required this.city,
    required this.onChangeVenue,
  });

  final String address;
  final String city;
  final VoidCallback onChangeVenue;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: KolabingColors.surfaceVariant,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: KolabingColors.darkBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.mapPin,
              size: 18,
              color: KolabingColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                address,
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: KolabingColors.onSurface,
                ),
              ),
            ),
          ],
        ),
        if (city.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            city,
            style: KolabingTextStyles.captionSecondary.copyWith(
              color: KolabingColors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onChangeVenue,
          icon: const Icon(
            LucideIcons.refreshCcw,
            size: 16,
            color: KolabingColors.primary,
          ),
          label: Text(
            AppLocalizations.of(context).businessStep2ChangeVenue,
            style: KolabingTextStyles.captionSecondary.copyWith(
              fontWeight: FontWeight.w600,
              color: KolabingColors.primary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: KolabingTextStyles.bodySmall.copyWith(
      fontWeight: FontWeight.w700,
      color: KolabingColors.onSurface,
    ),
  );
}

InputDecoration _inputDecoration({
  required String hint,
  IconData? prefixIcon,
  String? errorText,
}) => InputDecoration(
  hintText: hint,
  hintStyle: KolabingTextStyles.bodyMedium.copyWith(
    color: KolabingColors.textTertiary,
  ),
  prefixIcon: prefixIcon == null
      ? null
      : Icon(prefixIcon, size: 20, color: KolabingColors.textTertiary),
  errorText: errorText,
  errorStyle: KolabingTextStyles.bodySmall.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: KolabingColors.error,
  ),
  filled: true,
  fillColor: KolabingColors.surfaceVariant,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: KolabingColors.darkBorder),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: KolabingColors.darkBorder),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: KolabingColors.primary, width: 1.5),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: KolabingColors.error),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: KolabingColors.error, width: 1.5),
  ),
);
