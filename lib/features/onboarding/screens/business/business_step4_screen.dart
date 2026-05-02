import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/theme/colors.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/onboarding_header.dart';
import '../../widgets/photo_upload_widget.dart';
import '../../widgets/type_selection_card.dart';

/// Business onboarding step 4: collect business profile details.
class BusinessStep4Screen extends ConsumerStatefulWidget {
  const BusinessStep4Screen({super.key});

  @override
  ConsumerState<BusinessStep4Screen> createState() =>
      _BusinessStep4ScreenState();
}

class _BusinessStep4ScreenState extends ConsumerState<BusinessStep4Screen> {
  final _nameController = TextEditingController();
  final _aboutController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instagramController = TextEditingController();
  final _websiteController = TextEditingController();

  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _configureSystemUI();
    final data = ref.read(onboardingProvider);
    _nameController.text = data?.name ?? '';
    _aboutController.text = data?.about ?? '';
    _phoneController.text = data?.phone ?? '';
    _instagramController.text = data?.instagram ?? '';
    _websiteController.text = data?.website?.replaceFirst('https://', '') ?? '';
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

  @override
  void dispose() {
    _nameController.dispose();
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

  void _handleContinue() {
    _saveData();
    final data = ref.read(onboardingProvider);
    if (data == null || !data.isStep4Complete || _phoneError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the required business details'),
          backgroundColor: KolabingColors.error,
        ),
      );
      return;
    }
    context.push('/onboarding/business/step5');
  }

  void _saveData() {
    final notifier = ref.read(onboardingProvider.notifier);
    notifier.updateName(_nameController.text);
    notifier.updateAbout(_aboutController.text);
    notifier.updatePhone(_normalizePhoneNumber(_phoneController.text));
    notifier.updateInstagram(_instagramController.text);
    notifier.updateWebsite(_websiteController.text);
  }

  void _validatePhone(String value) {
    if (value.isEmpty) {
      setState(() => _phoneError = null);
      return;
    }
    if (!value.startsWith('+')) {
      setState(() => _phoneError = 'Must start with + (e.g. +34612345678)');
      return;
    }
    final afterPlus = value.substring(1);
    if (!RegExp(r'^\d*$').hasMatch(afterPlus)) {
      setState(() => _phoneError = 'Use E.164 format with digits only');
      return;
    }
    if (afterPlus.length < 9) {
      setState(() => _phoneError = 'Enter at least 9 digits after +');
      return;
    }
    if (afterPlus.length > 14) {
      setState(() => _phoneError = 'Phone number too long');
      return;
    }
    setState(() => _phoneError = null);
  }

  String _normalizePhoneNumber(String value) {
    if (value.isEmpty) return '';
    String normalized = value.replaceAll(RegExp(r'[^\d+]'), '');
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
    final businessTypes = ref.watch(businessTypesProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final canContinue = data?.isStep4Complete == true && _phoneError == null;
    final selectedTypeIds = data?.selectedBusinessTypeIds ?? const <String>[];

    return Scaffold(
      backgroundColor: KolabingColors.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingHeader(
              currentStep: 3,
              totalSteps: 4,
              onBack: _handleBack,
              showSkip: false,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    Center(
                      child: Text(
                        'FINISH YOUR BUSINESS PROFILE',
                        style: GoogleFonts.rubik(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: KolabingColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'We only ask these profile details once, then reuse them across your business experience.',
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          color: KolabingColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    PhotoUploadWidget(
                      photoBase64: data?.photoBase64,
                      onPhotoSelected: (file) => notifier.updatePhoto(file),
                      onPhotoRemoved: notifier.clearPhoto,
                    ),
                    const SizedBox(height: 24),
                    _FieldLabel(label: 'Business Name'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      maxLength: 255,
                      onChanged: notifier.updateName,
                      decoration: _inputDecoration(
                        hint: 'Enter your business name',
                      ),
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel(label: 'Business Type'),
                    const SizedBox(height: 12),
                    Text(
                      'Select up to 3 categories that describe your business.',
                      style: GoogleFonts.openSans(
                        fontSize: 13,
                        color: KolabingColors.textSecondary,
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
                        'Failed to load business types',
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          color: KolabingColors.error,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _FieldLabel(label: 'About Your Business'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _aboutController,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 1000,
                      onChanged: notifier.updateAbout,
                      decoration: _inputDecoration(
                        hint: 'Share what makes your business special',
                      ),
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel(label: 'Phone Number'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      onChanged: (value) {
                        _validatePhone(value);
                        notifier.updatePhone(_normalizePhoneNumber(value));
                      },
                      decoration: _inputDecoration(
                        hint: '+34 612 345 678',
                        prefixIcon: LucideIcons.phone,
                        errorText: _phoneError,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel(label: 'Instagram'),
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
                    _FieldLabel(label: 'Website'),
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: GoogleFonts.openSans(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: KolabingColors.textPrimary,
    ),
  );
}

InputDecoration _inputDecoration({
  required String hint,
  IconData? prefixIcon,
  String? errorText,
}) => InputDecoration(
  hintText: hint,
  hintStyle: GoogleFonts.openSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: KolabingColors.textTertiary,
  ),
  prefixIcon: prefixIcon == null
      ? null
      : Icon(prefixIcon, size: 20, color: KolabingColors.textTertiary),
  errorText: errorText,
  errorStyle: GoogleFonts.openSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: KolabingColors.error,
  ),
  filled: true,
  fillColor: KolabingColors.surfaceVariant,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: KolabingColors.border),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: KolabingColors.border),
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
