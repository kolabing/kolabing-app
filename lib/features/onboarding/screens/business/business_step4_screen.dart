import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../config/theme/colors.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/onboarding_header.dart';

/// Business Onboarding Step 4: About + Contact Info (Optional)
class BusinessStep4Screen extends ConsumerStatefulWidget {
  const BusinessStep4Screen({super.key});

  @override
  ConsumerState<BusinessStep4Screen> createState() => _BusinessStep4ScreenState();
}

class _BusinessStep4ScreenState extends ConsumerState<BusinessStep4Screen> {
  final _aboutController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instagramController = TextEditingController();
  final _websiteController = TextEditingController();

  /// Phone validation error message (null = valid or empty)
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _configureSystemUI();
    _loadExistingData();
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

  void _loadExistingData() {
    final data = ref.read(onboardingProvider);
    if (data != null) {
      _aboutController.text = data.about ?? '';
      _phoneController.text = data.phone ?? '';
      _instagramController.text = data.instagram ?? '';
      _websiteController.text =
          data.website?.replaceFirst('https://', '') ?? '';
    }
  }

  @override
  void dispose() {
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

  void _handleSkip() {
    context.push('/onboarding/business/final');
  }

  void _handleContinue() {
    _saveData();
    context.push('/onboarding/business/final');
  }

  void _saveData() {
    final notifier = ref.read(onboardingProvider.notifier);
    notifier.updateAbout(_aboutController.text);
    notifier.updatePhone(_phoneController.text);
    notifier.updateInstagram(_instagramController.text);
    notifier.updateWebsite(_websiteController.text);
  }

  /// Validate phone number format in real-time
  ///
  /// Returns null if valid or empty, error message if invalid.
  /// Allows: digits, +, spaces, dashes, parentheses
  /// Minimum 9 digits (without country code prefix)
  void _validatePhone(String value) {
    if (value.isEmpty) {
      setState(() => _phoneError = null);
      return;
    }

    // Remove formatting characters for digit counting
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    // Check for invalid characters
    if (!RegExp(r'^[\d\s\+\-\(\)]+$').hasMatch(value)) {
      setState(() => _phoneError = 'Only numbers, +, -, () and spaces allowed');
      return;
    }

    // Check minimum digits (9 for Spanish numbers)
    if (digitsOnly.length < 9) {
      setState(() => _phoneError = 'Enter at least 9 digits');
      return;
    }

    // Check maximum length (15 digits is E.164 max)
    if (digitsOnly.length > 15) {
      setState(() => _phoneError = 'Phone number too long');
      return;
    }

    // Valid
    setState(() => _phoneError = null);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: KolabingColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              OnboardingHeader(
                currentStep: 4,
                onBack: _handleBack,
                onSkip: _handleSkip,
                showSkip: true,
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),

                      // Title
                      Center(
                        child: Text(
                          'TELL US MORE',
                          style: GoogleFonts.rubik(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: KolabingColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Center(
                        child: Text(
                          'Share details to make your profile stand out (all optional)',
                          style: GoogleFonts.openSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: KolabingColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // About field
                      Text(
                        'About Your Business',
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: KolabingColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _aboutController,
                        maxLength: 1000,
                        maxLines: 5,
                        minLines: 3,
                        style: GoogleFonts.openSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: KolabingColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Describe your business...',
                          hintStyle: GoogleFonts.openSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: KolabingColors.textTertiary,
                          ),
                          filled: true,
                          fillColor: KolabingColors.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                          counterStyle: GoogleFonts.openSans(
                            fontSize: 12,
                            color: KolabingColors.textTertiary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Phone field
                      Text(
                        'Phone Number',
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: KolabingColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        onChanged: _validatePhone,
                        style: GoogleFonts.openSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: KolabingColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: '+34 612 345 678',
                          hintStyle: GoogleFonts.openSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: KolabingColors.textTertiary,
                          ),
                          prefixIcon: Icon(
                            LucideIcons.phone,
                            size: 20,
                            color: _phoneError != null
                                ? KolabingColors.error
                                : KolabingColors.textTertiary,
                          ),
                          filled: true,
                          fillColor: _phoneError != null
                              ? KolabingColors.error.withValues(alpha: 0.08)
                              : KolabingColors.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: _phoneError != null
                                ? const BorderSide(
                                    color: KolabingColors.error,
                                    width: 1.5,
                                  )
                                : BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _phoneError != null
                                  ? KolabingColors.error
                                  : KolabingColors.primary,
                              width: 1.5,
                            ),
                          ),
                          errorText: _phoneError,
                          errorStyle: GoogleFonts.openSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: KolabingColors.error,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Instagram field
                      Text(
                        'Instagram',
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: KolabingColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _instagramController,
                        style: GoogleFonts.openSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: KolabingColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'username',
                          hintStyle: GoogleFonts.openSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: KolabingColors.textTertiary,
                          ),
                          prefixIcon: const Icon(
                            LucideIcons.instagram,
                            size: 20,
                            color: KolabingColors.textTertiary,
                          ),
                          prefixText: '@ ',
                          prefixStyle: GoogleFonts.openSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: KolabingColors.textTertiary,
                          ),
                          filled: true,
                          fillColor: KolabingColors.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Website field
                      Text(
                        'Website',
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: KolabingColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _websiteController,
                        keyboardType: TextInputType.url,
                        style: GoogleFonts.openSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: KolabingColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'www.example.com',
                          hintStyle: GoogleFonts.openSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: KolabingColors.textTertiary,
                          ),
                          prefixIcon: const Icon(
                            LucideIcons.globe,
                            size: 20,
                            color: KolabingColors.textTertiary,
                          ),
                          filled: true,
                          fillColor: KolabingColors.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom button
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KolabingColors.primary,
                      foregroundColor: KolabingColors.onPrimary,
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
                        letterSpacing: 1.0,
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
